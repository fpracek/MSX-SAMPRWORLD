; misura la velocita' di HMMM a schermo intero (256x192 pagina 0 -> pagina 1) in openMSX
        output "bench.rom"
SPRMODE equ 2
CHGMOD equ 0x5F
JIFFY  equ 0xFC9E
        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0
start:  ld a,5
        call CHGMOD
        di
        IF SPRMODE==1
        ld a,0xEC
        ld e,5
        call wr
        ld hl,0x7600
        call vw_addr
        ld hl,sprs
        ld bc,0x1498
        otir
        ld hl,0x7800
        call vw_addr
        ld b,32
pl:     ld a,0xFF
        out (0x98),a
        djnz pl
        ld hl,0x7400
        call vw_addr
        ld a,15
        ld b,64
cl:     out (0x98),a
        djnz cl
        ENDIF
        IF SPRMODE==2
        ld a,0x0A
        ld e,8
        call wr
        ENDIF
        ei
        ld a,1
        ld (0xC003),a
        ld b,100
loop:   push bc
        ld hl,cmd
        call vdp_cmd
        pop bc
        djnz loop
        call vdp_wait
        ld hl,(JIFFY)
        ld de,(t0)
        or a
        sbc hl,de
        ld (0xC000),hl        ; tick (1/60 s o 1/50 s) per 100 copie
        ld a,0x55
        ld (0xC002),a
h:      jr h
wr:     out (0x99),a
        ld a,e
        or 0x80
        out (0x99),a
        ret
vw_addr: xor a
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        ld a,l
        out (0x99),a
        ld a,h
        and 0x3F
        or 0x40
        out (0x99),a
        ret
sprs:   db 80,16,0,0, 80,40,0,0, 80,64,0,0, 80,88,0,0, 216,0,0,0
vdp_wait:
        di
        ld a,2
        out (0x99),a
        ld a,0x8F
        out (0x99),a
vw:     in a,(0x99)
        rrca
        jr c,vw
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        ei
        ret
vdp_cmd:
        call vdp_wait
        di
        ld a,32
        out (0x99),a
        ld a,0x91
        out (0x99),a
        ld bc,0x0F9B
        otir
        ei
        ret
cmd:    db 0,0, 0,0, 0,0, 0,1, 0,1, 192,0, 0,0,0xD0   ; SX,SY=0  DX=0 DY=256  NX=256 NY=192  HMMM
t0:     dw 0
        ds 0xC000-$,0xFF
