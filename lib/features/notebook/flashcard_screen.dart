import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/notebook_entry.dart';

class FlashcardScreen extends StatefulWidget {
  final List<NotebookEntry> entries;

  const FlashcardScreen({super.key, required this.entries});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late List<NotebookEntry> _deck;
  int _index = 0;
  bool _flipped = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.entries)..shuffle();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipCtrl.isCompleted) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _flipped = !_flipped);
  }

  void _next() {
    if (_index >= _deck.length - 1) {
      Navigator.pop(context);
      return;
    }
    _flipCtrl.reset();
    setState(() {
      _index++;
      _flipped = false;
    });
  }

  void _prev() {
    if (_index <= 0) return;
    _flipCtrl.reset();
    setState(() {
      _index--;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = _deck[_index];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Flashcards · ${_index + 1}/${_deck.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _deck.length,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 32),
              // Card
              Expanded(
                child: GestureDetector(
                  onTap: _flip,
                  child: AnimatedBuilder(
                    animation: _flipAnim,
                    builder: (_, __) {
                      final angle = _flipAnim.value * 3.14159;
                      final showBack = _flipAnim.value > 0.5;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: showBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(3.14159),
                                child: _CardBack(entry: entry),
                              )
                            : _CardFront(entry: entry),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Hint
              Text(
                _flipped ? 'Swipe pour continuer' : 'Appuie pour voir la réponse',
                style: const TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
              const SizedBox(height: 20),
              // Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous
                  GestureDetector(
                    onTap: _index > 0 ? _prev : null,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _index > 0 ? Colors.white : AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: _index > 0 ? AppTheme.onSurface : AppTheme.border,
                      ),
                    ),
                  ),
                  // Next / Finish
                  ElevatedButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      _index >= _deck.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _index >= _deck.length - 1 ? 'Terminer' : 'Suivant',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final NotebookEntry entry;
  const _CardFront({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EN',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            entry.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Appuie pour voir la traduction',
            style: TextStyle(fontSize: 13, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final NotebookEntry entry;
  const _CardBack({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            entry.translation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          Text(
            entry.definition,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              entry.exampleSentence,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.muted,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
