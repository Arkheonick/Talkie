# Talkie — UX Flows & Architecture

> Ce document décrit l'architecture de navigation, les flows utilisateur,
> et les patterns UX par écran. Il est complémentaire au DESIGN_SYSTEM.md.

---

## 1. Architecture de Navigation

### Structure globale

```
App
├── Onboarding (premier lancement uniquement)
│   └── → Shell principal
│
└── Shell principal (NavigationBar 4 tabs)
    ├── [Tab 0] Apprendre
    │   ├── Écran thèmes (home)
    │   └── → LessonScreen
    │       ├── Tab: Audio
    │       ├── Tab: Chat
    │       └── Tab: Vocab
    │
    ├── [Tab 1] Quiz
    │   ├── QuizSetupScreen
    │   └── → QuizScreen
    │       └── → QuizSummaryScreen
    │
    ├── [Tab 2] Discussion
    │   └── ProfScreen (voice chat)
    │
    └── [Tab 3] Lexique
        ├── LexiqueScreen
        └── → FlashcardScreen
```

### Principes de navigation

- **Navigation latérale** (tabs) : contextes indépendants, pas de relation parent-enfant
- **Navigation verticale** (push) : drill-down dans un contexte (thème → leçon)
- **Retour** : toujours via flèche native Android ou geste swipe
- **Modales** : bottom sheets uniquement pour les sélecteurs (dossier, niveau)
  Jamais de dialog plein écran sauf confirmation destructive

### Transitions recommandées

```dart
// Navigation push standard (drill-down)
MaterialPageRoute(
  builder: (_) => TargetScreen(),
)

// Bottom sheets
showModalBottomSheet(
  isScrollControlled: true,
  backgroundColor: AppTheme.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
)
```

---

## 2. Flow — Apprendre

### Objectif utilisateur
Trouver un sujet d'apprentissage et démarrer une leçon.

### Flow principal

```
Apprendre (home)
    │
    ├─ [CTA Discussion] ──────────────────→ Discussion (Tab 2)
    │                                        (raccourci voice-first)
    │
    ├─ [CTA Générer une leçon] ──────────→ LessonScreen (générée)
    │
    └─ [Card thème] ──→ LessonList du thème
                            │
                            └─ [Card leçon] ──→ LessonScreen
                                                    ├── Audio (défaut)
                                                    ├── Chat
                                                    └── Vocab
```

### Structure de l'écran Apprendre

```
┌─────────────────────────────────────┐
│  ZONE ÉDITORIAL (Editorial Bold)    │
│  ─────────────────────────────────  │
│  Greeting + nom de l'utilisateur    │  display-lg, Sora 800
│  Sous-texte niveau + progression    │  body-sm, muted                  
│                                     │
│  [CTA Discussion — card hero]       │  orbe small + "Parler maintenant"
├─────────────────────────────────────┤
│  ZONE THÈMES (Structured Vibrant)   │
│  ─────────────────────────────────  │
│  Label section "Thèmes"             │
│                                     │
│  [Grid thèmes 2 colonnes]           │  cards gradient + SVG + label
│  Voyage    Travail                  │
│  Quotidien Sport                    │
│  Culture   Tech                     │
│  Santé     Social                   │
│                                     │
│  [Générer une leçon custom]         │  card secondaire pleine largeur
└─────────────────────────────────────┘
```

### Points d'attention UX

- Le CTA Discussion est visible immédiatement (above the fold) — c'est la
  fonctionnalité principale, elle ne doit pas être cachée dans un tab
- Les thèmes sont ordonnés par popularité/pertinence, pas alphabétiquement
- Pas de barre de recherche sur cet écran — les thèmes sont en nombre limité
- La card "Générer" doit visuellement différer des cards thèmes (pas de
  couleur thème, plutôt gradient primary/indigo)

---

## 3. Flow — Discussion (Voice)

### Objectif utilisateur
Avoir une conversation en anglais avec le professeur IA.

### Flow principal

```
ProfScreen
    │
    [État initial] Topic chips visibles
    │
    [Sélection topic] ou [Nouvelle discussion]
    │
    [Tap microphone] ──→ OrbState.listening
    │                        │
    │                    [Parole détectée] ──→ OrbState.thinking
    │                                              │
    │                                         [Réponse IA] ──→ OrbState.speaking
    │                                                              │
    │                                                         [Fin TTS] ──→ OrbState.idle
    │
    [Swipe/scroll] ──→ Transcript visible en dessous de l'orbe
    │
    [Mot intéressant dans transcript] ──→ [Bottom sheet: sauvegarder dans Lexique]
```

### Structure de l'écran Discussion

```
┌─────────────────────────────────────┐
│  AppBar minimal                     │
│  "Discussion" + topic actif         │
├─────────────────────────────────────┤
│                                     │
│                                     │
│         ┌───────────────┐           │  Zone haute (60% écran)
│         │   [ORBE]      │           │  L'orbe domine l'espace
│         │   140-160px   │           │
│         └───────────────┘           │
│                                     │
│     [Topic chips si aucun actif]    │
│                                     │
├─────────────────────────────────────┤
│  [Contrôles]                        │
│  [Nouveau]  [● MIC]  [Fin]          │  barre de contrôle compacte
├─────────────────────────────────────┤
│  Transcript (scroll)                │  Zone basse, secondaire
│  Bulles IA + utilisateur            │
└─────────────────────────────────────┘
```

### Points d'attention UX

- L'orbe EST le feedback. Elle remplace les spinners et les loading states.
- Pendant `OrbState.speaking`, le transcript défile automatiquement
- Les bulles de transcript sont petites (12–13px) — ce sont des notes, pas
  le focus principal
- Le bouton mic a une taille tactile minimum de 56×56px
- La discussion est éphémère (pas de persistance) — clarifier visuellement
  avec un indicateur "session temporaire" dans l'AppBar

---

## 4. Flow — Quiz

### Objectif utilisateur
Tester et mesurer son vocabulaire sur un thème précis.

### Flow principal

```
QuizSetupScreen
    │
    ├─ [Saisie thème custom] ──────→ QuizScreen (thème custom)
    ├─ [Card thème suggéré] ────────→ QuizScreen (thème prédéfini)
    └─ [Recent custom chip] ────────→ QuizScreen (thème récent)
    
QuizScreen
    │
    [Question affichée] → [4 réponses]
    │
    [Tap réponse] ──→ Feedback immédiat (correct/incorrect + explication)
    │
    [10 questions] ──→ QuizSummaryScreen
                           │
                           [Score + tier T1/T2/T3]
                           [Révision erreurs]
                           └─ [Refaire] ou [Retour]
```

### Structure QuizSetupScreen

```
┌─────────────────────────────────────┐
│  ZONE CUSTOM (Editorial Bold)       │
│  ─────────────────────────────────  │
│  "Je choisis mon thème"             │  title-lg
│  Sous-texte                         │
│                                     │
│  [Input texte + bouton Lancer]      │
│  [Chips thèmes récents]             │
│                                     │
├─────────────────────────────────────┤
│  "Thèmes suggérés"                  │
│  ─────────────────────────────────  │
│  Grid 2×4 cards thèmes              │  avec score si déjà joué
└─────────────────────────────────────┘
```

### Structure QuizScreen

```
┌─────────────────────────────────────┐
│  Progress bar + Question X/10       │
├─────────────────────────────────────┤
│                                     │
│  Question (display-md)              │  max 2 lignes
│                                     │
├─────────────────────────────────────┤
│  [A]  Réponse A                     │
│  [B]  Réponse B                     │
│  [C]  Réponse C                     │
│  [D]  Réponse D                     │
├─────────────────────────────────────┤
│  [Explication] (après réponse)      │  s'affiche après tap
└─────────────────────────────────────┘
```

### Points d'attention UX

- La progress bar est toujours visible — l'utilisateur sait où il en est
- Une seule question à l'écran, aucune distraction
- Le feedback (correct/incorrect) est immédiat et ne nécessite pas un bouton
  "Continuer" — l'utilisateur peut lire l'explication puis tapper pour passer
- Les cards réponses ont toutes la même hauteur (min-height: 52px)

---

## 5. Flow — Lexique

### Objectif utilisateur
Consulter, organiser et réviser le vocabulaire sauvegardé.

### Flow principal

```
LexiqueScreen
    │
    ├─ [Liste groupée par leçon ou dossier]
    │   │
    │   ├─ [Tap mot] ──→ Détail (expand in-place ou bottom sheet)
    │   ├─ [Swipe gauche] ──→ Actions (supprimer, déplacer)
    │   └─ [Long press] ──→ Mode sélection multiple
    │
    ├─ [Barre de recherche] ──→ Filtre temps réel
    │
    └─ [Bouton Flashcards] ──→ FlashcardScreen
                                   │
                                   [Card recto: mot]
                                   [Tap] → Recto/verso (animation flip)
                                   [Swipe →] Suivant
                                   [Swipe ←] Précédent
```

### Points d'attention UX

- Pas de toggle "mastered" visible (supprimé — complexité inutile)
- La recherche est visible immédiatement, pas derrière un bouton
- Les dossiers sont pliables/dépliables avec animation
- L'action de sauvegarde (depuis les leçons) ouvre un bottom sheet de
  sélection de dossier — jamais de dialog plein écran
- Les flashcards : animation flip obligatoire (c'est un moment de rétention)

---

## 6. Onboarding

### Objectif
Établir l'identité de l'app et collecter le niveau CEFR de l'utilisateur.

### Flow

```
Splash (1.5s, logo animé)
    │
    └─ OnboardingScreen
           ├─ Écran 1: Promesse ("Parle anglais avec un prof IA")
           ├─ Écran 2: Fonctionnement (3 features: Discussion, Quiz, Lexique)
           └─ Écran 3: Sélection niveau CEFR
                   │
                   └─ → Shell principal
```

### Points d'attention UX

- Maximum 3 écrans d'onboarding
- Chaque écran a UN seul message
- Les illustrations sont grandes (200×200px) et centrées
- Le bouton "Passer" est toujours visible (top right)
- La sélection de niveau est le seul input — pas de formulaire, pas de compte

---

## 7. Patterns d'État

### États de chargement

| Contexte | Pattern |
|----------|---------|
| Génération leçon IA | Orbe animée + texte "Création en cours..." |
| Chargement liste | Shimmer placeholders (3 cards) |
| Envoi message chat | Indicateur typing dans bulle |
| Quiz generation | Progress bar indéterminée + texte |

### États vides

| Écran | Message | Illustration |
|-------|---------|-------------|
| Lexique vide | "Commence une leçon pour sauvegarder du vocabulaire" | empty_state.svg |
| Pas de quiz récent | Texte court + invite à démarrer | — |
| Aucun résultat recherche | "Aucun mot trouvé pour '...'" | — |

### États d'erreur

- Toujours contextuels (inline, pas d'alerte générique)
- Texte court, action claire (Réessayer / Continuer sans)
- Jamais de message d'erreur technique à l'utilisateur

---

*Dernière mise à jour : 2026-05-17*
*Version : 1.0 — Document fondateur*
