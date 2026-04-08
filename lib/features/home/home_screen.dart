import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/generated_lesson_service.dart';
import '../../services/user_profile_service.dart';
import '../lesson/lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = UserProfileService();
  final _generatedService = GeneratedLessonService();

  UserProfile _profile = UserProfile.defaults();
  List<Lesson> _generatedLessons = [];
  bool _loading = true;

  // Which accordion is open
  _Section? _openSection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _profileService.init();
    await _generatedService.init();
    setState(() {
      _profile = _profileService.load();
      _generatedLessons = _generatedService.loadAll();
      _loading = false;
    });
  }

  void _toggleSection(_Section s) {
    setState(() => _openSection = _openSection == s ? null : s);
  }

  void _openLesson(Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
          profile: _profile,
          onCompleted: () async {
            _profile.completedLessonIds.add(lesson.id);
            await _profileService.save(_profile);
            setState(() {});
          },
        ),
      ),
    ).then((_) => setState(() => _generatedLessons = _generatedService.loadAll()));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
          children: [
            // ── TALKIE header ──────────────────────────────────────────
            const Center(
              child: Text(
                'TALKIE',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.onSurface,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Apprends l\'anglais par le dialogue',
                style: TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
            ),
            const SizedBox(height: 40),

            // ── Ce que je peux faire ───────────────────────────────────
            _AccordionCard(
              title: 'Ce que je peux faire',
              subtitle: '4 fonctionnalités',
              icon: Icons.lightbulb_outline_rounded,
              isOpen: _openSection == _Section.features,
              onTap: () => _toggleSection(_Section.features),
              child: const _FeatureList(),
            ),

            const SizedBox(height: 12),

            // ── Mes contenus ───────────────────────────────────────────
            _AccordionCard(
              title: 'Mes contenus',
              subtitle: _generatedLessons.isEmpty
                  ? 'Aucun dialogue généré'
                  : '${_generatedLessons.length} dialogue${_generatedLessons.length > 1 ? 's' : ''} généré${_generatedLessons.length > 1 ? 's' : ''}',
              icon: Icons.folder_open_rounded,
              isOpen: _openSection == _Section.contents,
              onTap: () => _toggleSection(_Section.contents),
              child: _generatedLessons.isEmpty
                  ? const _EmptyContents()
                  : _GeneratedList(
                      lessons: _generatedLessons,
                      profile: _profile,
                      onTap: _openLesson,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Section { features, contents }

// ── Accordion card ─────────────────────────────────────────────────────────────

class _AccordionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOpen;
  final VoidCallback onTap;
  final Widget child;

  const _AccordionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOpen,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? AppTheme.primary : AppTheme.border,
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isOpen ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isOpen ? Colors.white : AppTheme.muted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isOpen ? AppTheme.primary : AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isOpen ? AppTheme.primary : AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppTheme.border),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature list ───────────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _features = [
    ('🎧', 'Écouter, lire des dialogues vivants',
        'Transcriptions synchronisées, traductions FR, vocabulaire extrait'),
    ('✨', 'Générer mes propres situations',
        'Décris un contexte, Gemini crée un dialogue authentique sur mesure'),
    ('💬', 'Discuter librement',
        'Conversation orale avec Alex, ton prof IA adapté à ton niveau'),
    ('📖', 'Construire mon carnet de lexique',
        'Sauvegarde des mots, définitions, exemples et mode flashcards'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: _features.map((f) {
          final (emoji, title, desc) = f;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Generated lessons list ─────────────────────────────────────────────────────

class _GeneratedList extends StatelessWidget {
  final List<Lesson> lessons;
  final UserProfile profile;
  final void Function(Lesson) onTap;

  const _GeneratedList({
    required this.lessons,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: lessons.map((l) {
          final done = profile.completedLessonIds.contains(l.id);
          return GestureDetector(
            onTap: () => onTap(l),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: done
                      ? AppTheme.accent.withValues(alpha: 0.3)
                      : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Text(l.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.description,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _chip(l.level.code, AppTheme.primary),
                            _chip('⏱ ${l.durationLabel}', AppTheme.muted),
                            if (done)
                              _chip('✓', AppTheme.accent,
                                  bg: const Color(0xFFD1FAE5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.play_circle_rounded,
                      color: AppTheme.primary, size: 26),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chip(String label, Color color, {Color? bg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

// ── Empty contents ─────────────────────────────────────────────────────────────

class _EmptyContents extends StatelessWidget {
  const _EmptyContents();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          const Text(
            'Aucun dialogue généré pour l\'instant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Va dans Explorer → "Choisir mon thème"\npour créer ton premier dialogue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
