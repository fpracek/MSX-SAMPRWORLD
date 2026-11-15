# i progressi della campagna restano nella flash (FASE=a: vince il livello 3; FASE=b: dopo il riavvio legge i progressi). Usa editor.rom
set fase $::env(FASE)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/progress_$fase.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
if {$fase eq "a"} {
    after time 22 { L "all'avvio: done=[rd 0xCCB2],[rd 0xCCB3]"; tap 7 0x80 }
    after time 38 { tap 8 0x40 }
    after time 38.6 { tap 8 0x40 }
    after time 40 { tap 7 0x80 }                  ;# gioca il livello 3
    after time 48 { wr16 0xC8A0 1930; wr16 0xC8A5 144 }
    after time 66 { L "dopo la vittoria: done=[rd 0xCCB2],[rd 0xCCB3]"; close $log; exit }
} else {
    after time 24 { L "dopo il riavvio: done=[rd 0xCCB2],[rd 0xCCB3] (atteso 4,0)"; screenshot "$R/progress_b.png"; tap 7 0x80 }
    after time 40 { screenshot "$R/progress_b_list.png"; close $log; exit }
}
