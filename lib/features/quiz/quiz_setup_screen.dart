import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz_result.dart';
import '../../models/quiz_session.dart';
import '../../models/quiz_theme.dart';
import '../../models/user_profile.dart';
import '../../services/quiz_result_service.dart';
import '../../services/user_profile_service.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final _profileService = UserProfileService();
  final _resultService = QuizResultService();
  final _customController = TextEditingController();

  UserProfile _profile = UserProfile.defaults();
  Map<String, QuizResult> _bestResults = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _profileService.init();
    await _resultService.init();
    final profile = _profileService.load();
    final results = <String, QuizResult>{};
    for (final theme in QuizTheme.suggested) {
      final best = _resultService.getBestForTheme(theme.id);
      if (best != null) results[theme.id] = best;
    }
    setState(() {
      _profile = profile;
      _bestResults = results;
      _loading = false;
    });
  }

  void _startQuiz(QuizTheme theme) {
    final session = QuizSession(
      themeId: theme.id,
      themeLabel: theme.displayLabel,
      themeEmoji: theme.emoji,
      level: _profile.level,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(session: session, theme: theme)),
    ).then((_) => _load());
  }

  void _startCustomQuiz() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    final theme = QuizTheme(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      label: text,
      emoji: '🎯',
      isCustom: true,
      userPrompt: text,
    );
    _startQuiz(theme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  _buildHeader(),
                  _buildLevelBadge(),
                  _buildSuggestedTitle(),
                  _buildThemeGrid(),
                  _buildCustomSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('🧠', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Teste tes connaissances',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(Icons.school_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Niveau : ${_profile.level.code} — ${_profile.level.labelFr}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                'Les questions s\'adaptent',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          'Thèmes suggérés',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildThemeGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final theme = QuizTheme.suggested[i];
            final best = _bestResults[theme.id];
            return _ThemeCard(
              theme: theme,
              best: best,
              onTap: () => _startQuiz(theme),
            );
          },
          childCount: QuizTheme.suggested.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
      ),
    );
  }

  Widget _buildCustomSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer mon thème',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Un thème, une situation, un vocabulaire spécifique…',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: InputDecoration(
                      hintText: 'Ex: faire du shopping, parler de films…',
                      hintStyle: TextStyle(color: AppTheme.muted, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _startCustomQuiz(),
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _customController,
                  builder: (_, value, __) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed:
                          value.text.trim().isEmpty ? null : _startCustomQuiz,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Lancer'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final QuizTheme theme;
  final QuizResult? best;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlayed = best != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPlayed
                ? AppTheme.primary.withOpacity(0.3)
                : AppTheme.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (hasPlayed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tier ${best!.bestTier}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      'Nouveau',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              theme.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            if (hasPlayed) ...[
              const SizedBox(height: 2),
              Text(
                '${best!.lastScore}/10 au dernier tier',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
