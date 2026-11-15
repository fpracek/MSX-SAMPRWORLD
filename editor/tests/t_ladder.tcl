# scala del Maniero: controllo di raggiungibilita' (con e senza scala) e salita in gioco con i frame di schiena
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {$v >> 8}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
set f [open "$R/ladder.txt" w]
proc L {s} { global f; puts $f $s; flush $f }
after time 18 {
    for {set x 0} {$x < 60} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    for {set x 12} {$x < 31} {incr x} { cell $x 6 4 }     ;# piano superiore (mattoni)
    cell 20 5 27                                           ;# moneta sul piano superiore
    wr 0xC766 1
}
after time 19 { tap 3 0x01 }                               ;# C: controllo (senza scala)
after time 20 { L "senza scala: monete irraggiungibili=[rd 0xCE02]"; for {set r 5} {$r < 10} {incr r} { cell 11 $r 23 } }
after time 21 { tap 3 0x01 }
after time 22 { L "con scala: monete irraggiungibili=[rd 0xCE02]"; keymatrixdown 5 0x02; after time 0.2 { keymatrixup 5 0x02 } }
after time 25 { wr16 0xC8A0 [expr {11*16+3}]; wr16 0xC8A5 144; wr16 0xC8A8 0; keymatrixdown 8 0x20 }     ;# eroe sulla scala, SU
after time 26 { screenshot "$R/ladder_a.png"; L "salita: y=[rd16 0xC8A5] climb=[rd 0xC8BA]" }
after time 27.5 { screenshot "$R/ladder_b.png"; L "dopo: y=[rd16 0xC8A5] climb=[rd 0xC8BA]"; keymatrixup 8 0x20; close $f; exit }
