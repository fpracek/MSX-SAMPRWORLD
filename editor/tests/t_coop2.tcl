# due giocatori: rinascita accanto all'altro e rinascita totale al checkpoint; con MACHINE si prova anche il V9938
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set tag $::env(TAG)
set log [open "$R/coop2_$tag.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc hs {} { return "P1 x=[rd16 0xC720] y=[rd16 0xC725] dead=[rd 0xC731] | P2 x=[rd16 0xC738] y=[rd16 0xC73D] dead=[rd 0xC749] | cam=[rd16 0xC8C0] ring=[rd 0xCCC4] sx=[rd16 0xC8B2]" }
after time 18 {
    for {set x 0} {$x < 60} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    wr 0xC760 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 22 { L "start: [hs]"; wr 0xC764 0x80 }
after time 26 { wr 0xC764 0; L "P2 avanti: [hs]"; screenshot "$R/coop2_${tag}_a.png"; wr 0xC731 5 }
after time 26.05 { L "P1 morto: [hs]" }
after time 27 { L "P1 rinato accanto a P2?: [hs]"; screenshot "$R/coop2_${tag}_b.png"; wr 0xC731 5; wr 0xC749 5 }
after time 28.5 { L "entrambi rinati al checkpoint: [hs]"; screenshot "$R/coop2_${tag}_c.png" }
after time 29 { close $log; exit }
