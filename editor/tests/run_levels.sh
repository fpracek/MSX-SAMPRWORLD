#!/bin/sh
# collauda i livelli della campagna con il bot (uno dopo l'altro): sh run_levels.sh 02 03 ...
cd "$(dirname "$0")/../.."
for n in "$@"; do
  LEVEL=$n timeout 400 /e/Dropbox/FAUSTO/SVILUPPI/MSX/EMULATORI/openMSX/openmsx.exe -machine ${MACHINE:-Panasonic_FS-A1ST} -script editor/tests/t_level.tcl >/dev/null 2>&1
  echo "livello $n: $(tail -1 editor/tests/level_$n.txt)" >> editor/tests/levels_summary.txt
done
echo FINE >> editor/tests/levels_summary.txt
