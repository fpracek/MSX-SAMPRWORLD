# moneta presa nei livelli alti: la cella deve sparire per intero (scarto HUD nelle viste)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/coin_result.txt" w]
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 52 {
  set found ""
  for {set r 0} {$r < 12} {incr r} { for {set c 0} {$c < 64} {incr c} {
    if {[rd [expr {0xC000 + $r*128 + $c}]] == 27} { lappend found "$r,$c" } } }
  puts $log "coins: $found"
  if {[llength $found]} {
    lassign [split [lindex $found 0] ,] r c
    wr16 0xC8A0 [expr {$c*16}]; wr16 0xC8A5 [expr {$r*16}]; wr16 0xC8AA [expr {$r*16}]
    puts $log "tp to $r,$c"
  }
  flush $log
}
after time 56 { screenshot "$R/coin_a.png" }
after time 58 { screenshot "$R/coin_b.png" }
after time 60 { screenshot "$R/coin_c.png"; close $log; exit }
