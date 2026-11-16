; swspr.asm - SPRITE SOFTWARE con triplo buffer (solo V9958, scroll ad anello): spike dell'eroe.
; Modello di soccerwl (Tools/SpriteEncoder.py): ogni sprite e' codice Z80 compilato che scrive in VRAM solo i pixel opachi;
; niente limite di 8 sprite per riga, tutti i colori. Qui l'anello da 256 px e' triplicato:
;   pagine 0,1,2 = viste (y 0, 256, 512), pagina 3 righe 0..191 = master dello sfondo (y 768), tileset a y 960.
; A ogni fotogramma f: si MOSTRA la pagina S; si CANCELLA nella pagina E=(S+2)%3 lo sprite che c'era (HMMM dal master);
; si DISEGNA nella pagina D=(S+1)%3 la nuova posizione (che si vedra' al fotogramma f+1). Ogni pagina ricorda camera e
; posizione dello sprite. Le strisce di mondo entrano nel master (tile) e da li si copiano nelle viste (HMMM).
; Gli sprite sono a x pari (2 px per byte). Se lo sprite attraversa la cucitura dell'anello (x>240) o il confine di 16 KB
; della VRAM (riga 128 di una pagina) si disegna in un'area di lavoro (pagina 2, riga 224) e si copia con LMMM (TIMP).
; Con sw_on = 0 non cambia nulla: gli sprite restano hardware.
p_sw    equ PXV+6               ; 1 = abilita gli sprite software (V9958, un giocatore)
sw_on   equ PXV+0x10            ; attivo nella prova corrente
sw_S    equ PXV+0x11            ; pagina mostrata (0..2)
SWN     equ 10                  ; oggetti: 0-7 nemici, 8 giocatore 2, 9 giocatore 1
SWO     equ 0xCD00              ; SWN x 4 byte: frame (0xFF = assente), x del mondo (2), y  (RAM di reach.asm: libera in gioco)
SWOK    equ 0xCD40              ; 3 pagine x SWN: l'oggetto e' stato disegnato in quella vista
SWX     equ 0xCD60              ; 3 x SWN: x nell'anello (pari)
SWY     equ 0xCD80              ; 3 x SWN: y
sw_cam  equ PXV+0x1C            ; 3 x 2 byte: camera di ogni pagina
sw_lo   equ PXV+0x22            ; 4 x 2 byte: lo (primo px valido dell'anello) per le pagine 0..2 e il master (3)
sw_idle equ PXV+0x2A            ; 2 byte: giri di attesa del vblank nell'ultimo fotogramma (misura del carico)
sw_ovr  equ PXV+0x2C            ; 2 byte: fotogrammi in cui il vblank era gia' passato
sw_fn   equ PXV+0x2E            ; 2 byte: fotogrammi eseguiti
sx_x    equ PXV+0x30
sx_n    equ PXV+0x31
sx_y    equ PXV+0x32
sx_h    equ PXV+0x33
sx_pg   equ PXV+0x34
sw_D    equ PXV+0x35
sw_E    equ PXV+0x36
sw_rx   equ PXV+0x37
sw_ry   equ PXV+0x38
sx_t    equ PXV+0x39
sx_n2   equ PXV+0x3A
p_cmax  equ PXV+0x4B            ; 2 byte: camera massima = larghezza del livello (ultima colonna non vuota + 1) * 16 - 256
p_needk equ PXV+0x4D            ; 1 byte: il livello ha una chiave (serve per uscire)
p_cr    equ PXV+0x4E            ; livelli alti (tall.asm): riga di BIG in cima alla finestra MAP
p_tall  equ PXV+0x4F            ; 1 = livello alto (32 righe) in BIG
p_tkey  equ PXV+0x50            ; 1 = c'e' una chiave in BIG
; HUD dei livelli alti (hud.asm) e geometria delle viste
h_init  equ PXV+0x5E            ; 0xA5 = punteggi inizializzati
h_sc1   equ PXV+0x5F            ; 3 byte BCD (LSB per primo)
h_sc2   equ PXV+0x62
h_hi    equ PXV+0x65
h_life  equ PXV+0x68
h_dirty equ PXV+0x69            ; bit0 = fascia alta da ridisegnare, bit1 = bassa
p_voff  equ PXV+0x6A            ; riga della vista dove inizia il gioco: 0 normale, 8 con l'HUD
p_vh    equ PXV+0x6B            ; altezza del gioco in righe: 192 / 176
p_vmax  equ PXV+0x6C            ; y massima (esclusa) di un oggetto interamente visibile: 177 / 161
p_vr1   equ PXV+0x6D            ; ultima riga di tile disegnata nel master: MAPH-1 / 10
h_nrow  equ PXV+0x6E
h_tmp   equ PXV+0x6F
h_f1    equ PXV+0x70
h_f2    equ PXV+0x71
h_fill  equ PXV+0x72
h_line  equ PXV+0x73
h_col   equ PXV+0x74
h_rm    equ PXV+0x75
h_ad    equ PXV+0x76            ; 2 byte
h_rows  equ PXV+0x78
h_pg    equ PXV+0x79
h_rot   equ PXV+0x7A
h_sx    equ PXV+0x7B
h_dx    equ PXV+0x7C
h_nx    equ PXV+0x7D
h_nh    equ PXV+0x7E
h_sy    equ PXV+0x7F
h_dy    equ PXV+0x80
h_buf   equ PXV+0x81            ; 8 byte
h_lr    equ PXV+0x8A            ; 3 byte: rotazione dell'ultima copia dell'HUD in ogni vista (0xFF = da rifare)
; interruzione di linea per l'HUD fermo (irq.asm): vettori IM2 a 0xEC00, gestore a 0xEDED
isr_st  equ PXV+0x90            ; 0 = prossima IRQ alla riga alta (scroll di gioco), 1 = alla riga bassa (scroll 0)
isr_c26 equ PXV+0x91            ; valori R#26/R#27 della vista mostrata (scritti da sw_show)
isr_c27 equ PXV+0x92
irq_on  equ PXV+0x93            ; 1 = interrupt abilitati (solo durante la prova di un livello alto)
isr_mp  equ PXV+0x94
sw_inframe equ PXV+0x95         ; 1 = si sta eseguendo un frame compilato (coppie di indirizzo non interrompibili)
isr_l1  equ PXV+0x96            ; R#19 per la riga alta
isr_l2  equ PXV+0x97            ; R#19 per la riga bassa
isr_r1  equ PXV+0x98            ; RG1SAV originale
isr_vb  equ PXV+0x99            ; bit7 = la ISR ha consumato il flag di vblank (sw_vwait lo deve considerare visto)
sw_wy   equ PXV+0x89            ; y dell'oggetto nella finestra (la y nella vista e' sw_ry = sw_wy + p_voff)
sw_t    equ PXV+0x3B            ; 2 byte
sw_j    equ PXV+0x3E            ; oggetto corrente
sw_fr   equ PXV+0x3F            ; frame dell'oggetto corrente
sw_dbg  equ PXV+0x3D            ; solo misure: bit0 = salta sw_update, bit1 = salta fisica/nemici
SWSCR_Y equ 736                 ; area di lavoro: pagina 2, riga 224 (0x17000)

; ------------------------------------------------------------------------- ciclo di gioco
pl_sw:  call sw_vwait
        call sw_show
        call snd_tick
        call read_inputs
        ld a,7
        call readrow
        bit 2,a                 ; ESC
        jr nz,pls_ne
        ld a,1
        ld (p_exit),a
pls_ne: ld a,(sw_dbg)
        bit 1,a
        jr nz,pls_nl
        ld a,(p_two)
        or a
        jr nz,pls_2
        call play_physics
        call ent_update
        call ent_hit
pls_nl: call hero_calcframe
        jr pls_cm
pls_2:  call play_2p_sw         ; due giocatori: fisica e frame di entrambi, camera sul leader
pls_cm: call win_check
        call ring_frame         ; politica di camera (in sw_on aggiorna solo p_cam)
        ld a,(sw_dbg)
        bit 0,a
        call z,sw_update
        call sw_sat             ; sprite hardware: nemici e HUD (l'eroe e' software)
        ld a,(sw_S)
        inc a
        cp 3
        jr c,pls_s
        xor a
pls_s:  ld (sw_S),a
        ld a,(p_exit)
        or a
        jr z,pl_sw
        jp play_end

; attesa del vblank misurando i giri a vuoto
sw_vwait:
        ld hl,0
        ld a,(isr_vb)
        or a
        jr z,swv_l
        xor a
        ld (isr_vb),a
        jr swv_d
swv_l:  in a,(0x99)
        rlca
        jr c,swv_d
        inc hl
        jr swv_l
swv_d:  ld (sw_idle),hl
        ld a,h
        or l
        jr nz,swv_n
        ld hl,(sw_ovr)
        inc hl
        ld (sw_ovr),hl
swv_n:  ld hl,(sw_fn)
        inc hl
        ld (sw_fn),hl
        ret


; ---- ingressi in pagina 1: il motore sta nel segmento 3 (finestra A000, insieme ai frame compilati)
sw_show:   ld bc,sw_show_i
           jr sw_tr
sw_update: ld bc,sw_update_i
           jr sw_tr
sw_fill:   ld bc,sw_fill_i
           jr sw_tr
sw_cell:   ld bc,sw_cell_i
           jr sw_tr
win_check: ld bc,win_check_i
           jr sw_tr
win_fit:   ld bc,win_fit_i
           jr sw_tr
tall_init: ld bc,tall_init_i
           jr sw_tr
tall_decode: ld bc,tall_decode_i
           jr sw_tr
hud_item:  ld bc,hud_item_i             ; A = tile raccolto
           jp seg3_tr
irq_start: ld bc,irq_start_i
           jr sw_tr
irq_stop:  ld bc,irq_stop_i
           jr sw_tr
hud_kill:  ld bc,hud_kill_i
           jp seg3_tr
hud_win:   ld bc,hud_win_i
           jp seg3_tr
hud_die:   ld bc,hud_die_i
           jp seg3_tr
view_geo:  ld bc,view_geo_i
sw_tr:     ld a,3
           ld (0xB000),a
           call sw_jbc
           ld a,HEROSEG
           ld (0xB000),a
           ret
sw_jbc:    push bc
           ret

; sprite hardware: solo l'HUD (piani 10-15); eroe e nemici (piani 0-9) sono software
sw_sat:
        ld hl,0x7600
        call vram_w
        ld b,5
ssb_l:  push bc
        ld hl,hide_attr
        ld bc,0x0898
        otir
        pop bc
        djnz ssb_l
        ld a,(p_tall)           ; livelli alti: l'HUD e' quello nelle viste (hud.asm)
        or a
        ret nz
        jp hud_attr

