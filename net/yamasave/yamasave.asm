; yamasave.asm - test salvataggio su flash Yamanooto (S29GL064N, settori da 64K)
; ROM 256K: seg0 = codice, seg 24..31 = settore riservato ai dati (parte a FF).
; Area dati = LOG di record da 64 byte: si aggiunge in coda (programmazione), il
; settore viene cancellato solo quando e' pieno. Qui il "pieno" e' simulato a TESTLIMIT
; record per esercitare anche l'erase. I valori sono segnaposto, NON credenziali vere.
;
; Sequenza AMD (WREN=1 in ENAR): AA@xAAA 55@x555 A0@xAAA dato@indirizzo (program)
;                                AA 55 80 AA 55 30@settore (sector erase)
; Con WREN=1 le scritture NON cambiano banco: mappare il settore PRIMA.
        output "yamasave.rom"
CHPUT    equ 0x00A2
INITXT   equ 0x006C
ENASLT   equ 0x0024
LINL40   equ 0xF3AE
EXPTBL   equ 0xFCC1
SLTTBL   equ 0xFCC5
V        equ 0xDE00
RECBUF   equ 0xDD00
SAVSEG   equ 24
TESTLIMIT equ 3
ENAR     equ 0x7FFF

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
        ld (V+0x32),a
        ld (V+0x33),a
        ld (V+0x36),a
        ld hl,msg_title
        call prints
        call getslot
        ld h,0x80
        call ENASLT
        ei
        ; --- 1) cerca l'ultimo record valido ---
        call scan                ; V+0x30 = ultimo valido (FF=nessuno), V+0x31 = primo libero
        ld hl,msg_prev
        call prints
        ld a,(V+0x30)
        cp 0xFF
        jr nz,.have
        ld hl,msg_none
        call prints
        jr .build
.have:  call showrec             ; stampa il record trovato
        ; --- 2) costruisce il nuovo record ---
.build: call buildrec
        ; --- 3) slot di scrittura ---
        ld a,(V+0x31)
        cp TESTLIMIT
        jr c,.write
        ld hl,msg_full
        call prints
        call flash_erase
        ld a,1
        ld (V+0x36),a
        xor a
        ld (V+0x31),a
.write: ld a,(V+0x31)
        ld (V+0x37),a
        call program_rec
        call verify_rec
        ld a,(V+0x33)
        or a
        ld hl,msg_ok
        jr nz,.pm
        ld hl,msg_ko
.pm:    call prints
        ld a,0x55
        ld (V),a
.h:     halt
        jr .h

; ---- bank Konami5 ----
setbank_a: ld (0x5000),a
        ret

; ---- ricerca nel log ----
scan:   ld a,SAVSEG
        call setbank_a
        ld hl,0x4000
        ld b,0                   ; indice
        ld c,0xFF                ; ultimo valido
.s1:    ld a,b
        cp TESTLIMIT
        jr nc,.end
        ld a,(hl)
        cp 0xFF
        jr z,.end
        cp 'N'
        jr nz,.next
        push hl
        push bc
        call crc_ok
        pop bc
        pop hl
        jr nz,.next
        ld c,b
.next:  ld de,64
        add hl,de
        inc b
        jr .s1
.end:   ld a,b
        ld (V+0x31),a
        ld a,c
        ld (V+0x30),a
        ret

crc_ok: ld b,64                  ; somma di tutti i 64 byte == 0 ?
        xor a
.l:     add a,(hl)
        inc hl
        djnz .l
        or a
        ret

recaddr:                         ; A = indice -> HL = 0x4000 + A*64
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,0x4000
        add hl,de
        ret

showrec: ld a,(V+0x30)
        call recaddr
        push hl
        ld hl,msg_seq
        call prints
        pop hl
        push hl
        inc hl
        inc hl
        ld a,(hl)                ; seq lo
        call printdec
        call crlf
        pop hl
        push hl
        ld de,10
        add hl,de                ; host
        call prints
        call crlf
        pop hl
        ld de,36
        add hl,de                ; user
        call prints
        call crlf
        ret

; ---- compone il record nuovo in RECBUF ----
buildrec:
        ld a,(V+0x30)
        cp 0xFF
        jr z,.def
        call recaddr
        ld de,RECBUF
        ld bc,64
        ldir
        ld hl,RECBUF+2
        inc (hl)                 ; seq++ (basta il byte basso nel test)
        jr .crc
.def:   ld hl,defrec
        ld de,RECBUF
        ld bc,64
        ldir
.crc:   ld hl,RECBUF
        ld b,63
        xor a
.c:     add a,(hl)
        inc hl
        djnz .c
        neg
        ld (RECBUF+63),a
        ld a,(RECBUF+2)
        ld (V+0x34),a
        ret

; ---- scrive RECBUF nello slot V+0x31 (finestra A = settore) ----
program_rec:
        ld a,SAVSEG
        call setbank_a
        ld a,(V+0x31)
        call recaddr             ; HL = destinazione
        ld de,RECBUF
        ld b,64
.p:     ld a,(de)
        cp 0xFF
        jr z,.skip
        push bc
        push de
        call flash_prog          ; HL = indirizzo, A = dato
        pop de
        pop bc
        jr nc,.skip
        ld a,1
        ld (V+0x32),a            ; errore di programmazione
.skip:  inc hl
        inc de
        djnz .p
        ret

verify_rec:
        ld a,(V+0x31)
        call recaddr
        ld de,RECBUF
        ld b,64
.v:     ld a,(de)
        cp (hl)
        jr nz,.bad
        inc hl
        inc de
        djnz .v
        ld a,1
        ld (V+0x33),a
        ret
.bad:   xor a
        ld (V+0x33),a
        ret

; ---- flash: HL = indirizzo 0x4xxx (finestra A mappata), A = dato; CF=1 se timeout ----
flash_prog:
        di
        ld c,a
        ld a,0x10
        ld (ENAR),a              ; WREN
        ld a,0xAA
        ld (0x4AAA),a
        ld a,0x55
        ld (0x4555),a
        ld a,0xA0
        ld (0x4AAA),a
        ld (hl),c
        ld de,0
.w:     ld a,(hl)
        cp c
        jr z,.ok
        dec de
        ld a,d
        or e
        jr nz,.w
        xor a
        ld (ENAR),a
        ei
        scf
        ret
.ok:    xor a
        ld (ENAR),a
        ei
        or a                     ; CF=0
        ret

; ---- erase del settore mappato in finestra A ----
flash_erase:
        ld a,SAVSEG
        call setbank_a
        di
        ld a,0x10
        ld (ENAR),a
        ld a,0xAA
        ld (0x4AAA),a
        ld a,0x55
        ld (0x4555),a
        ld a,0x80
        ld (0x4AAA),a
        ld a,0xAA
        ld (0x4AAA),a
        ld a,0x55
        ld (0x4555),a
        ld a,0x30
        ld (0x4000),a
        ld b,32                  ; ~ pazienza per 64K erase su hardware vero
.o:     ld de,0
.e:     ld a,(0x4000)
        cp 0xFF
        jr z,.done
        dec de
        ld a,d
        or e
        jr nz,.e
        djnz .o
        ld a,2
        ld (V+0x32),a            ; timeout erase
.done:  xor a
        ld (ENAR),a
        ei
        ret

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

; record di default (64 byte): 'N','S', seq, ...
defrec: db "NS",0,0             ; 0-3 magic + seq
        db 0                    ; 4 modo IP (0 = DHCP)
        db 0,0,0,0,0            ; 5-9 IP statico + riserva
        db "levels.example.org" ; 10.. host[24]
        ds 24-18,0
        dw 8080                 ; 34 porta
        db "testuser"           ; 36.. utente[12]
        ds 12-8,0
        db "TESTKEY-0123456"    ; 48.. chiave[15]
        db 0                    ; 63 crc (ricalcolato)
bk_pad:
msg_title: db "Yamanooto: salvataggio flash",13,10,0
msg_prev:  db "Record precedente: ",0
msg_none:  db "nessuno (area vuota)",13,10,0
msg_seq:   db "seq=",0
msg_full:  db "Log pieno: erase settore",13,10,0
msg_ok:    db "Scrittura verificata: OK",13,10,0
msg_ko:    db "Scrittura: ERRORE",13,10,0
cl_end:
        ent
        ds 0x6000-$,0xFF

; ---- segmenti 1..31: tutti a FF (24..31 = settore dati) ----
        ds 0x40000-0x2000,0xFF
