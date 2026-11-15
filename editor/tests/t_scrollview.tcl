# sequenza di screenshot durante lo scorrimento (hero che corre a destra sul livello 1): verifica visiva dei passi da 16 px
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_bot.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
set f [open "$R/maps/01.txt" r]; set tiles [split [string trim [read $f]] " "]; close $f
set log [open "$R/scrollview.txt" w]
after time 18 {
    set i 0; foreach t $tiles { wr [expr {0xC000 + $i}] $t; incr i }
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; keymatrixdown 8 0x80 }
}
set k 0
foreach tt {19.6 19.8 20.0 20.2 20.4 20.6 20.8 21.0} {
    after time $tt [list apply {{k} { global R log; screenshot "$R/sv_$k.png"; puts $log "sv_$k: x=[rd16 0xC8A0] cam=[rd16 0xC8C0]"; flush $log }} $k]
    incr k
}
after time 22 { close $log; exit }
