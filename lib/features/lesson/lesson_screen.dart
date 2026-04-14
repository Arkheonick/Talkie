import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/lesson.dart';
import '../../models/user_profile.dart';
import '../../services/notebook_service.dart';
import '../../services/tts_player_service.dart';
import '../../services/vocab_folder_service.dart';
import '../../utils/app_audio.dart';
import 'tabs/audio_tab.dart';
import 'tabs/vocab_tab.dart';
import 'tabs/chat_tab.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final UserProfile profile;
  final VoidCallback? onCompleted;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.profile,
    this.onCompleted,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ttsPlayer = TtsPlayerService();
  final _notebookService = NotebookService();
  final _folderService = VocabFolderService();

  @override
  void initState() {
    super.initState();
    // Tab order: Écoute | Chat | Vocabulaire
    _tabController = TabController(length: 3, vsync: this);
    _initAsync();
  }

  Future<void> _initAsync() async {
    await _ttsPlayer.init();
    await _ttsPlayer.loadLesson(widget.lesson.transcript);
    await _notebookService.init();
    await _folderService.init();
  }

  @override
  void dispose() {
    AppAudio.stopAll();
    _tabController.dispose();
    _ttsPlayer.dispose();
    super.dispose();
  }

  void _markCompleted() {
    widget.onCompleted?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leçon terminée ! Ajoutée à ton historique.'),
        backgroundColor: AppTheme.accent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(widget.lesson.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.lesson.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _markCompleted,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Terminé'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.headphones_rounded, size: 18), text: 'Écoute'),
            Tab(icon: Icon(Icons.chat_bubble_rounded, size: 18), text: 'Chat'),
            Tab(icon: Icon(Icons.book_rounded, size: 18), text: 'Vocabulaire'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AudioTab(
            lesson: widget.lesson,
            ttsPlayer: _ttsPlayer,
            notebookService: _notebookService,
            folderService: _folderService,
          ),
          ChatTab(
            lesson: widget.lesson,
            profile: widget.profile,
            notebookService: _notebookService,
            folderService: _folderService,
          ),
          VocabTab(
            lesson: widget.lesson,
            notebookService: _notebookService,
            folderService: _folderService,
          ),
        ],
      ),
    );
  }
}
