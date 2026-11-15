# sprite software con eroe e nemici del Maniero: corsa verso un goblin e un pipistrello, screenshot e carico
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set f [open "$R/sw5.txt" w]
proc L {s} { global f; puts $f $s; flush $f }
after time 18 {
    for {set x 0} {$x < 120} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35; cell 14 9 51; cell 18 5 52; cell 24 9 51; cell 28 6 52
    wr 0xC766 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 21 { screenshot "$R/sw5_a.png"; L "inizio: x=[rd16 0xC8A0] on=[rd 0xC770] idle=[expr {[rd 0xC78A]+256*[rd 0xC78B]}]"; keymatrixdown 8 0x80 }
foreach t {23 24 25 26 27} { after time $t [list apply {{t} { L "t=$t x=[rd16 0xC8A0] dead=[rd 0xC8B1] idle=[expr {[rd 0xC78A]+256*[rd 0xC78B]}] ovr=[expr {[rd 0xC78C]+256*[rd 0xC78D]}]"; screenshot "$::R/sw5_$t.png" }} $t] }
after time 28 { close $f; exit }
