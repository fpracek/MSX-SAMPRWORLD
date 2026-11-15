set n 0; set tstart -1; set tend -1
proc poll {} {
    global n tstart tend
    incr n
    set st [debug read memory 0xC003]; set dn [debug read memory 0xC002]
    if {$st == 1 && $tstart < 0} { set tstart $n }
    if {$dn == 0x55 && $tend < 0} { set tend $n }
    if {$tend > 0 || $n > 20000} {
        set f [open "E:/TEMP/Claude/SAMPRWORLD/repo/spikes/hmmm/res.txt" w]
        puts $f "polls inizio=$tstart fine=$tend durata_s=[expr {($tend-$tstart)*0.005}] per_copia_ms=[expr {($tend-$tstart)*0.005*1000/100.0}]"
        close $f; exit
    }
    after time 0.005 poll
}
after time 8 poll
