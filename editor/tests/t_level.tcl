# collaudo di un livello della campagna con un bot euristico (corre a destra, salta davanti a muri, buche, spuntoni, nemici)
# uso: LEVEL=NN  (carica tests/maps/NN.txt nella mappa, avvia la prova, il bot gioca fino al portale o al tempo massimo)
set lv $::env(LEVEL)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_bot.rom -romtype Yamanooto
reset
set throttle off
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tile {col row} { if {$col < 0 || $col > 127 || $row < 0 || $row > 11} { return 3 }; return [rd [expr {0xC000 + $row*128 + $col}]] }
set solid {3 4 5 6 7 8 13 14 15 16 25 26 31}
set ground {1 2 3 4 5 6 7 8 10 11 12 13 14 15 16 31}
set f [open "$R/maps/$lv.txt" r]; set tiles [split [string trim [read $f]] " "]; close $f
set log [open "$R/level_$lv.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
set sxmin 999; set sxmax -999; set wasair 0; set n 0; set deaths 0; set wasdead 0; set jump 0; set hold 0; set t0 0; set res TIMEOUT
proc tick {} {
    global n solid ground deaths wasdead jump hold res log lv wasair sxmin sxmax
    incr n
    set x [rd16 0xC8A0]; set y [rd16 0xC8A5]; set gr [rd 0xC8AC]; set dead [rd 0xC8B1]
    if {$x > 32768 || $y > 32768} { after time 0.04 tick; return }
    if {$dead > 0 && !$wasdead} { incr deaths; L "morte a x=$x y=$y" }
    set wasdead [expr {$dead > 0}]
    if {[rd 0xC8B6] == 1 && [rd 0xC8BE] == 1} { set res VINTO; L "$res nel tick $n  morti=$deaths  x=$x  sx(min,max)=$sxmin,$sxmax"; close $log; exit }
    if {$n > 3200} { L "$res (x=$x) morti=$deaths"; close $log; exit }
    if {!$gr} { set wasair 1 } elseif {$wasair} { set hold 0; set wasair 0 }
    set sx [expr {$x - [rd16 0xC8C0]}]; if {$dead == 0 && $n > 20} { if {$sx < $sxmin} { set sxmin $sx }; if {$sx > $sxmax} { set sxmax $sx } }
    set row [expr {$y / 16}]
    set fx [expr {$x + 13}]
    set want 0; set why ""
    # muro davanti (all'altezza del corpo)
    foreach dx {5 12 22} {
        set c [expr {($fx + $dx) / 16}]
        foreach r [list $row [expr {($y+15)/16}]] { if {[lsearch $solid [tile $c $r]] >= 0} { set want 1; append why " wall($c,$r)=[tile $c $r]" } }
    }
    # buca/pericolo sotto i piedi davanti
    set below [expr {($y + 16) / 16}]
    set c [expr {($fx + 5) / 16}]
    if {[lsearch $ground [tile $c $below]] < 0} { set want 1; append why " gap($c,$below)=[tile $c $below]" }
    # spuntoni e lava davanti
    foreach dx {6 14 22} {
        set c [expr {($fx + $dx) / 16}]
        set t [tile $c $row]
        if {$t == 18} { set want 1; append why " spike" }
    }
    # nemici vicini
    for {set i 0} {$i < 8} {incr i} {
        set b [expr {0xCA00 + $i*8}]
        if {[rd $b] != 0} {
            set ex [rd16 [expr {$b+1}]]; set ey [rd [expr {$b+3}]]
            if {$ex > $x - 6 && $ex < $x + 44 && abs($ey - $y) < 28} { set want 1; append why " enemy$i" }
        }
    }
    if {$gr && $want && $hold == 0} { set hold 14 }
    if {0} { L "x=$x y=$y gr=$gr want=$want why=$why hold=$hold" }
    if {$hold > 0} { keymatrixdown 8 0x01; incr hold -1 } else { keymatrixup 8 0x01 }
    after time 0.04 tick
}
after time 18 {
    set i 0
    foreach t $tiles { wr [expr {0xC000 + $i}] $t; incr i }
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; keymatrixdown 8 0x80 }
    after time 0.5 tick
}
