# sprite software: casi limite (cucitura dell'anello x>240, confine di 16 KB y>112, entrambi) con l'eroe fermo
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {$v >> 8}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc put {x y n} { wr 0xC79D 2; wr16 0xC8A0 $x; wr16 0xC8A5 $y; wr16 0xC8A8 0; after time 0.5 [list screenshot "$::R/sw3_$n.png"] }
after time 18 {
    for {set x 0} {$x < 120} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    for {set x 0} {$x < 120} {incr x 7} { cell $x 5 5 }
    wr 0xC766 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 21 { put 300 144 a }
after time 22 { put 506 144 b; after time 1.6 { screenshot "$::R/sw3_b2.png" } }     ;# x & 255 = 250: cucitura
after time 23 { put 300 120 c }     ;# y a cavallo del confine di 16 KB
after time 24 { put 506 120 d }     ;# entrambi
after time 25 { put 250 144 f; after time 1.6 { screenshot "$::R/sw3_f2.png" } }
after time 28 { exit }
