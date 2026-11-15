# client di rete in gioco: pubblica un livello, apre l'elenco (D), prova un livello non valido, scarica e gioca quello pubblicato
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc rcell {col row} { return [rd [expr {0xC000 + $row*128 + $col}]] }
proc tap {row mask} { keymatrixdown $row $mask; after time 0.25 [list keymatrixup $row $mask] }
set log [open "$R/browse_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
after time 18 { cell 1 10 35; cell 5 10 27; cell 24 9 33; cell 24 10 34 }
after time 19 { tap 5 0x08 }                       ;# V: valida (DEV)
after time 22 { tap 5 0x04 }                       ;# U: pubblica
after time 30 { L "dopo pubblicazione: valid=[rd 0xC896]"; screenshot "$R/b1_pub.png"; cell 60 3 5 }
after time 31 { tap 3 0x02 }                       ;# D: elenco
after time 38 { screenshot "$R/b2_list.png" }
after time 38.5 { tap 7 0x80 }                     ;# INVIO sul primo (livello di prova del server: formato non valido)
after time 44 { screenshot "$R/b3_bad.png" }
# naviga fino all'ultimo livello (il nostro, id piu' alto): pagina = (n-1)/6, riga = (n-1)%6
after time 44.5 {
    set f [open "E:/TEMP/Claude/SAMPRWORLD/repo/net/server/store/index.json" r]; set js [read $f]; close $f
    set n [llength [regexp -all -inline {"title"} $js]]
    set pg [expr {($n-1)/6}]; set sl [expr {($n-1)%6}]
    L "livelli sul server: $n -> pagina [expr {$pg+1}], riga [expr {$sl+1}]"
    set tt 0.0
    for {set i 0} {$i < $pg} {incr i} { after time [expr {$tt}] { tap 8 0x80 }; set tt [expr {$tt+6.0}] }
    for {set i 0} {$i < $sl} {incr i} { after time [expr {$tt}] { tap 8 0x40 }; set tt [expr {$tt+0.5}] }
    after time [expr {$tt+1.0}] { screenshot "E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests/b4_sel.png" }
    after time [expr {$tt+1.5}] { tap 7 0x80 }
}
after time 62 { L "in gioco: foreign=[rd 0xC8F9] x=[rd16 0xC8A0] map(5,10)=[rcell 5 10] map(60,3)=[rcell 60 3]"; screenshot "$R/b5_play.png"; keymatrixdown 8 0x80 }
set won 0
proc poll {} {
    global won
    set w [rd 0xC8B6]; set e [rd 0xC8BE]
    if {$w == 1 && $e == 1} { set won 1 }
    after time 0.2 poll
}
after time 62.5 poll
after time 80 { keymatrixup 8 0x80; L "vittoria nel livello scaricato: $won" }
after time 84 { L "editor ripristinato: map(60,3)=[rcell 60 3] (atteso 5) valid=[rd 0xC896] (atteso 0) foreign=[rd 0xC8F9]"; screenshot "$R/b6_back.png"; close $log; exit }
