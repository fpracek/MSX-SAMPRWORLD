# periodo dei passi di scorrimento: frame di gioco (p_tick) tra un cambio di camera e il successivo
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_bot.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
set f [open "$R/maps/01.txt" r]; set tiles [split [string trim [read $f]] " "]; close $f
set log [open "$R/period.txt" w]
set last -1; set lasttick 0
proc poll {} {
    global last lasttick log
    set cam [rd16 0xC8C0]; set tk [rd 0xC8E8]
    if {$cam != $last} { puts $log "cam=$cam tick=$tk d=[expr {($tk - $lasttick) & 255}]"; set last $cam; set lasttick $tk }
    after time 0.004 poll
}
after time 18 {
    set i 0; foreach t $tiles { wr [expr {0xC000 + $i}] $t; incr i }
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; keymatrixdown 8 0x80; poll }
}
after time 26 { close $log; exit }
