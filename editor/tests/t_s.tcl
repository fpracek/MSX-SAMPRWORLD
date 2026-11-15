# tasto S: salva la bozza e (FASE=b) rilegge dopo il riavvio; FASE=c: stessa cosa dopo aver sporcato la flash
set fase $::env(FASE)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.2 [list keymatrixup $row $mask] }
set log [open "$R/s_$fase.txt" w]
if {$fase eq "b"} {
    after time 18 { puts $::log "dopo il riavvio: cella(1,10)=[rd 0xC501] cella(2,10)=[rd 0xC502]"; close $::log; exit }
} else {
    after time 18 { tap 8 0x80 }
    after time 18.6 { tap 8 0x01 }          ;# destra + spazio: tile sulla cella (1,10)
    after time 19.4 { tap 8 0x80 }
    after time 20 { tap 8 0x01 }            ;# cella (2,10)
    after time 21 { tap 5 0x01 }            ;# S
    after time 24 { puts $::log "dopo S: unsaved=[rd 0xCCB6] lvalid=[rd 0xC880]"; screenshot "$R/s_$fase.png"; close $::log; exit }
}
