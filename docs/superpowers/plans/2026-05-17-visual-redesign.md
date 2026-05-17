# Visual Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refonte visuelle complète — Phosphor Icons, illustrations SVG par thème, orbe vocale animée, headers éditoriaux, suppression totale des emojis UI.

**Architecture:** 4 phases séquentielles — (1) Foundation (packages, assets, tokens), (2) Shared widgets (TalkieOrb, ThemeCard, DisplayHeader), (3) Navigation + Apprendre + Discussion, (4) Quiz + Lexique. Chaque phase est compilable et testable indépendamment.

**Tech Stack:** Flutter/Dart, `phosphor_flutter ^2.1.0`, `flutter_svg ^2.0.3`, `lottie ^3.1.0`, `google_fonts` (déjà installé), Hive (déjà installé).

## Adaptations obligatoires (self-review)

Corrections identifiées avant implémentation — à respecter impérativement :

| Problème | Correction |
|----------|------------|
| `_newDiscussion` n'existe pas | Utiliser `_newDiscussion()` (méthode existante ligne 125) |
| `_startRecording`/`_stopRecording` n'existent pas | Utiliser `_toggleRecording()` (méthode existante ligne 316) |
| `_tts.isPlaying` n'existe pas | Utiliser `_tts.playingIndex.value != -1` (TtsService expose `playingIndex` ValueNotifier) |
| `findAncestorStateOfType<_MainShellState>` — `_MainShellState` est privé, inaccessible | Le CTA Discussion dans Apprendre navigue via `DefaultTabController` ou simplement par `Navigator.push` vers `ProfScreen` — OU passer un callback `onOpenDiscussion` depuis MainShell (préféré) |
| `_buildTranscript()` non défini dans Task 9 | Utiliser le widget de liste messages existant, le déplacer dans un `Expanded(flex: 4)` |

---

## Fichiers affectés

| Action | Fichier |
|--------|---------|
| Modify | `pubspec.yaml` |
| Modify | `lib/app/theme.dart` |
| Create | `assets/illustrations/theme_travel.svg` |
| Create | `assets/illustrations/theme_work.svg` |
| Create | `assets/illustrations/theme_daily.svg` |
| Create | `assets/illustrations/theme_sport.svg` |
| Create | `assets/illustrations/theme_culture.svg` |
| Create | `assets/illustrations/theme_tech.svg` |
| Create | `assets/illustrations/theme_health.svg` |
| Create | `assets/illustrations/theme_social.svg` |
| Create | `lib/widgets/talkie_orb.dart` |
| Create | `lib/widgets/theme_card.dart` |
| Create | `lib/widgets/display_header.dart` |
| Modify | `lib/features/shell/main_shell.dart` |
| Modify | `lib/features/explore/explore_screen.dart` |
| Modify | `lib/features/prof/prof_screen.dart` |
| Modify | `lib/features/quiz/quiz_setup_screen.dart` |
| Modify | `lib/features/notebook/lexique_screen.dart` |

---

## PHASE 1 — Foundation

### Task 1 : Packages + assets déclarés dans pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1 : Ajouter les dépendances**

Ouvrir `pubspec.yaml`. Dans la section `dependencies:`, après `google_fonts: ^6.2.1`, ajouter :

```yaml
  # Design
  phosphor_flutter: ^2.1.0
  flutter_svg: ^2.0.3
  lottie: ^3.1.0
```

- [ ] **Step 2 : Déclarer les assets SVG**

Dans la section `flutter: > assets:`, ajouter après les lignes existantes :

```yaml
    - assets/illustrations/
```

Le bloc `assets` complet doit ressembler à :

```yaml
  assets:
    - .env
    - assets/content/manifest.json
    - assets/content/lessons/travel_hotel.json
    - assets/content/lessons/work_interview.json
    - assets/content/lessons/daily_coffee.json
    - assets/content/lessons/sport_gym.json
    - assets/illustrations/
```

- [ ] **Step 3 : Installer les packages**

```bash
cd /home/fbai/Talkie && flutter pub get
```

Résultat attendu : `Got dependencies!` sans erreur.

- [ ] **Step 4 : Vérifier la compilation**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Résultat attendu : `Built build/app/outputs/...` sans erreur.

- [ ] **Step 5 : Commit**

```bash
git add pubspec.yaml pubspec.lock && git commit -m "chore: add phosphor_flutter, flutter_svg, lottie packages"
```

---

### Task 2 : Créer les 8 illustrations SVG

**Files:**
- Create: `assets/illustrations/theme_travel.svg`
- Create: `assets/illustrations/theme_work.svg`
- Create: `assets/illustrations/theme_daily.svg`
- Create: `assets/illustrations/theme_sport.svg`
- Create: `assets/illustrations/theme_culture.svg`
- Create: `assets/illustrations/theme_tech.svg`
- Create: `assets/illustrations/theme_health.svg`
- Create: `assets/illustrations/theme_social.svg`

- [ ] **Step 1 : Créer theme_travel.svg**

Créer `assets/illustrations/theme_travel.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <path d="M6 34 L18 8 L22 12 L38 6 L40 10 L26 18 L30 22 L22 30 Z" fill="#38BDF8" opacity="0.75"/>
  <line x1="8" y1="40" x2="42" y2="40" stroke="#38BDF8" stroke-width="2.5" stroke-linecap="round" opacity="0.3"/>
  <circle cx="36" cy="14" r="3" fill="#38BDF8" opacity="0.4"/>
</svg>
```

- [ ] **Step 2 : Créer theme_work.svg**

Créer `assets/illustrations/theme_work.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <rect x="8" y="18" width="32" height="22" rx="3" fill="#A78BFA" opacity="0.6"/>
  <rect x="16" y="12" width="16" height="8" rx="2" fill="#A78BFA" opacity="0.4"/>
  <line x1="8" y1="28" x2="40" y2="28" stroke="#0F172A" stroke-width="1.5" opacity="0.4"/>
  <rect x="20" y="26" width="8" height="4" rx="1" fill="#0F172A" opacity="0.25"/>
</svg>
```

- [ ] **Step 3 : Créer theme_daily.svg**

Créer `assets/illustrations/theme_daily.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <circle cx="24" cy="24" r="9" fill="#F59E0B" opacity="0.8"/>
  <line x1="24" y1="6" x2="24" y2="11" stroke="#F59E0B" stroke-width="2.5" stroke-linecap="round" opacity="0.5"/>
  <line x1="24" y1="37" x2="24" y2="42" stroke="#F59E0B" stroke-width="2.5" stroke-linecap="round" opacity="0.5"/>
  <line x1="6" y1="24" x2="11" y2="24" stroke="#F59E0B" stroke-width="2.5" stroke-linecap="round" opacity="0.5"/>
  <line x1="37" y1="24" x2="42" y2="24" stroke="#F59E0B" stroke-width="2.5" stroke-linecap="round" opacity="0.5"/>
  <line x1="11.5" y1="11.5" x2="15" y2="15" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" opacity="0.35"/>
  <line x1="33" y1="33" x2="36.5" y2="36.5" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" opacity="0.35"/>
  <line x1="36.5" y1="11.5" x2="33" y2="15" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" opacity="0.35"/>
  <line x1="15" y1="33" x2="11.5" y2="36.5" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" opacity="0.35"/>
</svg>
```

- [ ] **Step 4 : Créer theme_sport.svg**

Créer `assets/illustrations/theme_sport.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <path d="M20 6 L14 22 L22 20 L16 42 L34 18 L24 22 Z" fill="#22C55E" opacity="0.8"/>
  <circle cx="34" cy="12" r="5" fill="#22C55E" opacity="0.25"/>
</svg>
```

- [ ] **Step 5 : Créer theme_culture.svg**

Créer `assets/illustrations/theme_culture.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <circle cx="18" cy="26" r="12" fill="#F472B6" opacity="0.5"/>
  <circle cx="30" cy="26" r="12" fill="#F472B6" opacity="0.35"/>
  <path d="M28 8 L30 14 L36 14 L31 18 L33 24 L28 20 L23 24 L25 18 L20 14 L26 14 Z" fill="#F472B6" opacity="0.7"/>
</svg>
```

- [ ] **Step 6 : Créer theme_tech.svg**

Créer `assets/illustrations/theme_tech.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <circle cx="12" cy="12" r="4" fill="#2DD4BF" opacity="0.7"/>
  <circle cx="36" cy="12" r="4" fill="#2DD4BF" opacity="0.7"/>
  <circle cx="12" cy="36" r="4" fill="#2DD4BF" opacity="0.7"/>
  <circle cx="36" cy="36" r="4" fill="#2DD4BF" opacity="0.7"/>
  <circle cx="24" cy="24" r="5" fill="#2DD4BF" opacity="0.9"/>
  <line x1="16" y1="12" x2="32" y2="12" stroke="#2DD4BF" stroke-width="1.5" opacity="0.4"/>
  <line x1="12" y1="16" x2="12" y2="32" stroke="#2DD4BF" stroke-width="1.5" opacity="0.4"/>
  <line x1="36" y1="16" x2="36" y2="32" stroke="#2DD4BF" stroke-width="1.5" opacity="0.4"/>
  <line x1="16" y1="36" x2="32" y2="36" stroke="#2DD4BF" stroke-width="1.5" opacity="0.4"/>
  <line x1="16" y1="16" x2="20" y2="20" stroke="#2DD4BF" stroke-width="1.5" opacity="0.3"/>
  <line x1="32" y1="16" x2="28" y2="20" stroke="#2DD4BF" stroke-width="1.5" opacity="0.3"/>
  <line x1="16" y1="32" x2="20" y2="28" stroke="#2DD4BF" stroke-width="1.5" opacity="0.3"/>
  <line x1="32" y1="32" x2="28" y2="28" stroke="#2DD4BF" stroke-width="1.5" opacity="0.3"/>
</svg>
```

- [ ] **Step 7 : Créer theme_health.svg**

Créer `assets/illustrations/theme_health.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <path d="M24 38 C24 38 8 28 8 18 C8 13 12 10 16 10 C19 10 22 12 24 15 C26 12 29 10 32 10 C36 10 40 13 40 18 C40 28 24 38 24 38 Z" fill="#F87171" opacity="0.65"/>
  <polyline points="6,26 12,26 16,18 20,34 24,22 28,30 32,26 42,26" stroke="#F87171" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" opacity="0.4" fill="none"/>
</svg>
```

- [ ] **Step 8 : Créer theme_social.svg**

Créer `assets/illustrations/theme_social.svg` :

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <rect x="6" y="8" width="26" height="18" rx="5" fill="#FB923C" opacity="0.65"/>
  <path d="M10 26 L6 34 L16 28" fill="#FB923C" opacity="0.65"/>
  <rect x="16" y="22" width="26" height="18" rx="5" fill="#FB923C" opacity="0.4"/>
  <path d="M38 40 L42 46 L32 42" fill="#FB923C" opacity="0.4"/>
</svg>
```

- [ ] **Step 9 : Commit**

```bash
git add assets/illustrations/ && git commit -m "feat: add SVG illustrations for 8 theme categories"
```

---

### Task 3 : Ajouter le token surfaceTop dans AppTheme

**Files:**
- Modify: `lib/app/theme.dart`

- [ ] **Step 1 : Ajouter le token**

Dans `lib/app/theme.dart`, après la ligne `static const Color surfaceHigh = Color(0xFF273549);`, ajouter :

```dart
  static const Color surfaceTop  = Color(0xFF2F3F55); // couche 3 — éléments actifs
```

- [ ] **Step 2 : Vérifier la compilation**

```bash
flutter build apk --debug 2>&1 | tail -3
```

Résultat attendu : succès sans erreur.

- [ ] **Step 3 : Commit**

```bash
git add lib/app/theme.dart && git commit -m "feat: add surfaceTop color token to AppTheme"
```

---

## PHASE 2 — Shared Widgets

### Task 4 : Créer TalkieOrb (orbe vocale animée)

**Files:**
- Create: `lib/widgets/talkie_orb.dart`
- Test: `test/widgets/talkie_orb_test.dart`

- [ ] **Step 1 : Créer le fichier widget**

Créer `lib/widgets/talkie_orb.dart` :

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../app/theme.dart';

enum OrbState { idle, listening, speaking, thinking }

class TalkieOrb extends StatefulWidget {
  final OrbState state;
  final Color? color;
  final VoidCallback? onTap;
  final double size;

  const TalkieOrb({
    super.key,
    required this.state,
    this.color,
    this.onTap,
    this.size = 140,
  });

  @override
  State<TalkieOrb> createState() => _TalkieOrbState();
}

class _TalkieOrbState extends State<TalkieOrb> with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _pulseController,
          _rotationController,
        ]),
        builder: (context, _) {
          return SizedBox(
            width: widget.size + 40,
            height: widget.size + 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRing(widget.size + 36, color, _ring3Opacity()),
                _buildRing(widget.size + 18, color, _ring2Opacity()),
                _buildRing(widget.size + 4, color, _ring1Opacity()),
                _buildCore(color),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRing(double diameter, Color color, double opacity) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 1.0,
        ),
      ),
    );
  }

  Widget _buildCore(Color color) {
    final rotation = widget.state == OrbState.thinking
        ? _rotationController.value * 2 * pi
        : 0.0;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              color.withValues(alpha: 0.75),
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(child: _buildIcon(color)),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    switch (widget.state) {
      case OrbState.idle:
      case OrbState.listening:
        return Icon(
          PhosphorIcons.microphone(),
          color: Colors.white.withValues(alpha: 0.88),
          size: widget.size * 0.28,
        );
      case OrbState.speaking:
        return _buildWaveform(color);
      case OrbState.thinking:
        return Icon(
          PhosphorIcons.sparkle(),
          color: Colors.white.withValues(alpha: 0.88),
          size: widget.size * 0.28,
        );
    }
  }

  Widget _buildWaveform(Color color) {
    final bars = [0.4, 0.7, 1.0, 0.6, 0.85, 0.5, 0.75];
    final maxHeight = widget.size * 0.28;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: bars.asMap().entries.map((e) {
        final phase = (e.key / bars.length) * 2 * pi;
        final t = (sin(_pulseController.value * 2 * pi + phase) + 1) / 2;
        final height = maxHeight * (e.value * 0.4 + t * e.value * 0.6);
        return Container(
          width: widget.size * 0.035,
          height: height,
          margin: EdgeInsets.symmetric(horizontal: widget.size * 0.018),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }

  double _ring1Opacity() {
    switch (widget.state) {
      case OrbState.idle: return 0.18 + _idleController.value * 0.07;
      case OrbState.listening: return 0.28 + _pulseController.value * 0.18;
      case OrbState.speaking: return 0.22 + _pulseController.value * 0.14;
      case OrbState.thinking: return 0.16;
    }
  }

  double _ring2Opacity() {
    switch (widget.state) {
      case OrbState.idle: return 0.10 + _idleController.value * 0.04;
      case OrbState.listening: return 0.16 + _pulseController.value * 0.12;
      case OrbState.speaking: return 0.14 + _pulseController.value * 0.08;
      case OrbState.thinking: return 0.10;
    }
  }

  double _ring3Opacity() {
    switch (widget.state) {
      case OrbState.idle: return 0.05 + _idleController.value * 0.03;
      case OrbState.listening: return 0.08 + _pulseController.value * 0.07;
      case OrbState.speaking: return 0.07 + _pulseController.value * 0.05;
      case OrbState.thinking: return 0.06;
    }
  }
}
```

- [ ] **Step 2 : Créer le répertoire test/widgets**

```bash
mkdir -p /home/fbai/Talkie/test/widgets
```

- [ ] **Step 3 : Créer le test widget**

Créer `test/widgets/talkie_orb_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkie/widgets/talkie_orb.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('TalkieOrb renders in idle state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.idle)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb renders in listening state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.listening)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb renders in speaking state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.speaking)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb renders in thinking state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.thinking)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb calls onTap when tapped', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      wrap(TalkieOrb(state: OrbState.idle, onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(TalkieOrb));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 4 : Lancer les tests**

```bash
flutter test test/widgets/talkie_orb_test.dart
```

Résultat attendu : `All tests passed!`

- [ ] **Step 5 : Commit**

```bash
git add lib/widgets/talkie_orb.dart test/widgets/talkie_orb_test.dart && git commit -m "feat: add TalkieOrb widget with 4 animated states"
```

---

### Task 5 : Créer ThemeCard (card thème avec illustration SVG)

**Files:**
- Create: `lib/widgets/theme_card.dart`

- [ ] **Step 1 : Créer le widget**

Créer `lib/widgets/theme_card.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app/theme.dart';

class ThemeCard extends StatelessWidget {
  final String themeId;
  final String label;
  final Color color;
  final String? scoreBadge;
  final String? subLabel;
  final VoidCallback onTap;
  final double aspectRatio;

  const ThemeCard({
    super.key,
    required this.themeId,
    required this.label,
    required this.color,
    required this.onTap,
    this.scoreBadge,
    this.subLabel,
    this.aspectRatio = 1.15,
  });

  String get _svgPath => 'assets/illustrations/theme_$themeId.svg';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.40),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    _svgPath,
                    width: 36,
                    height: 36,
                  ),
                  if (scoreBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        scoreBadge!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel ?? 'Explorer',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2 : Compiler et vérifier**

```bash
flutter build apk --debug 2>&1 | grep -E "(error|Error|Built)"
```

Résultat attendu : `Built build/app/...` sans error.

- [ ] **Step 3 : Commit**

```bash
git add lib/widgets/theme_card.dart && git commit -m "feat: add ThemeCard widget with SVG illustration and gradient"
```

---

### Task 6 : Créer DisplayHeader (header éditorial)

**Files:**
- Create: `lib/widgets/display_header.dart`

- [ ] **Step 1 : Créer le widget**

Créer `lib/widgets/display_header.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme.dart';

class DisplayHeader extends StatelessWidget {
  final String greeting;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const DisplayHeader({
    super.key,
    required this.greeting,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 0.10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.onSurface,
                    letterSpacing: -1.4,
                    height: 0.95,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2 : Commit**

```bash
git add lib/widgets/display_header.dart && git commit -m "feat: add DisplayHeader widget (editorial bold style)"
```

---

## PHASE 3 — Navigation + Apprendre + Discussion

### Task 7 : NavigationBar — Phosphor Icons

**Files:**
- Modify: `lib/features/shell/main_shell.dart`

- [ ] **Step 1 : Ajouter l'import Phosphor**

Dans `lib/features/shell/main_shell.dart`, ajouter l'import :

```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';
```

- [ ] **Step 2 : Remplacer _tabs par Phosphor**

Remplacer la déclaration `static const _tabs = [...]` par :

```dart
  static final _tabs = [
    _TabItem(
      icon: PhosphorIcons.bookOpen(),
      activeIcon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
      label: 'Apprendre',
    ),
    _TabItem(
      icon: PhosphorIcons.brain(),
      activeIcon: PhosphorIcons.brain(PhosphorIconsStyle.fill),
      label: 'Quiz',
    ),
    _TabItem(
      icon: PhosphorIcons.microphone(),
      activeIcon: PhosphorIcons.microphone(PhosphorIconsStyle.fill),
      label: 'Discussion',
    ),
    _TabItem(
      icon: PhosphorIcons.notePencil(),
      activeIcon: PhosphorIcons.notePencil(PhosphorIconsStyle.fill),
      label: 'Lexique',
    ),
  ];
```

- [ ] **Step 3 : Supprimer `const` de _TabItem**

Puisque `_tabs` n'est plus `const` (PhosphorIcons retourne des IconData non-const), changer la classe `_TabItem` :

```dart
class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _TabItem({required this.icon, required this.activeIcon, required this.label});
}
```

- [ ] **Step 4 : Compiler**

```bash
flutter build apk --debug 2>&1 | grep -E "(error|Error|Built)"
```

Résultat attendu : succès.

- [ ] **Step 5 : Tester sur device**

```bash
flutter run -d 59021FDCH000G5
```

Vérifier visuellement que la navigation bar affiche des icônes Phosphor propres. Taper sur chaque tab et vérifier le changement d'icône fill/outline.

- [ ] **Step 6 : Commit**

```bash
git add lib/features/shell/main_shell.dart && git commit -m "feat: replace Material Icons with Phosphor in NavigationBar"
```

---

### Task 8 : Redesign ExploreScreen (Apprendre)

**Files:**
- Modify: `lib/features/explore/explore_screen.dart`

L'objectif : header éditorial `DisplayHeader`, CTA Discussion card hero, grille de `ThemeCard` avec SVG illustrations, suppression totale des emojis.

- [ ] **Step 1 : Ajouter les imports**

En haut de `lib/features/explore/explore_screen.dart`, ajouter :

```dart
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/display_header.dart';
import '../../widgets/theme_card.dart';
```

- [ ] **Step 2 : Remplacer la méthode build() de _ExploreScreenState**

Remplacer le `Widget build(BuildContext context)` complet par :

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // ── Header éditorial ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: DisplayHeader(
                      greeting: 'Bonjour',
                      title: 'Speak\nEnglish.',
                      subtitle: 'Niveau ${_profile.level.code} · Continue ta progression',
                      actions: [
                        const SizedBox(width: 12),
                        _buildLevelButton(),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── CTA Discussion ────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildDiscussionCta()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Section thèmes ────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildSectionLabel('Thèmes')),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  _buildThemeGrid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Générer une leçon ─────────────────────────────────────
                  SliverToBoxAdapter(child: _buildGenerateSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }
```

- [ ] **Step 3 : Ajouter _buildDiscussionCta()**

Ajouter cette méthode dans `_ExploreScreenState` :

```dart
  Widget _buildDiscussionCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        // Pour naviguer vers Discussion : passer onOpenDiscussion depuis MainShell
        // Dans main_shell.dart, passer callback : ExploreScreen(onOpenDiscussion: () => _selectTab(2))
        // Dans ExploreScreen, ajouter : final VoidCallback? onOpenDiscussion;
        onTap: widget.onOpenDiscussion ?? () {},
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Mini orbe
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.70),
                      AppTheme.primary.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.22),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                  color: Colors.white.withValues(alpha: 0.88),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCUSSION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        letterSpacing: 0.10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Parler avec ton prof',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE0E7FF),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Démarre maintenant →',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 4 : Ajouter _buildSectionLabel()**

```dart
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.muted,
          letterSpacing: 0.12,
        ),
      ),
    );
  }
```

- [ ] **Step 5 : Remplacer _buildThemeGrid() par version ThemeCard**

```dart
  Widget _buildThemeGrid() {
    final domains = _contentService.domains;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final domain = domains[i];
            final isSelected = _selectedDomain == domain.id;
            return ThemeCard(
              themeId: domain.id,
              label: domain.label,
              color: _domainColor(domain.id),
              scoreBadge: isSelected ? null : null,
              subLabel: isSelected ? 'Sélectionné' : 'Explorer',
              onTap: () => setState(() {
                _selectedDomain = isSelected ? null : domain.id;
              }),
            );
          },
          childCount: domains.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
      ),
    );
  }
```

- [ ] **Step 6 : Mettre à jour _buildGenerateSection() (supprimer emojis)**

Trouver la méthode existante `_buildGenerateSection()` ou `_buildGenerateCard()` et s'assurer qu'il n'y a aucun emoji. Remplacer tout emoji par un `Icon` Phosphor. Exemple pour l'icône microphone de génération :

```dart
// Avant (si présent) :
Text('🎤', style: TextStyle(fontSize: 24))

// Après :
Icon(PhosphorIcons.microphone(), color: AppTheme.primary, size: 24)
```

- [ ] **Step 7 : Tester sur device**

```bash
flutter run -d 59021FDCH000G5
```

Vérifier : header "Speak English.", CTA Discussion avec mini-orbe, grilles de ThemeCard avec illustrations SVG, aucun emoji visible.

- [ ] **Step 8 : Commit**

```bash
git add lib/features/explore/explore_screen.dart && git commit -m "feat: redesign Apprendre — editorial header, Discussion CTA, ThemeCard SVG"
```

---

### Task 9 : Redesign ProfScreen — Intégration TalkieOrb

**Files:**
- Modify: `lib/features/prof/prof_screen.dart`

L'objectif : remplacer la zone d'affichage par l'orbe vocale animée comme élément hero, déplacer le transcript en zone secondaire, contrôles épurés.

- [ ] **Step 1 : Ajouter les imports**

Dans `lib/features/prof/prof_screen.dart`, ajouter :

```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/talkie_orb.dart';
```

- [ ] **Step 2 : Ajouter _orbState getter**

Dans `_ProfScreenState`, ajouter cette méthode (après les champs d'état existants) :

```dart
  OrbState get _orbState {
    if (_isRecording) return OrbState.listening;
    if (_isTranscribing || _isProcessing) return OrbState.thinking;
    if (_tts.playingIndex.value != -1) return OrbState.speaking;
    return OrbState.idle;
  }
```

Note : `_tts.isPlaying` — vérifier que `TtsService` expose ce getter. Si non, ajouter dans `lib/services/tts_service.dart` :

```dart
bool get isPlaying => _ttsState == TtsState.playing;
```

- [ ] **Step 3 : Remplacer le build() de ProfScreen**

Remplacer `Widget build(BuildContext context)` dans `_ProfScreenState` par :

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              'Discussion',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            if (_messages.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _currentTopicLabel ?? 'Libre',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(PhosphorIcons.arrowCounterClockwise(),
                  color: AppTheme.muted, size: 20),
              tooltip: 'Nouvelle discussion',
              onPressed: _newDiscussion,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Zone orbe (hero) ────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: _buildOrbZone(),
          ),
          // ── Transcript ─────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: _buildTranscript(),
          ),
          // ── Contrôles ──────────────────────────────────────────────────
          _buildControls(),
        ],
      ),
    );
  }
```

- [ ] **Step 4 : Ajouter _buildOrbZone()**

```dart
  Widget _buildOrbZone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_messages.isEmpty) ...[
          // Topic chips si pas encore démarré
          _buildTopicChips(),
          const SizedBox(height: 20),
        ],
        TalkieOrb(
          state: _orbState,
          size: 130,
          onTap: _toggleRecording,
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _orbLabel,
            key: ValueKey(_orbLabel),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: 0.08,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _orbSubLabel,
          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      ],
    );
  }

  String get _orbLabel {
    if (_isRecording) return 'EN ÉCOUTE';
    if (_isTranscribing) return 'ANALYSE...';
    if (_isProcessing) return 'RÉFLEXION...';
    if (_tts.isPlaying) return 'PROF PARLE';
    return 'EN ATTENTE';
  }

  String get _orbSubLabel {
    if (_isRecording) return 'Relâche pour envoyer';
    if (_isProcessing || _isTranscribing) return '';
    if (_tts.isPlaying) return 'Écoute ton professeur';
    return 'Appuie sur l\'orbe pour parler';
  }

  String? get _currentTopicLabel {
    if (_messages.isEmpty) return null;
    // Extraire le topic du premier message système si disponible
    return null;
  }
```

- [ ] **Step 5 : Remplacer _buildControls() existant**

Remplacer la méthode de contrôles actuelle par :

```dart
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Bouton Nouveau
          _ControlBtn(
            icon: PhosphorIcons.plus(),
            label: 'Nouveau',
            onTap: _newDiscussion,
          ),
          // Bouton Mic (principal)
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [const Color(0xFF7C3AED), const Color(0xFFA855F7)]
                      : [const Color(0xFF4338CA), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: _isRecording ? 0.45 : 0.25),
                    blurRadius: _isRecording ? 20 : 12,
                    spreadRadius: _isRecording ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording
                    ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                    : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          // Bouton Fin
          _ControlBtn(
            icon: PhosphorIcons.x(),
            label: 'Terminer',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 6 : Ajouter _ControlBtn widget local**

À la fin du fichier (hors de la classe), ajouter :

```dart
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.muted, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7 : Supprimer tous les emojis restants dans prof_screen.dart**

Chercher et remplacer :

```bash
grep -n "Text('" lib/features/prof/prof_screen.dart | grep -E "emoji|[^\x00-\x7F]"
```

Remplacer tout emoji trouvé dans les `Text()` UI par l'équivalent Phosphor ou supprimer.

- [ ] **Step 8 : Tester sur device**

```bash
flutter run -d 59021FDCH000G5
```

Vérifier : l'orbe est centré et anime selon l'état, les contrôles sont épurés, le transcript est en zone secondaire.

- [ ] **Step 9 : Commit**

```bash
git add lib/features/prof/prof_screen.dart && git commit -m "feat: integrate TalkieOrb as hero in Discussion screen"
```

---

## PHASE 4 — Quiz + Lexique

### Task 10 : Redesign QuizSetupScreen

**Files:**
- Modify: `lib/features/quiz/quiz_setup_screen.dart`

- [ ] **Step 1 : Ajouter imports**

```dart
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/display_header.dart';
import '../../widgets/theme_card.dart';
```

- [ ] **Step 2 : Remplacer _buildThemeGrid() par ThemeCard**

Remplacer la méthode `_buildThemeGrid()` par :

```dart
  Widget _buildThemeGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final theme = QuizTheme.suggested[i];
            final best = _bestResults[theme.id];
            return ThemeCard(
              themeId: theme.id,
              label: theme.label,
              color: _themeColor(theme.id),
              scoreBadge: best != null ? 'T${best.bestTier}' : null,
              subLabel: best != null ? '${best.lastScore}/10' : 'Nouveau',
              onTap: () => _startQuiz(theme),
            );
          },
          childCount: QuizTheme.suggested.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
      ),
    );
  }
```

- [ ] **Step 3 : Remplacer AppBar par DisplayHeader**

Remplacer l'`appBar:` du Scaffold par `null` et ajouter `DisplayHeader` en tête du `CustomScrollView` :

```dart
// Dans build(), le Scaffold devient :
body: _loading
    ? const Center(child: CircularProgressIndicator())
    : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: DisplayHeader(
                greeting: 'Entraîne-toi',
                title: 'Quiz.',
                subtitle: 'Teste ton vocabulaire sur le thème de ton choix',
                actions: [
                  const SizedBox(width: 12),
                  _buildLevelChip(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          _buildCustomSection(),
          _buildSuggestedTitle(),
          _buildThemeGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
```

- [ ] **Step 4 : Supprimer les emojis dans les chips récents**

Dans `_buildCustomSection()`, les chips de thèmes récents utilisent `theme.emoji`. Remplacer par un icon Phosphor générique :

```dart
// Avant :
Text(theme.emoji, style: const TextStyle(fontSize: 13)),

// Après :
Icon(PhosphorIcons.target(), size: 13, color: AppTheme.muted),
```

- [ ] **Step 5 : Tester sur device**

```bash
flutter run -d 59021FDCH000G5
```

Vérifier : header éditorial "Quiz.", ThemeCard avec SVG et scores, aucun emoji UI.

- [ ] **Step 6 : Commit**

```bash
git add lib/features/quiz/quiz_setup_screen.dart && git commit -m "feat: redesign Quiz — DisplayHeader + ThemeCard SVG"
```

---

### Task 11 : Cleanup LexiqueScreen — Phosphor Icons

**Files:**
- Modify: `lib/features/notebook/lexique_screen.dart`

- [ ] **Step 1 : Ajouter import Phosphor**

```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';
```

- [ ] **Step 2 : Remplacer les Material Icons dans l'AppBar**

Trouver dans la méthode `build()` :

```dart
// Remplacer Icons.search par :
Icon(PhosphorIcons.magnifyingGlass())

// Remplacer Icons.style_rounded (flashcards) par :
Icon(PhosphorIcons.cards())

// Remplacer Icons.delete_outline par :
Icon(PhosphorIcons.trash())

// Remplacer Icons.folder_outlined par :
Icon(PhosphorIcons.folder())
```

- [ ] **Step 3 : Remplacer les icônes bookmark**

Dans `_WordTile` ou équivalent, remplacer :

```dart
// Avant :
Icons.bookmark_rounded / Icons.bookmark_border_rounded

// Après :
PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)  // sauvegardé
PhosphorIcons.bookmarkSimple()                          // non sauvegardé
```

- [ ] **Step 4 : Ajouter couleurs thème aux headers de groupe**

Dans le widget de groupe (si présent), ajouter un point de couleur thème :

```dart
// Dans le header de groupe (leçon ou dossier), ajouter :
Container(
  width: 8,
  height: 8,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: _groupColor, // couleur basée sur le thème de la leçon
  ),
),
```

Pour `_groupColor`, utiliser la même méthode `_domainColor()` que dans ExploreScreen, en extrayant le domaine du `lessonId`.

- [ ] **Step 5 : Tester sur device**

```bash
flutter run -d 59021FDCH000G5
```

Vérifier : icônes Phosphor dans toute la navigation, points de couleur dans les headers de groupe, aucun emoji UI.

- [ ] **Step 6 : flutter analyze**

```bash
flutter analyze lib/
```

Résultat attendu : `No issues found!`

- [ ] **Step 7 : Commit final**

```bash
git add lib/features/notebook/lexique_screen.dart && git commit -m "feat: Lexique — Phosphor Icons + color-coded group headers"
```

---

## Vérification finale

- [ ] **Scan emoji UI**

```bash
grep -rn "Text('" lib/features/ lib/widgets/ | grep -v "//\|test\|\.dart:[0-9]*:.*'[^']*[^\x00-\x7F][^']*'" | head -20
```

Aucun emoji ne doit apparaître dans les chaînes Text() des widgets UI (uniquement dans le contenu généré par Gemini).

- [ ] **flutter analyze**

```bash
flutter analyze lib/
```

Résultat attendu : `No issues found!`

- [ ] **Tests complets**

```bash
flutter test
```

- [ ] **Build release**

```bash
flutter build apk --obfuscate --split-debug-info=build/symbols 2>&1 | tail -5
```

- [ ] **Test device final**

```bash
flutter run -d 59021FDCH000G5
```

Parcourir les 4 tabs et vérifier chaque point du design system.

- [ ] **Commit de clôture**

```bash
git push origin main
```
