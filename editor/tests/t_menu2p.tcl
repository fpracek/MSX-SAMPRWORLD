cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc tap {row mask} { keymatrixdown $row $mask; after time 0.12 [list keymatrixup $row $mask] }
after time 20 { screenshot "$R/m2p_0.png" }
foreach {t} {21 22 23 24} { after time $t { tap 8 0x40 } }
after time 25 { screenshot "$R/m2p_1.png"; tap 7 0x80 }
after time 26.5 { screenshot "$R/m2p_2.png"; puts [open "$R/m2p.txt" w] "p_two=[debug read memory 0xC760]"; exit }
