; client2.asm - client UNAPI generico: capacita', DNS (ok + errore), UDP (echo con server locale)
; Nessun accesso diretto alle porte: solo EXTBIO + CALSLT. Codice in RAM pagina 3.
        output "client2.rom"
CHPUT    equ 0x00A2
INITXT   equ 0x006C
RDSLT    equ 0x000C
CALSLT   equ 0x001C
LINL40   equ 0xF3AE
EXTBIO   equ 0xFFCA
ARG      equ 0xF847
V        equ 0xDE00
BLK      equ V+0x40          ; blocco parametri UDP_SEND (8 byte)
RXBUF    equ V+0x60          ; buffer ricezione
; V+0 done, +1 count, +2 caps, +3/4 dns ip ok (4 byte V+4..7), +8 dns err2,
; +0x10 udp conn, +0x11 err send, +0x12 err rcv, +0x13 rcv len, +0x14..17 src ip, +0x18/19 port
; +0x1A err open dup, +0x1B dns B2, +0x1C open err, +0x1D close err

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
        ; --- scoperta ---
        call setarg
        xor a
        ld b,a
        ld de,0x2222
        call EXTBIO
        ld a,b
        ld (V+1),a
        or a
        jr nz,.have
        ld hl,msg_none
        call prints
        jp fin
.have:  call setarg
        ld a,1
        ld de,0x2222
        call EXTBIO
        ld (u_slotb),a
        ld (u_entry),hl
        ; --- capacita' blocco 1 ---
        ld a,1
        ld b,1
        call ucall
        ld a,l
        ld (V+2),a
        ld hl,msg_caps
        call prints
        ld a,(V+2)
        call printhex
        call crlf

        ; === DNS: nome valido ===
        ld hl,msg_dns1
        call prints
        ld hl,name_ok
        ld b,0
        ld a,6
        call ucall
        call dnswait            ; A = esito, V+4..7 = IP
        or a
        jr nz,.d1e
        ld hl,V+4
        call printip
        call crlf
        jr .d2
.d1e:   ld hl,msg_err
        call prints
        call printhex
        call crlf
        ; === DNS: nome inesistente ===
.d2:    ld hl,msg_dns2
        call prints
        ld hl,name_bad
        ld b,0
        ld a,6
        call ucall
        call dnswait
        ld (V+8),a
        ld a,b
        ld (V+0x1B),a
        ld a,(V+8)
        cp 8
        jr nz,.d2x
        ld hl,msg_dnserr
        call prints
        ld a,(V+0x1B)
        call printdec
        call crlf
        jr .u0
.d2x:   ld hl,msg_unexp
        call prints
        ld a,(V+8)
        call printhex
        call crlf

        ; === UDP: apri con porta casuale (FFFFh) ===
.u0:    ld hl,0xFFFF
        ld b,0
        ld a,8
        call ucall
        ld (V+0x1C),a
        ld a,b
        ld (V+0x10),a
        ld hl,msg_open
        call prints
        ld a,(V+0x1C)
        call printhex
        ld hl,msg_conn
        call prints
        ld a,(V+0x10)
        call printdec
        call crlf
        ; invio "HELLO" a 127.0.0.1:9000
        ld hl,dst
        ld de,BLK
        ld bc,8
        ldir
        ld a,(V+0x10)
        ld b,a
        ld hl,payload_str
        ld de,BLK
        ld a,11
        call ucall
        ld (V+0x11),a
        ld hl,msg_send
        call prints
        ld a,(V+0x11)
        call printhex
        call crlf
        ; attesa risposta (max 300 frame)
        ld de,0
.w:     push de
        ld a,(V+0x10)
        ld b,a
        ld a,10
        call ucall              ; UDP_STATE
        pop de
        ld a,b
        or a
        jr nz,.rx
        halt
        inc de
        ld a,d
        cp 300/256+1
        jr c,.w
        ld hl,msg_to
        call prints
        jr .ud
.rx:    ld a,(V+0x10)
        ld b,a
        ld hl,RXBUF
        ld de,0xFFFF
        ld a,12
        call ucall              ; UDP_RCV
        ld (V+0x12),a
        ld (V+0x14),hl          ; IP: L,H
        ld (V+0x16),de          ; IP: E,D
        push ix
        pop hl
        ld (V+0x18),hl          ; porta
        ld a,c
        ld (V+0x13),a
        ld hl,msg_rx
        call prints
        ld a,(V+0x13)
        call printdec
        ld hl,msg_bytes
        call prints
        ld a,(V+0x13)
        ld b,a
        ld hl,RXBUF
.pc:    ld a,b
        or a
        jr z,.pe
        ld a,(hl)
        call CHPUT
        inc hl
        dec b
        jr .pc
.pe:    ld hl,msg_from
        call prints
        ld hl,V+0x14
        call printip
        ld a,':'
        call CHPUT
        ld hl,(V+0x18)
        ld a,h
        cp 0x23
        jr nz,.pn
        ld a,l
        cp 0x28
        jr nz,.pn
        ld hl,msg_9000
        call prints
        jr .pnx
.pn:    ld hl,msg_unexp
        call prints
.pnx:   call crlf
        ; --- seconda connessione sulla stessa porta: atteso ERR_CONN_EXISTS (10) ---
.ud:    ld hl,5555
        ld b,0
        ld a,8
        call ucall
        ld a,b
        ld (V+0x1E),a           ; conn A
        ld hl,5555
        ld b,0
        ld a,8
        call ucall
        ld (V+0x1A),a
        ld hl,msg_dup
        call prints
        ld a,(V+0x1A)
        call printdec
        call crlf
        ; --- chiusura ---
        ld a,(V+0x10)
        ld b,a
        ld a,9
        call ucall
        ld (V+0x1D),a
        ld hl,msg_close
        call prints
        ld a,(V+0x1D)
        call printhex
        call crlf
fin:    ld a,0x55
        ld (V),a
        ld hl,msg_end
        call prints
.h:     halt
        jr .h

; attende il risultato DNS (max 300 frame). Uscita: A = errore, B = codice DNS, V+4..7 = IP
dnswait:
        ld de,0
.l:     push de
        ld b,0
        ld a,7
        call ucall
        ld (V+4),hl             ; IP (valido se B=2): L,H
        ld (V+6),de             ; E,D
        pop de
        or a
        ret nz                  ; ERR_DNS (8) o altro
        ld c,a
        ld a,b
        cp 2
        jr z,.ok
        halt
        inc de
        ld a,d
        cp 300/256+1
        jr c,.l
        ld a,0xFE               ; timeout locale
        ret
.ok:    xor a
        ret

setarg: ld hl,id_str
        ld de,ARG
        ld bc,7
        ldir
        ret
ucall:  rst 0x30                ; CALLF: chiamata inter-slot che conserva TUTTI i registri (IX incluso)
u_slotb: db 0
u_entry: dw 0
        ei                      ; CALLF lascia gli interrupt disabilitati
        ret
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

id_str:  db "TCP/IP",0
name_ok:  db "dns.google",0
name_bad: db "nonesiste.invalid",0
payload_str: db "HELLO",0
dst:     db 127,0,0,1, 0x28,0x23, 5,0
msg_title: db "Client2 UNAPI: DNS + UDP",13,10,13,10,0
msg_none:  db "Nessuna impl. UNAPI",13,10,0
msg_caps:  db "Capab (L): ",0
msg_dns1:  db "DNS dns.google -> ",0
msg_dns2:  db "DNS nonesiste.invalid -> ",0
msg_dnserr: db "ERR_DNS, codice ",0
msg_err:   db "errore ",0
msg_unexp: db "INATTESO ",0
msg_open:  db "UDP_OPEN(FFFF) err=",0
msg_conn:  db " conn=",0
msg_send:  db "UDP_SEND err=",0
msg_to:    db "UDP: TIMEOUT",13,10,0
msg_rx:    db "UDP_RCV: ",0
msg_bytes: db " byte: ",0
msg_from:  db " da ",0
msg_9000:  db "9000 (ok)",0
msg_dup:   db "2a UDP_OPEN(5555) err=",0
msg_close: db "UDP_CLOSE err=",0
msg_end:   db 13,10,"Fine.",0
cl_end:
        ent
        ds 0xC000-$,0xFF
