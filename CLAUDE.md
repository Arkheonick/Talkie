# Talkie — Claude Instructions

## Project Context
- **Type:** Application mobile Android (Flutter)
- **Stack:** Flutter / Dart — Gemini API — Android STT/TTS — PDF Dart
- **Target:** Android (Pixel 10 Pro prioritaire), pas de backend serveur

## Project Structure
```
lib/
├── features/       # Fonctionnalités (home, session, summary, export)
├── services/       # Gemini, STT, TTS, PDF
├── models/         # Session, ThemeTopic, VocabularyEntry
└── app/            # Router, Theme
```

## Coding Conventions
- Language: Dart (Flutter)
- Formatting: `dart format` — 2 spaces indent
- Naming: camelCase variables/methods, PascalCase classes, snake_case files
- Comments: English

## Key Commands
- Install: `flutter pub get`
- Dev (Android): `flutter run`
- Build release: `flutter build apk --obfuscate --split-debug-info=build/symbols`
- Tests: `flutter test`

## Absolute Rules
- Jamais de clé API dans le code — toujours via `.env` (flutter_dotenv)
- Ne jamais commit `.env` — utiliser `.env.example`
- Architecture 100% client-side — pas de backend, pas de base de données distante
- Toujours tester le dialogue vocal sur device réel (pas simulateur)

## External Services
- **Gemini API** : clé dans `.env` → `GEMINI_API_KEY=...`
- **Android STT** : `speech_to_text` package Flutter
- **Android TTS** : `flutter_tts` package Flutter
- **PDF** : package `pdf` + `printing` pour export

## Known Issues / Gotchas
- STT nécessite permission `RECORD_AUDIO` dans AndroidManifest.xml
- TTS : tester les voix anglaises disponibles sur le device (qualité variable)
- Gemini Flash : contexte limité à ~1M tokens — gérer la fenêtre de conversation
- PDF generation : fonts custom à embarquer dans assets/fonts/
