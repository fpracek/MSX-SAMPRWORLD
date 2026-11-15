# camera di gruppo: chi e' davanti si ferma al bordo e la camera aspetta l'altro (a destra e a sinistra)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set f [open "$R/cam.txt" w]
proc L {s} { global f; puts $f $s; flush $f }
proc st {} { return "P1 x=[rd16 0xC720] P2 x=[rd16 0xC738] cam=[rd16 0xC8C0]" }
after time 18 {
    for {set x 0} {$x < 100} {incr x} { cell $x 10 1; cell $x 11 2 }
    cell 1 9 35
    wr 0xC760 1
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 22 { L "inizio: [st]"; wr 0xC764 0x80 }                                  ;# P2 a destra, P1 fermo
after time 26 { L "P2 corre, P1 fermo: [st]  (atteso: P2 ~ cam+240, cam ferma)"; screenshot "$R/cam_a.png"; wr 0xC765 0x80 }   ;# anche P1 a destra
after time 30 { L "entrambi a destra: [st]"; wr 0xC764 0 }                         ;# P2 si ferma, P1 continua
after time 34 { L "P1 davanti, P2 fermo: [st]  (atteso: P1 <= cam+240, cam <= P2)"; screenshot "$R/cam_b.png"; wr 0xC765 0; wr 0xC764 0x10 }  ;# ora P2 a sinistra
after time 38 { L "P2 corre a sinistra, P1 fermo: [st]  (atteso: P2 >= cam, la camera non torna indietro)"; wr 0xC764 0; wr 0xC765 0x10 }
after time 42 { L "P1 a sinistra: [st]"; screenshot "$R/cam_c.png"; close $f; exit }
