; client.asm - ROM 16K: client UNAPI TCP/IP generico (nessun accesso diretto alle porte).
; Il codice reale gira in RAM pagina 3 (0xC000): CALSLT non puo' cambiare lo slot
; della pagina 1 se il chiamante sta li'.
        output "client.rom"
CHPUT    equ 0x00A2
INITXT   equ 0x006C
RDSLT    equ 0x000C
CALSLT   equ 0x001C
LINL40   equ 0xF3AE
EXTBIO   equ 0xFFCA
ARG      equ 0xF847
V        equ 0xDE00          ; risultati per il test Tcl
; V+0 done 0x55, +1 count, +2 slot, +3 netstate, +4..7 IP, +8 err send, +9 err rcv
; V+10..20 blocco echo, +0x16/17 frame
BLK      equ V+10

        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0
start:  ld hl,payload
        ld de,0xC000
        ld bc,cl_end-0xC000
        ldir
        jp 0xC000
payload:
        disp 0xC000
main:   di
        ld sp,0xF380
        ld a,40
        ld (LINL40),a
        call INITXT
        ei
        xor a
        ld (V),a
        ld hl,msg_title
        call prints

        ; --- scoperta: conta le implementazioni "TCP/IP" ---
        call setarg
        xor a
        ld b,a
        ld de,0x2222
        call EXTBIO
        ld a,b
        ld (V+1),a
        ld hl,msg_cnt
        call prints
        ld a,(V+1)
        call printdec
        call crlf
        ld a,(V+1)
        or a
        jr nz,.have
        ld hl,msg_none
        call prints
        jp fin
.have:  call setarg
        ld a,1
        ld de,0x2222
        call EXTBIO
        ld (u_slotw+1),a
        ld (V+2),a
        ld (u_entry),hl
        ld a,b
        cp 0xFF
        jr z,.rom
        ld hl,msg_ram
        call prints
        jp fin
.rom:   ld hl,msg_slot
        call prints
        ld a,(u_slotw+1)
        call printhex
        call crlf

        ; --- UNAPI_GET_INFO: nome dell'implementazione ---
        xor a
        call ucall
        call pname
        call crlf

        ; --- NET_STATE ---
        ld a,3
        call ucall
        ld a,b
        ld (V+3),a
        ld hl,msg_net
        call prints
        ld a,(V+3)
        call printhex
        call crlf

        ; --- GET_IPINFO(1) ---
        ld a,2
        ld b,1
        call ucall
        ld a,l
        ld (V+4),a
        ld a,h
        ld (V+5),a
        ld a,e
        ld (V+6),a
        ld a,d
        ld (V+7),a
        ld hl,msg_ip
        call prints
        ld hl,V+4
        call printip
        call crlf

        ; --- SEND_ECHO verso TARGET ---
        ld hl,msg_tgt
        call prints
        ld hl,target
        call printip
        call crlf
        ld hl,target            ; blocco: IP[4] TTL ID[2] SEQ[2] LEN[2]
        ld de,BLK
        ld bc,4
        ldir
        ld hl,echo_tail
        ld bc,7
        ldir
        ld hl,BLK
        ld a,4
        call ucall
        ld (V+8),a
        ld hl,msg_send
        call prints
        ld a,(V+8)
        call printhex
        call crlf

        ; --- RCV_ECHO a polling, max 600 frame ---
        ld de,0
        ld (V+0x16),de
.poll:  push de
        ld hl,BLK
        ld a,5
        call ucall
        pop de
        ld (V+9),a
        or a
        jr z,.got
        halt
        inc de
        ld (V+0x16),de
        ld a,d
        cp 600/256
        jr c,.poll
        ld a,e
        cp 600&255
        jr c,.poll
        ld hl,msg_to
        call prints
        jr fin
.got:   ld hl,msg_rep
        call prints
        ld hl,BLK
        call printip
        ld hl,msg_ttl
        call prints
        ld a,(BLK+4)
        call printdec
        ld hl,msg_frm
        call prints
        ld a,(V+0x16)
        call printdec
        call crlf
fin:    ld a,0x55
        ld (V),a
        ld hl,msg_end
        call prints
.h:     halt
        jr .h

setarg: ld hl,id_str
        ld de,ARG
        ld bc,7
        ldir
        ret

; chiamata UNAPI: A = funzione, altri registri come da spec
ucall:  push ix
        push iy
        ld ix,(u_entry)
        ld iy,(u_slotw)
        call CALSLT
        ei
        pop iy
        pop ix
        ret

pname:  push hl
        ld a,(u_slotw+1)
        call RDSLT
        ei
        pop hl
        inc hl
        or a
        ret z
        push hl
        call CHPUT
        pop hl
        jr pname

prints: ld a,(hl)
        inc hl
        or a
        ret z
        call CHPUT
        jr prints
crlf:   ld a,13
        call CHPUT
        ld a,10
        jp CHPUT
printhex:
        push af
        rrca
        rrca
        rrca
        rrca
        call .n
        pop af
        push af
        call .n
        pop af
        ret
.n:     and 0x0F
        add a,'0'
        cp '9'+1
        jr c,.o
        add a,7
.o:     jp CHPUT
printdec:
        push bc
        ld c,0
        ld b,100
        call .d
        ld b,10
        call .d
        add a,'0'
        call CHPUT
        pop bc
        ret
.d:     ld e,'0'-1
.l:     inc e
        sub b
        jr nc,.l
        add a,b
        ld d,a
        ld a,e
        cp '0'
        jr nz,.pr
        bit 0,c
        jr z,.skip
.pr:    set 0,c
        call CHPUT
.skip:  ld a,d
        ret
printip:
        ld b,4
.i:     ld a,(hl)
        inc hl
        push hl
        push bc
        call printdec
        pop bc
        pop hl
        dec b
        ret z
        push hl
        push bc
        ld a,'.'
        call CHPUT
        pop bc
        pop hl
        jr .i

u_slotw: dw 0
u_entry: dw 0
id_str:  db "TCP/IP",0
target:  db 8,8,8,8
echo_tail: db 64, 0x34,0x12, 1,0, 32,0
msg_title: db "Client UNAPI TCP/IP (solo UNAPI)",13,10,13,10,0
msg_cnt:   db "Implementazioni TCP/IP: ",0
msg_none:  db "Nessuna implementazione trovata",13,10,0
msg_ram:   db "Implementazione in RAM: serve l'helper",13,10,0
msg_slot:  db "Slot: ",0
msg_net:   db "Stato rete: ",0
msg_ip:    db "IP locale: ",0
msg_tgt:   db "Ping verso ",0
msg_send:  db "SEND_ECHO errore: ",0
msg_rep:   db "Risposta da ",0
msg_ttl:   db "  TTL=",0
msg_frm:   db "  frame=",0
msg_to:    db "TIMEOUT",13,10,0
msg_end:   db 13,10,"Fine.",0
cl_end:
        ent
        ds 0xC000-$,0xFF
