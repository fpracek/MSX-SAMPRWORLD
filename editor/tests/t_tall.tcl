# livelli alti: campagna -> livello 1, finestra verticale (p_cr), scorrimento su/giu' (usa editor.rom)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/tall_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
proc st {tag} { L "$tag: tall=[rd 0xC7AF] cr=[rd 0xC7AE] x=[rd16 0xC8A0] y=[rd16 0xC8A5] sy=[rd16 0xC8B4] ne=[rd 0xC8EA] ymin=[rd16 0xC7B5] ymax=[rd16 0xC7B7] dead=[rd 0xC8B1] ncr=[rd 0xC7B2] dlt=[rd16 0xC7B3]" }
after time 24 { tap 7 0x80 }                                          ;# INVIO: Play the campaign
after time 40 { tap 7 0x80 }                                          ;# INVIO: livello 1
after time 52 { st start; screenshot "$R/tall_0.png" }
after time 53 { keymatrixdown 8 0x80 }                                  ;# corre a destra: la camera scorre, l'HUD deve restare fermo
foreach {t n} {56 r1 58 r2 60 r3} { after time $t [list st $n] }
after time 56 { screenshot "$R/tall_h1.png" }
after time 58.3 { screenshot "$R/tall_h2.png" }
after time 60 { keymatrixup 8 0x80; wr16 0xC8A0 200; wr16 0xC8A5 30; wr16 0xC8AA 30 }
after time 61 { screenshot "$R/tall_h3.png" }
after time 63 { close $log; exit }
