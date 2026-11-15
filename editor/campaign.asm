; campaign.asm - i 10 livelli fissi della campagna, sempre presenti nella ROM (segmento 6, tools/make_levels.py).
; Directory: byte 0 = numero di livelli, poi voci da 20 byte: offset(2), lunghezza(2), titolo(16).
; Si giocano come i livelli scaricati (play_foreign): non toccano il lavoro dell'editor.
CAMPSEG equ 6
cp_n    equ 10
cp_sel  equ FBUF+0xB1
cp_done equ FBUF+0xB2           ; 2 byte: bit i = livello i superato (solo in questa sessione)

do_campaign:
        call hide_cursor
        xor a
        ld (cp_sel),a
        call cp_draw
cp_loop:
        call vwait
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        bit 2,a                 ; ESC: indietro
        ret nz
        bit 7,a                 ; INVIO
        jr nz,cp_play
        ld a,(v_e8)
        bit 0,a                 ; SPAZIO
        jr nz,cp_play
        bit 5,a
        jr nz,cp_up
        bit 6,a
        jr nz,cp_dn
        jr cp_loop
cp_up:  ld a,(cp_sel)
        or a
        jr z,cp_loop
        ld c,' '
        call cp_mark
        ld a,(cp_sel)
        dec a
        ld (cp_sel),a
        ld c,'>'
        call cp_mark
        jr cp_loop
cp_dn:  ld a,(cp_sel)
        cp cp_n-1
        jr nc,cp_loop
        ld c,' '
        call cp_mark
        ld a,(cp_sel)
        inc a
        ld (cp_sel),a
        ld c,'>'
        call cp_mark
        jr cp_loop

cp_play:
        ld a,CAMPSEG
        ld (0xB000),a
        ld hl,0xA001            ; voce della directory
        ld a,(cp_sel)
        or a
        jr z,cpp_e
        ld de,20
cpp_l:  add hl,de
        dec a
        jr nz,cpp_l
cpp_e:  ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld (n_glen),bc
        ld hl,0xA000
        add hl,de
        ld de,REC
        ldir                    ; il blob va in REC, poi come un livello scaricato
        call play_foreign
        ld a,(p_win)
        or a
        jr z,cp_again
        ld a,(cp_sel)           ; superato: segna il livello
        ld b,a
        ld hl,1
        or a
        jr z,cpd_s
cpd_l:  add hl,hl
        djnz cpd_l
cpd_s:  ld a,(cp_done)
        or l
        ld (cp_done),a
        ld a,(cp_done+1)
        or h
        ld (cp_done+1),a
        call cp_save            ; i progressi restano nella flash (record impostazioni)
cp_again:
        call hide_cursor
        call cp_draw
        jp cp_loop

; carattere C a sinistra della voce A
cp_mark:
        call cp_y
        ld hl,8
        ld (GRPACX),hl
        ld a,c
        jp print_char

cp_y:   ld b,a                  ; y = 22 + indice*14 -> GRPACY
        ld a,22
        ld d,b
        inc d
cy_l:   dec d
        jr z,cy_d
        add a,14
        jr cy_l
cy_d:   ld l,a
        ld h,0
        ld (GRPACY),hl
        ret

cp_draw:
        ld hl,p_clear
        call vdp_cmd
        ld a,CAMPSEG
        ld (0xB000),a
        ld a,15
        ld (FORCLR),a
        ld a,1
        ld (BAKCLR),a
        ld hl,8
        ld (GRPACX),hl
        ld hl,6
        ld (GRPACY),hl
        ld hl,s_cptitle
        call print_str
        ld b,0
cd_l:   push bc
        ld a,b
        call cp_y
        pop bc
        push bc
        ld hl,8
        ld (GRPACX),hl
        ld a,(cp_sel)
        cp b
        ld a,' '
        jr nz,cd_m
        ld a,'>'
cd_m:   call print_char
        pop bc
        push bc
        ld hl,24                ; numero
        ld (GRPACX),hl
        ld l,b
        ld h,0
        inc hl
        call printdec16
        ld hl,56
        ld (GRPACX),hl
        pop bc
        push bc
        ld hl,0xA001+4          ; titolo della voce B
        ld de,20
        ld a,b
        or a
        jr z,cd_t
cd_p:   add hl,de
        dec a
        jr nz,cd_p
cd_t:   ld b,16
cd_c:   ld a,(hl)
        or a
        jr z,cd_e
        push hl
        push bc
        call print_char
        pop bc
        pop hl
        inc hl
        djnz cd_c
cd_e:   pop bc
        push bc
        ld a,b                  ; superato? bit B di cp_done
        ld hl,(cp_done)
        cp 8
        jr c,cd_b
        sub 8
        ld l,h
cd_b:   ld b,a
        inc b
        ld a,l
cd_r:   rrca
        djnz cd_r
        jr nc,cd_n
        ld hl,216
        ld (GRPACX),hl
        ld hl,s_cpdone
        call print_str
cd_n:   pop bc
        inc b
        ld a,b
        cp cp_n
        jp nz,cd_l
        ld hl,8
        ld (GRPACX),hl
        ld hl,176
        ld (GRPACY),hl
        ld hl,s_cph1
        call print_str
        ld hl,8
        ld (GRPACX),hl
        ld hl,190
        ld (GRPACY),hl
        ld hl,s_cph2
        jp print_str

s_cptitle: db "CAMPAIGN - 10 LEVELS",0
s_cpdone:  db "[X]",0
s_cph1:    db "UP/DOWN select  ENTER play",0
s_cph2:    db "ESC back  [X] = cleared",0

; il record impostazioni piu' recente + i progressi (SETREC+0x52/53) come nuovo record
cp_save:
        call load_settings
        ret c                   ; nessun record impostazioni: niente da aggiornare
        ld a,(cp_done)
        ld (SETREC+0x52),a
        ld a,(cp_done+1)
        ld (SETREC+0x53),a
        jp ns_append

; all'avvio: legge i progressi dal record impostazioni
cp_load:
        xor a
        ld (cp_done),a
        ld (cp_done+1),a
        call load_settings
        ret c
        ld a,(SETREC+0x52)
        ld (cp_done),a
        ld a,(SETREC+0x53)
        ld (cp_done+1),a
        ret
