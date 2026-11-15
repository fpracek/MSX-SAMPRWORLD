set out "E:/TEMP/Claude/MSXMAKER/unapi/result2.txt"
set tries 0
proc rd {a} { return [debug read memory $a] }
proc check {} {
    global out tries
    incr tries
    if {[rd 0xDE00] == 0x55 || $tries > 400} {
        set f [open $out w]
        puts $f "done=[format %02X [rd 0xDE00]] tries=$tries count=[rd 0xDE01] caps=[format %02X [rd 0xDE02]]"
        puts $f "dns_ip=[rd 0xDE04].[rd 0xDE05].[rd 0xDE06].[rd 0xDE07] dnsbad_err=[rd 0xDE08] dnsbad_B=[rd 0xDE1B]"
        puts $f "udp conn=[rd 0xDE10] open_err=[rd 0xDE1C] send_err=[rd 0xDE11] rcv_err=[rd 0xDE12] len=[rd 0xDE13] dupopen_err=[rd 0xDE1A] close_err=[rd 0xDE1D]"
        puts $f "src=[rd 0xDE14].[rd 0xDE15].[rd 0xDE16].[rd 0xDE17] port=[expr {[rd 0xDE18] + 256*[rd 0xDE19]}]"
        close $f
        after time 1 { screenshot "E:/TEMP/Claude/MSXMAKER/unapi/shot2.png" }
        after time 3 exit
        return
    }
    after time 1 check
}
after time 1 check
