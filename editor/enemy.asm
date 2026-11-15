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

; copia la mappa in VRAM (pagina 3, 0x18000) e la ripristina
map_save:
        ld a,6
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
        ld a,0x40
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
        ld a,6
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        xor a
        out (0x99),a
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
        ld a,(p_tick)
        and 1
        jr nz,gb_grav
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
        jr gb_grav
gb_turn:
        ld a,(ix+4)
        xor 1
        ld (ix+4),a
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
        ld (ix+7),96
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
        jr z,eh_n
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
        ld (ix+0),0             ; il nemico muore
        ld a,(p_kills)
        inc a
        ld (p_kills),a
        ld a,SFX_STOMP
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
