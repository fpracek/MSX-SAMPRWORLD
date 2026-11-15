; probe.asm - dump grezzo delle risposte del bridge UnapiNet (openMSX 22)
        output "probe.rom"
IO_CMD equ 0x28
IO_DATA equ 0x29
BUF    equ 0xC100
DONE   equ 0xC0FF
        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0
start:  di
        ld sp,0xF380
        ei
        xor a
        ld (DONE),a
        ld hl,BUF
        ; slot0 PING
        ld a,0x00
        call rawcmd
        ; slot1 LOCALIP
        ld a,0x0D
        call rawcmd
        ; slot2 NET_STATE
        ld a,0x0E
        call rawcmd
        ; slot3 QUERY_CAP
        ld a,0x10
        call rawcmd
        ; slot4 ICMP_SEND 8.8.8.8 ttl64 id1234 seq1 len32
        push hl
        ld hl,icmp
        ld b,11
.w:     ld a,(hl)
        out (IO_DATA),a
        inc hl
        djnz .w
        pop hl
        ld a,0x11
        call rawcmd
        ; slot5.. ICMP_RECV x20, 10 frame di distanza
        ld c,20
.p:     push bc
        ld b,10
.h:     halt
        djnz .h
        pop bc
        ld a,0x12
        call rawcmd
        dec c
        jr nz,.p
        ld a,0x55
        ld (DONE),a
.hang:  halt
        jr .hang

rawcmd: out (IO_CMD),a
        ld b,16
.r:     in a,(IO_DATA)
        ld (hl),a
        inc hl
        djnz .r
        ret
icmp:   db 8,8,8,8,64,0x34,0x12,1,0,32,0
        ds 0x8000-$,0xFF
