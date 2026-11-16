# sale la scala a destra con input vero: la finestra deve scorrere verso l'alto
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/vr_result.txt" w]
proc dump {tag} {
  global log
  set m [debug read_block VRAM [expr {0x18000+176*128}] 2048]
  binary scan $m H* mh
  set out "$tag"
  for {set p 0} {$p < 3} {incr p} {
    set top [debug read_block VRAM [expr {$p*0x8000}] 1024]
    set bot [debug read_block VRAM [expr {$p*0x8000+184*128}] 1024]
    set mtop [string range $m 0 1023]
    set mbot [string range $m [expr {8*128}] [expr {16*128-1}]]
    set ok1 [expr {$top eq $mtop}]
    set ok2 [expr {$bot eq $mbot}]
    append out " p$p:top=$ok1,bot=$ok2"
  }
  puts $log $out; flush $log
}
for {set t 59} {$t < 64} {set t [expr {$t+0.25}]} { after time $t [list dump $t] }
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
