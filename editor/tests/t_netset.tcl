# impostazioni di rete: modifica dei campi, salvataggio in flash, rilettura dopo il riavvio (FASE=a|b)
set fase $::env(FASE)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc str {a n} { set s ""; for {set i 0} {$i<$n} {incr i} { set c [rd [expr {$a+$i}]]; if {$c == 0} break; append s [format %c $c] }; return $s }
proc rel {row mask sh} { keymatrixup $row $mask; if {$sh} { keymatrixup 6 0x01 } }
proc tap {row mask {sh 0}} {
    if {$sh} { keymatrixdown 6 0x01 }
    keymatrixdown $row $mask
    after time 0.2 [list rel $row $mask $sh]
}
set log [open "$R/netset_$fase.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc dump {tag} { L "$tag: host='[str 0xCC00 28]' porta='[str 0xCC1D 5]' utente='[str 0xCC23 12]' chiave='[str 0xCC30 16]' rete='[str 0xCC41 7]' ip='[str 0xCC49 15]'" }
set t 18.0
proc at {dt body} { global t; set t [expr {$t+$dt}]; after time $t $body }
proc key {row mask {sh 0}} { at 0.6 [list tap $row $mask $sh] }
at 0 { tap 4 0x08 }                          ;# N
at 12 { dump aperte; screenshot "$R/ns_1.png" }
if {$fase eq "a"} {
    for {set i 0} {$i < 9} {incr i} { key 7 0x20 }            ;# BS x9: cancella "localhost"
    key 0 0x02; key 0 0x04; key 0 0x80; key 2 0x08; key 0 0x01; key 2 0x08; key 0 0x01; key 2 0x08; key 0 0x02   ;# 127.0.0.1
    at 1 { dump server }
    key 8 0x40; key 8 0x40                                     ;# GIU x2: utente
    for {set i 0} {$i < 8} {incr i} { key 7 0x20 }            ;# BS x8: "testuser"
    key 2 0x40 1; key 2 0x80; key 0 0x02                       ;# Ab1 (maiuscola con SHIFT)
    key 8 0x40; key 8 0x40                                     ;# GIU x2: Rete
    key 8 0x01                                                 ;# SPAZIO: STATICO
    key 8 0x40                                                 ;# GIU: IP
    key 0 0x02; key 0 0x01; key 2 0x08; key 0 0x01; key 2 0x08; key 0 0x01; key 2 0x08; key 0 0x20   ;# 10.0.0.5
    at 1 { dump modificate; screenshot "$R/ns_2.png" }
    key 7 0x80                                                 ;# INVIO: salva
    at 6 { L "SETREC dopo il salvataggio: host='[str 0xE21A 28]' user='[str 0xE236 12]' flags=[rd 0xE203] seq=[rd 0xE202] ip=[rd 0xE204].[rd 0xE205].[rd 0xE206].[rd 0xE207]" }
}
if {$fase eq "b"} {
    key 7 0x04                                   ;# ESC: torna all'editor
    key 3 0x02                                   ;# D: elenco livelli con le impostazioni nuove (host 127.0.0.1, IP statico)
    at 12 { screenshot "$R/ns_3.png"; L "elenco: server raggiunto? vedi ns_3.png" }
}
at 3 { close $log; exit }
