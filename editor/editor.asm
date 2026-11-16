; SamPr World - editor di livelli (v0): scelta e posizionamento dei blocchi
; MSX2, SCREEN 5. ROM 32K (pagina 1), codice eseguito in ROM, mappa in RAM.
;
; Tasti:  frecce = muovi    SPAZIO = piazza    X o DEL = cancella    , e . = tile prec/succ
;         P = prendi il tile sotto il cursore    TAB = elenco blocchi    INVIO = scegli    ESC = chiudi
;
; Schermo: mappa 16x12 tile (256x192) + barra di stato (20 righe). Il tileset sta in pagina 1 di VRAM
; (y=256..), la mappa si ridisegna con HMMM pagina1->pagina0.
        IFDEF TESTBUILD
        output "editor_test.rom"        ; per i test automatici: senza menu all'avvio
        ELSE
        output "editor.rom"
        ENDIF

CHGMOD  equ 0x005F
GRPPRT  equ 0x008D
ENASLT  equ 0x0024
EXPTBL  equ 0xFCC1
SLTTBL  equ 0xFCC5
FORCLR  equ 0xF3E9
GRPACX  equ 0xFCB7
GRPACY  equ 0xFCB9
RG1SAV  equ 0xF3E0
BAKCLR  equ 0xF3EA

MAPW    equ 128
MAPH    equ 12
MAP     equ 0xC000              ; MAPW*MAPH = 1536 byte
V       equ 0xC800
P       equ 0xC840              ; tabella parametri VDP (15 byte)
v_curx  equ V+0
v_cury  equ V+1
v_scrx  equ V+2
v_tile  equ V+3
v_pick  equ V+4
v_pcur  equ V+5
v_rep   equ V+6
v_held  equ V+7
v_prev2 equ V+8
v_prev4 equ V+9
v_prev7 equ V+10
v_prev8 equ V+11
v_k8    equ V+12
v_k5    equ V+13
v_e2    equ V+14
v_e4    equ V+15
v_e7    equ V+16
v_e8    equ V+17
v_frame equ V+18
v_bcol  equ V+19
v_redr  equ V+20
v_dirty equ V+21
v_nosp  equ V+22
v_prev5 equ V+23
v_e5    equ V+24
v_msg   equ V+25                ; puntatore al messaggio da mostrare (2 byte)
v_lvalid equ V+0x80
v_lseg  equ V+0x81
v_lpos  equ V+0x82              ; 2 byte
v_fseg  equ V+0x84
v_fpos  equ V+0x85              ; 2 byte
v_rlen  equ V+0x87              ; 2 byte
v_seq   equ V+0x89
v_perr  equ V+0x8A
v_rt    equ V+0x8B
v_rn    equ V+0x8C
v_tmp   equ V+0x8D              ; 2 byte
v_segi  equ V+0x8F
REC     equ 0xD000              ; record bozza: 'D','R',seq,len2,blob,somma
FLRT    equ 0xC900              ; routine flash copiate in RAM
DRAFTSEG equ 24                 ; primo segmento (8K) del settore bozza = 64K allineati
SETSEG  equ 16                  ; settore impostazioni di rete (riservato)
BANKW   equ 0x9000              ; registro banco Konami5 della finestra 8000-9FFF
ENAR    equ 0x7FFF
EXTBIO  equ 0xFFCA
ARG     equ 0xF847
TXBUF   equ 0xE000
RXBUF   equ 0xE100
SETREC  equ 0xE200              ; copia in RAM del record impostazioni (128 B)
NETRT   equ 0xE400              ; modulo di rete copiato in RAM
v_sfound equ V+0x92
v_msgnum equ V+0x93             ; 2 byte: numero da accodare al messaggio
v_msgnf equ V+0x95
v_prev3 equ V+0x9E
v_flash equ FBUF+0xB7             ; 1 = flash Yamanooto rilevata
v_unsaved equ FBUF+0xB6          ; 1 = il disegno ha modifiche non ancora salvate in flash
v_prev6 equ V+0x9C
v_e6    equ V+0x9D
v_e3    equ V+0x9F
v_valid equ V+0x96              ; 1 = il creatore ha superato questo livello (vale solo finche' non lo modifica)
v_conf  equ V+0x97              ; conferma di SELECT: frame residui
DEVBUILD equ 1                  ; 1 = tasto V valida senza giocare (SOLO SVILUPPO: finche' non c'e' la modalita' prova)

        org 0x4000
        db "AB"
        dw start,0,0,0,0,0,0

start:  di
        ld sp,0xF380
        call getslot
        ld h,0x80
        call ENASLT             ; pagina 2 = cartuccia (finestre banco 8000-BFFF)
        ld hl,flashrt_rom
        ld de,FLRT
        ld bc,flashrt_end-flashrt_rom
        ldir
        ld a,9                  ; il modulo di rete sta nel segmento 9 (finestra A000)
        ld (0xB000),a
        ld hl,0xA000
        ld de,NETRT
        ld bc,netrt_end-netrt_rom
        ldir
        ld a,HEROSEG
        ld (0xB000),a
        ld a,DRAFTSEG           ; rileva la flash (e se manca non si tenta di salvare)
        ld (BANKW),a
        call ram_probe
        ld a,0
        jr c,st_nf
        inc a
st_nf:  ld (v_flash),a
        ld a,5
        call CHGMOD
        di
        call detect_vdp         ; V9958 (MSX2+) = scroll hardware, V9938 = scroll a passi
        ld a,0x80               ; 212 righe
        ld e,9
        call wrreg
        ld a,0x28               ; TP=1: il colore 0 e' un colore vero (non trasparente)
        ld e,8
        call wrreg
        ld a,(RG1SAV)
        or 2                    ; sprite 16x16
        ld e,1
        call wrreg
        ld a,0xEF               ; attributi sprite 0x7600 (i bit 1-0 di R#5 devono valere 1: azzerati, i piani 8-31 usano le tabelle colore dei piani 0-7)
        ld e,5
        call wrreg
        ld a,0x0F               ; generatore sprite = 0x7800
        ld e,6
        call wrreg
        xor a
        ld e,11
        call wrreg
        ; palette
        xor a
        ld e,16
        call wrreg
        ld hl,palette
        ld bc,0x209A
        otir
        ; schermo nero
        ld hl,p_clear
        call vdp_cmd
        call upload_tiles
        call init_sprite
        call init_map
        ; variabili
        ld hl,V
        ld de,V+1
        ld bc,0xFF
        ld (hl),0
        ldir
        ld a,T_GRASS
        ld (v_tile),a
        ld a,15
        ld (v_bcol),a
        ld a,10
        ld (v_cury),a
        xor a
        ld (p_two),a            ; un giocatore (il menu lo cambia)
        ld (p_tin1),a           ; (solo TESTBUILD: tasti forzati da Tcl) la RAM all'accensione non e' azzerata
        ld (p_tin2),a
        ld (p_tall),a
        ld (p_cr),a
        ld (p_sw),a
        ld (sw_on),a
        ld (sw_dbg),a
        ld (sw_ovr),a
        ld (sw_ovr+1),a
        ld (sw_fn),a
        ld (sw_fn+1),a
        inc a
        ld (p_sw),a             ; sprite software attivi di default (solo V9958: play_init li abilita se p_ring)
        call cp_load            ; progressi della campagna dalla flash
        call load_draft         ; se c'e' una bozza in flash, si riparte da li'
        ld a,(v_flash)
        or a
        jr nz,st_fl
        ld hl,m_nofl2           ; senza flash il salvataggio non funziona: lo si dice subito
        ld (v_msg),hl
st_fl:
        IFNDEF TESTBUILD
        call do_menu
        ENDIF
        call redraw_map
        call sprite_update
        call draw_status

; ------------------------------------------------------------------------- ciclo principale
main:   call vwait
        ld a,(v_conf)
        or a
        jr z,mcf
        dec a
        ld (v_conf),a
mcf:    ld hl,v_frame
        inc (hl)
        ld a,(hl)
        and 0x0F
        call z,blink
        ld a,8
        call readrow
        cpl
        ld (v_k8),a
        ld a,5
        call readrow
        cpl
        ld (v_k5),a
        ld a,2
        ld hl,v_prev2
        call edge
        ld (v_e2),a
        ld a,4
        ld hl,v_prev4
        call edge
        ld (v_e4),a
        ld a,7
        ld hl,v_prev7
        call edge
        ld (v_e7),a
        ld a,5
        ld hl,v_prev5
        call edge
        ld (v_e5),a
        ld a,3
        ld hl,v_prev3
        call edge
        ld (v_e3),a
        ld a,6
        ld hl,v_prev6
        call edge
        ld (v_e6),a
        ld a,8
        ld hl,v_prev8
        call edge
        ld (v_e8),a
        ; TAB apre/chiude l'elenco, ESC lo chiude
        ld a,(v_e7)
        bit 3,a
        jp nz,toggle_picker
        bit 2,a
        jr z,nopk
        ld a,(v_pick)
        or a
        jp nz,toggle_picker
nopk:   ld a,(v_pick)
        or a
        jp nz,picker_logic

; ------------------------------------------------------------------------- modalita' modifica
        call get_move           ; B=dx C=dy
        ld a,b
        or c
        jr z,nomove
        ld a,(v_curx)
        add a,b
        cp MAPW
        jr nc,skx
        ld (v_curx),a
skx:    ld a,(v_cury)
        add a,c
        cp MAPH
        jr nc,sky
        ld (v_cury),a
sky:    ld a,(v_curx)           ; scorrimento orizzontale
        ld hl,v_scrx
        cp (hl)
        jr nc,chkr
        ld (hl),a
        jr dored
chkr:   sub 15
        jr c,nosc
        cp (hl)
        jr c,nosc
        jr z,nosc
        ld (hl),a
dored:  ld a,1
        ld (v_redr),a
nosc:   ld a,1
        ld (v_dirty),a
nomove: ld a,(v_k8)
        bit 0,a
        jr nz,spc
        xor a
        ld (v_nosp),a
        jr nospc
spc:    ld a,(v_nosp)
        or a
        jr nz,nospc
        ld a,(v_tile)
        call place
nospc:  ld a,(v_k8)
        bit 3,a                 ; DEL
        jr nz,erase
        ld a,(v_k5)
        bit 5,a                 ; X
        jr z,noerase
erase:  xor a
        call place
noerase:
        ld a,(v_e2)
        bit 2,a                 ; ,
        jr z,nprev
        ld a,(v_tile)
        or a
        jr nz,pv1
        ld a,T_COUNT
pv1:    dec a
        ld (v_tile),a
        ld a,1
        ld (v_dirty),a
nprev:  ld a,(v_e2)
        bit 3,a                 ; .
        jr z,nnext
        ld a,(v_tile)
        inc a
        cp T_COUNT
        jr c,nx1
        xor a
nx1:    ld (v_tile),a
        ld a,1
        ld (v_dirty),a
nnext:  ld a,(v_e4)
        bit 5,a                 ; P
        jr z,nopick
        call cur_addr
        ld a,(hl)
        ld (v_tile),a
        ld a,1
        ld (v_dirty),a
nopick: ld a,(v_e7)
        bit 7,a                 ; INVIO su un nemico = proprieta' (props.asm)
        jr z,noprop
        call cur_addr
        ld a,(hl)
        cp T_GOBLIN
        jr z,doprop
        cp T_BAT
        jr nz,noprop
doprop: call do_eprops
noprop: ld a,(v_e6)
        bit 5,a                 ; F1 = menu (salva prima la bozza se serve)
        jr z,nomenu
        call autosave
        call do_menu
nomenu:
        ld a,(v_e4)
        bit 3,a                 ; N = impostazioni di rete
        call nz,do_netset
        ld a,(v_e3)
        bit 1,a                 ; D = livelli sul server
        call nz,do_browse
        ld a,(v_e3)
        bit 0,a                 ; C = controlla le monete raggiungibili
        call nz,do_check
        ld a,(v_e5)
        bit 0,a                 ; S = salva la bozza in flash
        call nz,do_save
        ld a,(v_e5)
        bit 2,a                 ; U = pubblica sul server
        call nz,do_publish
        ld a,(v_e5)
        bit 1,a                 ; T = prova il livello (salva prima la bozza se serve)
        jr z,noplay
        call autosave
        call do_play
        xor a
        call rc_run             ; dopo la prova: avviso se ci sono monete/uscita irraggiungibili
noplay:
        IF DEVBUILD
        ld a,(v_e5)
        bit 3,a                 ; V = valida (DEV)
        call nz,do_devvalid
        ENDIF
        ld a,(v_e4)
        bit 1,a                 ; L = ricarica la bozza
        call nz,do_load
        ld a,(v_e7)
        bit 6,a                 ; SELECT = nuovo livello (cancella anche la bozza)
        call nz,do_new
        ld a,(v_redr)
        or a
        jr z,nor
        xor a
        ld (v_redr),a
        call redraw_map
nor:    call sprite_update
        ld a,(v_dirty)
        or a
        jp z,main
        xor a
        ld (v_dirty),a
        call draw_status
        jp main

; ------------------------------------------------------------------------- modalita' elenco blocchi
picker_logic:
        call get_move
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        add a,b
        ld d,a
        or a
        jr z,pnomv
        ld a,(v_pcur)
        add a,d
        cp T_COUNT
        jr nc,pnomv
        ld (v_pcur),a
        ld a,1
        ld (v_dirty),a
pnomv:  ld a,(v_e8)
        bit 0,a
        jr nz,pselect
        ld a,(v_e7)
        bit 7,a
        jr z,pdone
pselect:
        ld a,(v_pcur)
        ld (v_tile),a
        ld a,1
        ld (v_nosp),a
        jp toggle_picker
pdone:  call sprite_update
        ld a,(v_dirty)
        or a
        jp z,main
        xor a
        ld (v_dirty),a
        call draw_status
        jp main

toggle_picker:
        ld a,(v_pick)
        xor 1
        ld (v_pick),a
        jr z,tpclose
        ld a,(v_tile)
        ld (v_pcur),a
        call draw_picker
        jr tpend
tpclose:
        call redraw_map
tpend:  call sprite_update
        call draw_status
        xor a
        ld (v_dirty),a
        jp main

draw_picker:
        ld hl,p_pick
        call vdp_cmd
        ld d,0
dpl:    ld a,d
        and 15
        ld b,a
        ld a,d
        rrca
        rrca
        rrca
        rrca
        and 15
        ld c,a
        ld a,d
        push de
        call draw_tile
        pop de
        inc d
        ld a,d
        cp T_COUNT
        jr nz,dpl
        ret

; ------------------------------------------------------------------------- mappa
; indirizzo in RAM della cella sotto il cursore -> HL
cur_addr:
        ld a,(v_cury)
        ld h,a
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(v_curx)
        ld e,a
        ld d,0
        add hl,de
        ret

; piazza il tile A nella cella del cursore
place:  ld c,a
        call cur_addr
        ld a,(hl)
        cp c
        ret z
        ld (hl),c
        xor a
        ld (v_valid),a          ; modificato: va rigiocato
        inc a
        ld (v_unsaved),a
        ld a,(v_curx)
        ld hl,v_scrx
        sub (hl)
        ld b,a
        ld e,c
        ld a,(v_cury)
        ld c,a
        ld a,e
        jp draw_tile

; tile della mappa in colonna schermo B, riga C -> A
get_tile:
        ld h,c
        ld l,0
        srl h
        rr l
        ld de,MAP
        add hl,de
        ld a,(v_scrx)
        add a,b
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ret

redraw_map:
        ld c,0
rmr:    ld b,0
rmc:    push bc
        call get_tile
        call draw_tile
        pop bc
        inc b
        ld a,b
        cp 16
        jr nz,rmc
        inc c
        ld a,c
        cp MAPH
        jr nz,rmr
        ret

; disegna il tile A in colonna B, riga C (celle da 16x16 su pagina 0)
draw_tile:
        ld e,a
        and 15
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+0),a              ; SX
        xor a
        ld (P+1),a
        ld a,e
        call tile_sy            ; SY dalla tabella delle righe del tileset
        ld a,l
        ld (P+2),a
        ld a,h
        ld (P+3),a
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+4),a              ; DX
        xor a
        ld (P+5),a
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        ld (P+6),a              ; DY
        xor a
        ld (P+7),a
        ld a,16
        ld (P+8),a              ; NX
        xor a
        ld (P+9),a
        ld a,16
        ld (P+10),a             ; NY
        xor a
        ld (P+11),a
        ld (P+12),a
        ld (P+13),a
        ld a,0xD0               ; HMMM
        ld (P+14),a
        ld hl,P
        jp vdp_cmd

; ------------------------------------------------------------------------- input
; riga della matrice tastiera A -> A (0 = tasto premuto)
readrow:
        ld b,a
        in a,(0xAA)
        and 0xF0
        or b
        out (0xAA),a
        in a,(0xA9)
        ret

; fronti di salita: A = riga, HL = indirizzo del valore precedente -> A = tasti appena premuti
edge:   push hl
        call readrow
        pop hl
        cpl
        ld b,a
        ld a,(hl)
        cpl
        and b
        ld c,a
        ld (hl),b
        ld a,c
        ret

; movimento con ripetizione: B = dx, C = dy (0, 1, 255)
get_move:
        ld a,(v_k8)
        and 0xF0
        jr nz,gmh
        xor a
        ld (v_rep),a
        ld (v_held),a
        ld b,a
        ld c,a
        ret
gmh:    ld a,(v_rep)
        or a
        jr z,gmgo
        dec a
        ld (v_rep),a
        ld bc,0
        ret
gmgo:   ld a,(v_held)
        or a
        ld a,10
        jr z,gms
        ld a,3
gms:    ld (v_rep),a
        ld a,1
        ld (v_held),a
        ld a,(v_k8)
        ld b,0
        ld c,0
        bit 4,a
        jr z,gm1
        ld b,0xFF
gm1:    bit 7,a
        jr z,gm2
        ld b,1
gm2:    bit 5,a
        jr z,gm3
        ld c,0xFF
gm3:    bit 6,a
        ret z
        ld c,1
        ret

; ------------------------------------------------------------------------- sprite cursore
init_sprite:
        ld hl,0x7800
        call vram_w
        ld hl,spat
        ld bc,0x2098
        otir
        ld hl,0x7400
        call vram_w
        ld a,15
        ld b,16
isc:    out (0x98),a
        djnz isc
        ret

blink:  ld a,(v_bcol)
        xor 15^12
        ld (v_bcol),a
        ld hl,0x7400
        call vram_w
        ld a,(v_bcol)
        ld b,16
bl1:    out (0x98),a
        djnz bl1
        ret

sprite_update:
        ld a,(v_pick)
        or a
        jr nz,supk
        ld a,(v_curx)
        ld hl,v_scrx
        sub (hl)
        ld b,a
        ld a,(v_cury)
        ld c,a
        jr suw
supk:   ld a,(v_pcur)
        and 15
        ld b,a
        ld a,(v_pcur)
        rrca
        rrca
        rrca
        rrca
        and 15
        ld c,a
suw:    ld hl,0x7600
        call vram_w
        ld a,c
        add a,a
        add a,a
        add a,a
        add a,a
        dec a
        out (0x98),a            ; Y
        ld a,b
        add a,a
        add a,a
        add a,a
        add a,a
        out (0x98),a            ; X
        xor a
        out (0x98),a            ; pattern 0
        out (0x98),a
        ld a,216                ; fine lista sprite
        out (0x98),a
        ret

; ------------------------------------------------------------------------- barra di stato
draw_status:
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
        ld a,(v_pick)
        or a
        ld a,(v_tile)
        jr z,dst1
        ld a,(v_pcur)
dst1:   ld e,a
        call print_num2
        ld a,' '
        call print_char
        ; nome
        ld l,e
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld d,h
        ld e,l
        add hl,hl
        add hl,de               ; *24
        ld de,tile_names
        add hl,de
        ld a,2                  ; i nomi stanno nel segmento 2 (finestra A000)
        ld (0xB000),a
        call print_str
        ld a,(v_valid)
        or a
        ld hl,s_val
        call nz,print_str
        ld hl,2
        ld (GRPACX),hl
        ld hl,203
        ld (GRPACY),hl
        ld hl,s_x
        call print_str
        ld a,(v_curx)
        call print_num3
        ld hl,s_y
        call print_str
        ld a,(v_cury)
        call print_num2
        ld hl,(v_msg)
        ld a,h
        or l
        jr nz,dsm
        ld hl,s_help
dsm:    call print_str
        ld a,(v_msgnf)
        or a
        jr z,dsn
        xor a
        ld (v_msgnf),a
        ld hl,(v_msgnum)
        call printdec16
dsn:    ld hl,0
        ld (v_msg),hl
        ret

print_char:
        push bc
        push de
        push hl
        call GRPPRT
        di
        pop hl
        pop de
        pop bc
        ret

print_str:
        ld a,(hl)
        or a
        ret z
        inc hl
        push hl
        call print_char
        pop hl
        jr print_str

print_num3:
        ld b,100
        call pnd
print_num2x:
        ld b,10
        call pnd
        add a,'0'
        jp print_char
print_num2:
        ld b,10
        call pnd
        add a,'0'
        jp print_char
pnd:    ld c,'0'-1
pnl:    inc c
        sub b
        jr nc,pnl
        add a,b
        push af
        ld a,c
        call print_char
        pop af
        ret

; ------------------------------------------------------------------------- VDP
wrreg:  out (0x99),a
        ld a,e
        or 0x80
        out (0x99),a
        ret

vwait:  in a,(0x99)
vwl:    in a,(0x99)
        rlca
        jr nc,vwl
        ret

vdp_wait:
        ld a,2
        out (0x99),a
        ld a,0x8F
        out (0x99),a
vwc:    in a,(0x99)
        rrca
        jr c,vwc
        xor a
        out (0x99),a
        ld a,0x8F
        out (0x99),a
        ret

; esegue il comando VDP descritto da 15 byte in (HL), a partire da R#32
vdp_cmd:
        call vdp_wait
        ld a,32
        out (0x99),a
        ld a,0x91
        out (0x99),a
        ld bc,0x0F9B
        otir
        ret

; imposta l'indirizzo VRAM di scrittura HL (bit 16 = 0)
vram_w: ld a,h
        rlca
        rlca
        and 3
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        ld a,l
        out (0x99),a
        ld a,h
        and 0x3F
        or 0x40
        out (0x99),a
        ret

; imposta l'indirizzo VRAM di scrittura 0x10000+HL (pagina 2)
vram_w_hi:
        ld a,h
        rlca
        rlca
        and 3
        or 4
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        ld a,l
        out (0x99),a
        ld a,h
        and 0x3F
        or 0x40
        out (0x99),a
        ret

; Geometria del tileset in VRAM: i tile (16x16) stanno in righe da 16 tile (16 righe di pixel); la riga r del tileset
; (tile 16r..16r+15) sta alla y assoluta trow_tab[r] (0..1023 = pagina*256 + riga). Le righe stanno negli spazi liberi
; delle pagine (le pagine 0-2 sono viste di gioco, la 3 e' il master): vedi docs/SWSPRITES.md. Fino a 9 righe = 144 tile.
; Con -DTILETEST due righe vengono spostate altrove (prova della tabella).
trow_tab:
        IFDEF TILETEST
        dw 960,976,720,480,720+32,752,480,496,212
        ELSE
        dw 960,976,992,1008,720,752,480,496,212
        ENDIF
; segmento dei dati per ogni gruppo di 64 tile (128 byte ciascuno = 8 KB)
tileseg_tab: db 5,7,8,9

; A = id del tile -> HL = y assoluta (pagina*256 + riga) del suo bordo superiore nel tileset (clobbera A, DE)
tile_sy:
        rrca
        rrca
        rrca
        rrca
        and 15
        add a,a
        ld e,a
        ld d,0
        ld hl,trow_tab
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        ret

; imposta l'indirizzo VRAM di scrittura DE (16 bit bassi) con A16 in A (0/1)
vram_w17:
        add a,a
        add a,a
        ld b,a
        ld a,d
        rlca
        rlca
        and 3
        or b
        out (0x99),a
        ld a,0x8E
        out (0x99),a
        ld a,e
        out (0x99),a
        ld a,d
        and 0x3F
        or 0x40
        out (0x99),a
        ret

; copia il tileset in VRAM secondo trow_tab: i dati dei tile stanno nei segmenti di tileseg_tab (finestra A000)
upload_tiles:
        xor a
        ld (V+0x30),a
utt:    ld a,(V+0x30)
        and 63
        jr nz,uts
        ld a,(V+0x30)           ; ogni 64 tile si cambia segmento
        rlca
        rlca
        and 3
        ld e,a
        ld d,0
        ld hl,tileseg_tab
        add hl,de
        ld a,(hl)
        ld (0xB000),a
        ld hl,0xA000
        ld (V+0x32),hl
uts:    ld a,(V+0x30)           ; DE = y assoluta della riga del tile
        call tile_sy
        ex de,hl
        ld a,d                  ; A16 = y >> 9
        and 2
        rrca
        ld (V+0x31),a
        ld a,d                  ; indirizzo = (y & 511) * 128 + colonna * 8
        and 1
        rrca
        ld h,a
        ld a,e
        srl a
        or h
        ld h,a
        ld a,e
        and 1
        rrca
        ld l,a
        ld a,(V+0x30)
        and 15
        add a,a
        add a,a
        add a,a
        add a,l
        ld e,a
        ld d,h                  ; DE = indirizzo a 16 bit
        ld b,16
utr:    push bc
        push de
        ld a,(V+0x31)
        call vram_w17
        ld hl,(V+0x32)
        ld bc,0x0898
        otir
        ld (V+0x32),hl
        pop de
        ld a,128
        add a,e
        ld e,a
        jr nc,utn
        inc d
utn:    pop bc
        djnz utr
        ld a,(V+0x30)
        inc a
        ld (V+0x30),a
        cp T_COUNT
        jr nz,utt
        ret

        include "draft.asm"
        include "publish.asm"
        include "scroll.asm"
        include "ring.asm"
        include "enemy.asm"
        include "blocks.asm"
        include "reach.asm"
        include "audio.asm"
        include "netui.asm"
        include "netset.asm"
        include "menu.asm"
        include "campaign.asm"
        include "play.asm"
        include "coop.asm"
        include "swspr.asm"
        include "props.asm"

; ------------------------------------------------------------------------- dati
p_clear: db 0,0,0,0, 0,0,0,0, 0,1, 212,0, 0x11,0,0xC0
p_stat:  db 0,0,0,0, 0,0,192,0, 0,1, 20,0, 0x11,0,0xC0
p_pick:  db 0,0,0,0, 0,0,0,0, 0,1, 64,0, 0x11,0,0xC0
s_x:     db "X:",0
s_y:     db " Y:",0
s_help:  db "  S=save TAB=list",0
s_val:   db " [OK]",0
; cursore 16x16: cornice spessa 2 pixel (UL, LL, UR, LR)
spat:    db 0xFF,0xFF,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0
         db 0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xFF,0xFF
         db 0xFF,0xFF,0x03,0x03,0x03,0x03,0x03,0x03
         db 0x03,0x03,0x03,0x03,0x03,0x03,0xFF,0xFF
palette: incbin "../assets/palette.bin"
        include "../assets/tileset.inc"
        ds 0x8000-$,0xFF
; segmenti 2..31 vuoti (FF). 16..23 = settore impostazioni, 24..31 = settore bozza (64K allineati)
        ; segmento 2: nomi dei tile (finestra A000, registro B000) per liberare spazio nella pagina 1; segmento 3 vuoto
        disp 0xA000
        include "../assets/tilenames.inc"
tile_names_end:
        ent
        ds 0x2000-(tile_names_end-tile_names),0xFF
        ; segmento 3: frame compilati dell'eroe (sprite software), finestra A000
        disp 0xA000
        include "swengine.asm"
        include "swreach.asm"
        include "swprops.asm"
        include "swcam.asm"
        include "tall.asm"
        include "hud.asm"
        include "swtab.inc"
swh_end:
        ent
        ds 0x2000-(swh_end-0xA000),0xFF
        incbin "../assets/sprites.bin"          ; segmento 4: sprite eroe + nemici (finestra A000)
        incbin "../assets/tiles_seg.bin"        ; segmento 5: tileset (finestra A000)
        incbin "../assets/campaign.bin"         ; segmento 6: i 7 livelli fissi della campagna
        incbin "../assets/tiles_seg2.bin"       ; segmento 7: tile 64..127
        incbin "../assets/tiles_seg3.bin"       ; segmento 8: tile 128..191
netrt_rom:                                              ; segmento 9 (i tile 192.. non servono): modulo di rete, copiato in RAM all'avvio
        include "netpub.asm"
        ds 0x2000-(netrt_end-netrt_rom),0xFF
        include "swfr10.inc"                    ; segmento 10: frame compilati degli sprite software (finestra 8000)
        ds 0x2000-(swfr10_end-0x8000),0xFF
        include "swfr11.inc"                    ; segmento 11
        ds 0x2000-(swfr11_end-0x8000),0xFF
        include "swfr12.inc"                    ; segmento 12
        ds 0x2000-(swfr12_end-0x8000),0xFF
        include "swfr13.inc"                    ; segmento 13
        ds 0x2000-(swfr13_end-0x8000),0xFF
        ds 0x20000-0x1C000,0xFF
        incbin "../assets/settings_dev.bin"     ; segmento 16: record impostazioni di SVILUPPO (segnaposto)
        ds 0x40000-0x20000-128,0xFF
