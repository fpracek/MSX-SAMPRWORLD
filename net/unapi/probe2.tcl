set out "E:/TEMP/Claude/MSXMAKER/unapi/probe2.txt"
set tries 0
proc check {} {
    global out tries
    incr tries
    if {[debug read memory 0xC0FF] == 0x55 || $tries > 200} {
        set f [open $out w]
        for {set s 0} {$s < 17} {incr s} {
            set l {}
            for {set i 0} {$i < 32} {incr i} { lappend l [format %02X [debug read memory [expr {0xC100 + $s*32 + $i}]]] }
            puts $f "slot$s: [lrange $l 0 19]"
        }
        close $f
        after time 1 exit
        return
    }
    after time 2 check
}
after time 2 check
