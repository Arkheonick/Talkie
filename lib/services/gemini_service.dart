import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/session.dart';
import '../models/vocabulary_entry.dart';

class GeminiService {
  GenerativeModel? _model;
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

  void endSession() {
    _chat = null;
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
