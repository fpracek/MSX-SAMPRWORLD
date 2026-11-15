# apre il selettore di tile (TAB) e salva uno screenshot; poi sceglie l'ultimo tile e lo piazza
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
after time 18 { tap 7 0x08 }
after time 20 { screenshot "$R/picker_$::env(TAG).png"; exit }
