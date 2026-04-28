class QuizResult {
  final String id;
  final String themeId;
  final String themeLabel;
  final String themeEmoji;
  final int bestTier;
  final int lastScore; // out of 10
  final DateTime completedAt;

  const QuizResult({
    required this.id,
    required this.themeId,
    required this.themeLabel,
    required this.themeEmoji,
    required this.bestTier,
    required this.lastScore,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'themeId': themeId,
        'themeLabel': themeLabel,
        'themeEmoji': themeEmoji,
        'bestTier': bestTier,
        'lastScore': lastScore,
        'completedAt': completedAt.toIso8601String(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        id: j['id'] as String,
        themeId: j['themeId'] as String,
        themeLabel: j['themeLabel'] as String,
        themeEmoji: j['themeEmoji'] as String? ?? '🎯',
        bestTier: (j['bestTier'] as num).toInt(),
        lastScore: (j['lastScore'] as num).toInt(),
        completedAt: DateTime.parse(j['completedAt'] as String),
      );
}
