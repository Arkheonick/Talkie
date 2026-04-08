import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../models/cefr_level.dart';
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
  bool _levelOpen = false;
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

  Future<void> _selectLevel(CefrLevel level) async {
    _profile.level = level;
    await _profileService.save(_profile);
    setState(() => _levelOpen = false);
  }

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
    ).then((_) => setState(() => _generatedLessons = _generatedService.loadAll()));
  }

  Future<void> _deleteGenerated(String id) async {
    await _generatedService.delete(id);
    setState(() => _generatedLessons = _generatedService.loadAll());
  }

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
              : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 1. Sélecteur de niveau ─────────────────────────────────────
        _LevelTile(
          profile: _profile,
          isOpen: _levelOpen,
          onToggle: () => setState(() => _levelOpen = !_levelOpen),
          onSelect: _selectLevel,
        ),
        const SizedBox(height: 14),

        // ── 2. Génère un dialogue ──────────────────────────────────────
        _SectionLabel(
          title: 'Génère un dialogue',
          subtitle:
              'Décris une situation en français ou en anglais.\nEx : "un médecin et un patient, consultation pour une douleur au dos à Paris"',
        ),
        const SizedBox(height: 10),
        _GenerateCard(
          controller: _textController,
          isGenerating: _isGenerating,
          isRecording: _isRecording,
          isTranscribing: _isTranscribing,
          onToggleRecording: _toggleRecording,
          onGenerate: _generate,
        ),
        const SizedBox(height: 24),

        // ── 3. Thème ───────────────────────────────────────────────────
        const _SectionLabel(title: 'Thème'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: _contentService.domains.length,
          itemBuilder: (_, i) {
            final domain = _contentService.domains[i];
            final meta = ContentService.domainMeta[domain] ??
                {'label': domain, 'emoji': '📖'};
            return GestureDetector(
              onTap: () => setState(() => _selectedDomain = domain),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Text(meta['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meta['label']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppTheme.muted),
                  ],
                ),
              ),
            );
          },
        ),

        // ── 4. Dialogues générés ───────────────────────────────────────
        if (_generatedLessons.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionLabel(title: 'Mes dialogues'),
          const SizedBox(height: 10),
          ..._generatedLessons.map((l) => _GeneratedCard(
                lesson: l,
                isCompleted: _profile.completedLessonIds.contains(l.id),
                onTap: () => _openLesson(l),
                onDelete: () => _deleteGenerated(l.id),
              )),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Level tile ─────────────────────────────────────────────────────────────────

class _LevelTile extends StatelessWidget {
  final UserProfile profile;
  final bool isOpen;
  final VoidCallback onToggle;
  final void Function(CefrLevel) onSelect;

  const _LevelTile({
    required this.profile,
    required this.isOpen,
    required this.onToggle,
    required this.onSelect,
  });

  static const _levels = [
    (CefrLevel.a1, 'Je commence tout juste'),
    (CefrLevel.a2, 'Je connais les bases'),
    (CefrLevel.b1, 'Niveau intermédiaire'),
    (CefrLevel.b2, 'Assez à l\'aise'),
    (CefrLevel.c1, 'Niveau avancé'),
    (CefrLevel.c2, 'Maîtrise'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen ? AppTheme.primary : AppTheme.border,
          width: isOpen ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isOpen ? AppTheme.primary : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        profile.level.code,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isOpen ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mon niveau',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          profile.level.labelFr,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppTheme.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    children: _levels.map(((CefrLevel, String) info) {
                      final (level, label) = info;
                      final isSelected = profile.level == level;
                      return GestureDetector(
                        onTap: () => onSelect(level),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryLight
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Center(
                                  child: Text(
                                    level.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.muted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.primary, size: 18),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generate card ──────────────────────────────────────────────────────────────

class _GenerateCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final bool isRecording;
  final bool isTranscribing;
  final VoidCallback onToggleRecording;
  final VoidCallback onGenerate;

  const _GenerateCard({
    required this.controller,
    required this.isGenerating,
    required this.isRecording,
    required this.isTranscribing,
    required this.onToggleRecording,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isGenerating || isTranscribing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecording ? const Color(0xFFEF4444) : AppTheme.border,
          width: isRecording ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text field
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
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
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          // Mic + Generate side by side
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
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              blurRadius: 8,
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
              // Generate button — fills remaining width
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: busy || isRecording ? null : onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: isRecording
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : AppTheme.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : isTranscribing
                            ? const Text(
                                'Transcription...',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : isRecording
                                ? const Text(
                                    '🔴 Enregistrement...',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded,
                                          size: 16, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Générer',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
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

class _GeneratedCard extends StatelessWidget {
  final Lesson lesson;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GeneratedCard({
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
            Text(lesson.emoji, style: const TextStyle(fontSize: 24)),
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
                    style:
                        const TextStyle(fontSize: 11, color: AppTheme.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip(lesson.level.code, AppTheme.primary),
                      _chip('⏱ ${lesson.durationLabel}', AppTheme.muted),
                      if (isCompleted)
                        _chip('✓', AppTheme.accent,
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
                    color: AppTheme.primary, size: 24),
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
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
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
        ? const Center(
            child: Text('Aucun dialogue dans ce domaine.',
                style: TextStyle(color: AppTheme.muted)),
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
                            Text(l.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(l.description,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.muted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
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
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionLabel({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.muted, height: 1.5),
            ),
          ),
      ],
    );
  }
}
