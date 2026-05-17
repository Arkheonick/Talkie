# Talkie — Références Visuelles

Ces images définissent l'ambition design de l'app.
À lire avant tout travail de redesign.

---

## ref_editorial_bold.jpg — "iPhone App Design Ideas"

**Ce qu'on emprunte :**

- **Grosse typographie display comme élément de design** — Le titre "The Android
  Design Trends" en 3 lignes qui occupe presque la moitié de l'écran. C'est le
  modèle pour les headers éditoriaux de Talkie (écran Apprendre, Onboarding).

- **Blocs de couleur géométriques en fond** — Les backgrounds ne sont pas des
  dégradés génériques mais des blocs de couleur francs et courageux. À appliquer
  sur les cards thèmes et les sections hero.

- **Cards de tailles et densités variées** — Pas de grille uniforme. Les cards
  ont des proportions différentes, créant un rythme visuel. L'écran en bas à
  gauche mélange une grande card colorée avec du texte dense.

- **Contraste fort entre zones sombres et éléments colorés** — Fond noir/très
  sombre, éléments en couleur vive. Pas de gris neutre partout.

- **Énergie et dynamisme** — L'app donne envie d'agir. Pour Talkie : l'envie
  de parler anglais maintenant.

**Ce qu'on n'emprunte PAS :**
- La densité maximale de certains écrans (trop de niveaux simultanés)
- Le mélange de 3+ couleurs vives sur un même composant

---

## ref_premium_serene.jpg — "Modern Mobile App Smart"

**Ce qu'on emprunte :**

- **L'orbe/sphère vocale** — L'écran "Voice assistant" est le modèle direct
  de l'écran Discussion de Talkie. La sphère géométrique avec waveform, le
  glow vert, l'espace blanc autour. C'est le composant `TalkieOrb`.

- **Fond sombre profond non-noir** — Pas `#000000` mais un vert-forêt très
  sombre (`#071812` dans la référence). Pour Talkie : le slate-900 `#0F172A`
  remplit ce rôle. La profondeur est importante.

- **Qualité d'illustration** — Les photos de rooms sont de qualité réelle.
  Pour Talkie : les SVG illustrations doivent avoir ce niveau de soin, pas
  des formes géométriques basiques.

- **Sérénité et espace** — Le layout respire. Les éléments ont de l'espace
  autour. Pas de sur-remplissage de l'écran.

- **Accent unique et cohérent** — Un seul accent couleur (émeraude/teal)
  utilisé avec discipline. Pour Talkie : l'accent `primary` indigo est
  l'unique couleur interactive, les couleurs thèmes s'ajoutent mais ne
  remplacent pas l'accent principal.

- **Navigation bottom bar épurée** — 4 items, icons + labels, fond sombre.
  Pas de pill indicator criard. Changement de couleur discret.

**Ce qu'on n'emprunte PAS :**
- La monochromie verte totale (trop restrictive pour 8 thèmes colorés)
- Le style "smart home" qui ne colle pas à une app d'apprentissage

---

## Synthèse — L'esthétique Talkie

L'app combine les deux références :

```
ARCHITECTURE + SÉRÉNITÉ    ←   ref_premium_serene
    +
ÉNERGIE + TYPOGRAPHIE      ←   ref_editorial_bold
    =
TALKIE : Entraîneur vocal premium, énergique et clair
```

**Mots-clés design :**
- Editorial, bold, premium
- Profond mais pas austère
- Coloré mais pas criard
- Énergique mais pas fatigant
- Signature vocale forte (l'orbe)
