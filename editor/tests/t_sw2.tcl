# misura del carico dello sprite software: media dei giri a vuoto per fotogramma (piu' giri = piu' libero)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set log [open "$R/sw2_trace.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
set sum 0; set n 0
proc samp {} { global sum n; incr n; incr sum [rd16 0xC78A]; after time 0.011 samp }
proc phase {name dbg move} {
    global sum n
    wr 0xC79D $dbg
    if {$move} { keymatrixdown 8 0x80 } else { keymatrixup 8 0x80 }
    set ::sum 0; set ::n 0
    after time 1.5 [list apply {{name} { L "$name: campioni=$::n idle medio=[expr {$::n ? $::sum/double($::n) : 0}] (busy ms = [expr {$::n ? 16.67 - ($::sum/double($::n))*41/3579.5 : 0}]) ovr=[rd16 0xC78C]" }} $name]
}
after time 18 {
    for {set x 0} {$x < 120} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    wr 0xC766 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; samp }
}
after time 21 { phase "fermo, completo" 0 0 }
after time 23 { phase "fermo, senza sw_update" 1 0 }
after time 25 { phase "fermo, senza fisica" 2 0 }
after time 27 { phase "fermo, senza nulla" 3 0 }
after time 29 { phase "corsa, completo" 0 1 }
after time 32 { phase "corsa, senza sw_update" 1 1 }
after time 35 { phase "corsa, senza nulla" 3 1 }
after time 38 { close $log; exit }
