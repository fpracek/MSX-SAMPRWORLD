set out "E:/TEMP/Claude/MSXMAKER/unapi/result.txt"
set tries 0
proc rd {a} { return [debug read memory $a] }
proc check {} {
    global out tries
    incr tries
    if {[rd 0xDE00] == 0x55 || $tries > 600} {
        set f [open $out w]
        puts $f "done=[format %02X [rd 0xDE00]] tries=$tries count=[rd 0xDE01] slot=[format %02X [rd 0xDE02]] net=[rd 0xDE03]"
        puts $f "ip=[rd 0xDE04].[rd 0xDE05].[rd 0xDE06].[rd 0xDE07] errsend=[rd 0xDE08] errrcv=[rd 0xDE09]"
        set r {}
        for {set i 0} {$i < 11} {incr i} { lappend r [rd [expr {0xDE0A + $i}]] }
        puts $f "reply=$r"
        close $f
        after time 1 { screenshot "E:/TEMP/Claude/MSXMAKER/unapi/shot.png" }
        after time 3 exit
        return
    }
    after time 1 check
}
after time 1 check
