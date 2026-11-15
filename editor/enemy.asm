; enemy.asm - nemici della modalita' prova. Si piazzano nell'editor come tile "Goblin" / "Pipistrello";
; all'avvio della prova diventano entita' (i tile si cancellano dalla mappa di gioco, che a fine prova viene ripristinata
; dalla copia in VRAM). Ogni nemico = 2 sprite hardware (contorno nero + riempimento colorato).
;   Goblin (tipo 1): cammina 1 px ogni 2 frame, si gira davanti a muri e bordi, cade se non ha terreno.
;   Pipistrello (tipo 2): vola 1 px/frame in orizzontale, ondeggia (tabella seno), si gira contro i muri o a fine pattuglia.
; Contatto: schiacciato dall'alto (eroe in discesa) = muore e l'eroe rimbalza; altrimenti l'eroe muore.
E_MAX   equ 8
ENT     equ 0xCA00              ; E_MAX entita' da 8 byte: tipo, x(2), y, direzione, -, y base, contatore pattuglia
p_tick  equ V+0xE8
p_kills equ V+0xE9
p_ne    equ V+0xEA
e_fx    equ V+0xEB              ; 2 byte
e_nx    equ V+0xED              ; 2 byte
e_buf   equ V+0xF0              ; 8 byte: attributi di due piani
ENPAT   equ 132                 ; primo numero di pattern degli sprite nemici (VRAM 0x7C20)

; copia la mappa in VRAM (pagina 2, 0x16000: la pagina 3 e' il master degli sprite software) e la ripristina
map_save:
        ld a,5                  ; 0x16000: righe 192.. della pagina 2 (libere)
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x60
        out (0x99),a
        ld hl,MAP
        ld b,6
ms_l:   push bc
        ld bc,0x0098
        otir
        pop bc
        djnz ms_l
        ret

map_load:
        ld a,5
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x20
        out (0x99),a
        ld hl,MAP
        ld b,6
ml_l:   push bc
        ld bc,0x0098
        inir
        pop bc
        djnz ml_l
        ret

; entita' dai tile Goblin/Pipistrello della mappa
ent_spawn:
        ld hl,ENT
        ld de,ENT+1
        ld bc,E_MAX*8-1
        ld (hl),0
        ldir
        xor a
        ld (p_ne),a
        ld (p_kills),a
        ld hl,MAP
        ld bc,MAPW*MAPH
es_l:   ld a,(hl)
        ld d,1
        cp T_GOBLIN
        jr z,es_mk
        ld d,2
        cp T_BAT
        jr nz,es_n
es_mk:  ld a,(p_ne)
        cp E_MAX
        jr nc,es_ov
        push hl
        push bc
        push de
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld ix,ENT
        add ix,de
        pop de
        ld (ix+0),d             ; tipo
        ld de,MAP
        or a
        sbc hl,de               ; offset nella mappa
        ld a,l
        and 0x7F                ; colonna
        add hl,hl
        ld c,h                  ; riga
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld (ix+1),l
        ld (ix+2),h
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld (ix+3),a
        ld (ix+6),a
        ld (ix+7),96
        call ep_spawn           ; proprieta' dal record della bozza/livello (props.asm)
        pop bc
        pop hl
        ld a,(p_ne)
        inc a
        ld (p_ne),a
es_ov:  ld (hl),0               ; il tile marcatore non esiste nel gioco
es_n:   inc hl
        dec bc
        ld a,b
        or c
        jr nz,es_l
        ret

; pattern e colori degli sprite nemici (finestra A000 = segmento sprite)
ent_vram:
        ld hl,0x7800+ENPAT*8
        call vram_w
        ld hl,0xA000+1536
        ld bc,0x0098
        otir
        ld bc,0x8098
        otir
        ld hl,0x7440            ; colori dei 3 slot: piano pari = contorno (1), dispari = riempimento (3 = goblin)
        call vram_w
        ld c,3
ev_l:   ld b,16
        ld a,1
ev_1:   out (0x98),a
        djnz ev_1
        ld b,16
        ld a,3
ev_2:   out (0x98),a
        djnz ev_2
        dec c
        jr nz,ev_l
        ld a,1
        ld (e_st),a
        ld (e_st+1),a
        ld (e_st+2),a
        ret

ent_update:
        ld hl,p_tick
        inc (hl)
        ld ix,ENT
        ld b,E_MAX
eu_l:   push bc
        ld a,(ix+0)
        cp 1
        call z,gob_update
        ld a,(ix+0)
        cp 2
        call z,bat_update
        pop bc
        ld de,8
        add ix,de
        djnz eu_l
        ret

gob_update:
        push ix                 ; IY = proprieta' di questa entita' (ENP ha lo stesso passo di ENT)
        pop hl
        ld de,ENP-ENT
        add hl,de
        push hl
        pop iy
        ld a,(iy+0)
        or a
        jr z,gb_mv              ; pattuglia
        call ep_near            ; C = 1 se l'eroe e' entro il raggio di rilevamento, B = 1 se e' a sinistra
        ld a,(iy+0)
        cp 1
        jr nz,gb_ch
        ld a,c
        or a
        jr nz,gb_mv             ; dormiglione: sveglio solo se l'eroe e' vicino
        jp gb_grav
gb_ch:  ld d,a
        ld a,c
        or a
        jr z,gb_mv              ; inseguitore / pauroso: lontano = pattuglia normale
        ld a,d
        cp 2
        ld a,b
        jr z,gb_dir             ; inseguitore: verso l'eroe
        xor 1                   ; pauroso: via dall'eroe
gb_dir: ld (ix+4),a
gb_mv:  ld a,(iy+1)
        cp 1
        jr nz,gb_ng             ; velocita' 1: un passo ogni 2 fotogrammi
        ld a,(p_tick)
        and 1
        jp nz,gb_grav
gb_ng:  call gb_step
        ld a,(iy+1)
        cp 3
        call z,gb_step          ; velocita' 3: due passi per fotogramma
        ld a,(iy+2)
        or a
        jp z,gb_grav            ; raggio illimitato
        ld l,(ix+1)             ; oltre il raggio dalla posizione di partenza: si torna indietro
        ld h,(ix+2)
        ld e,(iy+5)
        ld d,(iy+6)
        or a
        sbc hl,de
        ld c,0
        bit 7,h
        jr z,gb_r1
        ld c,1
        call neg_hl
gb_r1:  ld a,h
        or a
        jr nz,gb_ro
        ld a,l
        cp (iy+2)
        jp c,gb_grav
gb_ro:  ld a,c
        xor 1
        ld (ix+4),a
        jp gb_grav

; un passo orizzontale del goblin: si ferma davanti a muri e bordi
gb_step:
        ld e,(ix+1)
        ld d,(ix+2)
        bit 0,(ix+4)
        jr nz,gb_l
        inc de
        ld hl,13
        jr gb_f
gb_l:   dec de
        ld hl,2
gb_f:   ld (e_nx),de
        add hl,de
        ld (e_fx),hl
        ld a,(ix+3)
        add a,8
        ld e,a
        ld d,0
        ld hl,(e_fx)
        call tclass             ; muro davanti?
        call blocks
        jr c,gb_turn
        ld a,(ix+3)
        add a,16
        ld e,a
        ld d,0
        ld hl,(e_fx)
        call tclass             ; terreno davanti ai piedi?
        ld b,a
        call blocks
        jr c,gb_go
        ld a,b
        cp 2
        jr nz,gb_turn
gb_go:  ld hl,(e_nx)
        ld (ix+1),l
        ld (ix+2),h
        ret
gb_turn:
        ld a,(ix+4)
        xor 1
        ld (ix+4),a
        ret

; eroe entro il raggio di rilevamento (IY+4 px)? C = 1 si'; B = 1 se l'eroe sta a sinistra del nemico
ep_near:
        ld hl,(p_x)
        ld e,(ix+1)
        ld d,(ix+2)
        or a
        sbc hl,de
        ld b,0
        bit 7,h
        jr z,epn_p
        ld b,1
        call neg_hl
epn_p:  ld a,h
        or a
        jr nz,epn_f
        ld a,l
        cp (iy+4)
        jr nc,epn_f
        ld c,1
        ret
epn_f:  ld c,0
        ret

; IX = entita' appena creata (indice p_ne): riempie ENP dal record della tabella EPT (o coi valori predefiniti)
ep_spawn:
        ld a,(ix+1)             ; colonna e riga del nemico
        rrca
        rrca
        rrca
        rrca
        and 15
        ld b,a
        ld a,(ix+2)
        add a,a
        add a,a
        add a,a
        add a,a
        or b
        ld b,a
        ld a,(ix+3)
        rrca
        rrca
        rrca
        rrca
        and 15
        ld c,a
        ld a,(p_ne)
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,ENP
        add hl,de
        push hl
        pop iy
        ld (iy+0),0             ; IA: pattuglia
        ld (iy+1),1             ; velocita'
        ld (iy+2),0             ; raggio: illimitato
        ld (iy+3),1             ; vita
        ld (iy+4),96            ; rilevamento 6 tile
        ld (iy+7),96            ; durata della pattuglia dei pipistrelli
        ld (ix+5),0             ; sprite: quello del tipo
        ld a,(ix+1)
        ld (iy+5),a             ; posizione di partenza
        ld a,(ix+2)
        ld (iy+6),a
        call ept_find
        ret c
        inc hl
        inc hl
        ld a,(hl)
        ld (iy+0),a
        inc hl
        ld a,(hl)
        ld (iy+1),a
        inc hl
        ld a,(hl)
        add a,a
        add a,a
        add a,a
        add a,a
        ld (iy+2),a             ; raggio in px
        or a
        jr z,eps_h
        ld (ix+7),a             ; i pipistrelli: durata della pattuglia = raggio
        ld (iy+7),a
eps_h:  inc hl
        ld a,(hl)
        ld (iy+3),a
        inc hl
        ld a,(hl)
        add a,a
        add a,a
        add a,a
        add a,a
        ld (iy+4),a
        inc hl
        ld a,(hl)
        ld (ix+5),a             ; sprite scelto (0 = quello del tipo, 1-3 = soldato, medico, poliziotto)
        ret

gb_grav:
        ld l,(ix+1)
        ld h,(ix+2)
        ld de,8
        add hl,de
        ld a,(ix+3)
        add a,16
        ld e,a
        ld d,0
        call tclass             ; terreno sotto i piedi?
        ld b,a
        call blocks
        ret c
        ld a,b
        cp 2
        ret z
        ld a,(ix+3)             ; cade di 2 px
        add a,2
        ld (ix+3),a
        cp 192
        ret c
        ld (ix+0),0             ; caduto fuori dalla mappa
        ret

bat_update:
        push ix
        pop hl
        ld de,ENP-ENT
        add hl,de
        push hl
        pop iy
        ld e,(ix+1)
        ld d,(ix+2)
        bit 0,(ix+4)
        jr nz,bt_l
        inc de
        ld hl,13
        jr bt_f
bt_l:   dec de
        ld hl,2
bt_f:   ld (e_nx),de
        add hl,de
        ld (e_fx),hl
        ld a,(ix+3)
        add a,8
        ld e,a
        ld d,0
        ld hl,(e_fx)
        call tclass
        call blocks
        jr c,bt_turn
        ld a,(ix+7)
        dec a
        ld (ix+7),a
        jr z,bt_turn
        ld hl,(e_nx)
        ld (ix+1),l
        ld (ix+2),h
        jr bt_y
bt_turn:
        ld a,(ix+4)
        xor 1
        ld (ix+4),a
        ld a,(iy+7)
        ld (ix+7),a
bt_y:   ld a,(p_tick)
        srl a
        and 31
        ld e,a
        ld d,0
        ld hl,sintab
        add hl,de
        ld a,(hl)
        add a,(ix+6)
        ld (ix+3),a
        ret

; contatto eroe-nemici
ent_hit:
        ld a,(p_dead)
        or a
        ret nz
        ld ix,ENT
        ld b,E_MAX
eh_l:   push bc
        ld a,(ix+0)
        or a
        jp z,eh_n
        ld hl,(p_x)             ; |dx| < 11 ?
        ld e,(ix+1)
        ld d,(ix+2)
        or a
        sbc hl,de
        bit 7,h
        jr z,eh_p
        call neg_hl
eh_p:   ld a,h
        or a
        jr nz,eh_n
        ld a,l
        cp 11
        jr nc,eh_n
        ld hl,(p_y)             ; dy firmato = y eroe - y nemico
        ld e,(ix+3)
        ld d,0
        or a
        sbc hl,de
        ld (e_fx),hl
        bit 7,h
        jr z,eh_q
        call neg_hl
eh_q:   ld a,h
        or a
        jr nz,eh_n
        ld a,l
        cp 13
        jr nc,eh_n
        ld hl,(p_vy)            ; schiacciato: eroe in discesa e sopra il nemico
        bit 7,h
        jr nz,eh_hurt
        ld hl,(e_fx)
        ld de,5
        add hl,de
        bit 7,h
        jr z,eh_hurt
        push ix                 ; vita del nemico (ENP+3): con piu' vite serve piu' di un balzo
        pop hl
        ld de,ENP-ENT
        add hl,de
        push hl
        pop iy
        dec (iy+3)
        jr nz,eh_wd
        ld (ix+0),0             ; il nemico muore
        ld a,(p_kills)
        inc a
        ld (p_kills),a
eh_wd:  ld a,SFX_STOMP
        call sfx_a
        ld hl,0xFC80            ; rimbalzo
        ld (p_vy),hl
        xor a
        ld (p_ground),a
        push ix
        call play_status
        pop ix
        jr eh_n
eh_hurt:
        ld a,40
        ld (p_dead),a
        ld a,SFX_DIE
        call sfx_a
        pop bc
        ret
eh_n:   pop bc
        ld de,8
        add ix,de
        dec b
        jp nz,eh_l
        ret

; attributi degli sprite nemici. Solo 16 piani hanno una tabella colore propria (i piani 16-31 ne condividono una con i piani
; 0-15, verificato in openMSX): eroe = piani 0-3, nemici = 3 slot dinamici (piani 4-9: contorno + riempimento) assegnati ai
; primi 3 nemici visibili, HUD = piani 10-15 (modalita' V9958), terminatore subito dopo.
; La VRAM e' gia' posizionata dopo i 4 piani dell'eroe.
e_sl    equ 0xCA80              ; 3 byte: indice dell'entita' in ogni slot (0xFF = vuoto)
e_st    equ 0xCA83              ; 3 byte: tipo di cui e' caricata la tabella colore del riempimento

ent_sprites:
        ld a,0xFF
        ld (e_sl),a
        ld (e_sl+1),a
        ld (e_sl+2),a
        ld ix,ENT
        ld b,0                  ; indice entita'
        ld c,0                  ; slot assegnati
es_scan:
        ld a,(ix+0)
        or a
        jr z,es_nx
        ld l,(ix+1)
        ld h,(ix+2)
        ld de,(p_cam)
        or a
        sbc hl,de
        bit 7,h
        jr nz,es_nx
        ld a,h
        or a
        jr nz,es_nx
        push bc
        ld e,c
        ld d,0
        ld hl,e_sl
        add hl,de
        ld (hl),b
        pop bc
        inc c
        ld a,c
        cp 3
        jr z,es_go
es_nx:  ld de,8
        add ix,de
        inc b
        ld a,b
        cp E_MAX
        jr nz,es_scan
es_go:  ld c,0                  ; scrittura dei 3 slot
es_w:   ld e,c
        ld d,0
        ld hl,e_sl
        add hl,de
        ld a,(hl)
        cp 0xFF
        jr z,es_hide
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld ix,ENT
        add ix,de
        ld l,(ix+1)
        ld h,(ix+2)
        ld de,(p_cam)
        or a
        sbc hl,de
        ld d,l                  ; X
        ld a,(ix+3)
        dec a
        ld e,a                  ; Y
        ld a,(ix+0)
        cp 1
        jr nz,es_bat
        ld a,(ix+4)             ; goblin: frame = direzione*2 + passo
        add a,a
        ld b,a
        ld a,(p_tick)
        rrca
        rrca
        rrca
        and 1
        add a,b
        jr es_pat
es_bat: ld a,(p_tick)
        rrca
        rrca
        rrca
        and 1
        add a,4
es_pat: add a,a
        add a,a
        add a,a                 ; frame*8
        add a,ENPAT
        ld b,a
        ld hl,e_buf             ; due piani: Y,X,pattern,0 (poi OTIR: scritture VDP troppo ravvicinate si perdono)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),b
        inc hl
        ld (hl),0
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld a,b
        add a,4
        ld (hl),a
        inc hl
        ld (hl),0
        ld hl,e_buf
        jr es_out
es_hide:
        ld hl,hide_attr
es_out: push bc
        ld bc,0x0898
        otir
        pop bc
        inc c
        ld a,c
        cp 3
        jr nz,es_w
        ld a,(p_ring)
        or a
        jr z,es_term
        call hud_attr           ; V9958: sei sprite HUD (piani 10-15) e terminatore
        jr es_col
es_term:
        call p2_attrs           ; due giocatori: sprite dell'eroe 2 (piani 10-11)
        ld a,216                ; fine della lista sprite
        out (0x98),a
es_col: ld c,0                  ; tabelle colore dei riempimenti, solo se il tipo dello slot e' cambiato
ec_l:   ld e,c
        ld d,0
        ld hl,e_sl
        add hl,de
        ld a,(hl)
        cp 0xFF
        jr z,ec_n
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld ix,ENT
        add ix,de
        ld a,(ix+0)             ; tipo
        ld hl,e_st
        ld e,c
        ld d,0
        add hl,de
        cp (hl)
        jr z,ec_n
        ld (hl),a
        ld b,a                  ; colore: goblin 3, pipistrello 13
        ld a,3
        dec b
        jr z,ec_c
        ld a,13
ec_c:   ld b,a
        ld a,c                  ; piano riempimento = 5 + 2*slot -> VRAM 0x7400 + piano*16
        add a,a
        add a,5
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,0x7400
        add hl,de
        push bc
        call vram_w
        pop bc
        ld a,b
        ld b,16
ec_w:   out (0x98),a
        djnz ec_w
ec_n:   inc c
        ld a,c
        cp 3
        jr nz,ec_l
        ret

hide_attr: db 0xE0,0,0,0,0xE0,0,0,0
sintab: db 0,2,3,5,6,7,8,8,8,8,7,6,5,3,2,0
        db 0,-2,-3,-5,-6,-7,-8,-8,-8,-8,-7,-6,-5,-3,-2,0
