# Roadmap — Talkie

## Phase 1 — Foundation
- [ ] Structure Flutter créée (`flutter create`)
- [ ] Git initialisé + `.gitignore` + `.env.example`
- [ ] CLAUDE.md configuré
- [ ] Gemini API connectée et testée
- [ ] STT et TTS natifs fonctionnels

## Phase 2 — MVP (Dialogue vocal)
- [ ] Écran d'accueil avec choix de thématique
- [ ] Session de dialogue : micro → Gemini → voix
- [ ] Prompt système du professeur (correction, traduction, questions)
- [ ] Historique de conversation en mémoire (contexte)
- [ ] Affichage progressif du résumé (vocab + phrases + traductions)

## Phase 3 — Export PDF
- [ ] Génération PDF structuré et esthétique
- [ ] Sections : titre thème, vocabulaire, phrases clés, traductions
- [ ] Téléchargement depuis l'app (partage Android)
- [ ] Typographie et mise en page soignées

## Phase 4 — Polissage
- [ ] UI/UX finalisée (light theme, typographie, animations)
- [ ] Gestion des erreurs (réseau, STT raté, quota Gemini)
- [ ] Persistance des sessions (Hive)
- [ ] Performance et latence optimisées
- [ ] Tests sur Pixel 10 Pro + autres Android

## Phase 5 — Évolutions futures
- [ ] Modes d'apprentissage supplémentaires (quiz, dictée, roleplay)
- [ ] Niveaux de difficulté configurables
- [ ] Historique des thèmes parcourus
- [ ] Statistiques de progression
