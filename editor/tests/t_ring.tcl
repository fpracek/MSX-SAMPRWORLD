# scroll hardware V9958 (MSX2+): usa -machine C-BIOS_MSX2+ ; screenshot in sequenza mentre l'eroe corre sul livello 1
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_bot.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
set f [open "$R/maps/01.txt" r]; set tiles [split [string trim [read $f]] " "]; close $f
set log [open "$R/ring.txt" w]
after time 24 {
    puts $::log "ring=[rd 0xCCC4]"
    set i 0; foreach t $tiles { wr [expr {0xC000 + $i}] $t; incr i }
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02; wr16 0xC8A0 400 }
}
set k 0
foreach tt {27 27.1 27.2 27.3 27.4 27.5 27.6 27.7} {
    after time $tt [list apply {{k} { global R log; screenshot "$R/rg_$k.png"; puts $log "rg_$k: x=[rd16 0xC8A0] cam=[rd16 0xC8C0] lo=[rd16 0xCCC5]"; flush $log }} $k]
    incr k
}
after time 30 { close $log; exit }
