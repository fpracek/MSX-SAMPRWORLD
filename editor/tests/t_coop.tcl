# due giocatori: P2 corre a destra (guida la camera), P1 resta indietro e viene riportato; poi P1 muore e rinasce accanto a P2
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set log [open "$R/coop_trace.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc hs {} { return "P1 x=[rd16 0xC720] y=[rd16 0xC725] dead=[rd 0xC731] | P2 x=[rd16 0xC738] y=[rd16 0xC73D] dead=[rd 0xC749] | cam=[rd16 0xC8C0] cur=[rd 0xC761] coins=[rd 0xC8B8]" }
after time 18 {
    for {set x 0} {$x < 60} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    cell 40 9 27   ;# moneta
    cell 50 10 33  ;# portale: 33 sopra? (usato come nel test play)
    wr 0xC760 1    ;# p_two
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 22 { L "start: [hs]"; screenshot "$R/coop_1.png" }
after time 22.5 { wr 0xC764 0x80 }          ;# P2 a destra
after time 26 { L "P2 corre: [hs]"; screenshot "$R/coop_2.png" }
after time 30 { L "P2 corre piu' a lungo: [hs]"; screenshot "$R/coop_3.png" }
after time 30.1 { wr 0xC764 0; wr 0xC765 0x80 }   ;# ora P1 a destra
after time 34 { L "P1 corre: [hs]"; screenshot "$R/coop_4.png"; wr 0xC765 0 }
after time 35 { L "fine: [hs]"; close $log; exit }
