# uso: variabile d'ambiente FASE = a | b | c  (a: modifica+valida, b: riavvio+pubblica, c: riavvio dopo la pubblicazione)
set fase $::env(FASE)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory $a] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
proc out {l} { global R fase; set f [open "$R/persist_$fase.txt" w]; puts $f "$l: valid=[rd 0xC896] lvalid=[rd 0xC880] map10=[rd 0xC500] [rd 0xC501] [rd 0xC502]"; close $f }
if {$fase eq "a"} {
    after time 20 { tap 8 0x80 }
    after time 20.6 { tap 8 0x01 }
    after time 21.4 { tap 5 0x08 }
    after time 24 { out dopo_validazione; exit }
} elseif {$fase eq "b"} {
    after time 20 { out riavvio_dopo_giorni }
    after time 21 { tap 5 0x04 }
    after time 29 { out dopo_pubblica; exit }
} else {
    after time 20 { out riavvio_dopo_pubblica; exit }
}
