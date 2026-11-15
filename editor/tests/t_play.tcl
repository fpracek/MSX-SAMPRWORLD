# prova di gioco con un "bot": livello con buca, muro e portale; il bot corre a destra e salta nei punti giusti
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set log [open "$R/play_trace.txt" w]
set n 0
proc tick {} {
    global log n R
    incr n
    set x [rd16 0xC8A0]; set y [rd16 0xC8A5]
    if {$y > 32768} { set y [expr {$y-65536}] }
    set gr [rd 0xC8AC]; set ex [rd 0xC8BE]; set dead [rd 0xC8B1]
    puts $log "$n x=$x y=$y gr=$gr dead=$dead coins=[rd 0xC8B8] win=[rd 0xC8B6] cam=[rd16 0xC8C0] page=[rd 0xC8C4] job=[rd 0xC8C5]"
    if {$n == 60} { screenshot "$R/play_mid.png" }
    if {($ex && $ex != 255) || $n > 900} {
        after time 3 {
            puts $log "FINE exit=[rd 0xC8BE] win=[rd 0xC8B6] valid=[rd 0xC896] coins=[rd 0xC8B8]"
            close $log
            screenshot "E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests/play_end.png"
            exit
        }
        return
    }
    # il bot: sempre a destra; salta davanti alla buca (x 140-170) e al muro (x 196-215)
    if {($x >= 125 && $x <= 150) || ($x >= 245 && $x <= 300)} { keymatrixdown 8 0x01 } else { keymatrixup 8 0x01 }
    after time 0.06 tick
}
after time 18 {
    # costruisce il livello di prova
    cell 1 10 35 ;# START
    cell 5 10 27 ;# moneta
    cell 10 11 0; cell 11 11 0 ;# buca
    cell 19 9 3; cell 19 10 3 ;# muro
    cell 24 9 33; cell 24 10 34 ;# portale
    keymatrixdown 5 0x02   ;# T: prova
    after time 0.2 { keymatrixup 5 0x02; keymatrixdown 8 0x80; tick }
}
