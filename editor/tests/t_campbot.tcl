# collaudo di un livello della campagna con un bot che segue il percorso del pianificatore (tools/make_levels.py):
# corse con salto automatico di buche/muri/spuntoni/nemici, scale (su/giu') alla colonna giusta. LEVEL=NN
set lv $::env(LEVEL)
set TALL [info exists ::env(TALL)]   ;# livelli alti: campagna vera dal menu (editor.rom), coordinate di mondo = y + 16*p_cr
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/[expr {$TALL ? "editor.rom" : "editor_test.rom"}] -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc slurp {p} { set f [open $p r]; set d [string trim [read $f]]; close $f; return $d }
set mp [expr {$TALL ? "tall_$lv" : $lv}]
set tiles [split [slurp "$R/maps/$mp.txt"] " "]
set cls [split [slurp "$R/maps/classes.txt"] " "]
set route {}
foreach l [split [slurp "$R/maps/$mp.route"] "\n"] { lappend route $l }
set ents {}
catch { foreach l [split [slurp "$R/maps/$mp.ents"] "\n"] { if {$l ne ""} { lappend ents $l } } }
set log [open "$R/campbot_$lv.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc cl {c r} { global tiles cls TALL; if {$TALL} { if {$c < 0 || $c > 63 || $r < 0 || $r > 31} { return 1 }; set t [lindex $tiles [expr {$r*64+$c}]]; return [lindex $cls $t] }; if {$c < 0 || $c > 127 || $r < 0 || $r > 11} { return 1 }; set t [lindex $tiles [expr {$r*128+$c}]]; return [lindex $cls $t] }
proc tl {c r} { global tiles TALL; if {$TALL} { if {$c < 0 || $c > 63 || $r < 0 || $r > 31} { return 3 }; return [lindex $tiles [expr {$r*64+$c}]] }; if {$c < 0 || $c > 127 || $r < 0 || $r > 11} { return 3 }; return [lindex $tiles [expr {$r*128+$c}]] }
set jp 0; set wp 0; set n 0; set deaths 0; set wasdead 0; set hold 0; set res TIMEOUT; set wasair 0; set stuck 0; set lastx 0
if {$TALL} {
    after time 24 { keymatrixdown 7 0x80; after time 0.25 { keymatrixup 7 0x80 } }
    for {set k 1} {$k < [expr {int($lv)}]} {incr k} { after time [expr {30 + $k*0.6}] { keymatrixdown 8 0x40; after time 0.25 { keymatrixup 8 0x40 } } }
    after time 40 { keymatrixdown 7 0x80; after time 0.25 { keymatrixup 7 0x80 } }
    after time 50 tick
} else {
after time 17 {
    for {set i 0} {$i < 1536} {incr i} { wr [expr {0xC000+$i}] [lindex $::tiles $i] }
    set k 0
    foreach e $::ents { set a [expr {0xC600 + $k*8}]; set j 0; foreach v $e { wr [expr {$a+$j}] $v; incr j }; incr k }
    wr 0xC680 $k
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; after time 1.5 tick }
}
}
proc nearest {x y} {   ;# y = y di mondo
    global route
    set best 0; set bd 99999; set i 0
    foreach w $route { lassign $w kind c r; set d [expr {abs($c*16 - $x) + 3*abs($r*16 - $y)}]; if {$d < $bd} { set bd $d; set best $i }; incr i }
    return $best
}
proc tick {} {
    global n route wp deaths wasdead hold res log lv wasair R jp
    incr n
    set x [rd16 0xC8A0]; set y [rd16 0xC8A5]; set cr [expr {$::TALL ? [rd 0xC7AE] : 0}]; set yw [expr {$y + 16*$cr}]; set gr [rd 0xC8AC]; set dead [rd 0xC8B1]; set climb [rd 0xC8BA]
    if {$x > 32768 || $y > 32768} { after time 0.04 tick; return }
    if {$dead > 0 && !$wasdead} { incr deaths; L "morte a x=$x y=$y (waypoint $wp)"; if {$deaths <= 3} { screenshot "$R/campbot_${lv}_morte$deaths.png" } }
    if {$wasdead && $dead == 0} { set wp [nearest $x $yw]; L "rinasce a x=$x y=$y -> waypoint $wp" }
    set wasdead [expr {$dead > 0}]
    if {[rd 0xC8B6] == 1 && [rd 0xC8BE] == 1} { set res VINTO; L "$res nel tick $n morti=$deaths coins=[rd 0xC8B8]"; close $log; exit }
    if {$n > [expr {[info exists ::env(MAXN)] ? $::env(MAXN) : 4500}]} { L "$res x=$x y=$y waypoint=$wp/[llength $route] morti=$deaths"; screenshot "$R/campbot_$lv.png"; close $log; exit }
    if {$dead > 0} { keymatrixup 8 0xF0; after time 0.04 tick; return }
    if {$wp >= [llength $route]} { keymatrixup 8 0xF1; after time 0.04 tick; return }
    lassign [lindex $route $wp] kind col row
    set tx [expr {$col*16}]
    set dx [expr {$tx - $x}]
    set row0 [expr {$yw/16}]
    set keys 0
    if {$kind eq "up" || $kind eq "down"} {
        # centrarsi sulla colonna della scala (anche mentre si sale: lo scafo di 10 px deve stare dentro la colonna)
        if {$dx > 2} { set keys 0x80 } elseif {$dx < -2} { set keys 0x10 }
        if {abs($dx) <= 5 || $climb} {
            if {$kind eq "up"} {
                if {abs($dx) <= 3} { set keys [expr {$keys | 0x20}] }
                if {$yw <= $row*16 - 1} { incr wp; set hold 0; set keys 0 }
            } else {
                if {abs($dx) <= 3} { set keys [expr {$keys | 0x40}] }
                if {$gr && $yw >= $row*16 - 2 && !$climb} { incr wp }
            }
        }
    } else {
        if {abs($dx) <= 4 && ($row0 == $row || $yw >= $row*16 - 6)} { incr wp }
        set dir [expr {$dx > 0 ? 1 : -1}]
        set keys [expr {$dx > 0 ? 0x80 : 0x10}]
        set want 0
        set fx [expr {$x + 8}]
        # muro davanti
        foreach ddx {10 18 28} {
            set c [expr {($fx + $dir*$ddx) / 16}]
            foreach r [list $row0 [expr {($yw+15)/16}]] { set k [cl $c $r]; if {$k == 1 || $k == 6 || [tl $c $r] == 25 || [tl $c $r] == 26} { set want 1 } }
        }
        # buca: manca il pavimento subito davanti ma c'e' ancora entro 6 tile (altrimenti e' una discesa: non si salta)
        set below [expr {($yw + 16) / 16}]
        set c [expr {($fx + $dir*10) / 16}]
        set kb [cl $c $below]
        if {$kb != 1 && $kb != 2 && $kb != 6 && $kb != 5} {
            for {set j 1} {$j <= 6} {incr j} {
                set k2 [cl [expr {$c + $dir*$j}] $below]
                if {$k2 == 1 || $k2 == 2 || $k2 == 6} { set want 1; break }
            }
        }
        foreach ddx {10 18} { set c [expr {($fx + $dir*$ddx) / 16}]; if {[cl $c $row0] == 3} { set want 1 } }
        for {set i 0} {$i < 8} {incr i} {
            set b [expr {0xCA00 + $i*8}]
            if {[rd $b] != 0} {
                set ex [rd16 [expr {$b+1}]]; set ey [rd [expr {$b+3}]]
                if {[expr {abs($ex - $x) < 48 && abs($ey - $y) < 28 && ($ex - $x)*$dir >= -6}]} { set want 1 }
            }
        }
        if {!$gr} { set wasair 1 } elseif {$wasair} { set hold 0; set wasair 0 }
        if {$gr && $want && $hold == 0 && !$jp} { set hold 24 }
        if {$hold > 0} { incr hold -1; set keys [expr {$keys | 0x01}] }
    }
    if {[info exists ::env(DBG)] && ($n % 10 == 0 || [info exists ::env(DBGALL)])} { L "n=$n x=$x y=$y yw=$yw gr=$gr climb=$climb dead=$dead wp=$wp keys=$keys hold=$hold" }
    set jp [expr {$keys & 1}]
    keymatrixup 8 0xF1
    if {$keys} { keymatrixdown 8 $keys }
    after time 0.04 tick
}
