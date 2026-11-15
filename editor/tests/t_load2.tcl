carta E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor
proc rd {a} { return [debug read memory $a] }
proc csum {} { set s 0; for {set i 0} {$i<1536} {incr i} { set s [expr {($s*31 + [rd [expr {0xC000+$i}]]) & 0xFFFFFF}] }; return $s }
after time 18 { set f [open "$R/result4.txt" w]; puts $f "csum=[csum] lvalid=[rd 0xC880] seq=[rd 0xC889]"; close $f; screenshot "$R/s_loaded.png"; exit }
