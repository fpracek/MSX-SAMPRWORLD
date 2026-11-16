# V9938: la campagna avvisa che serve il V9958 (usa editor.rom)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
after time 24 { tap 7 0x80 }
after time 30 { screenshot "$R/nov_a.png" ; tap 7 0x04 }
after time 36 { screenshot "$R/nov_b.png"; exit }
