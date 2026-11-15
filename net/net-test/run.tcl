# esegue pingtest.rom e salva i risultati in result.txt
set out "E:/TEMP/Claude/MSXMAKER/net-test/result.txt"
set tries 0
proc rd {a} { return [debug read memory $a] }
proc check {} {
    global out tries
    incr tries
    if {[rd 0xC020] == 0x55 || $tries > 400} {
        set f [open $out w]
        puts $f "done=[format %02X [rd 0xC020]] tries=$tries"
        puts $f "ping=[format %02X [rd 0xC000]]"
        puts $f "ip=[rd 0xC001].[rd 0xC002].[rd 0xC003].[rd 0xC004]"
        puts $f "net=[rd 0xC005] send=[rd 0xC006] got=[rd 0xC007]"
        set r {}
        for {set i 0} {$i < 11} {incr i} { lappend r [rd [expr {0xC008 + $i}]] }
        puts $f "reply=$r"
        puts $f "frames=[expr {[rd 0xC014] + 256*[rd 0xC015]}]"
        close $f
        after time 1 { screenshot "E:/TEMP/Claude/MSXMAKER/net-test/shot.png" }
        after time 3 exit
        return
    }
    after time 1 check
}
#throttle normale
after time 1 check
