; probe3.asm - quale formato di parametri accetta DNS_QUERY (01) del bridge openMSX 22?
        output "probe3.rom"
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
        ld ix,variants
        ld c,(variants_end-variants)/2
.v:     push bc
        ld e,(ix+0)
        ld d,(ix+1)              ; DE = descrittore variante
        inc ix
        inc ix
        call sendvar
        ld a,0x01
        call rawcmd              ; risposta a DNS_QUERY
        ld b,100                 ; attendi 100 frame: la risoluzione e' asincrona
.w:     halt
        djnz .w
        ld a,0x02
        call rawcmd              ; DNS_STATUS
        pop bc
        dec c
        jr nz,.v
        ld a,0x55
        ld (DONE),a
.hang:  halt
        jr .hang

; descrittore: lunghezza dati, poi i byte da inviare su 0x29
sendvar: ex de,hl
        push de                  ; salva puntatore buffer (era HL)
        ld b,(hl)
        inc hl
.s:     ld a,(hl)
        out (IO_DATA),a
        inc hl
        djnz .s
        pop hl
        ret

rawcmd: out (IO_CMD),a
        ld b,16
.r:     in a,(IO_DATA)
        ld (hl),a
        inc hl
        djnz .r
        ret

variants:
        dw va,vb,vc,vd,ve,vf
variants_end:
va:     db 10,"dns.google"                   ; nome senza terminatore
vb:     db 11,10,"dns.google"                ; lunghezza + nome
vc:     db 12,10,"dns.google",0              ; lunghezza + nome + NUL
vd:     db 12,0,10,"dns.google"              ; flag 0 + lunghezza + nome
ve:     db 12,"dns.google",0,0               ; nome + NUL + flag 0
vf:     db 8,"8.8.8.8",0                     ; IP letterale
        ds 0xC000-$,0xFF
