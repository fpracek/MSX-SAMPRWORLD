# profilo a campionamento del PC durante la corsa a destra (livello alto, 1 nemico + eroe)
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
array set cnt {}
set on 0
proc samp {} { global cnt on; if {$on && [expr {[debug read memory 0xC8A0]+256*[debug read memory 0xC8A1]}] > 130 && [expr {[debug read memory 0xC8A0]+256*[debug read memory 0xC8A1]}] < 285 && [debug read memory 0xC8B1]==0} { set p [reg PC]; if {$p >= 0x45E5 && $p <= 0x45F8} { set sp [reg SP]; set p "v [expr {[debug read memory $sp]+256*[debug read memory [expr {$sp+1}]]}] [expr {[debug read memory [expr {$sp+2}]]+256*[debug read memory [expr {$sp+3}]]}]" }; if {[info exists cnt($p)]} {incr cnt($p)} else {set cnt($p) 1} }; after time 0.0003 samp }
after time 24 { tap 7 0x80 }
after time 40 { tap 7 0x80 }
after time 54 { keymatrixdown 8 0x80; set ::on 1; samp }
after time 62 { set ::on 0; keymatrixup 8 0x80
  set f [open "$R/prof2.txt" w]
  foreach p [lsort [array names cnt]] { puts $f "$p $cnt($p)" }
  close $f; exit }
