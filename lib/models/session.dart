import 'vocabulary_entry.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class Session {
  final String id;
  final String topicId;
  final String topicTitle;
  final DateTime startedAt;
  DateTime? endedAt;
  final List<ChatMessage> messages;
  final List<VocabularyEntry> vocabulary;
  int correctionCount;

  Session({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    DateTime? startedAt,
    this.endedAt,
    List<ChatMessage>? messages,
    List<VocabularyEntry>? vocabulary,
    this.correctionCount = 0,
  })  : startedAt = startedAt ?? DateTime.now(),
        messages = messages ?? [],
        vocabulary = vocabulary ?? [];

  Duration get duration =>
      (endedAt ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'vocabulary': vocabulary.map((v) => v.toJson()).toList(),
        'correctionCount': correctionCount,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        topicId: json['topicId'] as String,
        topicTitle: json['topicTitle'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        vocabulary: (json['vocabulary'] as List)
            .map((v) => VocabularyEntry.fromJson(v as Map<String, dynamic>))
            .toList(),
        correctionCount: json['correctionCount'] as int? ?? 0,
      );
}
