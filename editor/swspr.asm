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
sw_ok   equ PXV+0x12            ; 3 byte: la pagina contiene lo sprite
sw_x    equ PXV+0x15            ; 3 byte: x nell'anello (pari)
sw_y    equ PXV+0x18            ; 3 byte: y
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
sw_t    equ PXV+0x3B            ; 2 byte
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
        call play_physics
        call ent_update
        call ent_hit
pls_nl: call hero_calcframe
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
sw_tr:     ld a,3
           ld (0xB000),a
           call sw_jbc
           ld a,HEROSEG
           ld (0xB000),a
           ret
sw_jbc:    push bc
           ret

; sprite hardware: eroe nascosto, poi nemici e HUD
sw_sat:
        ld hl,0x7600
        call vram_w
        ld hl,hide_attr
        ld bc,0x0898
        otir
        ld hl,hide_attr
        ld bc,0x0898
        otir
        jp ent_sprites

