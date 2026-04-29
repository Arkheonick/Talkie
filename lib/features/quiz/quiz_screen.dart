import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_result.dart';
import '../../models/quiz_session.dart';
import '../../models/quiz_theme.dart';
import '../../services/gemini_service.dart';
import '../../services/quiz_result_service.dart';
import 'quiz_summary_screen.dart';

enum _QState { loading, active, tierDone, error }

class QuizScreen extends StatefulWidget {
  final QuizSession session;
  final QuizTheme theme;

  const QuizScreen({
    super.key,
    required this.session,
    required this.theme,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final _gemini = GeminiService();
  final _resultService = QuizResultService();

  late QuizSession _session;
  _QState _state = _QState.loading;
  int? _selectedIndex;
  late AnimationController _feedbackController;

  QuizQuestion get _current =>
      _session.currentTierQuestions[_session.currentQuestionIndex];

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gemini.init();
    _resultService.init().then((_) => _loadTier());
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadTier() async {
    setState(() {
      _state = _QState.loading;
      _selectedIndex = null;
    });
    final questions = await _gemini.generateQuizTier(
      theme: _session.themeLabel,
      level: _session.level,
      tier: _session.currentTier,
    );
    if (!mounted) return;
    if (questions.isEmpty) {
      setState(() => _state = _QState.error);
      return;
    }
    setState(() {
      _session.currentTierQuestions = questions;
      _session.currentQuestionIndex = 0;
      _session.currentTierAnswers.clear();
      _selectedIndex = null;
      _state = _QState.active;
    });
  }

  void _onAnswer(int index) {
    if (_state != _QState.active || _selectedIndex != null) return;
    final isCorrect = index == _current.correctIndex;
    _session.currentTierAnswers.add(isCorrect);
    if (isCorrect) _session.totalCorrect++;
    _session.totalAnswered++;
    setState(() => _selectedIndex = index);
    _feedbackController.forward(from: 0);
  }

  void _next() {
    _session.currentQuestionIndex++;
    if (_session.currentQuestionIndex >= 10) {
      _saveTierResult();
      setState(() => _state = _QState.tierDone);
      return;
    }
    setState(() {
      _selectedIndex = null;
      _state = _QState.active;
    });
    _feedbackController.reset();
  }

  Future<void> _saveTierResult() async {
    final result = QuizResult(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      themeId: _session.themeId,
      themeLabel: _session.themeLabel,
      themeEmoji: _session.themeEmoji,
      bestTier: _session.currentTier,
      lastScore: _session.currentTierScore,
      completedAt: DateTime.now(),
    );
    await _resultService.save(result);
  }

  void _nextTier() {
    if (_session.isLastTier) {
      _goToSummary();
      return;
    }
    _session.currentTier++;
    _session.currentTierAnswers.clear();
    _loadTier();
  }

  void _retryTier() {
    _session.currentTierAnswers.clear();
    _loadTier();
  }

  void _goToSummary() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSummaryScreen(session: _session),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_state == _QState.tierDone || _state == _QState.loading) {
      return true;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter le quiz ?'),
        content:
            const Text('Ta progression sur ce tier sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Quitter',
                style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: _buildAppBar(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: switch (_state) {
            _QState.loading => _buildLoading(),
            _QState.error   => _buildError(),
            _QState.active  => _buildQuiz(),
            _QState.tierDone => _buildTierDone(),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () async {
          final should = await _onWillPop();
          if (should && mounted) Navigator.pop(context);
        },
      ),
      title: Text(
        '${widget.theme.emoji} ${widget.theme.displayLabel}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        if (_state == _QState.active || _state == _QState.tierDone)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Partie ${_session.currentTier}/20',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.5),
          const SizedBox(height: 20),
          const Text(
            'Génération du quiz…',
            style: TextStyle(color: AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Dans quelques secondes !',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😞', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Impossible de générer les questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifie ta connexion et réessaie.',
              style: TextStyle(color: AppTheme.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTier,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final answered = _selectedIndex != null;
    final total = _session.currentTierQuestions.length;
    final progress =
        (_session.currentQuestionIndex) / total;

    return Column(
      key: const ValueKey('quiz'),
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.border,
          valueColor: AlwaysStoppedAnimation(AppTheme.primary),
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Counter + type chip
                Row(
                  children: [
                    Text(
                      '${_session.currentQuestionIndex + 1} / $total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _TypeChip(type: _current.type),
                  ],
                ),
                const SizedBox(height: 20),
                // Question
                Text(
                  _current.question,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                // Options
                ...List.generate(
                  _current.options.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionCard(
                      label: _current.options[i],
                      index: i,
                      selectedIndex: _selectedIndex,
                      correctIndex: _current.correctIndex,
                      onTap: () => _onAnswer(i),
                    ),
                  ),
                ),
                // Explanation
                if (answered) ...[
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _feedbackController,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedIndex == _current.correctIndex
                                ? '✅'
                                : '💡',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _current.explanation,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        // Bottom button
        if (answered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _session.currentQuestionIndex >= total - 1
                        ? 'Voir les résultats'
                        : 'Question suivante',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTierDone() {
    final score = _session.currentTierScore;
    final passed = score >= 7;
    final isLast = _session.isLastTier;

    final scoreColor = score <= 4
        ? Colors.red.shade400
        : score <= 6
            ? Colors.orange.shade400
            : score <= 8
                ? AppTheme.primary
                : Colors.green.shade500;

    final message = score <= 4
        ? 'Continue à pratiquer !'
        : score <= 6
            ? 'Bien joué, tu progresses !'
            : score <= 8
                ? 'Excellent travail !'
                : 'Parfait ! Tu maîtrises ce tier.';

    return SafeArea(
      key: const ValueKey('tier_done'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            // Tier badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Tier ${_session.currentTier} terminé',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Score
            Text(
              '$score',
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w700,
                color: scoreColor,
                height: 1,
              ),
            ),
            Text(
              'sur 10',
              style: TextStyle(fontSize: 18, color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            // Answer dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _session.currentTierAnswers.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _session.currentTierAnswers[i]
                        ? Colors.green.shade400
                        : Colors.red.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _session.currentTierAnswers[i]
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Buttons
            if (isLast) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToSummary,
                  icon: const Icon(Icons.emoji_events_rounded, size: 18),
                  label: const Text('Voir le bilan final'),
                ),
              ),
            ] else if (passed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextTier,
                  child:
                      Text('Tier ${_session.currentTier + 1} →'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _goToSummary,
                  child: const Text('Arrêter'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retryTier,
                  child: const Text('Réessayer ce tier'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _nextTier,
                  child: Text('Continuer (Tier ${_session.currentTier + 1})'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _goToSummary,
                  child: const Text('Arrêter'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final QuestionType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${type.emoji} ${type.labelFr}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final answered = selectedIndex != null;
    final isSelected = selectedIndex == index;
    final isCorrect = index == correctIndex;

    Color borderColor = AppTheme.border;
    Color bgColor = Colors.white;
    Color textColor = AppTheme.onSurface;
    Widget? trailing;

    if (answered) {
      if (isCorrect) {
        borderColor = Colors.green.shade400;
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        trailing = Icon(Icons.check_circle_rounded,
            color: Colors.green.shade500, size: 20);
      } else if (isSelected) {
        borderColor = Colors.red.shade300;
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        trailing =
            Icon(Icons.cancel_rounded, color: Colors.red.shade400, size: 20);
      } else {
        borderColor = AppTheme.border;
        bgColor = AppTheme.surface;
        textColor = AppTheme.muted;
      }
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: answered && !isCorrect && !isSelected
                    ? AppTheme.surface
                    : answered && isCorrect
                        ? Colors.green.shade100
                        : answered && isSelected
                            ? Colors.red.shade100
                            : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: answered && !isCorrect && !isSelected
                        ? AppTheme.muted
                        : answered && isCorrect
                            ? Colors.green.shade700
                            : answered && isSelected
                                ? Colors.red.shade600
                                : AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected || (answered && isCorrect)
                          ? FontWeight.w600
                          : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
