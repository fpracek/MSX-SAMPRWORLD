#!/bin/sh
# Avvia il server dei livelli (UDP 9100). Serve Python 3. Ctrl+C per fermarlo.
cd "$(dirname "$0")"
exec python3 levelserver.py
