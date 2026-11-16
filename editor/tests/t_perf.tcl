# carico: fotogrammi in ritardo (sw_ovr) su sw_fn in un livello alto, eroe che corre e sale
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/perf_result.txt" w]
proc st {tag} { puts $::log "$tag: ovr=[rd16 0xC78C] fn=[rd16 0xC78E] idle=[rd16 0xC78A] cr=[rd 0xC7AE] x=[rd16 0xC8A0] ne=[rd 0xC8EA]"; flush $::log }
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 50 { st s0; keymatrixdown 8 0x80 }
foreach {t n} {52 a 54 b 56 c 58 d 60 e} { after time $t [list st $n] }
after time 61 { keymatrixup 8 0x80; wr16 0xC8A0 400; wr16 0xC8A5 20; wr16 0xC8AA 20 }
foreach {t n} {63 f 65 g 67 h} { after time $t [list st $n] }
after time 68 { close $log; exit }
