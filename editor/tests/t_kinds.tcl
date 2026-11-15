# nemici con sprite diversi (proprieta') e scala: screenshot in gioco; poi controllo di raggiungibilita' con la scala
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {$v >> 8}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc rec {i col row sprite} { set a [expr {0xC600 + $i*8}]; foreach v [list $col $row 0 1 0 1 6 $sprite] k {0 1 2 3 4 5 6 7} { wr [expr {$a+$k}] $v } }
set f [open "$R/kinds.txt" w]
proc L {s} { global f; puts $f $s; flush $f }
after time 18 {
    for {set x 0} {$x < 60} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    cell 8 9 51; cell 12 9 51; cell 16 9 51; cell 20 5 52
    rec 0 8 9 1; rec 1 12 9 2; rec 2 16 9 3; rec 3 20 5 2; wr 0xC680 4      ;# soldato, medico, poliziotto, pipistrello-medico
    wr 0xC766 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 19.6 { screenshot "$R/kinds_a.png" }                 ;# eroe vicino ai nemici (si vedono tutti)
after time 22.5 { screenshot "$R/kinds_b.png"; L "ent: [rd 0xCA05] [rd 0xCA0D] [rd 0xCA15] [rd 0xCA1D]"; for {set i 0} {$i < 5} {incr i} { L "ENT$i type=[rd [expr {0xCA00+$i*8}]] x=[rd16 [expr {0xCA01+$i*8}]] y=[rd [expr {0xCA03+$i*8}]] | SWO frame=[rd [expr {0xCD00+$i*4}]] x=[rd16 [expr {0xCD01+$i*4}]] y=[rd [expr {0xCD03+$i*4}]]" }; L "on=[rd 0xC770] cam=[rd16 0xC8C0] hero x=[rd16 0xC8A0]"; close $f; exit }
