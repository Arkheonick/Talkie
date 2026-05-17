# Talkie — Claude Instructions

## Project Context
- **Type:** Application mobile Android (Flutter)
- **Stack:** Flutter / Dart — Gemini API — Android STT/TTS — PDF Dart
- **Target:** Android (Pixel 10 Pro prioritaire), compatible autres Android
- **Objectif produit:** Améliorer le niveau d'anglais via dialogue vocal interactif avec un professeur IA
- **Utilisateur:** Solo, autonome — pas de compte, pas d'authentification

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

## Design System — Source de vérité absolue

Tout travail UI/UX DOIT commencer par lire `docs/DESIGN_SYSTEM.md`.
Tout travail sur les flows et l'architecture DOIT lire `docs/UX_FLOWS.md`.
Les références visuelles sont dans `references/REFERENCES.md`.

**Ces fichiers font autorité sur toute autre convention.**

### Règles design non-négociables

- **Dark theme uniquement** — tokens `AppTheme.*` exclusivement, jamais `Colors.white`
- **No emoji dans l'UI** — Phosphor Icons (`phosphor_flutter`) + SVG illustrations
- **withValues(alpha:) uniquement** — `withOpacity()` est interdit (deprecated)
- **Spectre éditorial** — les screens d'entrée penchent vers Editorial Bold (A),
  les screens de contenu vers Structured Vibrant (C)
- **Orbe vocale** — l'écran Discussion a une orbe animée comme élément signature
- **Typo display** — les gros titres utilisent Sora 800+ avec letter-spacing négatif
- **Couleurs par thème** — chaque thème a sa couleur identitaire (voir AppTheme)

### Avant TOUTE tâche UI

1. Charger la skill `frontend-design:frontend-design`
2. Lire `docs/DESIGN_SYSTEM.md` section pertinente
3. Valider que le composant respecte les 15 contraintes négatives du design system

### Packages design requis

```yaml
phosphor_flutter: ^2.0.0    # Icons (remplace emojis UI)
flutter_svg: ^2.0.0         # Illustrations SVG par thème
lottie: ^3.0.0              # Animations orbe + célébrations
```

## Core UX Principles

- **Voice-first** — Le micro est accessible en 1 tap depuis n'importe où
- **Dialogue vocal = flux principal** — L'orbe Discussion est le CTA hero de l'écran Apprendre
- **Progressive disclosure** — Jamais plus de 2 niveaux de hiérarchie simultanés
- **Feedback immédiat** — Chaque interaction produit un retour visuel < 100ms
- PDF exporté : structuré, esthétique, lisible — titre, sections vocab, phrases, traductions

## Pedagogy — Comportement du Professeur IA
- Corrige les erreurs de l'utilisateur (prononciation, grammaire, vocabulaire)
- Traduit à la demande
- Pose des questions, fait répéter, challenge l'utilisateur
- Structure un plan de travail autour du thème choisi
- Adapte le niveau au fil de la conversation

## Known Issues / Gotchas
- STT nécessite permission `RECORD_AUDIO` dans AndroidManifest.xml
- TTS : tester les voix anglaises disponibles sur le device (qualité variable selon Android)
- Gemini Flash : gérer la fenêtre de contexte — résumer l'historique si trop long
- PDF generation : fonts custom à embarquer dans `assets/fonts/`
- Hive : initialiser avant `runApp()` dans `main.dart`
