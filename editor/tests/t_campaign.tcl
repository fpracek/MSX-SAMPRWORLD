# campagna dal menu: elenco dei 10 livelli, avvio del livello 1, vittoria (teletrasporto al portale) e segno [X]  (usa editor.rom)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/campaign_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
after time 24 { screenshot "$R/c0_menu.png"; tap 7 0x80 }          ;# INVIO: Play the campaign
after time 40 { screenshot "$R/c1_list.png" }
after time 41 { tap 8 0x40 }                                          ;# GIU: livello 2
after time 42 { tap 8 0x20 }                                          ;# SU: livello 1
after time 44 { tap 7 0x80 }                                          ;# INVIO: gioca
after time 52 { L "in gioco: foreign=[rd 0xC8F9] x=[rd16 0xC8A0] y=[rd16 0xC8A5]"; screenshot "$R/c2_play.png" }
after time 53 { wr16 0xC8A0 1930; wr16 0xC8A5 144 }                   ;# vicino al portale (colonna 121)
after time 70 { L "dopo la vittoria: win=[rd 0xC8B6] foreign=[rd 0xC8F9] done_bits=[rd 0xCCB2]"; screenshot "$R/c3_done.png"; close $log; exit }
