; probe2.asm - dump grezzo di DNS e UDP del bridge UnapiNet (openMSX 22), 32 byte per slot
        output "probe2.rom"
IO_CMD  equ 0x28
IO_DATA equ 0x29
BUF     equ 0xC100
DONE    equ 0xC0FF
        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0
start:  di
        ld sp,0xF380
        ei
        xor a
        ld (DONE),a
        ld hl,BUF
        ; slot0: DNS_QUERY "dns.google"
        push hl
        xor a
        out (IO_DATA),a          ; ipotesi: byte di flag prima del nome
        ld hl,dnsname
.d:     ld a,(hl)
        out (IO_DATA),a
        inc hl
        or a
        jr nz,.d
        pop hl
        ld a,0x01
        call rawcmd
        ; slot1..6: DNS_STATUS ogni 20 frame
        ld c,6
.ds:    push bc
        ld b,20
.dh:    halt
        djnz .dh
        pop bc
        ld a,0x02
        call rawcmd
        dec c
        jr nz,.ds
        ; slot7: UDP_OPEN porta locale 5000 (LE)
        ld a,0x88
        out (IO_DATA),a
        ld a,0x13
        out (IO_DATA),a
        ld a,0x09
        call rawcmd
        ; handle = secondo byte della risposta (slot7+1)
        ld a,(BUF+7*32+1)
        ld (0xC0FE),a
        ; slot8: UDP_SEND handle, IP 127.0.0.1, porta 9000 (LE 28 23), len 5, "HELLO"
        push hl
        ld hl,udpsend
        ld de,udpsend_end
        ; handle va per primo
        ld a,(0xC0FE)
        out (IO_DATA),a
.u:     ld a,(hl)
        out (IO_DATA),a
        inc hl
        or a
        sbc hl,de
        add hl,de
        jr nz,.u
        pop hl
        ld a,0x0C
        call rawcmd
        ; slot9..14: UDP_STATE ogni 10 frame
        ld c,6
.us:    push bc
        ld b,10
.uh:    halt
        djnz .uh
        pop bc
        ld a,(0xC0FE)
        out (IO_DATA),a
        ld a,0x0B
        call rawcmd
        dec c
        jr nz,.us
        ; slot15: UDP_RECV handle, maxlen 64
        ld a,(0xC0FE)
        out (IO_DATA),a
        ld a,64
        out (IO_DATA),a
        xor a
        out (IO_DATA),a
        ld a,0x0F
        call rawcmd
        ; slot16: UDP_CLOSE
        ld a,(0xC0FE)
        out (IO_DATA),a
        ld a,0x0A
        call rawcmd
        ld a,0x55
        ld (DONE),a
.hang:  halt
        jr .hang

rawcmd: out (IO_CMD),a
        ld b,32
.r:     in a,(IO_DATA)
        ld (hl),a
        inc hl
        djnz .r
        ret
dnsname: db "dns.google",0
udpsend: db 127,0,0,1, 0x28,0x23, 5,0, "HELLO"
udpsend_end:
        ds 0xC000-$,0xFF
