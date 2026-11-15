; swreach.asm (nel segmento 3, finestra A000; ingressi in reach.asm) - avviso "monete irraggiungibili" / "uscita irraggiungibile" (tasto C e dopo ogni prova con T).
; Modello prudente (meglio un avviso mancato che uno falso): l'eroe e' alto 1 tile, salta ~3 tile (sale 3 file),
; la molla ~7. Si calcola, per ogni colonna, la riga d'appoggio piu' alta raggiungibile (RC_LOW) partendo dal
; punto di partenza: da una colonna si raggiunge una riga d'appoggio r nelle colonne a distanza <= 4 se r >= soglia
; (RC_RCH = riga di partenza - 3, o - 7 su una molla). Poi ogni moneta/gemma/chiave/pozione e' raggiungibile se
; una colonna vicina (x-2..x+2: si salta anche sopra le buche) ha un appoggio al massimo 3 file piu' in basso, oppure 4 file se sotto la moneta
; non c'e' un blocco pieno (come la moneta sopra a un blocco runico a 4 tile da terra).
RC_LOW  equ 0xCD00              ; 128 byte: riga d'appoggio raggiungibile piu' alta per colonna (0xFF = nessuna)
RC_RCH  equ 0xCD80              ; 128 byte: soglia di salto per colonna (0xFF = nessuna)
rc_chg  equ 0xCE00
rc_T    equ 0xCE01
rc_cnt  equ 0xCE02              ; 2 byte: monete irraggiungibili
rc_exit equ 0xCE04              ; 1 = uscita irraggiungibile
rc_fx   equ 0xCE05              ; colonna e riga della prima moneta irraggiungibile (diagnostica)
rc_fy   equ 0xCE06

; A = 1: mostra anche il messaggio "tutto raggiungibile"
rc_run_i:
        push af
        call rc_scan
        pop bc
        ld a,(rc_exit)
        or a
        jr z,rcr_c
        ld hl,m_rcexit
        ld (v_msg),hl
        ret
rcr_c:   ld hl,(rc_cnt)
        ld a,h
        or l
        jr nz,rcr_n
        bit 0,b
        ret z
        ld hl,m_rcok
        ld (v_msg),hl
        ret
rcr_n:   ld (v_msgnum),hl
        ld a,1
        ld (v_msgnf),a
        ld hl,m_rcn
        ld (v_msg),hl
        ret

do_check_i:
        ld a,1
        jp rc_run

; B = colonna, C = riga -> A = id tile (0xFF fuori mappa), BC conservato
rc_tile:
        ld a,c
        cp MAPH
        jr nc,rt_o
        ld h,a
        ld l,0
        srl h
        rr l
        ld e,b
        ld d,0
        add hl,de
        ld de,MAP
        add hl,de
        ld a,(hl)
        ret
rt_o:   ld a,0xFF
        ret

; A = tile, E = maschera di classi (bit n = classe n) -> CF = la classe del tile e' nella maschera
rc_m:   cp T_COUNT
        jr nc,rm_n
        push de
        ld e,a
        ld d,0
        ld hl,tile_class
        add hl,de
        ld a,(hl)
        pop de
        cp 8
        jr nc,rm_n
        inc a
        ld d,a
        ld a,e
rm_l:   rrca
        dec d
        jr nz,rm_l
        ret
rm_n:   or a
        ret

; B = colonna, C = riga -> CF = riga d'appoggio (pavimento solido sotto, cella libera)
rc_stand:
        ld a,c
        cp MAPH-1
        jr nc,rs_n
        inc c
        call rc_tile
        dec c
        ld e,0x46               ; pavimento: classi 1, 2, 6
        call rc_m
        jr nc,rs_n
        call rc_tile
        ld e,0x4E               ; la cella non deve essere piena: classi 1, 2, 3, 6
        call rc_m
        ccf
        ret
rs_n:   or a
        ret

; B = colonna, C = riga raggiungibile: aggiorna RC_LOW / RC_RCH
rc_upd:
        call rc_tile
        ld e,3
        cp T_SPRING
        jr nz,ru_s
        ld e,7
ru_s:   ld a,c
        sub e
        jr nc,ru_a
        xor a
ru_a:   ld hl,RC_RCH
        ld e,b
        ld d,0
        add hl,de
        cp (hl)
        jr nc,ru_1
        ld (hl),a
        ld a,1
        ld (rc_chg),a
ru_1:   ld hl,RC_LOW
        add hl,de
        ld a,c
        cp (hl)
        ret nc
        ld (hl),a
        ld a,1
        ld (rc_chg),a
        ret

; B = colonna: prova tutte le righe d'appoggio sopra la soglia dei vicini
rc_col:
        push bc
        ld a,0xFF
        ld (rc_T),a
        ld a,b
        sub 4
        jr nc,rcl_1
        xor a
rcl_1:  ld e,a
        ld a,b
        add a,4
        cp MAPW
        jr c,rcl_2
        ld a,MAPW-1
rcl_2:  ld d,a
rcl_l:  ld a,e
        cp b
        jr z,rcl_n
        ld hl,RC_RCH
        ld a,l
        add a,e
        ld l,a
        ld a,(rc_T)
        ld c,(hl)
        cp c
        jr c,rcl_n
        ld a,c
        ld (rc_T),a
rcl_n:  ld a,e
        cp d
        jr z,rcl_e
        inc e
        jr rcl_l
rcl_e:  ld a,(rc_T)
        cp 0xFF
        jr z,rcl_x
        ld c,a
rcl_r:  call rc_stand
        call c,rc_upd
        inc c
        ld a,c
        cp MAPH-1
        jr c,rcl_r
rcl_x:  pop bc
        ret

; B = colonna, C = riga (moneta) -> CF = raggiungibile
rc_coin_ok:
        ld a,b
        sub 2
        jr nc,rco_1
        xor a
rco_1:  ld e,a
        ld a,b
        add a,2
        cp MAPW
        jr c,rco_2
        ld a,MAPW-1
rco_2:  ld d,a
rco_l:  ld hl,RC_LOW
        ld a,l
        add a,e
        ld l,a
        ld a,(hl)
        cp 0xFF
        jr z,rco_n
        sub c
        jr c,rco_ok
        cp 4
        jr c,rco_ok
        jr nz,rco_n
        push de                 ; appoggio 4 file sotto la moneta: serve che sotto non ci sia un blocco pieno
        push bc
        inc c
        call rc_tile
        ld e,0x42               ; classi 1 e 6
        call rc_m
        pop bc
        pop de
        jr nc,rco_ok
rco_n:  ld a,e
        cp d
        jr z,rco_bad
        inc e
        jr rco_l
rco_ok: scf
        ret
rco_bad: or a
        ret

; riempie rc_cnt e rc_exit
rc_scan:
        ld hl,0
        ld (rc_cnt),hl
        xor a
        ld (rc_exit),a
        ld hl,RC_LOW
        ld de,RC_LOW+1
        ld bc,255
        ld (hl),0xFF
        ldir
        ld hl,MAP               ; punto di partenza
        ld bc,MAPW*MAPH
        ld a,T_START
        cpir
        ret nz
        dec hl
        ld de,MAP
        or a
        sbc hl,de
        ld a,l
        and 0x7F
        ld b,a
        add hl,hl
        ld c,h
rcs_f:  call rc_stand
        jr c,rcs_s
        inc c
        ld a,c
        cp MAPH
        jr c,rcs_f
        ret
rcs_s:  call rc_upd
rcs_it: xor a
        ld (rc_chg),a
        ld b,0
rcs_c:  call rc_col
        inc b
        ld a,b
        cp MAPW
        jr c,rcs_c
        ld b,MAPW-1
rcs_d:  call rc_col
        ld a,b
        or a
        jr z,rcs_e
        dec b
        jr rcs_d
rcs_e:  ld a,(rc_chg)
        or a
        jr nz,rcs_it
        ; uscita: serve un appoggio raggiungibile in una colonna vicina
        ld hl,MAP
        ld bc,MAPW*MAPH
        ld a,T_PORTB
        cpir
        jr nz,rcs_k
        dec hl
        ld de,MAP
        or a
        sbc hl,de
        ld a,l
        and 0x7F
        ld b,a
        ld c,MAPH-1             ; riga in fondo: conta solo che una colonna x-1..x+1 abbia un appoggio raggiungibile
        call rc_coin_ok
        jr c,rcs_k
        ld a,1
        ld (rc_exit),a
rcs_k:  ld c,0                  ; monete
rcs_r:  ld b,0
rcs_c2: call rc_tile
        sub T_COIN
        cp 4                    ; COIN, GEM, KEY, POTION
        jr nc,rcs_n
        call rc_coin_ok
        jr c,rcs_n
        ld hl,(rc_cnt)
        ld a,h
        or l
        jr nz,rcs_u
        ld a,b
        ld (rc_fx),a
        ld a,c
        ld (rc_fy),a
rcs_u:  inc hl
        ld (rc_cnt),hl
rcs_n:  inc b
        ld a,b
        cp MAPW
        jr c,rcs_c2
        inc c
        ld a,c
        cp MAPH
        jr c,rcs_r
        ret

