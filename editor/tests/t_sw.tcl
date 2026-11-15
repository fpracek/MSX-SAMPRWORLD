# sprite software con triplo buffer (V9958): corsa a destra con salti, misura del carico e screenshot
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set log [open "$R/sw_trace.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc st {} { return "x=[rd16 0xC8A0] y=[rd16 0xC8A5] cam=[rd16 0xC8C0] on=[rd 0xC770] S=[rd 0xC771] idle=[expr {[rd 0xC78A]+256*[rd 0xC78B]}] ovr=[expr {[rd 0xC78C]+256*[rd 0xC78D]}] fn=[expr {[rd 0xC78E]+256*[rd 0xC78F]}]" }
after time 18 {
    for {set x 0} {$x < 120} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    cell 8 9 27; cell 9 9 27
    wr 0xC766 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 21 { L "inizio: [st]"; screenshot "$R/sw_0.png"; keymatrixdown 8 0x80 }
foreach {t} {22 23 24 25 26 27 28 29 30 31 32 33} {
    after time $t [list apply {{t} { L "t=$t [st]"; screenshot "$::R/sw_$t.png"; keymatrixdown 8 0x01; after time 0.25 { keymatrixup 8 0x01 } }} $t]
}
after time 34 { L "fine: [st]"; close $log; exit }
