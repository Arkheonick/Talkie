import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../app/theme.dart';
import '../../models/theme_topic.dart';
import '../session/session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _topicController = TextEditingController();
  final SpeechToText _stt = SpeechToText();
  bool _isListening = false;

  void _navigateToSession(ThemeTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionScreen(topic: topic)),
    );
  }

  void _submitCustomTopic() {
    final text = _topicController.text.trim();
    if (text.isEmpty) return;
    final topic = ThemeTopic(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: text,
      description: 'Custom topic',
      emoji: '💬',
      level: 'All levels',
    );
    _topicController.clear();
    _navigateToSession(topic);
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _stt.stop();
      setState(() => _isListening = false);
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final available = await _stt.initialize();
    if (!available) return;

    setState(() => _isListening = true);

    await _stt.listen(
      onResult: (result) {
        setState(() {
          _topicController.text = result.recognizedWords;
          _topicController.selection = TextSelection.fromPosition(
            TextPosition(offset: _topicController.text.length),
          );
        });
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(context),
            _buildCustomTopicBar(context),
            _buildSectionLabel(context),
            _buildTopicGrid(context),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Talkie', style: Theme.of(context).textTheme.headlineMedium),
                Text(
                  'Your AI English teacher',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTopicBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Or choose your own topic',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isListening ? AppTheme.primary : AppTheme.border,
                  width: _isListening ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Ordering at a café, Job interview...',
                        hintStyle: TextStyle(color: AppTheme.muted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _submitCustomTopic(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleMic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFEF4444)
                            : AppTheme.primaryLight,
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _isListening ? Colors.white : AppTheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _submitCustomTopic,
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Text('Topics', style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }

  Widget _buildTopicGrid(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TopicCard(
            topic: ThemeTopic.defaults[index],
            onTap: () => _navigateToSession(ThemeTopic.defaults[index]),
          ),
          childCount: ThemeTopic.defaults.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final ThemeTopic topic;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topic.emoji, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Text(
              topic.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              topic.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                topic.level,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
