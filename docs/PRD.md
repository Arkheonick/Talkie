# PRD — Talkie

## Objectif
Application Android pour améliorer son niveau d'anglais via un dialogue interactif et fluide avec un professeur IA. L'utilisateur parle, le professeur corrige, explique, traduit et guide — comme un vrai cours particulier dans sa poche.

## Utilisateur
Moi (Pixel 10 Pro), et tout Android compatible. Usage solo, autonome.

---

## Fonctions v1

1. **Choix de thématique** — l'utilisateur choisit un sujet (ex : voyage, business, vie quotidienne) et le professeur structure un plan de travail autour de ce thème
2. **Dialogue vocal** — micro pour parler, retour du professeur en audio (STT + TTS)
3. **Mode professeur interactif** — le professeur parle, corrige, traduit à la demande, pose des questions, fait répéter
4. **Affichage progressif** — résumé visuel en temps réel : vocabulaire appris, phrases clés, traductions — organisé par thème
5. **Export PDF** — génération d'un document structuré, clair et esthétique (titre, sections vocab, phrases + traductions), téléchargeable depuis l'app

---

## Hors scope v1
Non défini — à qualifier au fil du développement.

---

## Stack cible

| Couche | Choix | Raison |
|---|---|---|
| App mobile | **Flutter** | Performance native Android, UI moderne, cross-platform |
| IA / LLM | **Gemini API** (Flash) | Gratuit (free tier généreux), multimodal, rapide |
| Voix → texte | **Android STT natif** | Gratuit, intégré, rapide |
| Texte → voix | **Flutter TTS / Google TTS** | Gratuit, naturel |
| PDF | **package `pdf` (Dart)** | Génération client-side, gratuit, personnalisable |

---

## Critères de succès
- Dialogue vocal fluide sans latence perceptible
- Coût mensuel : 0€ ou < 5€
- PDF généré propre, lisible, esthétique

---

## Contraintes
- Sécurisé : clé API non exposée dans le code
- Projet durable — architecture maintenable et évolutive
- Interface moderne, user-friendly, light theme par défaut

---

## Statut
PRD v1 — à valider avant architecture
