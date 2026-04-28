#!/bin/bash
# watch.sh — Flutter hot reload automatique sur sauvegarde
# Usage: ./watch.sh

DEVICE_ID="59021FDCH000G5"

# ── Vérifications ──────────────────────────────────────────────────────────────

if ! command -v inotifywait &>/dev/null; then
  echo "inotify-tools manquant. Installe-le avec :"
  echo "  sudo apt-get install -y inotify-tools"
  exit 1
fi

if ! flutter devices 2>/dev/null | grep -q "$DEVICE_ID"; then
  echo "Appareil $DEVICE_ID non détecté."
  echo "Vérifie que le téléphone est branché et ADB autorisé."
  exit 1
fi

# ── Démarrage ─────────────────────────────────────────────────────────────────

FIFO=$(mktemp -u /tmp/flutter_ctrl_XXXXXX)
mkfifo "$FIFO"

cleanup() {
  exec 3>&- 2>/dev/null || true
  rm -f "$FIFO"
  kill "$FLUTTER_PID" 2>/dev/null || true
  echo ""
  echo "Arrêté."
}
trap cleanup EXIT INT TERM

# Ouvre le FIFO en écriture AVANT flutter run (sinon flutter run bloque)
exec 3>"$FIFO"

echo "Lancement de flutter run sur $DEVICE_ID..."
flutter run -d "$DEVICE_ID" < "$FIFO" &
FLUTTER_PID=$!

# Attend que l'app soit démarrée (flutter run prend ~10-30s)
echo "Attente du démarrage de l'app..."
sleep 20

echo ""
echo "Surveillance de lib/ active — hot reload automatique sur sauvegarde"
echo "(Ctrl+C pour arrêter)"
echo ""

# ── Boucle de surveillance ────────────────────────────────────────────────────

inotifywait -r -m -e close_write,moved_to,create \
  --format '%w%f' \
  --include '.*\.dart$' \
  lib/ 2>/dev/null | while read -r changed_file; do

  # Ignore les fichiers générés (.g.dart, .freezed.dart)
  if [[ "$changed_file" == *.g.dart || "$changed_file" == *.freezed.dart ]]; then
    continue
  fi

  echo "↻ $(basename "$changed_file") — hot reload..."
  sleep 0.3
  echo "r" >&3
done
