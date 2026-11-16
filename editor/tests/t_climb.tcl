# sale la scala a destra con input vero: la finestra deve scorrere verso l'alto
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/climb_result.txt" w]
proc st {tag} { puts $::log "$tag: x=[rd16 0xC8A0] y=[rd16 0xC8A5] cr=[rd 0xC7AE] climb=[rd 0xC8BA] dead=[rd 0xC8B1] ymin=[rd16 0xC7B5] ncr=[rd 0xC7B2] irq=[rd 0xC7F3] st=[rd 0xC7F0]"; flush $::log }
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 51 {
  # scala piu' a destra con la base al piano di partenza: x di una colonna con T_LADDER nella riga 9 (y=144)
  set best -1
  for {set c 0} {$c < 64} {incr c} { if {[rd [expr {0xC000 + 9*128 + $c}]] == 23} { set best $c } }
  puts $::log "ladder col $best"
  debug write memory 0xC8A0 [expr {$best*16 & 255}]; debug write memory 0xC8A1 [expr {($best*16) >> 8}]
}
after time 56 { }
for {set t 56} {$t < 80} {incr t 2} { after time $t [list st t$t] }
after time 58 { keymatrixdown 8 0x20 }
after time 74 { keymatrixup 8 0x20 }
after time 70 { screenshot "$R/climb_a.png" }
after time 78 { screenshot "$R/climb_b.png" }
after time 80 { close $log; exit }
