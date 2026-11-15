#!/bin/sh
# lancia un test openMSX azzerando prima la flash persistente (altrimenti la ROM ricompilata non conta): sh rt.sh MACCHINA script.tcl
rm -rf "$USERPROFILE/Documents/openMSX/persistent/roms/editor_test.rom" "$USERPROFILE/Documents/openMSX/persistent/roms/editor.rom"
cd "$(dirname "$0")/../.."
timeout ${TMO:-150} /e/Dropbox/FAUSTO/SVILUPPI/MSX/EMULATORI/openMSX/openmsx.exe -machine "$1" -script "$2" >/dev/null 2>&1
