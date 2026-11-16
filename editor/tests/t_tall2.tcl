# livelli alti con due giocatori: la finestra verticale scorre solo se entrambi restano visibili (usa editor.rom)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc rd16 {a} { set v [expr {[rd $a] + 256*[rd [expr {$a+1}]]}]; if {$v > 32767} { set v [expr {$v-65536}] }; return $v }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/tall2_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc st {tag} { L "$tag: cr=[rd 0xC7AE] P1 y=[rd16 0xC725] P2 y=[rd16 0xC73D] dead=[rd 0xC731]/[rd 0xC749] life=[rd 0xC7C8] ymin=[rd16 0xC7B5] ymax=[rd16 0xC7B7] ncr=[rd 0xC7B2] sc1=[rd 0xC7BF]:[rd 0xC7C0]" }
after time 20 { wr 0xC760 1 }
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 54 { st start; screenshot "$R/tall2_0.png" }
# P1 sale in alto (y=20) mentre P2 resta in basso: la finestra non deve scorrere (P2 uscirebbe dallo schermo)
after time 55 { wr16 0xC725 20; wr16 0xC72A 20; wr16 0xC727 0 }
for {set k 1} {$k <= 16} {incr k} { after time [expr {55 + $k*0.06}] [list st t$k] }
after time 57.5 { screenshot "$R/tall2_1.png" }
# anche P2 in alto: ora puo' scorrere
after time 58 { wr16 0xC725 20; wr16 0xC72A 20; wr16 0xC73D 24; wr16 0xC742 24 }
foreach {t n} {58.2 d 59 e} { after time $t [list st $n] }
after time 59.5 { screenshot "$R/tall2_2.png" }
after time 61 { close $log; exit }
