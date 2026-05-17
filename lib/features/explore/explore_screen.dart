import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../app/theme.dart';
import '../../models/cefr_level.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/content_service.dart';
import '../../services/gemini_service.dart';
import '../../services/generated_lesson_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/display_header.dart';
import '../../widgets/theme_card.dart';
import '../lesson/lesson_screen.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback? onOpenDiscussion;

  const ExploreScreen({super.key, this.onOpenDiscussion});

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

  static Color _domainColor(String domain) {
    switch (domain) {
      case 'travel':  return AppTheme.themeVoyage;
      case 'work':    return AppTheme.themeTravail;
      case 'daily':   return AppTheme.themeQuotidien;
      case 'sport':   return AppTheme.themeSport;
      case 'culture': return AppTheme.themeCulture;
      case 'tech':    return AppTheme.themeTech;
      case 'health':  return AppTheme.themeSante;
      case 'social':  return AppTheme.themeSocial;
      default:        return AppTheme.primary;
    }
  }

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

  // ── Level badge button shown in header actions ─────────────────────────────
  Widget _buildLevelButton() {
    return GestureDetector(
      onTap: () => setState(() => _levelOpen = !_levelOpen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _levelOpen ? AppTheme.primary : AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _levelOpen
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _profile.level.code,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _levelOpen ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _levelOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                PhosphorIcons.caretDown(),
                color: _levelOpen ? Colors.white : AppTheme.primary,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Discussion CTA card with mini-orb ──────────────────────────────────────
  Widget _buildDiscussionCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: widget.onOpenDiscussion,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.70),
                      AppTheme.primary.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.22),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                  color: Colors.white.withValues(alpha: 0.88),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DISCUSSION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        letterSpacing: 0.10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Parler avec ton prof',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE0E7FF),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Démarre maintenant →',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.muted,
          letterSpacing: 0.12,
        ),
      ),
    );
  }

  // ── Theme grid — returns a Sliver ──────────────────────────────────────────
  Widget _buildThemeGrid() {
    final domains = _contentService.domains;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final domain = domains[i];
            final label =
                ContentService.domainMeta[domain]?['label'] ?? domain;
            return ThemeCard(
              themeId: domain,
              label: label,
              color: _domainColor(domain),
              onTap: () => setState(() => _selectedDomain = domain),
            );
          },
          childCount: domains.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
      ),
    );
  }

  // ── Generate section — non-sliver, wrapped by caller ──────────────────────
  Widget _buildGenerateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GÉNÈRE UN DIALOGUE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
              letterSpacing: 0.12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Décris une situation en français ou en anglais.',
            style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.5),
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
          if (_generatedLessons.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'MES DIALOGUES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.muted,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(height: 10),
            ..._generatedLessons.map(
              (l) => _GeneratedCard(
                lesson: l,
                isCompleted: _profile.completedLessonIds.contains(l.id),
                onTap: () => _openLesson(l),
                onDelete: () => _deleteGenerated(l.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Drill-down view: domain selected ────────────────────────────────────
    if (_selectedDomain != null) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowLeft(), color: AppTheme.onSurface),
            onPressed: () => setState(() => _selectedDomain = null),
          ),
          title: Text(
            ContentService.domainMeta[_selectedDomain!]?['label'] ??
                _selectedDomain!,
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: _LessonList(
          domain: _selectedDomain!,
          lessons: _contentService.getByDomain(_selectedDomain!),
          profile: _profile,
          onLessonTap: _openLesson,
        ),
      );
    }

    // ── Main view ────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DisplayHeader(
                      greeting: 'Bonjour',
                      title: 'Speak\nEnglish.',
                      subtitle:
                          'Niveau ${_profile.level.code} · Continue ta progression',
                      actions: [
                        const SizedBox(width: 12),
                        _buildLevelButton(),
                      ],
                    ),
                  ),
                  // Level dropdown — only when open
                  if (_levelOpen)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _LevelTile(
                          profile: _profile,
                          isOpen: _levelOpen,
                          onToggle: () =>
                              setState(() => _levelOpen = !_levelOpen),
                          onSelect: _selectLevel,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(child: _buildDiscussionCta()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildSectionLabel('Thèmes')),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  _buildThemeGrid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(child: _buildGenerateSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }
}

// ── Shared chip helpers ───────────────────────────────────────────────────────

Widget _labelChip(String label, Color color,
    {Color? bg, double fontSize = 11, double radius = 6}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg ?? color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Text(
      label,
      style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

Widget _durationChipWidget(String durationLabel,
    {double iconSize = 11, double fontSize = 11, double radius = 6}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.muted.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIcons.clock(), size: iconSize, color: AppTheme.muted),
        const SizedBox(width: 3),
        Text(durationLabel,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted)),
      ],
    ),
  );
}

Widget _completedChipWidget({double iconSize = 11, double radius = 6}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.accentLight,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(
      PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
      size: iconSize,
      color: AppTheme.accent,
    ),
  );
}

// ── Level tile (dropdown body) ────────────────────────────────────────────────

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
        color: AppTheme.surfaceHigh,
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
                    child: Icon(
                      PhosphorIcons.caretDown(),
                      color: AppTheme.muted,
                    ),
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
                                      : AppTheme.surfaceHigh,
                                  borderRadius: BorderRadius.circular(7),
                                  border:
                                      Border.all(color: AppTheme.border),
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
                                Icon(
                                  PhosphorIcons.checkCircle(
                                      PhosphorIconsStyle.fill),
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
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

// ── Generate card ─────────────────────────────────────────────────────────────

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
        gradient: LinearGradient(
          colors: isRecording
              ? [
                  const Color(0xFFEF4444).withValues(alpha: 0.2),
                  AppTheme.surfaceHigh,
                ]
              : [
                  AppTheme.primary.withValues(alpha: 0.18),
                  AppTheme.surfaceHigh,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecording
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : AppTheme.primary.withValues(alpha: 0.35),
          width: 1.5,
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
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3),
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
                          isRecording
                              ? PhosphorIcons.stop()
                              : PhosphorIcons.microphone(),
                          color:
                              isRecording ? Colors.white : AppTheme.primary,
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
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Enregistrement...',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(PhosphorIcons.sparkle(),
                                          size: 16, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Text(
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

// ── Generated lesson card ─────────────────────────────────────────────────────

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
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? AppTheme.accent.withValues(alpha: 0.35)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            // Keep data-layer emoji as-is
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
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.sparkle(),
                                size: 10, color: AppTheme.primary),
                            const SizedBox(width: 3),
                            const Text(
                              'Généré',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
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
                      _labelChip(lesson.level.code, AppTheme.primary,
                          fontSize: 10, radius: 5),
                      _durationChipWidget(lesson.durationLabel,
                          iconSize: 10, fontSize: 10, radius: 5),
                      if (isCompleted)
                        _completedChipWidget(iconSize: 10, radius: 5),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Icon(
                  PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    PhosphorIcons.trash(),
                    color: AppTheme.muted,
                    size: 18,
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

// ── Lesson list (domain drill-down) ──────────────────────────────────────────

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
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: done
                          ? AppTheme.accent.withValues(alpha: 0.3)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Keep data-layer emoji as-is
                      Text(l.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
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
                                _labelChip(l.level.code, AppTheme.primary),
                                _durationChipWidget(l.durationLabel),
                                if (done) _completedChipWidget(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

}
