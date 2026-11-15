# salvataggio/caricamento della bozza con tile >= 64 (RLE a 7 bit)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory $a $v }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.15 [list keymatrixup $row $mask] }
proc row5 {} { set s ""; for {set i 0} {$i < 8} {incr i} { append s [rd [expr {0xC000+5*128+$i}]] " " }; return $s }
set f [open "$R/rt7.txt" w]
after time 18 { for {set i 0} {$i < 5} {incr i} { cell $i 5 100 }; cell 5 5 77; cell 6 5 121; cell 7 5 64; puts $f "prima: [row5]"; tap 5 0x01 }
after time 22 { for {set i 0} {$i < 8} {incr i} { cell $i 5 0 }; puts $f "cancellato: [row5]"; tap 4 0x02 }
after time 26 { puts $f "ricaricato: [row5] (atteso 100 100 100 100 100 77 121 64)"; close $f; exit }
