; irq.asm - HUD fermo con l'interruzione di linea del V9958 (livelli alti). Vive nel segmento 3 (come hud.asm).
; Lo scorrimento hardware R#26/R#27 vale per tutto lo schermo: invece di ricopiare le due fasce ruotate della camera a ogni
; fotogramma (2 KB di HMMM, ~20% del tempo), la ISR (IM 2, due volte per fotogramma) porta lo scroll a 0 sulle righe
; dell'HUD e lo rimette alla camera sulle righe di gioco. Solo la IRQ di linea e' attiva (IE0 spento: il vblank resta a polling).
;
; Atomicita' sulla porta 0x99: ogni coppia di byte (registro, indirizzo) del codice normale sta fra DI e `call vei`
; (editor.asm). L'unica eccezione sono i frame compilati degli sprite (centinaia di coppie): la ISR riconosce dal PC
; interrotto se e' in mezzo a una coppia e, dopo aver finito, rimanda il primo byte (E) per ripristinarla.

RG0SAV  equ 0xF3DF
ISRADR  equ 0xEDED              ; indirizzo del gestore = valore di ogni byte della tabella (0xED) x2
ISRTAB  equ 0xEC00              ; 257 byte di vettori: I = 0xEC
LTOP    equ 7                   ; R#19: IRQ all'inizio della riga 8 (fine HUD alto)
LBOT    equ 183                 ; IRQ all'inizio della riga 184 (inizio HUD basso)

irq_start_i:
        di
        ld hl,ISRTAB
        ld de,ISRTAB+1
        ld bc,256
        ld (hl),0xED
        ldir
        ld hl,isr_rom
        ld de,ISRADR
        ld bc,isr_end-isr_rom
        ldir
        xor a
        ld (isr_st),a
        ld (isr_c26),a
        ld (isr_c27),a
        ld (sw_inframe),a
        ld a,LTOP
        ld (isr_l1),a
        ld a,LBOT
        ld (isr_l2),a
        ld a,LTOP
        ld e,19
        call wrreg
        ld a,(RG1SAV)           ; IE0 spento: il vblank non genera interrupt (resta il polling di S#0)
        ld (isr_r1),a
        and 0xDF
        ld (RG1SAV),a
        ld e,1
        call wrreg
        ld a,(RG0SAV)           ; IE1 acceso: interrupt di linea
        or 0x10
        ld e,0
        call wrreg
        ld a,ISRTAB>>8
        ld i,a
        im 2
        ld a,1
        ld (irq_on),a
        jp vei

irq_stop_i:
        ld a,(irq_on)
        or a
        ret z
        di
        xor a
        ld (irq_on),a
        im 1
        ld a,(RG0SAV)
        ld e,0
        call wrreg
        ld a,(isr_r1)
        ld (RG1SAV),a
        ld e,1
        call wrreg
        ld a,1                  ; azzera il flag FH ancora pendente (S#1)
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        in a,(0x99)
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        ret

; HL = camera (px) -> C = R#27 = (8 - cam%8) % 8, B = R#26 = ((cam%256) + 7) / 8
irq_regs:
        ld a,l
        and 7
        ld b,a
        ld a,8
        sub b
        and 7
        ld c,a
        ld h,0
        ld de,7
        add hl,de
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld b,l
        ret

; ---- il gestore: copiato in RAM a ISRADR (solo salti relativi e indirizzi assoluti)
isr_rom:
        push af
        push hl
        xor a
        ld (isr_mp),a
        ld a,(sw_inframe)
        or a
        jr z,isr_c
        ld hl,4                 ; PC interrotto: SP+4 (HL, AF, poi l'indirizzo di ritorno)
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld a,(hl)               ; prossima istruzione: ld a,d / adc a,0 / ld d,a = siamo fra i due out della coppia
        cp 0x7A
        jr z,isr_m
        cp 0xCE
        jr z,isr_m
        cp 0x57
        jr z,isr_m
        cp 0xD3                 ; out (0x99),a preceduto da ld d,a: e' il secondo
        jr nz,isr_c
        dec hl
        ld a,(hl)
        cp 0x57
        jr nz,isr_c
isr_m:  ld a,1
        ld (isr_mp),a
        in a,(0x99)             ; il primo byte e' in sospeso: leggere lo stato azzera il latch (ma consuma il flag di vblank: lo si ricorda)
        and 0x80
        ld hl,isr_vb
        or (hl)
        ld (hl),a
isr_c:  ld a,1                  ; S#1: azzera il flag FH (spegne la richiesta)
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        in a,(0x99)
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        ld a,(isr_st)
        or a
        jr nz,isr_b
        ld a,(isr_c27)          ; riga alta raggiunta: scroll della camera
        out (0x99),a
        ld a,0x9B
        out (0x99),a
        ld a,(isr_c26)
        out (0x99),a
        ld a,0x9A
        out (0x99),a
        ld a,(isr_l2)
        out (0x99),a
        ld a,0x93
        out (0x99),a
        ld a,1
        ld (isr_st),a
        jr isr_x
isr_b:  xor a                   ; riga bassa raggiunta: scroll 0 (HUD fermo)
        out (0x99),a
        ld a,0x9B
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x9A
        out (0x99),a
        ld a,(isr_l1)
        out (0x99),a
        ld a,0x93
        out (0x99),a
        xor a
        ld (isr_st),a
isr_x:  ld a,(isr_mp)
        or a
        jr z,isr_e
        ld a,e                  ; coppia interrotta: si rimanda il primo byte (E: lo stesso gia' inviato)
        out (0x99),a
isr_e:  pop hl
        pop af
        ei
        reti
isr_end:
