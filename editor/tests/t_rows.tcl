# tileset su righe spostate: disegna i tile 16..52 nell'editor e salva uno screenshot (confrontare normale / -DTILETEST)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc wr {a v} { debug write memory $a $v }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
after time 18 {
    for {set i 0} {$i < 16} {incr i} { cell $i 1 [expr {16+$i}]; cell $i 3 [expr {32+$i}] }
    for {set i 0} {$i < 5} {incr i} { cell $i 5 [expr {48+$i}] }
    wr 0xC814 1; wr 0xC815 1
}
after time 20 { screenshot "$R/rows_$::env(TAG).png"; exit }
