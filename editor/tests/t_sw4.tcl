# corsa attraverso la cucitura dell'anello: screenshot mentre x & 255 e' tra 236 e 255
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set shots 0
proc watch {} {
    global shots R
    set x [rd16 0xC8A0]
    set r [expr {$x & 255}]
    if {$x > 400 && $r >= 232 && $shots < 8} { screenshot "$R/sw4_$shots.png"; incr shots; set ::log_[set shots] "x=$x ring=$r cam=[rd16 0xC8C0]" ; set f [open "$R/sw4.txt" a]; puts $f "shot [expr {$shots-1}]: x=$x ring=$r cam=[rd16 0xC8C0]"; close $f }
    if {$shots >= 8 || $x > 900} { exit }
    after time 0.04 watch
}
after time 18 {
    for {set x 0} {$x < 120} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    wr 0xC766 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; keymatrixdown 8 0x80; watch }
}
