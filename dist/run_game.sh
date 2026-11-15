#!/bin/sh
# Lancia SamPr World in openMSX (Linux / macOS / WSL). Uso: ./run_game.sh [macchina]   (predefinita: Panasonic_FS-A1ST)
# Opzionale: avvia anche il server dei livelli in background se python3 e' disponibile (SERVER=1 ./run_game.sh)
cd "$(dirname "$0")"
MACHINE="${1:-Panasonic_FS-A1ST}"
if [ "$SERVER" = "1" ] && [ -f levelserver.py ]; then
  python3 levelserver.py &
  SRV=$!
  trap 'kill $SRV 2>/dev/null' EXIT
fi
openmsx -machine "$MACHINE" -ext unapinet -script "$(pwd)/sampr.tcl"
