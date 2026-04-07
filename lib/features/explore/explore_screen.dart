import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/content_service.dart';
import '../../services/gemini_service.dart';
import '../../services/generated_lesson_service.dart';
import '../../services/user_profile_service.dart';
import '../lesson/lesson_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _contentService = ContentService();
  final _profileService = UserProfileService();
  final _generatedService = GeneratedLessonService();
  final _gemini = GeminiService();
  final _recorder = AudioRecorderService();
  final _textController = TextEditingController();

  String? _selectedDomain;
  UserProfile _profile = UserProfile.defaults();
  bool _loading = true;
  bool _isGenerating = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  List<Lesson> _generatedLessons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _profileService.init();
    await _contentService.loadAll();
    await _generatedService.init();
    _gemini.init();
    setState(() {
      _profile = _profileService.load();
      _generatedLessons = _generatedService.loadAll();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Mic recording ──────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isGenerating || _isTranscribing) return;

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });
      final bytes = await _recorder.stopRecording();
      if (bytes != null && bytes.isNotEmpty) {
        final text = await _gemini.transcribeAudio(bytes);
        if (text.isNotEmpty) {
          _textController.text = text;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        }
      }
      if (mounted) setState(() => _isTranscribing = false);
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission microphone requise')),
        );
      }
      return;
    }
    await _recorder.startRecording();
    setState(() => _isRecording = true);
  }

  // ── Generate ───────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;
    FocusScope.of(context).unfocus();
    setState(() => _isGenerating = true);
    try {
      final lesson = await _gemini.generateLesson(text, _profile.level);
      if (!mounted) return;
      if (lesson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Génération échouée. Réessaie.')),
        );
        return;
      }
      await _generatedService.save(lesson);
      _textController.clear();
      setState(() => _generatedLessons = _generatedService.loadAll());
      _openLesson(lesson);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
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
    );
  }

  Future<void> _deleteGenerated(String id) async {
    await _generatedService.delete(id);
    setState(() => _generatedLessons = _generatedService.loadAll());
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Explorer'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: _selectedDomain != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedDomain = null),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedDomain != null
              ? _LessonList(
                  domain: _selectedDomain!,
                  lessons: _contentService.getByDomain(_selectedDomain!),
                  profile: _profile,
                  onLessonTap: _openLesson,
                )
              : _MainView(
                  domains: _contentService.domains,
                  generatedLessons: _generatedLessons,
                  profile: _profile,
                  textController: _textController,
                  isGenerating: _isGenerating,
                  isRecording: _isRecording,
                  isTranscribing: _isTranscribing,
                  onDomainSelect: (d) => setState(() => _selectedDomain = d),
                  onToggleRecording: _toggleRecording,
                  onGenerate: _generate,
                  onOpenLesson: _openLesson,
                  onDeleteGenerated: _deleteGenerated,
                ),
    );
  }
}

// ── Main view (domains + custom theme) ────────────────────────────────────────

class _MainView extends StatelessWidget {
  final List<String> domains;
  final List<Lesson> generatedLessons;
  final UserProfile profile;
  final TextEditingController textController;
  final bool isGenerating;
  final bool isRecording;
  final bool isTranscribing;
  final void Function(String) onDomainSelect;
  final VoidCallback onToggleRecording;
  final VoidCallback onGenerate;
  final void Function(Lesson) onOpenLesson;
  final void Function(String) onDeleteGenerated;

  const _MainView({
    required this.domains,
    required this.generatedLessons,
    required this.profile,
    required this.textController,
    required this.isGenerating,
    required this.isRecording,
    required this.isTranscribing,
    required this.onDomainSelect,
    required this.onToggleRecording,
    required this.onGenerate,
    required this.onOpenLesson,
    required this.onDeleteGenerated,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Section : Choisir un domaine ──────────────────────────────────
        const _SectionTitle(
          title: 'Choisir un domaine',
          subtitle: 'Des dialogues authentiques par thématique',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: domains.length,
          itemBuilder: (_, i) {
            final domain = domains[i];
            final meta = ContentService.domainMeta[domain] ??
                {'label': domain, 'emoji': '📖'};
            return GestureDetector(
              onTap: () => onDomainSelect(domain),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(meta['emoji']!, style: const TextStyle(fontSize: 26)),
                    Text(
                      meta['label']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // ── Section : Choisir mon thème ───────────────────────────────────
        const _SectionTitle(
          title: 'Choisir mon thème',
          subtitle: 'Génère un dialogue sur le contexte de ton choix',
        ),
        const SizedBox(height: 14),
        _ThemeInputCard(
          controller: textController,
          isGenerating: isGenerating,
          isRecording: isRecording,
          isTranscribing: isTranscribing,
          profile: profile,
          onToggleRecording: onToggleRecording,
          onGenerate: onGenerate,
        ),

        // ── Leçons générées ───────────────────────────────────────────────
        if (generatedLessons.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionTitle(title: 'Mes dialogues générés'),
          const SizedBox(height: 12),
          ...generatedLessons.map((l) => _GeneratedLessonCard(
                lesson: l,
                isCompleted: profile.completedLessonIds.contains(l.id),
                onTap: () => onOpenLesson(l),
                onDelete: () => onDeleteGenerated(l.id),
              )),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Theme input card ──────────────────────────────────────────────────────────

class _ThemeInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final bool isRecording;
  final bool isTranscribing;
  final UserProfile profile;
  final VoidCallback onToggleRecording;
  final VoidCallback onGenerate;

  const _ThemeInputCard({
    required this.controller,
    required this.isGenerating,
    required this.isRecording,
    required this.isTranscribing,
    required this.profile,
    required this.onToggleRecording,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isGenerating || isTranscribing;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecording ? const Color(0xFFEF4444) : AppTheme.border,
          width: isRecording ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context hint
          Text(
            'Décris une situation en français ou en anglais',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ex : "Un médecin et un patient, consultation pour une douleur au dos à Paris"',
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
          const SizedBox(height: 12),
          // Text field
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: controller,
              enabled: !busy && !isRecording,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Décris ton contexte ici...',
                hintStyle: TextStyle(color: AppTheme.muted, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mic button
              GestureDetector(
                onTap: busy ? null : onToggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording
                        ? const Color(0xFFEF4444)
                        : busy
                            ? AppTheme.border
                            : AppTheme.primaryLight,
                    boxShadow: isRecording
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: isTranscribing
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: AppTheme.primary, strokeWidth: 2),
                        )
                      : Icon(
                          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: isRecording ? Colors.white : AppTheme.primary,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Status text
              Expanded(
                child: Text(
                  isRecording
                      ? '🔴 Enregistrement... tape pour arrêter'
                      : isTranscribing
                          ? 'Transcription...'
                          : isGenerating
                              ? 'Génération du dialogue...'
                              : 'Niveau ${profile.level.code} · ${profile.level.labelFr}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isRecording
                        ? const Color(0xFFEF4444)
                        : AppTheme.muted,
                    fontWeight: isRecording ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Generate button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  onPressed: busy || isRecording ? null : onGenerate,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Générer'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    disabledBackgroundColor: AppTheme.border,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Generated lesson card ──────────────────────────────────────────────────────

class _GeneratedLessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GeneratedLessonCard({
    required this.lesson,
    required this.isCompleted,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? AppTheme.accent.withValues(alpha: 0.35)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(lesson.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '✨ Généré',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.description,
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip(lesson.level.code, AppTheme.primary),
                      _chip('⏱ ${lesson.durationLabel}', AppTheme.muted),
                      if (isCompleted)
                        _chip('✓ Terminé', AppTheme.accent,
                            bg: const Color(0xFFD1FAE5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                const Icon(Icons.play_circle_rounded,
                    color: AppTheme.primary, size: 26),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.muted, size: 18),
                ),
              ],
            ),
          ],
        ),
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
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

// ── Lesson list (domain drill-down) ───────────────────────────────────────────

class _LessonList extends StatelessWidget {
  final String domain;
  final List<Lesson> lessons;
  final UserProfile profile;
  final void Function(Lesson) onLessonTap;

  const _LessonList({
    required this.domain,
    required this.lessons,
    required this.profile,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return lessons.isEmpty
        ? Center(
            child: Text(
              'Aucun dialogue dans ce domaine.',
              style: const TextStyle(color: AppTheme.muted),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final l = lessons[i];
              final done = profile.completedLessonIds.contains(l.id);
              return GestureDetector(
                onTap: () => onLessonTap(l),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: done
                          ? AppTheme.accent.withValues(alpha: 0.3)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(l.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.description,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.muted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
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
                      const Icon(Icons.play_circle_rounded,
                          color: AppTheme.primary, size: 28),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _chip(String label, Color color, {Color? bg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AppTheme.muted),
          ),
      ],
    );
  }
}
