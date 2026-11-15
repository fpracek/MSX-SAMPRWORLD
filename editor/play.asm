; play.asm - modalita' prova (tasto T): si gioca il livello in costruzione fino al portale.
; Superarlo imposta "validato" e salva la bozza (docs/VALIDATION.md). ESC esce senza validare.
; Fisica a virgola fissa 8.8 (px/frame), hitbox 10x16 (x+3..x+12, y..y+15), collisioni a tile (classe in tile_class).
; Camera a scatti di 8 colonne (scorrimento fluido = motore soccerlg, da integrare).
GRAV    equ 0x0030
MAXFALL equ 0x0400
JUMPV   equ 0xFB80              ; -0x0480
SPRINGV equ 0xF900              ; -0x0700
ACC     equ 0x0030
VMAX    equ 0x0180
HEROSEG equ 4                   ; segmento con hero.bin (finestra A000, registro B000)

p_x     equ V+0xA0              ; 2 byte (px)
p_xf    equ V+0xA2
p_vx    equ V+0xA3              ; 2 byte, 8.8 con segno
p_y     equ V+0xA5              ; 2 byte (px, con segno)
p_yf    equ V+0xA7
p_vy    equ V+0xA8              ; 2 byte
p_oy    equ V+0xAA              ; 2 byte: y del frame precedente
p_ground equ V+0xAC
p_face  equ V+0xAD
p_anim  equ V+0xAE
p_frame equ V+0xAF
p_lastf equ V+0xB0
p_dead  equ V+0xB1
p_sx    equ V+0xB2              ; 2 byte: punto di ripartenza
p_sy    equ V+0xB4              ; 2 byte
p_win   equ V+0xB6
p_jh    equ V+0xB7
p_coins equ V+0xB8
p_water equ V+0xB9
p_climb equ V+0xBA
p_tcol  equ V+0xBB
p_trow  equ V+0xBC
p_cavail equ V+0xBD
p_exit  equ V+0xBE
p_cnt   equ V+0xBF

; ------------------------------------------------------------------------- avvio / fine
do_play:
        call play_init
pl_loop:
        call vwait
        call scroll_flip
        call snd_tick
        ld a,8
        call readrow
        cpl
        ld (v_k8),a
        ld a,7
        call readrow
        bit 2,a                 ; ESC (premuto = 0)
        jr nz,pl_noesc
        ld a,1
        ld (p_exit),a
pl_noesc:
        call play_physics
        call ent_update
        call ent_hit
        call play_sprite
        call scroll_update
        ld a,(p_exit)
        or a
        jr z,pl_loop
        jp play_end

play_init:
        ld hl,MAP               ; cerca il tile di partenza
        ld bc,MAPW*MAPH
        ld a,T_START
        cpir
        jr nz,pi_def
        dec hl
        ld de,MAP
        or a
        sbc hl,de
        ld a,l
        and 0x7F
        ld e,a                  ; colonna
        add hl,hl
        ld a,h                  ; riga = offset >> 7
        ld d,a
        jr pi_pos
pi_def: ld e,1
        ld d,MAPH-2
pi_pos: ld a,e
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld (p_sx),hl
        ld a,d
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld (p_sy),hl
        ld a,e
        ld (v_curx),a           ; per riposizionare il cursore dell'editor alla fine
        ld a,d
        ld (v_cury),a
        ; pattern dell'eroe in VRAM
        ld a,HEROSEG
        ld (0xB000),a
        ld de,0x7820
        ld hl,0xA000
        ld a,32
        ld (p_cnt),a
pi_up:  push hl
        push de
        ex de,hl
        call vram_w
        pop de
        pop hl
        ld bc,0x2098
        otir
        ld bc,16
        add hl,bc
        ex de,hl
        ld bc,32
        add hl,bc
        ex de,hl
        ld a,(p_cnt)
        dec a
        ld (p_cnt),a
        jr nz,pi_up
        ld hl,CRMB              ; blocchi friabili e chiavi azzerati
        ld de,CRMB+1
        ld bc,11
        ld (hl),0
        ldir
        xor a
        ld (p_keys),a
        call snd_init           ; SCC: onde, musica
        call map_save           ; la mappa originale resta in VRAM: la prova la modifica (monete, nemici)
        call ent_spawn
        call ent_vram
        xor a
        ld (p_win),a
        ld (p_exit),a
        ld (p_coins),a
        ld (p_dead),a
        ld (p_jh),a
        ld a,0xFF
        ld (p_lastf),a
        call respawn
        call play_status
        ret

respawn:
        ld hl,(p_sx)
        ld (p_x),hl
        ld hl,(p_sy)
        ld (p_y),hl
        ld (p_oy),hl
        ld hl,0
        ld (p_vx),hl
        ld (p_vy),hl
        xor a
        ld (p_xf),a
        ld (p_yf),a
        ld (p_ground),a
        ld (p_climb),a
        ld (p_face),a
        ld (p_dead),a
        ; camera sul punto di ripartenza (pari, entro la mappa), ridisegno completo sulla pagina 0
        call vdp_wait
        ld hl,(p_x)
        ld de,48
        or a
        sbc hl,de
        bit 7,h
        jr z,rs_p
        ld hl,0
rs_p:   ld a,l
        and 0x80
        ld l,a                  ; multiplo di 128
        push hl
        ld de,MAPW*16-256
        or a
        sbc hl,de
        pop hl
        jr c,rs_c
        ld hl,MAPW*16-256
rs_c:
        ld (p_cam),hl
        xor a
        ld (p_page),a
        ld (p_job),a
        ld (p_nd),a
        ld e,2
        ld a,0x1F
        call wrreg              ; R#2: pagina 0 visibile
        ld hl,(p_cam)
        xor a
        jp redraw_view

play_end:
        ld a,(p_win)            ; vittoria: si lascia suonare il jingle
        or a
        jr z,pe_nj
        ld b,50
pe_j:   push bc
        call vwait
        call snd_tick
        pop bc
        djnz pe_j
pe_nj:  call snd_off
        call map_load
        call vdp_wait
        ld e,2
        ld a,0x1F
        call wrreg
        ld a,(p_win)
        or a
        jr z,pe_quit
        ld a,(p_foreign)
        or a
        ld hl,m_fwon
        jr nz,pe_msg            ; livello scaricato: nessuna validazione
        ld a,1
        ld (v_valid),a
        call do_save            ; la validazione si scrive nella bozza in flash
        ld hl,m_won
        jr pe_msg
pe_quit:
        ld hl,m_quit
pe_msg: ld (v_msg),hl
        ld a,(v_curx)           ; cursore dell'editor sul punto di partenza, ben visibile
        and 0xF8
        cp 113
        jr c,pe_c
        ld a,112
pe_c:   ld (v_scrx),a
        call init_sprite
        ld a,1
        ld (v_redr),a
        ld (v_dirty),a
        ret

play_status:
        ld hl,p_stat
        call vdp_cmd
        ld a,15
        ld (FORCLR),a
        ld a,1
        ld (BAKCLR),a
        ld hl,2
        ld (GRPACX),hl
        ld hl,194
        ld (GRPACY),hl
        ld hl,s_coins
        call print_str
        ld a,(p_coins)
        call print_num3
        ld hl,s_keys
        call print_str
        ld a,(p_keys)
        add a,'0'
        call print_char
        ld hl,s_kills
        call print_str
        ld a,(p_kills)
        call print_num3
        ld hl,2
        ld (GRPACX),hl
        ld hl,203
        ld (GRPACY),hl
        ld hl,s_playhelp
        call print_str
        jp status_copy

; ------------------------------------------------------------------------- lettura tile
; HL = x (px), DE = y (px, con segno) -> A = classe (0xFF = sotto la mappa), E = id tile
; imposta p_tcol/p_trow
tclass: bit 7,h
        jr nz,tc_solid
        ld a,h
        cp MAPW*16/256
        jr nc,tc_solid
        bit 7,d
        jr nz,tc_empty
        ld a,d
        or a
        jr nz,tc_pit
        ld a,e
        cp MAPH*16
        jr nc,tc_pit
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l
        ld a,l
        ld (p_tcol),a
        ld a,e
        rrca
        rrca
        rrca
        rrca
        and 15
        ld (p_trow),a
        ld h,a
        ld e,l
        ld l,0
        srl h
        rr l
        ld d,0
        add hl,de
        ld de,MAP
        add hl,de
        ld e,(hl)
        ld d,0
        ld hl,tile_class
        add hl,de
        ld a,(hl)
        ret
tc_solid:
        ld a,1
        ld e,0
        ret
tc_empty:
        xor a
        ld e,0
        ret
tc_pit: ld a,0xFF
        ld e,0
        ret

; B = scarto x, C = scarto y dal vertice della figura -> A = classe, E = id
probe:  ld hl,(p_x)
        ld e,b
        ld d,0
        add hl,de
        push hl
        ld hl,(p_y)
        ld e,c
        ld d,0
        add hl,de
        ex de,hl
        pop hl
        jp tclass

; carry = la classe A (tile E) ferma il movimento
blocks: cp 1
        jr z,bl_y
        cp 6
        jr z,bl_y
        cp 8
        jr nz,bl_n
        ld a,e
        cp T_DOORT
        jr z,bl_y
        cp T_DOORB
        jr z,bl_y
bl_n:   or a
        ret
bl_y:   scf
        ret

; ------------------------------------------------------------------------- fisica
play_physics:
        ld a,(p_dead)
        or a
        jr z,pp_alive
        dec a
        ld (p_dead),a
        ret nz
        jp respawn
pp_alive:
        ; --- ambiente: acqua / scala (punto centrale) ---
        ld bc,0x0808
        call probe
        ld b,0
        cp 4
        jr nz,pp_nw
        ld b,1
pp_nw:  ld a,b
        ld (p_water),a
        ld bc,0x0808
        call probe
        ld b,0
        cp 5
        jr nz,pp_nc
        ld b,1
pp_nc:  ld a,b
        ld (p_cavail),a
        or a
        jr nz,pp_cl
        xor a
        ld (p_climb),a
pp_cl:  ; --- movimento orizzontale ---
        ld hl,(p_vx)
        ld a,(v_k8)
        bit 7,a
        jr z,pp_nr
        ld de,ACC
        add hl,de
        ld a,(p_face)
        xor a
        ld (p_face),a
        jr pp_clamp
pp_nr:  bit 4,a
        jr z,pp_fr
        ld de,-ACC
        add hl,de
        ld a,1
        ld (p_face),a
        jr pp_clamp
pp_fr:  bit 7,h                 ; attrito
        jr nz,pp_fn
        ld a,h
        or l
        jr z,pp_vdone
        ld de,-ACC
        add hl,de
        bit 7,h
        jr z,pp_vdone
        ld hl,0
        jr pp_vdone
pp_fn:  ld de,ACC
        add hl,de
        bit 7,h
        jr nz,pp_vdone
        ld hl,0
        jr pp_vdone
pp_clamp:
        ld a,(p_water)
        or a
        ld de,VMAX
        jr z,pp_mx
        ld de,0x00C0
pp_mx:  bit 7,h
        jr nz,pp_neg
        push hl
        or a
        sbc hl,de
        pop hl
        jr c,pp_vdone
        ex de,hl                ; vx > limite: vx = limite
        jr pp_vdone
pp_neg: push hl
        call neg_hl
        or a
        sbc hl,de
        pop hl
        jr c,pp_vdone
        ld hl,0                 ; -vx > limite: vx = -limite
        or a
        sbc hl,de
pp_vdone:
        ld (p_vx),hl
        ; --- salto / scala / gravita' ---
        ld hl,(p_vy)
        ld a,(v_k8)
        bit 0,a
        jr z,pp_nojump
        ld a,(p_jh)
        or a
        jr nz,pp_grav
        ld a,1
        ld (p_jh),a
        ld a,(p_water)
        or a
        jr z,pp_dry
        ld hl,0xFD80            ; nuoto: spinta verso l'alto
        jr pp_grav
pp_dry: ld a,(p_ground)
        or a
        jr z,pp_clj
        ld hl,JUMPV
        xor a
        ld (p_ground),a
        ld (p_climb),a
        ld a,SFX_JUMP
        call sfx_a
        jr pp_grav
pp_clj: ld a,(p_climb)          ; salto dalla scala
        or a
        jr z,pp_grav
        ld hl,0xFD00
        xor a
        ld (p_climb),a
        jr pp_grav
pp_nojump:
        xor a
        ld (p_jh),a
        bit 7,h                 ; salto variabile: rilasciando si accorcia
        jr z,pp_grav
        ld a,h
        cp 0xFE
        jr nc,pp_grav
        ld hl,0xFE00
pp_grav:
        ld a,(p_cavail)
        or a
        jr z,pp_ng
        ld a,(v_k8)
        and 0x60                ; su/giu' sulla scala
        jr z,pp_hold
        ld a,1
        ld (p_climb),a
pp_hold:
        ld a,(p_climb)
        or a
        jr z,pp_ng
        ld hl,0
        ld a,(v_k8)
        bit 5,a
        jr z,pp_cd
        ld hl,0xFF00            ; su
        jr pp_gdone
pp_cd:  bit 6,a
        jr z,pp_gdone
        ld hl,0x0100            ; giu'
        jr pp_gdone
pp_ng:  ld a,(p_water)
        or a
        ld de,GRAV
        jr z,pp_gv
        ld de,0x0010
pp_gv:  add hl,de
        bit 7,h
        jr nz,pp_gdone
        ld a,(p_water)
        or a
        ld a,4
        jr z,pp_gm
        ld a,1
pp_gm:  cp h
        jr nc,pp_gdone
        ld h,a
        ld l,0
pp_gdone:
        ld (p_vy),hl
        ; --- spostamento X ---
        ld hl,(p_x)
        ld de,(p_vx)
        call add88x             ; aggiorna p_x/p_xf
        ld hl,(p_vx)
        ld a,h
        or l
        jr z,pp_xdone
        bit 7,h
        jr nz,pp_left
        ld b,12                 ; verso destra: bordo x+12
        call col_x
        jr nc,pp_xdone
        call try_door           ; con una chiave il portone si apre
        jr nc,pp_xdone
        ld hl,(p_x)
        ld de,12
        add hl,de
        ld a,l
        and 0xF0
        ld l,a
        ld de,-13
        add hl,de
        ld (p_x),hl
        ld hl,0
        ld (p_vx),hl
        xor a
        ld (p_xf),a
        jr pp_xdone
pp_left:
        ld b,3
        call col_x
        jr nc,pp_xdone
        call try_door           ; con una chiave il portone si apre
        jr nc,pp_xdone
        ld hl,(p_x)
        ld de,3
        add hl,de
        ld a,l
        and 0xF0
        ld l,a
        ld de,16-3
        add hl,de
        ld (p_x),hl
        ld hl,0
        ld (p_vx),hl
        xor a
        ld (p_xf),a
pp_xdone:
        ; --- spostamento Y ---
        ld hl,(p_y)
        ld (p_oy),hl
        call add88y
        xor a
        ld (p_ground),a
        ld hl,(p_vy)
        bit 7,h
        jr nz,pp_up
        ld a,h
        or l
        jr z,pp_ysol
        ; in discesa: bordo inferiore y+15
        ld b,3
        call land_at
        jr c,pp_land
        ld b,12
        call land_at
        jr nc,pp_ysol
pp_land:
        ld hl,(p_y)
        ld de,15
        add hl,de
        ld a,l
        and 0xF0
        ld l,a
        ld de,-16
        add hl,de
        ld (p_y),hl
        ld hl,0
        ld (p_vy),hl
        xor a
        ld (p_yf),a
        ld a,1
        ld (p_ground),a
        jr pp_ydone
pp_up:  ld b,3                  ; in salita: bordo superiore y
        ld c,0
        call probe
        call blocks
        jr c,pp_bump
        ld b,12
        ld c,0
        call probe
        call blocks
        jr nc,pp_ysol
pp_bump:
        call head_hit           ; blocchi colpiti da sotto
        ld hl,(p_y)
        ld a,l
        and 0xF0
        ld l,a
        ld de,16
        add hl,de
        ld (p_y),hl
        ld hl,0
        ld (p_vy),hl
        xor a
        ld (p_yf),a
        jr pp_ydone
pp_ysol:
        ; appoggio sul pavimento senza movimento verticale
        ld hl,(p_vy)
        bit 7,h
        jr nz,pp_ydone
        ld b,3
        call floor_at
        jr c,pp_gset
        ld b,12
        call floor_at
        jr nc,pp_ydone
pp_gset:
        ld a,1
        ld (p_ground),a
pp_ydone:
        call touch_all
        call crumble_check
        jp crumble_update

neg_hl: ld a,l
        cpl
        ld l,a
        ld a,h
        cpl
        ld h,a
        inc hl
        ret

; (HL=x) += DE(vx 8.8) con parte frazionaria in p_xf
add88x: ld a,(p_xf)
        add a,e
        ld (p_xf),a
        ld a,d
        adc a,0
        ld e,a
        rla
        sbc a,a
        ld d,a
        add hl,de
        ld (p_x),hl
        ret
add88y: ld de,(p_vy)
        ld hl,(p_y)
        ld a,(p_yf)
        add a,e
        ld (p_yf),a
        ld a,d
        adc a,0
        ld e,a
        rla
        sbc a,a
        ld d,a
        add hl,de
        ld (p_y),hl
        ret

; collisione orizzontale sul bordo B: punti in alto (y) e in basso (y+15). CF=1 se blocca
col_x:  ld c,0
        push bc
        call probe
        call blocks
        pop bc
        ret c
        ld c,15
        call probe
        jp blocks

; atterraggio sul bordo inferiore (y+15) con x+B: pieno, oppure piattaforma attraversabile dall'alto
land_at:
        ld c,15
        push bc
        call probe
        pop bc
        push af
        call blocks
        jr c,la_y
        pop af
        cp 2
        jr nz,la_n
        ; piattaforma: vale solo se prima i piedi erano sopra il suo bordo superiore
        ld hl,(p_y)
        ld de,15
        add hl,de
        ld a,l
        and 0xF0
        ld l,a
        ex de,hl                ; DE = bordo superiore della riga
        ld hl,(p_oy)
        ld bc,15
        add hl,bc
        or a
        sbc hl,de
        ret                     ; CF=1 se i piedi precedenti erano sopra
la_y:   pop af
        scf
        ret
la_n:   or a
        ret

; pavimento subito sotto i piedi (y+16) a x+B
floor_at:
        ld c,16
        call probe
        push af
        call blocks
        jr c,fa_y
        pop af
        cp 2
        jr nz,fa_n
        ld hl,(p_y)             ; piattaforma: se i piedi sono esattamente sul bordo
        ld de,16
        add hl,de
        ld a,l
        and 0x0F
        jr nz,fa_n
        scf
        ret
fa_y:   pop af
        scf
        ret
fa_n:   or a
        ret

; tocca i 6 punti della figura e applica gli effetti dei tile
touch_all:
        ld hl,tp_tab
        ld a,6
        ld (p_cnt),a
ta_l:   ld b,(hl)
        inc hl
        ld c,(hl)
        inc hl
        push hl
        call probe
        call touch
        pop hl
        ld a,(p_dead)
        or a
        ret nz
        ld a,(p_exit)
        or a
        ret nz
        ld a,(p_cnt)
        dec a
        ld (p_cnt),a
        jr nz,ta_l
        ret
tp_tab: db 3,2, 12,2, 3,8, 12,8, 3,15, 12,15

touch:  cp 3
        jr z,t_die
        cp 0xFF
        jr z,t_die
        cp 7
        jr z,t_pick
        cp 8
        ret nz
        ld a,e
        cp T_PORTT
        jr z,t_win
        cp T_PORTB
        jr z,t_win
        cp T_SPRING
        jr z,t_spring
        cp T_CHKPT
        ret nz
        ld a,(p_tcol)           ; checkpoint: da qui si riparte
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld (p_sx),hl
        ld a,(p_trow)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld (p_sy),hl
        ret
t_win:  ld a,1
        ld (p_win),a
        ld (p_exit),a
        call snd_music_off
        ld a,SFX_WIN
        jp sfx_a
t_spring:
        ld hl,(p_vy)
        bit 7,h
        ret nz
        ld hl,SPRINGV
        ld (p_vy),hl
        xor a
        ld (p_ground),a
        ret
t_die:  ld a,(p_dead)
        or a
        ret nz
        ld a,40
        ld (p_dead),a
        ld a,SFX_DIE
        jp sfx_a
t_pick: ld a,e
        cp T_KEY
        jr nz,tpk_c
        ld a,(p_keys)           ; la chiave non e' una moneta
        inc a
        ld (p_keys),a
        jr tpk_d
tpk_c:  cp T_GEM
        ld b,1
        jr nz,tpk_a
        ld b,5                  ; la gemma vale 5
tpk_a:  ld a,(p_coins)
        add a,b
        jr nc,tpk_s
        ld a,255
tpk_s:  ld (p_coins),a
tpk_d:  ld a,SFX_COIN
        call sfx_a
        ld a,(p_trow)           ; il tile sparisce dalla mappa
        ld h,a
        ld l,0
        srl h
        rr l
        ld a,(p_tcol)
        ld e,a
        ld d,0
        add hl,de
        ld de,MAP
        add hl,de
        ld (hl),0
        ld a,(p_tcol)
        ld (bo_col),a
        ld a,(p_trow)
        ld (bo_row),a
        call cell_changed
        jp play_status

; ------------------------------------------------------------------------- sprite
play_sprite:
        ld a,(p_ground)
        or a
        ld b,3
        jr z,ps_f
        ld hl,(p_vx)
        ld a,h
        or a
        jr nz,ps_run
        ld a,l
        cp 0x40
        jr nc,ps_run
        ld b,0
        jr ps_f
ps_run: ld a,(p_anim)
        inc a
        ld (p_anim),a
        and 8
        ld b,1
        jr z,ps_f
        ld b,2
ps_f:   ld a,(p_face)
        or a
        jr z,ps_nf
        ld a,b
        add a,4
        ld b,a
ps_nf:  ld a,b
        ld (p_frame),a
        ld hl,p_lastf
        cp (hl)
        jr z,ps_attr
        ld (hl),a
        ld l,a                  ; ROM: A000 + frame*192 + 32
        ld h,0
        ld d,h
        ld e,l
        add hl,hl
        add hl,de               ; *3
        ld b,6
ps_sh:  add hl,hl
        djnz ps_sh              ; *192
        ld de,0xA000+32
        add hl,de
        push hl
        ld hl,0x7400
        call vram_w
        pop hl
        ld b,4
ps_cl:  push bc
        ld bc,0x1098
        otir
        ld bc,32
        add hl,bc
        pop bc
        djnz ps_cl
ps_attr:
        ld hl,0x7600
        call vram_w
        ld a,(p_dead)
        or a
        jr z,ps_vis
        ld hl,hide_attr         ; morto: i 4 sprite dell'eroe spariscono
        ld bc,0x0898
        otir
        ld hl,hide_attr
        ld bc,0x0898
        otir
        jp ent_sprites
ps_vis: ld hl,(p_x)
        ld de,(p_cam)
        or a
        sbc hl,de
        ld d,l                  ; D = X sullo schermo
        ld hl,(p_y)
        ld a,l
        dec a
        ld e,a                  ; E = Y sprite (y-1)
        ld c,0
ps_pl:  ld a,e
        out (0x98),a
        ld a,d
        out (0x98),a
        ld a,(p_frame)          ; pattern = 4 + frame*16 + layer*4
        add a,a
        add a,a
        add a,a
        add a,a
        add a,c
        add a,4
        out (0x98),a
        xor a
        out (0x98),a
        ld a,c
        add a,4
        ld c,a
        cp 16
        jr nz,ps_pl
        jp ent_sprites          ; poi i nemici e il terminatore

m_won:    db "  Superato! Validato",0
m_quit:   db "  Prova interrotta",0
s_coins:  db "MONETE ",0
s_kills:  db "  NEMICI ",0
s_keys:   db "  CHIAVI ",0
s_playhelp: db "FRECCE SPAZIO=salta ESC=esci",0
