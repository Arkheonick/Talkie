import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/notebook_entry.dart';

class FlashcardScreen extends StatefulWidget {
  final List<NotebookEntry> entries;

  const FlashcardScreen({super.key, required this.entries});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final List<NotebookEntry> _deck;
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.entries)..shuffle();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _deck.length - 1) {
      Navigator.pop(context);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    if (_index <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Flashcards · ${_index + 1} / ${_deck.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _deck.length,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cards (swipeable)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _deck.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _FlashCard(entry: _deck[i]),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Navigation hint + arrow buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous arrow
                  GestureDetector(
                    onTap: _index > 0 ? _prev : null,
                    child: AnimatedOpacity(
                      opacity: _index > 0 ? 1.0 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            size: 16, color: AppTheme.onSurface),
                      ),
                    ),
                  ),

                  // Hint text
                  Text(
                    _index >= _deck.length - 1
                        ? 'Dernière carte'
                        : '← Glisser pour naviguer →',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),

                  // Next / Finish
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _index >= _deck.length - 1
                            ? AppTheme.accent
                            : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _index >= _deck.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flashcard showing word + translation together ──────────────────────────────

class _FlashCard extends StatelessWidget {
  final NotebookEntry entry;
  const _FlashCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // EN badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EN',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // English word
          Text(
            entry.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (entry.definition.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.definition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.muted,
                height: 1.4,
              ),
            ),
          ],

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppTheme.border)),
              ],
            ),
          ),

          // FR badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // French translation
          Text(
            entry.translation.isNotEmpty ? entry.translation : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: -0.3,
            ),
          ),
          if (entry.exampleSentence.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                entry.exampleSentence,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.muted,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
