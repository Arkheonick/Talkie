import 'cefr_level.dart';

class UserProfile {
  CefrLevel level;
  CefrLevel? quizLevel;
  CefrLevel? discussionLevel;
  bool onboardingCompleted;
  Set<String> completedLessonIds;

  UserProfile({
    this.level = CefrLevel.b1,
    this.quizLevel,
    this.discussionLevel,
    this.onboardingCompleted = false,
    Set<String>? completedLessonIds,
  }) : completedLessonIds = completedLessonIds ?? {};

  CefrLevel get effectiveQuizLevel => quizLevel ?? level;
  CefrLevel get effectiveDiscussionLevel => discussionLevel ?? level;

  Map<String, dynamic> toJson() => {
        'level': level.code,
        if (quizLevel != null) 'quizLevel': quizLevel!.code,
        if (discussionLevel != null) 'discussionLevel': discussionLevel!.code,
        'onboardingCompleted': onboardingCompleted,
        'completedLessonIds': completedLessonIds.toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        level: CefrLevel.fromString(j['level'] as String? ?? 'B1'),
        quizLevel: j['quizLevel'] != null
            ? CefrLevel.fromString(j['quizLevel'] as String)
            : null,
        discussionLevel: j['discussionLevel'] != null
            ? CefrLevel.fromString(j['discussionLevel'] as String)
            : null,
        onboardingCompleted: j['onboardingCompleted'] as bool? ?? false,
        completedLessonIds: Set<String>.from(
          (j['completedLessonIds'] as List?) ?? [],
        ),
      );

  factory UserProfile.defaults() => UserProfile();
}
