carta E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor
proc rd {a} { return [debug read memory $a] }
set log [open "$R/result2.txt" w]
proc st {l} { global log; puts $log "$l: map=[rd 0xC500] [rd 0xC501] [rd 0xC502] [rd 0xC503] [rd 0xC504] lvalid=[rd 0xC840] lseg=[rd 0xC841] seq=[rd 0xC849] fseg=[rd 0xC844] fpos=[format %02X [rd 0xC846]][format %02X [rd 0xC845]]"; flush $log }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
after time 16 { st loaded; screenshot "$R/s_loaded.png" }
# secondo salvataggio senza modifiche + modifica + salva: seq deve crescere
after time 17 { tap 8 0x80 }
after time 17.6 { tap 8 0x01 }
after time 18.4 { tap 5 0x01 }
after time 20.5 { st saved2 }
# SELECT: nuovo livello cancella la bozza
after time 21 { tap 7 0x40 }
after time 24 { st erased; screenshot "$R/s_erased.png" }
after time 25 { close $log; exit }
