class ThemeTopic {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String level;

  const ThemeTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.level,
  });

  static const List<ThemeTopic> defaults = [
    ThemeTopic(
      id: 'travel',
      title: 'Travel & Tourism',
      description: 'airports, hotels, directions, booking',
      emoji: '✈️',
      level: 'A2–B2',
    ),
    ThemeTopic(
      id: 'work',
      title: 'Work & Business',
      description: 'meetings, emails, negotiations, presentations',
      emoji: '💼',
      level: 'B1–C1',
    ),
    ThemeTopic(
      id: 'daily',
      title: 'Daily Life',
      description: 'shopping, restaurants, weather, small talk',
      emoji: '☕',
      level: 'A1–B1',
    ),
    ThemeTopic(
      id: 'culture',
      title: 'Culture & Society',
      description: 'arts, news, debates, opinions',
      emoji: '🎭',
      level: 'B2–C2',
    ),
    ThemeTopic(
      id: 'tech',
      title: 'Technology',
      description: 'AI, internet, gadgets, future',
      emoji: '💻',
      level: 'B1–C1',
    ),
    ThemeTopic(
      id: 'health',
      title: 'Health & Wellness',
      description: 'doctor, sport, nutrition, mental health',
      emoji: '🏃',
      level: 'A2–B2',
    ),
  ];
}
