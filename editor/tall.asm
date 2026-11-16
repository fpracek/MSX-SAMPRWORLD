; tall.asm - livelli ALTI (come l'originale Il Maniero: 512 px di altezza) con scorrimento verticale "a finestra"
; (segmento 3, finestra A000; gli ingressi in pagina 1 stanno in swspr.asm).
;
; Il livello alto sta intero in RAM (BIG: 32 righe x 64 colonne, una riga ogni 64 byte); il motore continua a lavorare su
; MAP = una finestra di 12 righe (192 px) copiata da BIG a partire dalla riga p_cr. Quando un eroe si avvicina al bordo alto
; o basso la finestra scorre di 6 righe: la finestra si riscrive in BIG (le monete prese restano prese), si ricarica MAP, si
; ribasano le y degli eroi/checkpoint/nemici e si ridisegna (sw_fill). I nemici che escono dalla finestra spariscono e
; ricompaiono, alla posizione di partenza, quando la loro riga rientra.
; Due giocatori: la finestra scorre solo se ENTRAMBI restano visibili; altrimenti chi sta andando verso il bordo e' bloccato
; (stessa regola della camera orizzontale di swcam.asm).
BIG     equ 0xD800              ; 2 KB: dopo REC (blob, max ~700 byte per i livelli alti) e prima di TXBUF (E000)
BIGW    equ 64
BIGH    equ 32
CRMAX   equ BIGH-MAPH           ; riga massima della finestra
WSTEP   equ 4                   ; righe per scorrimento
WUP     equ 80                  ; sopra questa y (top dell'eroe) la finestra sale: l'eroe resta nella meta' bassa dello schermo
; variabili: p_needk/p_cr/p_tall/p_tkey sono in swspr.asm
p_ncr   equ PXV+0x52
p_dlt   equ PXV+0x53            ; 2 byte: variazione delle y (px) dovuta allo scorrimento
p_ymin  equ PXV+0x55            ; 2 byte
p_ymax  equ PXV+0x57            ; 2 byte
p_nrd   equ PXV+0x59            ; 1 = non ridisegnare (chiamato da respawn)
p_ti    equ PXV+0x5A
p_tj    equ PXV+0x5B
p_tlo   equ PXV+0x5C
p_thi   equ PXV+0x5D

; ------------------------------------------------------------------------- decodifica del blob (h > 12)
tall_decode_i:
        ld a,(REC+24)           ; n_ent
        ld (ept_n),a
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        ld hl,REC+25
        or a
        jr z,td_ne
        ld de,EPT
        push bc
        ldir                    ; record dei nemici (riga = riga di BIG)
        pop bc
        jr td_go
td_ne:  add hl,bc
td_go:  ld de,BIG
        ld bc,BIGW*BIGH
td_lp:  ld a,(hl)
        inc hl
        bit 7,a
        jr nz,td_run
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr nz,td_lp
        jr td_san
td_run: and 0x7F
        ld (v_rt),a
        ld a,(hl)
        inc hl
        ld (v_rn),a
td_r2:  ld a,(v_rt)
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr z,td_san
        ld a,(v_rn)
        dec a
        ld (v_rn),a
        jr nz,td_r2
        jr td_lp
td_san: ld hl,BIG
        ld bc,BIGW*BIGH
td_s:   ld a,(hl)
        cp T_COUNT
        jr c,td_k
        ld (hl),0
td_k:   inc hl
        dec bc
        ld a,b
        or c
        jr nz,td_s
        ld a,1
        ld (p_tall),a
        xor a
        ld (p_nrd),a
        ld (p_cr),a
        ret

; ------------------------------------------------------------------------- avvio: finestra attorno alla partenza
tall_init_i:
        xor a
        ld (p_tkey),a
        ld hl,BIG               ; c'e' una chiave? (l'uscita funziona solo a chiave raccolta)
        ld bc,BIGW*BIGH
        ld a,T_KEY
        cpir
        jr nz,ti_nk
        ld a,1
        ld (p_tkey),a
ti_nk:  ld hl,BIG               ; riga del tile di partenza
        ld bc,BIGW*BIGH
        ld a,T_START
        cpir
        ld a,CRMAX
        jr nz,ti_cr
        dec hl
        ld de,BIG
        or a
        sbc hl,de               ; offset = riga*64 + colonna
        add hl,hl
        add hl,hl               ; *4: la riga sta in H (offset*4 >> 8 = offset >> 6)
        ld a,h
        sub 8                   ; la partenza sta nella parte bassa della finestra
        jr nc,ti_lo
        xor a
ti_lo:  cp CRMAX+1
        jr c,ti_cr
        ld a,CRMAX
ti_cr:  ld (p_cr),a
        jp win_load

; finestra p_cr: BIG -> MAP (le colonne 64..127 restano vuote)
win_load:
        ld a,(p_cr)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; riga * 64
        ld de,BIG
        add hl,de
        ld de,MAP
        ld b,MAPH
wl_r:   push bc
        ld bc,BIGW
        ldir
        push hl
        ld h,d
        ld l,e
        inc de
        ld (hl),0
        ld bc,BIGW-1
        ldir
        pop hl
        pop bc
        djnz wl_r
        ret

; MAP -> BIG: i marcatori dei nemici restano in BIG (in MAP sono gia' stati trasformati in entita')
win_save:
        ld a,(p_cr)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,BIG
        add hl,de
        ld de,MAP
        ld c,MAPH
ws_r:   ld b,BIGW
ws_c:   ld a,(hl)
        cp T_GOBLIN
        jr z,ws_k
        cp T_BAT
        jr z,ws_k
        ld a,(de)
        ld (hl),a
ws_k:   inc hl
        inc de
        djnz ws_c
        ex de,hl
        ld a,BIGW
        add a,l
        ld l,a
        jr nc,ws_n
        inc h
ws_n:   ex de,hl
        dec c
        jr nz,ws_r
        ret

; HL = indirizzo di una word: vi si somma p_dlt
win_adj:
        push de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl                ; HL = valore, DE = indirizzo+1
        push de
        ld de,(p_dlt)
        add hl,de
        pop de
        ex de,hl                ; HL = indirizzo+1, DE = nuovo valore
        ld (hl),d
        dec hl
        ld (hl),e
        pop de
        ret

; ------------------------------------------------------------------------- scorrimento: nuova riga della finestra in A
win_shift_i:
        ld (p_ncr),a
        call win_save
        ld a,(p_cr)
        ld c,a
        ld a,(p_ncr)
        ld b,a
        ld a,c
        sub b                   ; vecchia - nuova
        ld l,a
        sbc a,a
        ld h,a
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; * 16 px
        ld (p_dlt),hl
        ld hl,p_sy
        call win_adj
        ld hl,p_y               ; blocco attivo (con due giocatori e' una copia di uno dei due: HS e' gia' aggiornato)
        call win_adj
        ld hl,p_oy
        call win_adj
        ld a,(p_two)
        or a
        jr z,wsh_e
        ld hl,HS0+HO_Y
        call win_adj
        ld hl,HS0+HO_OY
        call win_adj
        ld hl,HS1+HO_Y
        call win_adj
        ld hl,HS1+HO_OY
        call win_adj
wsh_e:  ; nemici che restano nella finestra: y ribasata e slot compattati
        xor a
        ld (p_tj),a
        ld (p_ti),a
we_l:   ld a,(p_ti)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld ix,ENT
        add ix,de
        ld a,(ix+0)
        or a
        jr z,we_n
        ld e,(ix+3)
        ld d,0
        ld hl,(p_dlt)
        add hl,de
        bit 7,h
        jr nz,we_x
        ld a,h
        or a
        jr nz,we_x
        ld a,l
        cp 176
        jr nc,we_x
        ld (ix+3),a
        ld a,(p_dlt)
        add a,(ix+6)
        ld (ix+6),a
        ld a,(p_tj)
        ld b,a
        ld a,(p_ti)
        cp b
        jr z,we_k
        ld a,b                  ; sposta ENT[i] -> ENT[j] e ENP[i] -> ENP[j]
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,ENT
        add hl,de
        ex de,hl
        push ix
        pop hl
        ld bc,8
        ldir
        ld a,(p_tj)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,ENP
        add hl,de
        ex de,hl
        ld a,(p_ti)
        add a,a
        add a,a
        add a,a
        ld c,a
        ld b,0
        ld hl,ENP
        add hl,bc
        ld bc,8
        ldir
we_k:   ld hl,p_tj
        inc (hl)
we_x:
we_n:   ld hl,p_ti
        inc (hl)
        ld a,(hl)
        cp E_MAX
        jp c,we_l
        ld a,(p_tj)             ; gli slot dopo l'ultimo superstite si svuotano
        ld (p_ne),a
we_c:   cp E_MAX
        jr nc,we_d
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,ENT
        add hl,de
        ld (hl),0
        ld a,(p_tj)
        inc a
        ld (p_tj),a
        jr we_c
we_d:   ld a,(p_ncr)           ; nuova finestra
        ld (p_cr),a
        call win_load
        ; righe in comune con la vecchia finestra (d = vecchia - nuova): i nemici ci sono gia' (entita'), non si ricreano
        ld hl,(p_dlt)
        sra h
        rr l
        sra h
        rr l
        sra h
        rr l
        sra h
        rr l                    ; L = d con segno
        ld a,l
        ld b,0
        bit 7,a
        jr nz,wo_ng
        ld b,a                  ; d >= 0: righe d..11
        ld a,11
        jr wo_hi
wo_ng:  add a,11                ; d < 0: righe 0..11+d
        jr c,wo_hi
        ld b,12                 ; nessuna riga in comune
        xor a
wo_hi:  ld (p_thi),a
wo_r:   ld a,(p_thi)
        cp b
        jr c,wo_d               ; lo > hi: finito
        ld a,b
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; riga * 128
        ld de,MAP
        add hl,de
        push bc
        ld b,BIGW
wo_c:   ld a,(hl)
        cp T_GOBLIN
        jr z,wo_z
        cp T_BAT
        jr nz,wo_n
wo_z:   ld (hl),0
wo_n:   inc hl
        djnz wo_c
        pop bc
        inc b
        jr wo_r
wo_d:   call ent_spawn_scan     ; nemici delle righe nuove (pagina 1)
        ld a,(p_nrd)
        or a
        jr nz,wo_nr
        ld hl,(p_cam)           ; ridisegno completo (master + 3 viste)
        ld a,(sw_on)
        or a
        jp nz,sw_fill_i
        ld a,(p_ring)
        or a
        jp nz,ring_fill
        xor a
        jp redraw_view
wo_nr:  ret

; ------------------------------------------------------------------------- ogni fotogramma: la finestra deve seguire gli eroi
win_check_i:
        ld a,(p_tall)
        or a
        ret z
        ld hl,0x7FFF
        ld (p_ymin),hl
        ld hl,0xF000
        ld (p_ymax),hl
        ld a,(p_two)
        or a
        jr nz,wc_2
        ld a,(p_dead)
        or a
        ret nz
        ld hl,(p_y)
        ld (p_ymin),hl
        ld (p_ymax),hl
        jr wc_go
wc_2:   ld ix,HS0
        call wc_one
        ld ix,HS1
        call wc_one
        ld hl,(p_ymin)
        ld de,0x7FFF
        or a
        sbc hl,de
        ret z                   ; entrambi morti
wc_go:  ld hl,(p_ymin)          ; verso l'alto?
        ld de,WUP
        or a
        sbc hl,de
        jp p,wc_dn
        ld a,(p_cr)
        or a
        jr z,wc_dn
        ld c,a
        sub WSTEP
        jr nc,wc_u1
        xor a
wc_u1:  ld b,a                  ; nuova riga
        ld a,c
        sub b
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; spostamento (px)
        ld de,(p_ymax)
        add hl,de
        ld de,145               ; chi sta in basso deve restare entro 144 (altrimenti scatterebbe lo scorrimento opposto)
        or a
        sbc hl,de
        jp p,wc_blk
        ld a,b
        jp win_shift_i
wc_dn:  ld hl,(p_ymax)          ; verso il basso?
        ld de,145
        or a
        sbc hl,de
        ret m
        ld a,(p_cr)
        cp CRMAX
        ret nc
        ld c,a
        add a,WSTEP
        cp CRMAX+1
        jr c,wc_d1
        ld a,CRMAX
wc_d1:  ld b,a                  ; nuova riga
        sub c
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; px da togliere
        ld e,l
        ld d,h
        ld hl,(p_ymin)
        or a
        sbc hl,de
        ld de,WUP               ; chi sta in alto deve restare sotto WUP
        or a
        sbc hl,de
        ret m
        ld a,b
        jp win_shift_i
wc_blk: ld a,(p_two)            ; bloccato: solo con due giocatori; chi e' sotto il bordo alto non sale oltre
        or a
        ret z
        ld ix,HS0
        call wc_clamp
        ld ix,HS1
        jp wc_clamp

wc_clamp:
        ld a,(ix+HO_DEAD)
        or a
        ret nz
        ld l,(ix+HO_Y)
        ld h,(ix+HO_Y+1)
        ld de,8
        or a
        sbc hl,de
        ret p
        ld (ix+HO_Y),8
        ld (ix+HO_Y+1),0
        ld (ix+HO_VY),0
        ld (ix+HO_VY+1),0
        ret

wc_one:
        ld a,(ix+HO_DEAD)
        or a
        ret nz
        ld l,(ix+HO_Y)
        ld h,(ix+HO_Y+1)
        ld de,(p_ymin)
        push hl
        or a
        sbc hl,de
        pop hl
        jp p,wc_nm
        ld (p_ymin),hl
wc_nm:  ld de,(p_ymax)
        ex de,hl                ; HL = ymax, DE = y
        push hl
        or a
        sbc hl,de
        pop hl
        ex de,hl                ; HL = y, DE = ymax
        ret p
        ld (p_ymax),hl
        ret

; ------------------------------------------------------------------------- respawn: la finestra contiene p_y?
win_fit_i:
        ld a,(p_tall)
        or a
        ret z
        ld hl,(p_y)
        ld de,96
        or a
        sbc hl,de
        sra h
        rr l
        sra h
        rr l
        sra h
        rr l
        sra h
        rr l                    ; righe di scarto (con segno)
        ld a,(p_cr)
        ld e,a
        ld d,0
        add hl,de               ; nuova riga
        bit 7,h
        jr z,wf_p
        xor a
        jr wf_o
wf_p:   ld a,h
        or a
        jr nz,wf_b
        ld a,l
        cp CRMAX+1
        jr c,wf_o
wf_b:   ld a,CRMAX
wf_o:   ld hl,p_cr
        cp (hl)
        ret z
        ld c,a
        ld a,1
        ld (p_nrd),a
        ld a,c
        call win_shift_i
        xor a
        ld (p_nrd),a
        ret
