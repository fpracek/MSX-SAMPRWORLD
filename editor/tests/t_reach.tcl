cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
source E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests/maps.tcl
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
set log [open $R/reach.txt w]
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
set idx 0
proc step {} {
    global MAPS idx log
    if {$idx >= [llength $MAPS]} { close $log; exit }
    set title [lindex $MAPS $idx]; set tiles [lindex $MAPS [expr {$idx+1}]]
    set a 0xC000
    foreach t $tiles { debug write memory $a $t; incr a }
    tap 3 0x01
    after time 1.5 [list report $title]
}
proc report {title} {
    global idx log
    set n [expr {[debug read memory 0xCE02] + 256*[debug read memory 0xCE03]}]
    puts $log "$title: coins_unreachable=$n exit_bad=[debug read memory 0xCE04] first=[debug read memory 0xCE05],[debug read memory 0xCE06]"; flush $log
    incr idx 2
    after time 0.5 step
}
after time 20 step
