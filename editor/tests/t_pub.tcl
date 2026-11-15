# pubblicazione: richiede server UDP su 127.0.0.1:9100 e il driver UNAPI in slot A
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory $a] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
set log [open "$R/pub_result.txt" w]
proc st {l} { global log; puts $log "$l: valid=[rd 0xC896] msgnf=[rd 0xC895] msgnum=[expr {[rd 0xC893]+256*[rd 0xC894]}]"; flush $log }
after time 20 { tap 5 0x04 }                          ;# U senza validazione -> rifiutato
after time 21.5 { st no_valid; screenshot "$R/pub1.png" }
after time 22 { tap 8 0x80 }                          ;# destra
after time 22.6 { tap 8 0x01 }                        ;# spazio: piazza (modifica)
after time 23.4 { tap 5 0x08 }                        ;# V: valida (DEV) + salva
after time 25.5 { st validated; screenshot "$R/pub2.png" }
after time 26 { tap 5 0x04 }                          ;# U: pubblica
after time 33 { st published; screenshot "$R/pub3.png" }
after time 35 { tap 5 0x04 }                          ;# subito dopo la pubblicazione non si ripubblica
after time 36.5 { st after_edit_publish; screenshot "$R/pub4.png"; close $log; exit }
