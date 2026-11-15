; pingtest.asm - ROM 16K MSX2 : prova bridge openMSX UnapiNet (porte 28h/29h)
; 1) PING bridge  2) IP locale  3) ICMP echo verso TARGET_IP
        output "pingtest.rom"

IO_CMD   equ 0x28
IO_DATA  equ 0x29
CMD_PING equ 0x00
CMD_LOCALIP equ 0x0D
CMD_NETSTATE equ 0x0E
CMD_ICMP_SEND equ 0x11
CMD_ICMP_RECV equ 0x12

CHPUT    equ 0x00A2
INITXT   equ 0x006C
LINL40   equ 0xF3AE

; area risultati in RAM (pagina 3) per il test Tcl
R_PING   equ 0xC000     ; byte risposta PING (atteso 55)
R_IP     equ 0xC001     ; 4 byte IP locale
R_NET    equ 0xC005     ; stato rete
R_SEND   equ 0xC006     ; stato ICMP_SEND
R_GOT    equ 0xC007     ; 1 = risposta ricevuta
R_REPLY  equ 0xC008     ; 11 byte: IP4 TTL ID2 SEQ2 LEN2
R_FRAMES equ 0xC014     ; frame attesi (16 bit)
R_DONE   equ 0xC020     ; 0x55 a fine test

        org 0x4000
        db "AB"
        dw start, 0, 0, 0, 0, 0, 0

start:  di
        ld sp,0xF380
        ld a,40
        ld (LINL40),a
        call INITXT
        ei
        xor a
        ld (R_DONE),a
        ld hl,msg_title
        call prints

        ; --- 1) PING del bridge ---
        ld hl,msg_ping
        call prints
        ld a,CMD_PING
        out (IO_CMD),a
        in a,(IO_DATA)          ; byte di stato (00 = ok)
        ld b,a
        in a,(IO_DATA)          ; magic
        ld (R_PING),a
        call printhex
        cp 0x55
        ld hl,msg_ko
        jr nz,.p1
        ld a,b
        or a
        ld hl,msg_ko
        jr nz,.p1
        ld hl,msg_ok
        jr z,.p1
        ld hl,msg_ko
.p1:    call prints

        ; --- 2) IP locale ---
        ld hl,msg_ip
        call prints
        ld a,CMD_LOCALIP
        out (IO_CMD),a
        in a,(IO_DATA)          ; stato
        ld hl,R_IP
        ld b,4
.rd:    in a,(IO_DATA)
        ld (hl),a
        inc hl
        djnz .rd
        ld hl,R_IP
        call printip
        call crlf

        ; --- stato rete ---
        ld hl,msg_net
        call prints
        ld a,CMD_NETSTATE
        out (IO_CMD),a
        in a,(IO_DATA)          ; stato
        in a,(IO_DATA)
        ld (R_NET),a
        call printhex
        call crlf

        ; --- 3) ICMP echo ---
        ld hl,msg_tgt
        call prints
        ld hl,TARGET_IP
        call printip
        call crlf
        ld hl,TARGET_IP
        ld b,4
.wi:    ld a,(hl)
        out (IO_DATA),a
        inc hl
        djnz .wi
        ld a,64                 ; TTL
        out (IO_DATA),a
        ld a,0x34               ; ID = 0x1234 LE
        out (IO_DATA),a
        ld a,0x12
        out (IO_DATA),a
        ld a,1                  ; SEQ = 1 LE
        out (IO_DATA),a
        xor a
        out (IO_DATA),a
        ld a,32                 ; LEN = 32 LE
        out (IO_DATA),a
        xor a
        out (IO_DATA),a
        ld a,CMD_ICMP_SEND
        out (IO_CMD),a
        in a,(IO_DATA)
        ld (R_SEND),a
        ld hl,msg_send
        call prints
        ld a,(R_SEND)
        call printhex
        call crlf

        ; --- attesa risposta: max 600 frame (~12 s) ---
        ld de,0
        ld (R_FRAMES),de
.poll:  ld a,CMD_ICMP_RECV
        out (IO_CMD),a
        in a,(IO_DATA)          ; 00 = risposta presente, 03 = niente
        or a
        jr z,.got
        halt
        inc de
        ld (R_FRAMES),de
        ld a,d
        cp 600/256
        jr c,.poll
        ld a,e
        cp 600&255
        jr c,.poll
        ld hl,msg_timeout
        call prints
        jr .fin
.got:   ld a,1
        ld (R_GOT),a
        ld hl,R_REPLY
        ld b,11
.rr:    in a,(IO_DATA)
        ld (hl),a
        inc hl
        djnz .rr
        ld hl,msg_reply
        call prints
        ld hl,R_REPLY
        call printip
        ld hl,msg_ttl
        call prints
        ld a,(R_REPLY+4)
        call printdec
        ld hl,msg_frm
        call prints
        ld hl,(R_FRAMES)
        ld a,l                  ; (solo byte basso, RTT breve)
        call printdec
        call crlf
.fin:   ld a,0x55
        ld (R_DONE),a
        ld hl,msg_end
        call prints
.hang:  halt
        jr .hang

; ---------- utilita ----------
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

printhex:                       ; A -> 2 cifre hex (A preservato)
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

printdec:                       ; A -> decimale senza zeri iniziali
        push bc
        ld c,0                  ; flag cifra stampata
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

printip:                        ; HL -> a.b.c.d
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

TARGET_IP: db 8,8,8,8

msg_title: db "openMSX UnapiNet - ping test",13,10,13,10,0
msg_ping:  db "Bridge PING (atteso 55): ",0
msg_ok:    db "  OK",13,10,0
msg_ko:    db "  ERRORE: bridge assente",13,10,0
msg_ip:    db "IP locale: ",0
msg_net:   db "Stato rete: ",0
msg_tgt:   db "Ping verso ",0
msg_send:  db "ICMP_SEND stato: ",0
msg_reply: db "Risposta da ",0
msg_ttl:   db "  TTL=",0
msg_frm:   db "  frame=",0
msg_timeout: db "TIMEOUT: nessuna risposta",13,10,0
msg_end:   db 13,10,"Fine test.",0
        ds 0x8000-$,0xFF
