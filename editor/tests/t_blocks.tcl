# blocchi interattivi: runico (moneta), pietra fessurata, friabile, chiave + portone, portale
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc rcell {col row} { return [rd [expr {0xC000 + $row*128 + $col}]] }
proc tp {x y} { wr16 0xC8A0 $x; wr16 0xC8A5 $y; wr16 0xC8A8 0 }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.3 [list keymatrixup $row $mask] }
set log [open "$R/blocks_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
after time 18 {
    cell 1 10 35; cell 5 8 13; cell 8 8 15; cell 12 9 16
    cell 15 10 29; cell 20 9 25; cell 20 10 26; cell 24 9 33; cell 24 10 34
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 24 { tp 80 160 }
after time 24.2 { tap 8 0x01 }
after time 25.8 { L "runico: (5,8)=[rcell 5 8] (atteso 14=usato)  (5,7)=[rcell 5 7] (atteso 27=moneta)" }
after time 26 { tp 128 160 }
after time 26.2 { tap 8 0x01 }
after time 27.8 { L "fessurata: (8,8)=[rcell 8 8] (atteso 0=rotta)" }
after time 28 { tp 192 128 }
after time 28.4 { L "friabile subito: (12,9)=[rcell 12 9] (atteso 16)  hero y=[rd16 0xC8A5] ground=[rd 0xC8AC]" }
after time 30 { L "friabile dopo 1.6 s: (12,9)=[rcell 12 9] (atteso 0=crollato)" }
after time 31 { tp 16 160; keymatrixdown 8 0x80 }
after time 34 { L "chiave: chiavi=[rd 0xC8F8] (15,10)=[rcell 15 10] (atteso chiavi=1, 0)  x=[rd16 0xC8A0]" }
after time 38 {
    L "portone: (20,9)=[rcell 20 9] (20,10)=[rcell 20 10] (attesi 0 0) chiavi=[rd 0xC8F8] x=[rd16 0xC8A0]"
    L "vittoria: win=[rd 0xC8B6] exit=[rd 0xC8BE]"
    screenshot "$R/blocks_end.png"
    keymatrixup 8 0x80
    close $log; exit
}
