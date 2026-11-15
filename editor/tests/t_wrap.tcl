carta E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor
proc rd {a} { return [debug read memory $a] }
proc csum {} { set s 0; for {set i 0} {$i<1536} {incr i} { set s [expr {($s*31 + [rd [expr {0xC000+$i}]]) & 0xFFFFFF}] }; return $s }
set log [open "$R/result3.txt" w]
proc st {l} { global log; puts $log "$l: csum=[csum] lvalid=[rd 0xC880] lseg=[rd 0xC881] seq=[rd 0xC889] fseg=[rd 0xC884] fpos=[format %02X [rd 0xC886]][format %02X [rd 0xC885]] rlen=[expr {[rd 0xC887]+256*[rd 0xC888]}] perr=[rd 0xC88A]"; flush $log }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.12 [list keymatrixup $row $mask] }
set n 0
proc go {} {
    global n log
    incr n
    if {$n == 1} {
        # mappa casuale (caso peggiore per la compressione), tile < 51
        expr {srand(7)}
        for {set i 0} {$i<1536} {incr i} { debug write memory [expr {0xC000+$i}] [expr {int(rand()*51)}] }
        st random
    }
    if {$n <= 52} {
        tap 5 0x01
        after time 1.7 go
    } else {
        st done
        close $log
        exit
    }
}
after time 15 go
