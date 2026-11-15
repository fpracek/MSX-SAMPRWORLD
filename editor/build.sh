#!/bin/sh
# editor.rom = gioco (con menu iniziale); editor_test.rom = build per i test automatici (senza menu all'avvio)
set -e
cd "$(dirname "$0")"
sjasmplus editor.asm
sjasmplus -DTESTBUILD editor.asm
