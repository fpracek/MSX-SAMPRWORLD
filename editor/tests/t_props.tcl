# proprieta' dei nemici: finestra (INVIO), tabella EPT, salvataggio/caricamento e comportamento "dormiglione"
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.12 [list keymatrixup $row $mask] }
set f [open "$R/props.txt" w]
proc L {s} { global f; puts $f $s; flush $f }
proc ept {} { set s ""; for {set i 0} {$i < 8} {incr i} { append s [rd [expr {0xC600+$i}]] " " }; return "n=[rd 0xC680] rec0=$s" }
after time 18 {
    for {set x 0} {$x < 40} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35; cell 10 9 51      ;# partenza + goblin (T_GOBLIN)
    wr 0xC800 10; wr 0xC801 9      ;# cursore sul goblin
    wr 0xC814 1; wr 0xC815 1
}
after time 19.5 { tap 7 0x80 }                           ;# INVIO: finestra
after time 20.5 { screenshot "$R/props_dialog.png"; tap 8 0x80 }       ;# AI -> 1 (sleeper)
after time 21 { tap 8 0x40 }                             ;# giu': velocita'
after time 21.4 { tap 8 0x80 }
after time 21.8 { tap 8 0x80 }                           ;# velocita' 3
after time 22.2 { tap 8 0x40 }
after time 22.6 { tap 8 0x80 }
after time 23 { tap 8 0x80 }
after time 23.4 { tap 8 0x80 }                           ;# raggio 3
after time 23.8 { tap 8 0x40 }
after time 24.2 { tap 8 0x80 }                           ;# vita 2
after time 24.6 { tap 8 0x40 }
after time 25 { for {set i 0} {$i < 2} {incr i} { tap 8 0x80 } }   ;# rilevamento 8
after time 26 { screenshot "$R/props_dialog2.png"; L "dopo l'editing: [ept] (atteso n=1 rec0=10 9 1 3 3 2 8 0)"; tap 7 0x04 }  ;# ESC
after time 27 { tap 5 0x01 }                             ;# S: salva
after time 31 { wr 0xC680 0; L "azzerata: [ept]"; tap 4 0x02 }   ;# L: ricarica
after time 35 { L "ricaricata: [ept]"; keymatrixdown 5 0x02; after time 0.2 { keymatrixup 5 0x02 } }    ;# T: prova
after time 38 { L "gioco: goblin x=[rd16 0xCA01] (lontano: dormiglione fermo) enp=[rd 0xC690] [rd 0xC691] [rd 0xC692] [rd 0xC693] [rd 0xC694]" }
after time 40 { L "gioco, 2 s dopo: goblin x=[rd16 0xCA01] eroe x=[rd16 0xC8A0]"; wr 0xC8A0 150 }
after time 42 { L "eroe vicino: goblin x=[rd16 0xCA01]" }
after time 43 { L "eroe vicino +1 s: goblin x=[rd16 0xCA01]"; close $f; exit }
