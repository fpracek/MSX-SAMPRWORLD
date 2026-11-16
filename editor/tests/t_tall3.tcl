# vite: tre morti (caduta sotto la mappa) = game over e ritorno al menu; HUD (usa editor.rom)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/tall3_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc st {tag} { L "$tag: tall=[rd 0xC7AF] life=[rd 0xC7C8] dead=[rd 0xC8B1] exit=[rd 0xC8BE] y=[rd16 0xC8A5] sc=[rd 0xC7BF]:[rd 0xC7C0]:[rd 0xC7C1] hi=[rd 0xC7C5]:[rd 0xC7C6]:[rd 0xC7C7]" }
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 54 { st start }
foreach {t n} {55 d1 59 d2 63 d3} { after time $t { wr16 0xC8A5 230 } ; after time [expr {$t+1.5}] [list st $n] }
after time 70 { st after; screenshot "$R/tall3_end.png"; close $log; exit }
