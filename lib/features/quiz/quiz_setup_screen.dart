import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/cefr_level.dart';
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
  List<QuizTheme> _recentCustomThemes = [];
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
    // Derive recent custom themes from saved results (deduplicated by label)
    final allResults = _resultService.loadAll();
    final seen = <String>{};
    final customThemes = <QuizTheme>[];
    for (final r in allResults) {
      if (r.themeId.startsWith('custom_') && seen.add(r.themeLabel)) {
        customThemes.add(QuizTheme(
          id: r.themeId,
          label: r.themeLabel,
          emoji: r.themeEmoji,
          isCustom: true,
          userPrompt: r.themeLabel,
        ));
        if (customThemes.length >= 5) break;
      }
    }
    setState(() {
      _profile = profile;
      _bestResults = results;
      _recentCustomThemes = customThemes;
      _loading = false;
    });
  }

  Future<void> _selectLevel(CefrLevel level) async {
    _profile.quizLevel = level;
    await _profileService.save(_profile);
    setState(() {});
  }

  void _showLevelPicker() {
    final current = _profile.effectiveQuizLevel;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Niveau du quiz',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Indépendant de ton niveau dans Apprendre.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            ...CefrLevel.values.map((lvl) {
              final isSelected = current == lvl;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _selectLevel(lvl);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            lvl.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppTheme.muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        lvl.labelFr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.onSurface,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check_rounded,
                            color: AppTheme.primary, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      ),
    );
  }

  void _startQuiz(QuizTheme theme) {
    final session = QuizSession(
      themeId: theme.id,
      themeLabel: theme.displayLabel,
      themeEmoji: theme.emoji,
      level: _profile.effectiveQuizLevel,
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
    final level = _profile.effectiveQuizLevel;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Text('🧠', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Quiz'),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _showLevelPicker,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mon niveau',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        level.code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded,
                          size: 14, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildCustomSection(),
                _buildSuggestedTitle(),
                _buildThemeGrid(),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
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
          childAspectRatio: 1.9,
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
              'Je choisis mon thème',
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
            if (_recentCustomThemes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Récents',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentCustomThemes.map((theme) {
                  return GestureDetector(
                    onTap: () => _startQuiz(theme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(theme.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            theme.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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
