# morte nella buca + ripartenza dal punto di partenza + uscita con ESC (senza validare)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
set n 0; set deaths 0; set wasdead 0; set respx -1
proc tick {} {
    global n deaths wasdead respx R
    incr n
    set x [rd16 0xC8A0]; set dead [rd 0xC8B1]
    if {$n > 2} {
        if {$dead > 0 && !$wasdead} { incr deaths }
        if {$wasdead && $dead == 0} { set respx $x }
        set wasdead [expr {$dead > 0}]
    }
    if {$n == 250} { keymatrixdown 7 0x04 }          ;# ESC
    if {$n == 256} { keymatrixup 7 0x04; keymatrixup 8 0x80 }
    if {$n > 330} {
        set f [open "$R/play2_result.txt" w]
        puts $f "morti=$deaths ripartenza_x=$respx exit=[rd 0xC8BE] win=[rd 0xC8B6] valid=[rd 0xC896]"
        close $f; exit
    }
    after time 0.06 tick
}
after time 18 {
    cell 1 10 35; cell 10 11 0; cell 11 11 0
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; keymatrixdown 8 0x80; after time 0.1 tick }
}
