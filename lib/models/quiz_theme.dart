class QuizTheme {
  final String id;
  final String label;
  final String emoji;
  final bool isCustom;
  final String? userPrompt;

  const QuizTheme({
    required this.id,
    required this.label,
    required this.emoji,
    this.isCustom = false,
    this.userPrompt,
  });

  String get displayLabel => userPrompt ?? label;

  static const List<QuizTheme> suggested = [
    QuizTheme(id: 'travel',   label: 'Voyage',       emoji: '✈️'),
    QuizTheme(id: 'work',     label: 'Travail',      emoji: '💼'),
    QuizTheme(id: 'daily',    label: 'Quotidien',    emoji: '🏠'),
    QuizTheme(id: 'culture',  label: 'Culture',      emoji: '🎭'),
    QuizTheme(id: 'tech',     label: 'Technologie',  emoji: '💻'),
    QuizTheme(id: 'health',   label: 'Santé',        emoji: '🏥'),
    QuizTheme(id: 'social',   label: 'Social',       emoji: '👥'),
    QuizTheme(id: 'sport',    label: 'Sport',        emoji: '⚽'),
  ];
}
