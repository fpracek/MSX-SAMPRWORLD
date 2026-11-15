set out "E:/TEMP/Claude/MSXMAKER/net-test/probe.txt"
set tries 0
proc check {} {
    global out tries
    incr tries
    if {[debug read memory 0xC0FF] == 0x55 || $tries > 200} {
        set f [open $out w]
        for {set s 0} {$s < 25} {incr s} {
            set l {}
            for {set i 0} {$i < 16} {incr i} { lappend l [format %02X [debug read memory [expr {0xC100 + $s*16 + $i}]]] }
            puts $f "slot$s: $l"
        }
        close $f
        after time 1 exit
        return
    }
    after time 2 check
}
set throttle off
after time 2 check
