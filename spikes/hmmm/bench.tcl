after time 10 { puts stderr "x" }
after time 30 { set f [open "E:/TEMP/Claude/SAMPRWORLD/repo/spikes/hmmm/res.txt" w]; puts $f "done=[debug read memory 0xC002] ticks=[expr {[debug read memory 0xC000]+256*[debug read memory 0xC001]}] vdp60=[expr {[debug read memory 0xFFE8]}]"; close $f; exit }
