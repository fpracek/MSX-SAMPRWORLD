# nemici: pattuglia, schiacciamento, contatto letale, ripristino della mappa a fine prova
cartb E:/TEMP/Claude/SAMPRWORLD/repo/editor/editor_test.rom -romtype Yamanooto
reset
set R E:/TEMP/Claude/SAMPRWORLD/repo/editor/tests
proc rd {a} { return [debug read memory [expr {$a}]] }
proc wr {a v} { debug write memory [expr {$a}] $v }
proc rd16 {a} { return [expr {[rd $a] + 256*[rd [expr {$a+1}]]}] }
proc wr16 {a v} { wr $a [expr {$v & 255}]; wr [expr {$a+1}] [expr {($v >> 8) & 255}] }
proc cell {col row t} { wr [expr {0xC000 + $row*128 + $col}] $t }
proc rcell {col row} { return [rd [expr {0xC000 + $row*128 + $col}]] }
proc ent {i} { set b [expr {0xCA00 + $i*8}]; return "t=[rd $b] x=[rd16 [expr {$b+1}]] y=[rd [expr {$b+3}]] dir=[rd [expr {$b+4}]]" }
set log [open "$R/enemy_result.txt" w]
proc L {s} { global log; puts $log $s; flush $log }
after time 18 {
    cell 1 10 35; cell 3 10 27; cell 6 10 51; cell 14 6 52
    cell 20 11 0; cell 21 11 0
    keymatrixdown 5 0x02
    after time 0.2 { keymatrixup 5 0x02 }
}
after time 20 { L "spawn: ent0(pipistrello) [ent 0] ent1(goblin) [ent 1] ent2 [ent 2] ne=[rd 0xC8EA]"; L "mappa durante la prova: goblin=[rcell 6 10] bat=[rcell 14 6] moneta=[rcell 3 10]" }
foreach t {20.5 21 21.5 22 22.5 23} { after time $t [list apply {{t} { L "t=$t pipistrello: [ent 0] goblin: [ent 1]" }} $t] }
# schiacciamento: eroe sopra il goblin che cade
after time 24 {
    set gx [rd16 0xCA01]; set gy [rd 0xCA03]
    wr16 0xC8A0 $gx; wr16 0xC8A5 [expr {$gy - 12}]; wr16 0xC8A8 0x0200
    L "teleport sul pipistrello x=$gx y=$gy"
}
after time 24.6 { L "dopo schiacciamento: pipistrello [ent 0] kills=[rd 0xC8E9] dead=[rd 0xC8B1]" }
after time 24.7 { wr16 0xC8A0 40; wr16 0xC8A5 160; wr16 0xC8A8 0 }
# contatto laterale col goblin: eroe nello stesso punto
after time 25 {
    set bx [rd16 0xCA09]; set by [rd 0xCA0B]
    wr16 0xC8A0 $bx; wr16 0xC8A5 $by; wr16 0xC8A8 0
    L "teleport sul goblin x=$bx y=$by tipo=[rd 0xCA08]"
}
foreach t {25.05 25.1 25.2 25.4 25.7} { after time $t [list apply {{t} { L "t=$t dead=[rd 0xC8B1] hero=[rd16 0xC8A0],[rd16 0xC8A5] vy=[rd16 0xC8A8] goblin=[ent 1]" }} $t] }
after time 27 { L "ripartenza: x=[rd16 0xC8A0] dead=[rd 0xC8B1]"; keymatrixdown 7 0x04 }
after time 27.3 { keymatrixup 7 0x04 }
after time 29 {
    L "fine prova: exit=[rd 0xC8BE] mappa: goblin=[rcell 6 10] bat=[rcell 14 6] moneta=[rcell 3 10] (attesi 51 52 27)"
    screenshot "$R/enemy_end.png"
    close $log; exit
}
after time 21.5 { screenshot "$R/enemy_mid.png" }
