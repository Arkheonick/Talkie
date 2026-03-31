import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/session.dart';
import '../../models/vocabulary_entry.dart';
import '../../services/pdf_service.dart';
import '../../services/session_storage_service.dart';

class SummaryScreen extends StatefulWidget {
  final Session session;

  const SummaryScreen({super.key, required this.session});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final SessionStorageService _storage = SessionStorageService();
  bool _saved = false;
  bool _exporting = false;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  Future<void> _saveSession() async {
    await _storage.save(widget.session);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session saved'),
          backgroundColor: AppTheme.accent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      await PdfService.exportSession(widget.session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Session Summary'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Done',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildStats(context),
          const SizedBox(height: 16),
          _buildActions(),
          const SizedBox(height: 24),
          if (widget.session.vocabulary.isNotEmpty) ...[
            _sectionTitle(context, 'Vocabulary (${widget.session.vocabulary.length} words)'),
            const SizedBox(height: 12),
            ...widget.session.vocabulary.map((v) => _VocabCard(entry: v)),
            const SizedBox(height: 24),
          ],
          _sectionTitle(context, 'Conversation'),
          const SizedBox(height: 12),
          ...widget.session.messages.map((m) => _MessageRow(message: m)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saved ? null : _saveSession,
            icon: Icon(_saved ? Icons.check : Icons.bookmark_outline, size: 18),
            label: Text(_saved ? 'Saved' : 'Save session'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _saved ? AppTheme.accent : AppTheme.primary,
              side: BorderSide(
                  color: _saved ? AppTheme.accent : AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exporting ? null : _exportPdf,
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_exporting ? 'Generating...' : 'Export PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.session.topicTitle,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                  value: _formatDuration(widget.session.duration),
                  label: 'Duration'),
              _StatItem(
                  value:
                      '${widget.session.messages.where((m) => m.role == 'user').length}',
                  label: 'Exchanges'),
              _StatItem(
                  value: '${widget.session.vocabulary.length}',
                  label: 'Words'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _VocabCard extends StatelessWidget {
  final VocabularyEntry entry;
  const _VocabCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(entry.word,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface)),
              const SizedBox(width: 8),
              Text(entry.translation,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(entry.definition,
              style: const TextStyle(
                  color: AppTheme.muted, fontSize: 13, height: 1.3)),
          const SizedBox(height: 6),
          Text('"${entry.exampleSentence}"',
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.3)),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessage message;
  const _MessageRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              isUser ? 'You' : 'Alex',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isUser ? AppTheme.muted : AppTheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message.text,
                style: const TextStyle(
                    color: AppTheme.onSurface, fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
