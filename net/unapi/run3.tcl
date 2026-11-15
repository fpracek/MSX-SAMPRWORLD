set out "E:/TEMP/Claude/MSXMAKER/unapi/result3.txt"
set tries 0
proc rd {a} { return [debug read memory $a] }
proc check {} {
    global out tries
    incr tries
    if {[rd 0xDE00] == 0x55 || $tries > 400} {
        set f [open $out w]
        puts $f "done=[format %02X [rd 0xDE00]] tries=$tries"
        puts $f "list1=[rd 0xDE10] get1=[rd 0xDE11] begin=[rd 0xDE12] end=[rd 0xDE13] newid=[expr {[rd 0xDE14]+256*[rd 0xDE15]}] list2=[rd 0xDE16] get2=[rd 0xDE17] pattern=[rd 0xDE18] chunks=[rd 0xDE19]"
        close $f
        after time 1 { screenshot "E:/TEMP/Claude/MSXMAKER/unapi/shot3.png" }
        after time 3 exit
        return
    }
    after time 1 check
}
after time 1 check
