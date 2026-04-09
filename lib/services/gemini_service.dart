import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/session.dart';
import '../models/vocabulary_entry.dart';
import '../models/lesson.dart';
import '../models/cefr_level.dart';

class GeminiService {
  GenerativeModel? _model;
  GenerativeModel? _generationModel; // dedicated model with higher token limit
  ChatSession? _chat;

  static const Map<String, Map<String, String>> _scenarios = {
    'travel': {
      'role': 'a check-in agent at London Heathrow Airport',
      'situation': 'The student is checking in for a flight to New York. They need to drop off luggage, choose a seat, and ask about the flight.',
    },
    'work': {
      'role': 'an HR manager at a London tech company',
      'situation': 'The student is attending a job interview for a marketing manager position. They must present their experience, handle tough questions, and negotiate salary.',
    },
    'daily': {
      'role': 'a barista at a busy London coffee shop',
      'situation': 'The student wants to order a drink and a snack, ask about ingredients, and make small talk with the barista.',
    },
    'culture': {
      'role': 'a curator at the Tate Modern museum in London',
      'situation': 'The student is visiting the museum and wants to discuss a contemporary art exhibition, share opinions, and ask for recommendations.',
    },
    'tech': {
      'role': 'a senior software engineer at a Silicon Valley startup',
      'situation': 'The student is presenting their app idea during a startup pitch. They must explain the product, handle technical questions, and defend their choices.',
    },
    'health': {
      'role': 'a general practitioner at a London clinic',
      'situation': 'The student has an appointment to discuss fatigue and stress. They must describe symptoms, understand medical advice, and ask questions about treatment.',
    },
  };

  void init() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.85,
        maxOutputTokens: 400,
      ),
    );
    // Dedicated model for lesson generation — high token budget for thinking + JSON
    _generationModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 8192,
      ),
    );
  }

  void startSession(String topicId, String topicTitle) {
    assert(_model != null, 'Call init() before startSession()');
    final prompt = _buildSystemPrompt(topicId, topicTitle);
    _chat = _model!.startChat(history: [
      Content.model([TextPart(prompt)]),
    ]);
  }

  Future<String> sendMessage(String userMessage) async {
    if (_chat == null) throw StateError('No active session');
    final response = await _chat!.sendMessage(Content.text(userMessage));
    return response.text ?? '';
  }

  Future<List<VocabularyEntry>> extractVocabulary(
      List<ChatMessage> messages) async {
    if (_model == null) return [];

    final conversation = messages
        .map((m) => '${m.role == 'user' ? 'Student' : 'Teacher'}: ${m.text}')
        .join('\n');

    final prompt = '''
From this English learning conversation, extract 4-6 key vocabulary words or phrases the student encountered or struggled with.

Conversation:
$conversation

Return ONLY a JSON array (no markdown, no explanation):
[
  {
    "word": "...",
    "definition": "...",
    "exampleSentence": "...",
    "translation": "... (French)"
  }
]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '[]';
      final cleaned = text
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return _parseVocabularyJson(cleaned);
    } catch (_) {
      return [];
    }
  }

  List<VocabularyEntry> _parseVocabularyJson(String json) {
    try {
      final entries = <VocabularyEntry>[];
      final regex = RegExp(
        r'"word"\s*:\s*"([^"]+)".*?"definition"\s*:\s*"([^"]+)".*?"exampleSentence"\s*:\s*"([^"]+)".*?"translation"\s*:\s*"([^"]+)"',
        dotAll: true,
      );
      for (final match in regex.allMatches(json)) {
        entries.add(VocabularyEntry(
          word: match.group(1) ?? '',
          definition: match.group(2) ?? '',
          exampleSentence: match.group(3) ?? '',
          translation: match.group(4) ?? '',
        ));
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<String> transcribeAudio(Uint8List audioBytes) async {
    if (_model == null) return '';
    try {
      final response = await _model!.generateContent([
        Content.multi([
          DataPart('audio/aac', audioBytes),
          TextPart(
              'This is an English language learning recording. '
              'Transcribe exactly what the student says in English. '
              'Return ONLY the transcription, no comments, no punctuation changes.'),
        ])
      ]);
      return response.text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<Lesson?> generateLesson(String context, CefrLevel level) async {
    if (_generationModel == null) return null;
    final id = 'gen_${DateTime.now().millisecondsSinceEpoch}';
    final prompt = '''
Generate an authentic English learning dialogue based on this context: "$context"
Student level: ${level.code}

Return ONLY a raw JSON object — absolutely no markdown, no code fences, no explanation before or after.
The JSON must exactly match this structure:

{"id":"$id","title":"...","description":"...","domain":"daily","level":"${level.code.toLowerCase()}","duration_seconds":180,"emoji":"...","transcript":[{"index":0,"speaker":"role","text":"...","translation":"..."},{"index":1,"speaker":"role","text":"...","translation":"..."}],"vocabulary":[{"word":"...","definition":"...","example_sentence":"...","translation":"..."}]}

Strict requirements:
- 10 to 14 exchanges in the transcript
- Natural, realistic dialogue — not textbook, not formal
- Speaker labels: short role names matching the context (receptionist, customer, doctor, patient, friend, colleague, etc.)
- 5 to 6 vocabulary items, relevant to the dialogue
- All "translation" values in French
- Adapt complexity to ${level.code} level
- emoji: one emoji representing the topic
- domain: pick from travel, work, daily, culture, tech, health, social, sport
- duration_seconds: integer number (e.g. 180)
- index in transcript: integer starting at 0
- No asterisks, no markdown, no special characters in text fields
''';

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _generationModel!.generateContent(
          [Content.text(prompt)],
        );
        final raw = response.text ?? '';
        final jsonStr = _extractJsonObject(raw);
        if (jsonStr.isEmpty) continue;
        final decoded = _sanitizeGeneratedJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
          id,
          level,
        );
        return Lesson.fromJson(decoded);
      } catch (_) {
        if (attempt == 2) return null;
      }
    }
    return null;
  }

  /// Fixes common Gemini output issues: numbers as strings/doubles, missing fields.
  static Map<String, dynamic> _sanitizeGeneratedJson(
    Map<String, dynamic> j,
    String id,
    CefrLevel level,
  ) {
    j['id'] = id;
    j.putIfAbsent('level', () => level.code.toLowerCase());
    j.putIfAbsent('domain', () => 'daily');
    j.putIfAbsent('emoji', () => '🎧');

    // duration_seconds must be int
    final dur = j['duration_seconds'];
    if (dur is double) {
      j['duration_seconds'] = dur.toInt();
    } else if (dur is String) {
      j['duration_seconds'] = int.tryParse(dur) ?? 180;
    }
    j.putIfAbsent('duration_seconds', () => 180);

    // Fix transcript indices
    if (j['transcript'] is List) {
      final transcript = (j['transcript'] as List).toList();
      for (int i = 0; i < transcript.length; i++) {
        if (transcript[i] is Map) {
          final line = Map<String, dynamic>.from(transcript[i] as Map);
          final idx = line['index'];
          if (idx is double) {
            line['index'] = idx.toInt();
          } else if (idx is String) {
            line['index'] = int.tryParse(idx) ?? i;
          }
          line.putIfAbsent('index', () => i);
          transcript[i] = line;
        }
      }
      j['transcript'] = transcript;
    }

    return j;
  }

  /// Extracts the rightmost complete JSON object that contains lesson fields.
  /// Searches backwards to skip any thinking/preamble JSON fragments.
  static String _extractJsonObject(String raw) {
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Walk backwards through closing braces to find the rightmost valid lesson JSON
    int searchFrom = cleaned.length - 1;
    while (searchFrom >= 0) {
      final end = cleaned.lastIndexOf('}', searchFrom);
      if (end == -1) break;

      // Find matching opening brace using brace counting
      int depth = 0;
      int start = -1;
      for (int i = end; i >= 0; i--) {
        if (cleaned[i] == '}') depth++;
        if (cleaned[i] == '{') {
          depth--;
          if (depth == 0) {
            start = i;
            break;
          }
        }
      }
      if (start == -1) break;

      final candidate = cleaned.substring(start, end + 1);
      // Accept only if it looks like a lesson (has the required arrays)
      if (candidate.contains('"transcript"') &&
          candidate.contains('"vocabulary"')) {
        return candidate;
      }
      searchFrom = start - 1;
    }
    return '';
  }

  void startLessonChat(Lesson lesson, CefrLevel level) {
    assert(_model != null, 'Call init() before startLessonChat()');
    final prompt = _buildLessonPrompt(lesson, level);
    _chat = _model!.startChat(history: [
      Content.model([TextPart(prompt)]),
    ]);
  }

  void startFreeConversation(CefrLevel level) {
    assert(_model != null, 'Call init() before startFreeConversation()');
    final prompt = _buildFreeConversationPrompt(level);
    _chat = _model!.startChat(history: [
      Content.model([TextPart(prompt)]),
    ]);
  }

  void endSession() {
    _chat = null;
  }

  String _buildLessonPrompt(Lesson lesson, CefrLevel level) {
    return '''
You are Alex, an English teacher. The student (${level.code} level, French speaker) has just listened to the lesson: "${lesson.title}".

SCOPE — you can handle any of these:
- Discuss the dialogue: comprehension, context, characters
- Answer questions about the topic or theme (vocabulary, grammar, culture, real-world usage)
- Provide lists on request: expressions, collocations, synonyms, tips — related to the lesson theme
- Explain a grammar point if the student asks
- Correct errors and reformulate

Lesson vocabulary for reference: ${lesson.vocabulary.map((v) => v.word).join(', ')}.

TONE: Professional, direct, warm. Skip filler praise ("Great!", "Wonderful!", "Excellent!"). If the student does well, move forward without over-commenting. Be engaged, not effusive.

CORRECTIONS: Clean and brief. Say "Use X, not Y" or "We say X here" then continue. Never dwell on errors.

VOCAB LISTS: When the student requests a vocabulary or expression list, use this exact format — no exceptions:
[VOCAB]
1. English word or phrase | French translation | brief definition in English (max 8 words)
2. English word or phrase | French translation | brief definition in English (max 8 words)
[/VOCAB]
Add one sentence before the list introducing it, and one short follow-up sentence after. Five to six items max.

FORMAT — output is read aloud by TTS:
- Plain text only. No asterisks, bullets, hashtags, markdown, backticks or symbols of any kind.
- If the student writes in French, answer in English but briefly acknowledge what they asked.

LENGTH: 60 to 80 words for conversational turns. Up to 150 words for requested lists or explanations.
One question or prompt per response — never stack multiple questions.
Adapt vocabulary and complexity to ${level.code} level.

Open with a brief welcome and one focused question about the lesson.
''';
  }

  String _buildFreeConversationPrompt(CefrLevel level) {
    return '''
You are Alex, an expert English teacher helping French adults improve their spoken English.

Student level: ${level.code} (${level.labelFr})

Your approach:
Have a natural, engaging conversation on any topic the student chooses.
After each student response, gently correct one error if present.
Introduce one useful expression per exchange.
Ask open-ended follow-up questions to keep the student talking.
Adapt vocabulary complexity to ${level.code} level.
Be warm, encouraging, and conversational.

CRITICAL FORMAT RULES — your output is read by a text-to-speech engine:
- NEVER use asterisks, underscores, hashtags, bullet points, or any markdown formatting
- NEVER use symbols like *, **, _, __, #, or backticks
- Write corrections as plain spoken English: say "We would say X instead of Y" not "*X*"
- Plain text only — no formatting whatsoever, as if speaking out loud

Keep all responses under 100 words. Speak naturally.
Start by greeting the student and asking what they would like to talk about today.
''';
  }

  String _buildSystemPrompt(String topicId, String topicTitle) {
    final scenario = _scenarios[topicId];
    final roleDescription = scenario?['role'] ?? 'a native English speaker';
    final situationDescription = scenario?['situation'] ??
        'Have a natural conversation about $topicTitle.';

    return '''
You are Alex, an expert English teacher running an immersive roleplay session with a French adult learner.

## YOUR TWO ROLES

**Role 1 — The Character**
You play $roleDescription.
Situation: $situationDescription
Stay fully in character during the scene. Use natural, realistic dialogue appropriate to the role.

**Role 2 — The Teacher**
After EACH student response, you briefly step out of character to:
- Correct any grammar or vocabulary errors (gently, with the right version)
- Reformulate what the student said in better English
- Highlight 1 useful expression or vocabulary word from your response

Then immediately return to the scene.

## FORMAT (strictly follow this — output is read aloud by TTS)

Use this exact structure for every response:

[IN SCENE]
(Your character's dialogue — 2-3 sentences max, natural and engaging)

[TEACHER NOTE]
(One correction or reformulation if needed — or "Well done!" if correct)
New expression: "[word or phrase]" — [brief definition]

[BACK TO SCENE]
(A question that keeps the student engaged and speaking — in character)

## TEACHING PRINCIPLES
- Ask open questions to keep the student talking
- If the student makes an error, correct it warmly: "We'd say '...' instead of '...'"
- Reformulate: "You mean to say: '...' — that's perfect!"
- Challenge the student progressively: introduce slightly advanced vocabulary
- After 3-4 exchanges, briefly summarize progress: "Great! You've used [expression] correctly."
- Adapt to the student's level as the conversation develops

## CRITICAL CONSTRAINTS
- Keep ALL output under 120 words total — this is voice dialogue
- No bullet points, no markdown in the dialogue parts
- Speak clearly as if talking to someone face to face
- Never break immersion in the [IN SCENE] section

Start the session by briefly describing the situation to the student (in 1-2 sentences), then immediately begin the roleplay.
''';
  }
}
