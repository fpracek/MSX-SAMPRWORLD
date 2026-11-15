carta E:/TEMP/Claude/MSXMAKER/yamasave/yamasave.rom -romtype Yamanooto
reset
set out [open "E:/TEMP/Claude/MSXMAKER/yamasave/result2.txt" w]
set cycle 0
set ncycles 1
proc rd {a} { return [debug read memory $a] }
proc grab {} {
    global out cycle ncycles
    incr cycle
    set prev [rd 0xDE30]
    puts $out "ciclo $cycle: done=[format %02X [rd 0xDE00]] prev_idx=$prev free_idx=[rd 0xDE31] progerr=[rd 0xDE32] verify=[rd 0xDE33] newseq=[rd 0xDE34] erased=[rd 0xDE36] slot=[rd 0xDE37]"
    flush $out
    if {$cycle == 1} { screenshot "E:/TEMP/Claude/MSXMAKER/yamasave/shot1.png" }
    if {$cycle == $ncycles} {
        screenshot "E:/TEMP/Claude/MSXMAKER/yamasave/shot.png"
        close $out
        after time 2 exit
        return
    }
    reset
    after time 12 grab
}
after time 12 grab
