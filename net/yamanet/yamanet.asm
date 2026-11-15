; yamanet.asm - test: ROM 128K su mapper Yamanooto (Konami5/SCC, segmenti da 8K)
; + rete UNAPI. Registri di banco: 5000h(A=4000) 7000h(B=6000) 9000h(C=8000) B000h(D=A000)
; Il codice comune (bank switch + chiamata UNAPI) sta in RAM 0xC000; il "gioco" in segmenti.
        output "yamanet.rom"
CHPUT    equ 0x00A2
INITXT   equ 0x006C
RDSLT    equ 0x000C
CALSLT   equ 0x001C
ENASLT   equ 0x0024
LINL40   equ 0xF3AE
EXTBIO   equ 0xFFCA
ARG      equ 0xF847
EXPTBL   equ 0xFCC1
SLTTBL   equ 0xFCC5
V        equ 0xDE00
BLK      equ V+10
; V+0 done 55, +1 count, +2 slot, +3 net, +4..7 ip, +8 errsend, +9 errrcv,
; +10..20 blocco, +0x16 frame(2), +0x20 errori banchi, +0x21 controlli, +0x24 slot pag.2

;================= SEGMENTO 0 (4000h): header + stub + codice comune ==============
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
        ld (V+0x20),a
        ld (V+0x21),a
        ld hl,msg_title
        call prints
        ; pagina 2 sullo stesso slot della cartuccia (pagina 1)
        call getslot
        ld (V+0x24),a
        ld h,0x80
        call ENASLT
        ei
        ; configurazione 1: A=10 B=11 C=12 D=13
        ld a,10
        call setbank_a
        ld a,11
        call setbank_b
        ld a,12
        call setbank_c
        ld a,13
        call setbank_d
        ld hl,msg_b1
        call prints
        call check_banks
        call 0x8010             ; codice in segmento 12 (finestra C)
        call 0xA010             ; codice in segmento 13 (finestra D)
        ; ping eseguito da codice che vive nel segmento 6
        ld a,6
        call setbank_c
        ld hl,msg_b2
        call prints
        call check_banks
        call 0x8010             ; net_test (segmento 6)
        ld hl,msg_b3
        call prints
        call check_banks        ; i banchi reggono dopo le chiamate UNAPI?
        ; configurazione 2: A=14 B=15 C=12
        ld a,14
        call setbank_a
        ld a,15
        call setbank_b
        ld a,12
        call setbank_c
        ld hl,msg_b4
        call prints
        call check_banks
        call 0x8010
        ld hl,msg_sum
        call prints
        ld a,(V+0x20)
        call printdec
        call crlf
        ld a,0x55
        ld (V),a
.h:     halt
        jr .h

; ---- bank switching Konami5 ----
setbank_a: ld (bk_a),a
        ld (0x5000),a
        ret
setbank_b: ld (bk_b),a
        ld (0x7000),a
        ret
setbank_c: ld (bk_c),a
        ld (0x9000),a
        ret
setbank_d: ld (bk_d),a
        ld (0xB000),a
        ret

; confronta primo e ultimo byte di ogni finestra col numero di segmento atteso
check_banks:
        ld b,0
        ld hl,0x4000
        ld a,(bk_a)
        call chk1
        ld hl,0x6000
        ld a,(bk_b)
        call chk1
        ld hl,0x8000
        ld a,(bk_c)
        call chk1
        ld hl,0xA000
        ld a,(bk_d)
        call chk1
        ld a,(V+0x21)
        inc a
        ld (V+0x21),a
        ld a,(V+0x20)
        add a,b
        ld (V+0x20),a
        ld a,b
        or a
        ld hl,msg_ok
        jr z,.p
        ld hl,msg_ko
.p:     jp prints
chk1:   ld c,a
        ld a,(hl)
        cp c
        jr z,.c1
        inc b
.c1:    ld de,0x1FFF
        add hl,de
        ld a,(hl)
        cp c
        ret z
        inc b
        ret

; slot id (formato ENASLT/CALSLT) della pagina 1
getslot:
        in a,(0xA8)
        rrca
        rrca
        and 3
        ld e,a
        ld d,0
        ld hl,EXPTBL
        add hl,de
        ld a,(hl)
        and 0x80
        jr z,.r
        ld hl,SLTTBL
        add hl,de
        ld a,(hl)
        and 0x0C
        or 0x80
        or e
        ret
.r:     ld a,e
        ret

setarg: ld hl,id_str
        ld de,ARG
        ld bc,7
        ldir
        ret

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

bk_a:    db 0
bk_b:    db 1
bk_c:    db 2
bk_d:    db 3
u_slotw: dw 0
u_entry: dw 0
id_str:  db "TCP/IP",0
msg_title: db "Yamanooto Konami5 + UNAPI",13,10,0
msg_b1:  db "Banchi 10/11/12/13: ",0
msg_b2:  db "C=seg6:             ",0
msg_b3:  db "Dopo UNAPI:         ",0
msg_b4:  db "Banchi 14/15/12:    ",0
msg_ok:  db "OK",13,10,0
msg_ko:  db "ERRORE",13,10,0
msg_sum: db "Errori banchi tot: ",0
cl_end:
        ent
        ds 0x6000-$,0xFF

;================= SEGMENTI ======================================================
; segmento di soli dati: primo e ultimo byte = numero di segmento
        macro SEGDATA n, base
        org base
        db n
        ds 0x2000-1,n
        endm

        SEGDATA 1,0x6000
        SEGDATA 2,0x8000
        SEGDATA 3,0xA000
        SEGDATA 4,0x4000
        SEGDATA 5,0x6000

; --- segmento 6 (finestra C): test di rete ---
        org 0x8000
        db 6
        ds 15,6
net_test:                       ; 0x8010
        call setarg
        xor a
        ld b,a
        ld de,0x2222
        call EXTBIO
        ld a,b
        ld (V+1),a
        ld hl,n_cnt
        call prints
        ld a,(V+1)
        call printdec
        call crlf
        ld a,(V+1)
        or a
        jr nz,.have
        ld hl,n_none
        jp prints
.have:  call setarg
        ld a,1
        ld de,0x2222
        call EXTBIO
        ld (u_slotw+1),a
        ld (V+2),a
        ld (u_entry),hl
        xor a
        call ucall
        call pname
        call crlf
        ld a,3
        call ucall
        ld a,b
        ld (V+3),a
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
        ld hl,n_ip
        call prints
        ld hl,V+4
        call printip
        call crlf
        ld hl,n_tgt
        ld de,BLK
        ld bc,4
        ldir
        ld hl,n_tail
        ld bc,7
        ldir
        ld hl,BLK
        ld a,4
        call ucall
        ld (V+8),a
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
        ld hl,n_to
        jp prints
.got:   ld hl,n_rep
        call prints
        ld hl,BLK
        call printip
        ld hl,n_ttl
        call prints
        ld a,(BLK+4)
        call printdec
        call crlf
        ret
n_tgt:  db 8,8,8,8
n_tail: db 64,0x34,0x12,1,0,32,0
n_cnt:  db "Impl. TCP/IP: ",0
n_none: db "Nessuna impl. UNAPI",13,10,0
n_ip:   db "IP locale: ",0
n_rep:  db "Ping 8.8.8.8: risposta da ",0
n_ttl:  db " TTL=",0
n_to:   db "Ping: TIMEOUT",13,10,0
        ds 0xA000-$,6

        SEGDATA 7,0x4000
        SEGDATA 8,0x6000
        SEGDATA 9,0x8000
        SEGDATA 10,0xA000
        SEGDATA 11,0x4000

; --- segmento 12 (finestra C): hello ---
        org 0x8000
        db 12
        ds 15,12
hello12: ld hl,h12              ; 0x8010
        call prints
        ret
h12:    db "  Codice da seg12 @8000h",13,10,0
        ds 0xA000-$,12

; --- segmento 13 (finestra D): hello ---
        org 0xA000
        db 13
        ds 15,13
hello13: ld hl,h13              ; 0xA010
        call prints
        ret
h13:    db "  Codice da seg13 @A000h",13,10,0
        ds 0xC000-$,13

        SEGDATA 14,0x4000
        SEGDATA 15,0x6000
