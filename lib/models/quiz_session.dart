import 'quiz_question.dart';
import 'cefr_level.dart';

class QuizSession {
  final String themeId;
  final String themeLabel;
  final String themeEmoji;
  final CefrLevel level;
  int currentTier;
  int currentQuestionIndex;
  List<QuizQuestion> currentTierQuestions;
  final List<bool> currentTierAnswers;
  int totalCorrect;
  int totalAnswered;
  final DateTime startedAt;

  QuizSession({
    required this.themeId,
    required this.themeLabel,
    required this.themeEmoji,
    required this.level,
    this.currentTier = 1,
    this.currentQuestionIndex = 0,
    List<QuizQuestion>? currentTierQuestions,
    List<bool>? currentTierAnswers,
    this.totalCorrect = 0,
    this.totalAnswered = 0,
    DateTime? startedAt,
  })  : currentTierQuestions = currentTierQuestions ?? [],
        currentTierAnswers = currentTierAnswers ?? [],
        startedAt = startedAt ?? DateTime.now();

  int get currentTierScore => currentTierAnswers.where((a) => a).length;
  bool get isTierComplete => currentQuestionIndex >= 10;
  bool get isLastTier => currentTier >= 20;

  double get overallAccuracy =>
      totalAnswered == 0 ? 0 : totalCorrect / totalAnswered;
}
