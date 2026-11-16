# registro per fotogramma: idle del vblank, x, y, morto, riga finestra
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/frames.txt" w]
set on 0
proc fr {} { if {$::on} { puts $::log "[rd16 0xC78A] [rd16 0xC8A0] [rd16 0xC8A5] [rd 0xC8B1] [rd 0xC7AE] [rd 0xC8EA]" } }
debug set_watchpoint write_mem 0xC78B {} fr
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 50 { keymatrixdown 8 0x80; set ::on 1 }
after time 58 { set ::on 0; close $::log; exit }
