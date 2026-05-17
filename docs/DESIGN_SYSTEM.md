# Talkie — Design System v1.0

> Document de référence pour toutes les décisions de design UI/UX.
> Toute interface créée ou modifiée DOIT respecter ce document.
> En cas de conflit entre ce fichier et le code existant, ce fichier fait foi.

---

## 1. Identité & Philosophie

### Positionnement émotionnel

Talkie n'est pas une app d'études. C'est un entraîneur personnel vocal.
L'utilisateur ouvre l'app pour une chose : **parler anglais, maintenant**.

L'arc émotionnel visé :
```
Hésitation → Engagement → Flux → Confiance
```

Chaque écran doit soutenir cet arc. Un écran qui crée de la friction cognitive
rompt le flux. Un écran qui crée de l'énergie l'amplifie.

### Les 4 principes immuables

1. **Voice-first** — L'interaction vocale est primaire. Tout élément qui
   distrait de l'acte de parler est du bruit visuel à éliminer.

2. **Hierarchy before decoration** — La hiérarchie visuelle (taille, poids,
   contraste) précède toujours l'ornementation. Si la hiérarchie est floue,
   la décoration ne la sauvera pas.

3. **Earned color** — Chaque couleur a une signification fonctionnelle.
   La couleur identifie un thème, signale un état, guide une action.
   Elle n'est jamais purement décorative.

4. **Motion as feedback** — L'animation est une réponse à une action ou
   un état. Elle n'est jamais un spectacle autonome.

### Ce que Talkie n'est PAS visuellement

- Une app de flashcards (pas de grilles monotones de cartes identiques)
- Un outil SRS utilitaire (pas d'UI froide et fonctionnelle)
- Un cours en ligne (pas de structure scolaire avec progress bars partout)
- Une app générique "AI learning" (pas de purple/indigo sur blanc, pas de
  bulles de chat basiques, pas de Material Design par défaut)

---

## 2. Spectre de Direction Visuelle

Le design system fonctionne dans un spectre entre deux modes d'expression.
Les deux sont valides et complémentaires — ils s'appliquent selon le contexte.

```
  EDITORIAL BOLD                    STRUCTURED VIBRANT
  ──────────────────────────────────────────────────────
  Screens d'entrée                  Screens de contenu
  Moments d'énergie                 Moments d'apprentissage
  Hero, CTA, Onboarding             Leçon, Quiz, Lexique
  Typo display massive              Typo lisible et dense
  Blocs de couleur                  Couleur par thème / accent
  Layout asymétrique                Grid organisée
  ──────────────────────────────────────────────────────
       A                                     C
```

**Règle de composition** : Un même écran peut mélanger les deux modes.
L'en-tête d'un écran peut être Editorial Bold (titre display, couleur forte)
tandis que le contenu en dessous est Structured Vibrant (liste propre, dense).

---

## 3. Typographie

### Familles de polices

| Famille | Usage | Package |
|---------|-------|---------|
| **Sora** | Display, titres, hero text | google_fonts |
| **DM Sans** | Body, UI, descriptions | google_fonts |

Aucune autre police n'est autorisée sans validation explicite.
Inter, Roboto, et les polices système sont interdites.

### Échelle typographique

| Token | Famille | Taille | Poids | Letter-spacing | Usage |
|-------|---------|--------|-------|----------------|-------|
| `display-xl` | Sora | 48px | 900 | -1.5px | Hero screens, onboarding |
| `display-lg` | Sora | 36px | 800 | -1.2px | Titres d'écran editorial |
| `display-md` | Sora | 28px | 800 | -0.8px | Titres de sections majeures |
| `title-lg` | Sora | 22px | 700 | -0.5px | Titres de cartes, modales |
| `title-md` | Sora | 18px | 700 | -0.3px | Titres de composants |
| `title-sm` | Sora | 15px | 600 | -0.2px | Sous-titres |
| `body-lg` | DM Sans | 16px | 400 | 0 | Texte principal, définitions |
| `body-md` | DM Sans | 14px | 400 | 0 | Texte standard |
| `body-sm` | DM Sans | 13px | 400 | 0 | Texte secondaire |
| `label-lg` | DM Sans | 12px | 700 | +0.4px | Labels uppercase |
| `label-sm` | DM Sans | 10px | 700 | +0.6px | Badges, chips, tags |

### Règles typographiques critiques

- **Line-height display** : 0.95–1.05 — serré, impression éditoriale
- **Line-height body** : 1.5–1.6 — aéré, confort de lecture
- **Letter-spacing négatif** sur tous les tokens display — marqueur de
  maîtrise typographique, interdit d'utiliser 0 sur les grands titres
- **Jamais de texte en majuscules** sauf labels/tags (max 12px)
- **Jamais de texte** < 11px dans l'UI (badges uniquement)
- Contraste minimum : 4.5:1 pour le corps de texte (WCAG AA)

---

## 4. Système de Couleurs

### Tokens sémantiques — Dark Theme (mode actuel)

```dart
// ── Couches de fond (ne pas inverser la hiérarchie) ──────────────────────
bg          = #0F172A   // Scaffold, fond d'écran (couche 0)
surface     = #1E293B   // AppBar, nav bar, bottom sheets (couche 1)
surfaceHigh = #273549   // Cards, bulles, éléments conteneurs (couche 2)
surfaceTop  = #2F3F55   // Éléments actifs, hover states (couche 3)

// ── Texte ────────────────────────────────────────────────────────────────
onSurface   = #F1F5F9   // Texte principal (slate-100)
muted       = #94A3B8   // Texte secondaire (slate-400)
subtle      = #475569   // Texte tertiaire, placeholders (slate-600)

// ── Interactif ───────────────────────────────────────────────────────────
primary     = #818CF8   // Indigo-400 — accent principal
primaryLight= #1A818CF8 // Indigo 10% — surfaces actives
accent      = #34D399   // Émeraude — succès, validation, feedback positif

// ── Bordures ─────────────────────────────────────────────────────────────
border      = rgba(255,255,255,0.12)  // Bordure standard (subtile)
borderStrong= rgba(255,255,255,0.22)  // Bordure renforcée (focus, actif)
```

### Couleurs par thème (système earned color)

Chaque thème possède une couleur identitaire. Cette couleur est utilisée
exclusivement dans le contexte de ce thème. Elle crée l'ancrage mémoriel.

| Thème | Token | Hex | Personnalité |
|-------|-------|-----|-------------|
| Voyage | `themeVoyage` | `#38BDF8` | Sky blue — ouverture, horizon |
| Travail | `themeTravail` | `#A78BFA` | Violet — ambition, sérieux |
| Quotidien | `themeQuotidien` | `#F59E0B` | Amber — chaleur, proximité |
| Sport | `themeSport` | `#22C55E` | Vert — énergie, dépassement |
| Culture | `themeCulture` | `#F472B6` | Rose — créativité, expression |
| Tech | `themeTech` | `#2DD4BF` | Teal — innovation, précision |
| Santé | `themeSante` | `#F87171` | Rouge-corail — vitalité |
| Social | `themeSocial` | `#FB923C` | Orange — convivialité |

### Règles d'utilisation des couleurs thème

```
Autorisé :
  - Gradient de fond de card (themeColor × 0.22 → × 0.04)
  - Bordure de card (themeColor × 0.35–0.45)
  - Texte de label/sublabel dans la card
  - Icône ou illustration dans la card
  - Badge de score/résultat thématique

Interdit :
  - Couleur thème sur un écran qui n'est pas ce thème
  - Fond plein à themeColor (illisible + agressif)
  - Mélange de 2 couleurs thèmes sur un même composant
```

### Gradients autorisés

```dart
// Card thème (usage standard)
LinearGradient(
  colors: [
    themeColor.withValues(alpha: 0.22),
    themeColor.withValues(alpha: 0.04),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Hero editorial (mode A — écrans d'entrée)
// Utiliser 2 couleurs thèmes différentes OU primary + couleur thème
LinearGradient(
  colors: [Color1, Color2],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Interdit : gradients de 3 couleurs ou plus
// Interdit : gradient blanc→couleur (trop générique)
// Interdit : withOpacity() — utiliser withValues(alpha:) uniquement
```

---

## 5. Layout & Grille

### Unité de base : 4px

Tout espacement est un multiple de 4px (jamais de valeurs impaires comme 5, 7, 9).

### Échelle d'espacement

| Token | Valeur | Usage typique |
|-------|--------|---------------|
| `xs` | 4px | Espace interne minimal, gaps tight |
| `sm` | 8px | Padding interne compact, gaps listes |
| `md` | 12px | Padding cards compact |
| `lg` | 16px | Padding standard, marges internes |
| `xl` | 20px | Marge latérale d'écran (standard) |
| `2xl` | 24px | Espacement entre composants |
| `3xl` | 32px | Espacement entre sections |
| `4xl` | 48px | Espacement majeur, sections hero |

### Anatomie d'écran

```
┌─────────────────────────────────────┐
│  Status Bar (system)                │
├─────────────────────────────────────┤
│  AppBar / Header    [surface]       │  56–64px
├─────────────────────────────────────┤
│                                     │
│  Hero / Header section              │  variable
│  (Editorial Bold zone)              │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Contenu principal                  │  flex
│  (Structured Vibrant zone)          │
│                                     │
└─────────────────────────────────────┘
│  Navigation Bar    [surface]        │  80px
└─────────────────────────────────────┘
```

### Marges standards

- **Marge latérale écran** : 20px (invariable)
- **Padding top après header** : 24px
- **Espacement entre sections** : 28–32px
- **Gap entre cards en grid** : 12px
- **Gap entre items en liste** : 8px

### Border-radius

| Contexte | Rayon |
|----------|-------|
| Cards principales (thème, leçon) | 20px |
| Cards secondaires (quiz réponses, vocab) | 16px |
| Boutons primaires | 14px |
| Inputs, champs texte | 12px |
| Badges, chips, pills | 20–24px |
| Icônes container | 10–12px |
| Jamais moins de | 8px |

---

## 6. Iconographie & Illustration

### Politique "No Emoji" — Règle absolue

**Les emojis sont interdits dans l'interface utilisateur.**

Ils sont tolérés uniquement dans :
- Le contenu pédagogique généré par l'IA (textes de leçons, exemples)
- Les phrases d'exemple dans le Lexique

**Raison** : Les emojis sont inconsistants selon l'OS/version Android,
ils cassent la cohérence visuelle, et ils signalent une app générique.

### Système d'icônes : Phosphor Icons

```yaml
# pubspec.yaml
dependencies:
  phosphor_flutter: ^2.0.0
```

Règles d'usage :
- **Poids UI standard** : `PhosphorIconsRegular` (24px navigation, 20px cards)
- **Poids état actif/sélectionné** : `PhosphorIconsBold`
- **Poids micro-interactions** : `PhosphorIconsFill` (feedback immédiat)
- Taille navigation bar : 22–24px
- Taille dans cards/listes : 18–20px
- Taille labels/badges : 14–16px
- Couleur inactive : `AppTheme.muted` (#94A3B8)
- Couleur active : couleur du contexte (primary ou thème)

### Icônes de navigation recommandées

| Tab | Icône Phosphor inactive | Active |
|-----|------------------------|--------|
| Apprendre | `PhosphorIcons.book` | `PhosphorIcons.bookFill` |
| Quiz | `PhosphorIcons.brain` | `PhosphorIcons.brainFill` |
| Discussion | `PhosphorIcons.microphone` | `PhosphorIcons.microphoneFill` |
| Lexique | `PhosphorIcons.notePencil` | `PhosphorIcons.notePencilFill` |

### Illustrations SVG par thème

Remplacent les emojis dans les cards de thème.
Style : géométrique, abstrait, non-figuratif, inspiré de l'identité du thème.

```yaml
dependencies:
  flutter_svg: ^2.0.0

# assets/illustrations/
#   theme_travel.svg
#   theme_work.svg
#   theme_daily.svg
#   theme_sport.svg
#   theme_culture.svg
#   theme_tech.svg
#   theme_health.svg
#   theme_social.svg
#   empty_state.svg
#   voice_orb.svg (fallback statique)
```

Dimensions cibles :
- Cards thème : 48×48px (viewBox centré)
- Écrans vides (empty state) : 160×160px
- Onboarding : 200×200px

### Lottie Animations

```yaml
dependencies:
  lottie: ^3.0.0

# assets/animations/
#   orb_idle.json         Orbe vocale — état repos
#   orb_listening.json    Orbe vocale — écoute
#   orb_speaking.json     Orbe vocale — parole IA
#   orb_thinking.json     Orbe vocale — traitement
#   quiz_success.json     Célébration résultat quiz
#   level_up.json         Progression niveau
```

---

## 7. Voice UI — L'Orbe (Écran Discussion)

L'écran Discussion est le cœur fonctionnel de Talkie.
L'orbe vocale est l'élément de signature visuelle de l'app.

### Spécification de l'Orbe

**Taille** : 140–160px de diamètre
**Zone totale** : 280px de hauteur minimum (orbe + breathing room)
**Position** : centré horizontalement, upper-third de la zone de contenu

**États et comportement**

| État | Nom | Comportement visuel | Durée cycle |
|------|-----|---------------------|-------------|
| `OrbState.idle` | Repos | Sphère statique, glow subtil pulsé (0.85→1.0 opacity) | 3s |
| `OrbState.listening` | Écoute | Anneaux qui s'expandent vers l'extérieur | 1.2s |
| `OrbState.speaking` | Parole IA | Waveform circulaire animée | synchrone audio |
| `OrbState.thinking` | Traitement | Rotation lente du gradient (360° en 2s) | continu |

**Visuel de l'orbe**
```dart
// Couches de l'orbe (de l'extérieur vers l'intérieur)
// 1. Anneau d'état externe (animé selon OrbState)
// 2. Halo/glow (blur 24px, couleur primary × 0.25)
// 3. Bordure sphère (1.5px, primary × 0.5)
// 4. Fond sphère (radial gradient: primary × 0.35 center → transparent)
// 5. Icône centrale (microphone Phosphor, 32px, blanc × 0.9)
```

**Palette orbe**
- Mode indigo (défaut) : `primary` (#818CF8) avec glow indigo
- Mode custom : peut adopter la couleur du thème de la leçon active

### Contrôles Discussion

La barre de contrôle est minimaliste :
```
[  ←  ]  [       Orbe       ]  [  ✕  ]
Nouveau      Tap = mic ON       Fin
```
Un seul bouton d'action primaire. Pas de barre d'outils chargée.

---

## 8. Motion & Animation

### Tokens de durée

| Token | Durée | Usage |
|-------|-------|-------|
| `micro` | 80–100ms | Feedback tap, toggle, états immédiats |
| `fast` | 180–220ms | Transitions de composants, cards |
| `normal` | 280–320ms | Transitions d'écrans, modales, bottom sheets |
| `slow` | 450–550ms | Orbe états, celebrations partielles |
| `crawl` | 700–900ms | Onboarding, quiz summary celebration |

### Courbes d'easing

```dart
// Entrées (éléments qui apparaissent)
Curves.easeOut        // Standard — freine à l'arrivée
Curves.easeOutCubic   // Plus prononcé — pour les grandes distances

// Sorties (éléments qui disparaissent)
Curves.easeIn         // Standard — accélère au départ

// Transitions complètes
Curves.easeInOut      // Symétrique — pour les échanges

// Rebond (usage très limité)
Curves.elasticOut     // Seulement pour les celebrations, jamais l'UI standard
```

### Ce qu'on anime (liste explicite)

- Apparition de cards : `FadeTransition` + `SlideTransition` (8px vertical)
- Sélection de réponse quiz : `AnimatedContainer` scale 0.97 + color change
- Bouton microphone : `AnimatedContainer` scale + shadow + color (micro)
- Score counter quiz : `AnimatedSwitcher` avec slide vertical
- Orbe : `AnimationController` continu selon l'état
- Bottom sheets : SlideTransition natif Flutter (ne pas personnaliser)
- Navigation tabs : changement de couleur direct (pas d'animation)

### Ce qu'on n'anime PAS

- Le défilement des listes (natif Flutter, ne pas toucher)
- Les icônes de navigation (changement direct)
- Le texte (jamais d'animation sur le texte)
- Les transitions de page (utiliser MaterialPageRoute standard)

---

## 9. Composants — Spécifications

### ThemeCard (card de sélection de thème)

Structure :
```
┌─────────────────────────────────────┐  border: themeColor × 0.4
│  [Illustration SVG 48×48]           │  gradient: themeColor × 0.22 → × 0.04
│                                     │  border-radius: 20px
│  Nom du thème    [badge score ?]    │  padding: 16px
│  "Explorer →"                       │  min-height: 100px
└─────────────────────────────────────┘
```

- L'illustration remplace l'emoji
- "Explorer →" en couleur thème (11px, w700)
- Badge score si déjà joué : `T1`/`T2`/`T3` en couleur thème

### LessonCard (card de leçon dans un thème)

Structure :
```
┌─────────────────────────────────────┐
│  Numéro  Titre de la leçon          │  bg: surfaceHigh
│  A2      Description courte         │  border: border standard
│          [tag1] [tag2]              │  border-radius: 16px
│                           [→]      │  padding: 16px
└─────────────────────────────────────┘
```

### QuizAnswerCard

- Défaut : bg `surfaceHigh`, border standard
- Correct : bg `#064E3B`, border `#10b981 × 0.6`, texte `#6EE7B7`
- Incorrect : bg `#450A0A`, border `#ef4444 × 0.6`, texte `#FCA5A5`
- Transition : `AnimatedContainer` 200ms

### VocabCard (Lexique)

- Pas de toggle "mastered" (supprimé)
- Mot + traduction en header
- Définition en body
- Phrase d'exemple dans container distinct (bg surface, radius 10px)
- Bookmark : Phosphor `bookmarkSimple` / `bookmarkSimpleFill`

### NavigationBar

- Fond : `surface` (#1E293B)
- Indicateur actif : point ou underline en `primary`
- Icons : Phosphor (voir section iconographie)
- Labels : 10px, DM Sans, w700, visible toujours

---

## 10. UX Principles

### Voice-first

1. L'accès au micro ne demande jamais plus d'un tap
2. L'état du micro (actif/inactif) est toujours visible et non ambigu
3. Pendant la Discussion, aucun autre élément ne concurrence l'orbe
4. Le transcript est accessoire — il s'efface visuellement derrière l'orbe

### Progressive Disclosure

- L'écran Apprendre montre les thèmes, pas les leçons
- Les leçons s'ouvrent dans un écran dédié
- Les détails vocab sont dans les cards, pas en popup
- Jamais plus de 2 niveaux de hiérarchie visible simultanément

### Feedback immédiat

- Chaque tap produit un retour visuel en < 100ms
- Les états de chargement ont toujours un indicateur
- Les erreurs sont contextuelles, jamais dans une alerte générique

### Réduction de charge cognitive

- Maximum 2 actions primaires visible above the fold
- Un seul CTA par écran (le plus important)
- Les actions destructives sont cachées (swipe, long-press)

---

## 11. Contraintes Négatives — Ce Qu'on Ne Fait JAMAIS

Ces règles sont les plus importantes. Elles définissent ce qui rend le
design de Talkie distinct. Les enfreindre produit immédiatement une UI
"AI-generated generic".

1. **Jamais de grille 2 colonnes de cards identiques** en écran principal
   → Varier les tailles, les hauteurs, la densité
   
2. **Jamais d'emoji dans l'interface** (seul le contenu pédagogique)
   → Phosphor Icons + SVG illustrations

3. **Jamais de gradient violet/indigo sur fond blanc ou clair**
   → Le dark theme est imposé ; sur fond clair, utiliser couleur unie

4. **Jamais de border-radius < 8px** sur les cards et buttons

5. **Jamais de texte blanc sur fond coloré** sans vérifier le ratio (min 4.5:1)

6. **Jamais de layout > 5 éléments interactifs above the fold**

7. **Jamais de withOpacity()** — uniquement `withValues(alpha:)`

8. **Jamais de Colors.white** dans le code — utiliser les tokens AppTheme

9. **Jamais de font-size < 11px** dans l'UI production

10. **Jamais de titre de section en majuscules entières** > 13px

11. **Jamais de padding symétrique uniforme** sur toutes les cards d'un écran
    → Les cards doivent avoir un rythme visuel, pas une uniformité mécanique

12. **Jamais de shimmer/skeleton loader** sans fond `surfaceHigh`

13. **Jamais de TabBar Material par défaut** — la navigation est une
    NavigationBar custom en bas d'écran

14. **Jamais de AppBar avec titre centré** — titre toujours aligné à gauche

15. **Jamais de 3 boutons côte à côte** dans une même vue

---

## 12. Flutter — Packages et Implémentation

### Packages requis (à ajouter si manquants)

```yaml
dependencies:
  # Déjà présents
  google_fonts: ^6.x          # Sora + DM Sans
  
  # À ajouter
  phosphor_flutter: ^2.0.0    # Système d'icônes
  flutter_svg: ^2.0.0         # Illustrations SVG
  lottie: ^3.0.0              # Animations orbe + célébrations
```

### Composants Flutter custom à créer

| Composant | Fichier | Description |
|-----------|---------|-------------|
| `TalkieOrb` | `lib/widgets/talkie_orb.dart` | CustomPainter, 4 états animés |
| `ThemeCard` | `lib/widgets/theme_card.dart` | Card gradient + SVG + badge |
| `DisplayHeader` | `lib/widgets/display_header.dart` | Header éditorial avec greeting |
| `LevelBadge` | `lib/widgets/level_badge.dart` | Badge CEFR standardisé |
| `VocabCard` | `lib/widgets/vocab_card.dart` | Card vocabulaire unifiée |

### Conventions de code design

```dart
// Toujours utiliser les tokens AppTheme, jamais les valeurs brutes
// ✅ Correct
color: AppTheme.primary
border: Border.all(color: AppTheme.border)

// ❌ Interdit
color: Color(0xFF818CF8)
color: Colors.white
border: Border.all(color: Colors.grey)

// Opacité : toujours withValues(alpha:)
// ✅ Correct
color.withValues(alpha: 0.35)

// ❌ Interdit
color.withOpacity(0.35)
```

---

*Dernière mise à jour : 2026-05-17*
*Version : 1.0 — Document fondateur*
