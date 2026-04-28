enum QuestionType {
  translation,
  fillBlank,
  formulation,
  syntax;

  String get labelFr {
    switch (this) {
      case QuestionType.translation:
        return 'Traduction';
      case QuestionType.fillBlank:
        return 'Mot manquant';
      case QuestionType.formulation:
        return 'Formulation';
      case QuestionType.syntax:
        return 'Syntaxe';
    }
  }

  String get emoji {
    switch (this) {
      case QuestionType.translation:
        return '🔤';
      case QuestionType.fillBlank:
        return '✏️';
      case QuestionType.formulation:
        return '📝';
      case QuestionType.syntax:
        return '🔀';
    }
  }
}

class QuizQuestion {
  final String question;
  final List<String> options; // exactly 4
  final int correctIndex;
  final String explanation;
  final QuestionType type;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.type,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) {
    final typeStr = j['type'] as String? ?? 'translation';
    final qtype = switch (typeStr) {
      'fill_blank' => QuestionType.fillBlank,
      'formulation' => QuestionType.formulation,
      'syntax' => QuestionType.syntax,
      _ => QuestionType.translation,
    };
    return QuizQuestion(
      question: j['question'] as String,
      options: (j['options'] as List).cast<String>(),
      correctIndex: (j['correct_index'] as num).toInt(),
      explanation: j['explanation'] as String,
      type: qtype,
    );
  }
}
