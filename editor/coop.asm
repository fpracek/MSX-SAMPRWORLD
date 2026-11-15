; coop.asm - due giocatori sullo stesso MSX (joystick 1 / joystick 2, oppure tastiera).
;
; Lo stato di un eroe sta nel blocco "attivo" di play.asm (p_x..p_lastf, p_jh, p_water, p_climb, p_cavail): la fisica, le
; collisioni coi tile e coi nemici lavorano sempre su quello. Con due giocatori ogni eroe ha un blocco di salvataggio
; (HS0/HS1, 22 byte): per ogni passo si carica l'eroe nel blocco attivo, si esegue il passo, si risalva. Con un giocatore solo
; il blocco attivo resta li' e non cambia nulla (nessun costo, nessun rischio di regressione).
;
; Regole del co-op: monete, chiavi, nemici uccisi, checkpoint e portale sono condivisi (vale chi ci arriva); ogni eroe ha il
; suo stato di vita. Chi muore rinasce vicino all'altro (se e' vivo), altrimenti tutti e due al checkpoint. La camera segue
; l'eroe piu' avanti; chi resta fuori dallo schermo viene riportato accanto a lui.
; Sprite: l'eroe 1 ha 4 layer (piani 0-3), l'eroe 2 ne ha 2 (contorno + riempimento): con i nemici si resta entro gli 8
; sprite per riga. Piani dell'eroe 2: 14-15 (V9958, dove l'HUD perde il contatore dei nemici) o 10-11 (V9938).
PXV     equ 0xC760
p_two   equ PXV+0               ; 1 = due giocatori (impostato dal menu)
p_cur   equ PXV+1               ; eroe caricato nel blocco attivo (0/1)
p_in1   equ PXV+2               ; tasti dei due giocatori, formato di v_k8: b7 destra, b4 sinistra, b5 su, b6 giu', b0 salto
p_in2   equ PXV+3
p_tin2  equ PXV+4               ; solo TESTBUILD: tasti forzati per il giocatore 2 (si scrive da Tcl)
p_tin1  equ PXV+5               ; solo TESTBUILD: tasti forzati per il giocatore 1
p2attr  equ PXV+8               ; 8 byte: attributi dei 2 sprite dell'eroe 2
HS0     equ 0xC720              ; 22 byte per eroe (x, xf, vx, y, yf, vy, oy, ground, face, anim, frame, lastf, dead, jh, water, climb, cavail)
HS1     equ 0xC738
HO_X    equ 0
HO_VX   equ 3
HO_Y    equ 5
HO_VY   equ 8
HO_OY   equ 10
HO_DEAD equ 17
P2OFF   equ 3328                ; dati sprite dell'eroe 2 nel segmento 4: per frame 64 byte pattern + 32 byte colori
P2PAT   equ 204                 ; numero di pattern dell'eroe 2 (2 sprite 16x16: 204 e 208)

; HL = blocco di salvataggio dell'eroe A
hs_ptr: ld hl,HS0
        or a
        ret z
        ld hl,HS1
        ret

hero_load:                      ; A = eroe: blocco di salvataggio -> blocco attivo
        call hs_ptr
        ld de,p_x
        ld bc,18
        ldir
        ld a,(hl)
        ld (p_jh),a
        inc hl
        ld a,(hl)
        ld (p_water),a
        inc hl
        ld a,(hl)
        ld (p_climb),a
        inc hl
        ld a,(hl)
        ld (p_cavail),a
        ret

hero_save:                      ; A = eroe: blocco attivo -> blocco di salvataggio
        call hs_ptr
        ex de,hl
        ld hl,p_x
        ld bc,18
        ldir
        ld a,(p_jh)
        ld (de),a
        inc de
        ld a,(p_water)
        ld (de),a
        inc de
        ld a,(p_climb)
        ld (de),a
        inc de
        ld a,(p_cavail)
        ld (de),a
        ret

; ------------------------------------------------------------------------- ingressi
; joystick: A = 0 porta 1, 0x40 porta 2 -> A = tasti nel formato di v_k8 (premuto = 1)
joy_read:
        ld b,a
        ld a,15
        out (0xA0),a
        in a,(0xA2)
        and 0xBF
        or b
        out (0xA1),a
        ld a,14
        out (0xA0),a
        in a,(0xA2)
        cpl
        ld e,a                  ; E: b0 su, b1 giu', b2 sinistra, b3 destra, b4/b5 pulsanti
        xor a
        bit 3,e
        jr z,jr_l
        or 0x80
jr_l:   bit 2,e
        jr z,jr_u
        or 0x10
jr_u:   bit 0,e
        jr z,jr_d
        or 0x20
jr_d:   bit 1,e
        jr z,jr_b
        or 0x40
jr_b:   bit 4,e
        jr nz,jr_j
        bit 5,e
        ret z
jr_j:   or 1
        ret

; calcola p_in1 / p_in2 (la riga 8 della tastiera resta in v_k8 per il resto del gioco)
read_inputs:
        ld a,8
        call readrow
        cpl
        ld (v_k8),a
        ld (p_in1),a
        xor a
        call joy_read           ; joystick 1: affianca la tastiera
        ld hl,p_in1
        or (hl)
        ld (hl),a
        IFDEF TESTBUILD
        ld a,(p_tin1)
        or (hl)
        ld (hl),a
        ENDIF
        ld a,(p_two)
        or a
        jr nz,ri_2
        ld a,(p_in1)
        ld (v_k8),a
        ret
ri_2:   ld a,0x40
        call joy_read           ; giocatore 2: joystick 2 + tastiera A S D W, Z salta
        ld (p_in2),a
        ld a,2
        call readrow
        bit 6,a                 ; A = sinistra
        jr nz,ri_d
        ld hl,p_in2
        set 4,(hl)
ri_d:   ld a,3
        call readrow
        bit 1,a                 ; D = destra
        jr nz,ri_w
        ld hl,p_in2
        set 7,(hl)
ri_w:   ld a,5
        call readrow
        ld c,a
        ld hl,p_in2
        bit 4,c                 ; W = su (scala)
        jr nz,ri_s
        set 5,(hl)
ri_s:   bit 0,c                 ; S = giu'
        jr nz,ri_z
        set 6,(hl)
ri_z:   bit 7,c                 ; Z = salto
        jr nz,ri_t
        set 0,(hl)
ri_t:   IFDEF TESTBUILD
        ld a,(p_tin2)
        or (hl)
        ld (hl),a
        ENDIF
        ld a,(p_in1)
        ld (v_k8),a
        ret

; ------------------------------------------------------------------------- un fotogramma a due giocatori
play_2p:
        xor a
        call p2_phys
        ld a,1
        call p2_phys
        call ent_update
        xor a
        call p2_hit
        ld a,1
        call p2_hit
        call p2_clamp
        ld a,1                  ; sprite dell'eroe 2 (attributi in buffer: li scrive ent_sprites)
        call hero_load
        call p2_sprite
        ld a,1
        call hero_save
        xor a
        call hero_load
        call play_sprite        ; sprite dell'eroe 1, poi nemici, HUD, eroe 2 e terminatore
        xor a
        call hero_save
        call p2_leader          ; la camera segue il gruppo (vedi p2_anchor)
        call hero_load
        jp p2_anchor

p2_phys:
        ld (p_cur),a
        call hero_load
        ld a,(p_cur)
        ld hl,p_in1
        add a,l
        ld l,a
        ld a,(hl)
        ld (v_k8),a
        call play_physics
        ld a,(p_cur)
        jp hero_save

p2_hit:
        ld (p_cur),a
        call hero_load
        call ent_hit
        ld a,(p_cur)
        jp hero_save

; A = eroe che guida la camera: il vivo piu' avanti (a parita' l'eroe 1)
p2_leader:
        ld a,(HS0+HO_DEAD)
        or a
        jr z,pl_a0
        ld a,(HS1+HO_DEAD)
        or a
        ld a,1
        ret z                   ; solo l'eroe 2 e' vivo
        xor a
        ret
pl_a0:  ld a,(HS1+HO_DEAD)
        or a
        jr nz,pl_0
        ld hl,(HS0+HO_X)
        ld de,(HS1+HO_X)
        or a
        sbc hl,de               ; x1 - x2
        jr nc,pl_0
        ld a,1
        ret
pl_0:   xor a
        ret

; eroe morto: rinasce accanto all'altro (se e' vivo), altrimenti al checkpoint (con la camera)
respawn_hero:
        ld a,(p_two)
        or a
        jp z,respawn
        ld a,(p_cur)
        xor 1
        call hs_ptr
        ld de,HO_DEAD
        add hl,de
        ld a,(hl)
        or a
        jp nz,respawn           ; anche l'altro e' morto
        ld a,(p_cur)
        xor 1
        call hs_ptr
        ld de,p_x
        ld bc,2
        ldir
        ld a,(p_cur)
        xor 1
        call hs_ptr
        ld de,HO_Y
        add hl,de
        ld de,p_y
        ld bc,2
        ldir
        ld hl,(p_y)
        ld (p_oy),hl
        ld hl,0
        ld (p_vx),hl
        ld (p_vy),hl
        xor a
        ld (p_xf),a
        ld (p_yf),a
        ld (p_ground),a
        ld (p_climb),a
        ld (p_dead),a
        ret

; ------------------------------------------------------------------------- sprite dell'eroe 2
p2_sprite:
        call hero_calcframe
        ld hl,p_lastf
        cp (hl)
        jr z,p2_at
        ld (hl),a
        ld l,a                  ; sorgente = A000 + P2OFF + frame*96
        ld h,0
        ld d,h
        ld e,l
        add hl,hl
        add hl,de
        ld b,5
p2_m:   add hl,hl
        djnz p2_m
        ld de,0xA000+P2OFF
        add hl,de
        push hl
        ld hl,0x7800+P2PAT*8
        call vram_w
        pop hl
        ld bc,0x4098
        otir                    ; 2 layer di pattern
        push hl
        ld hl,0x74A0            ; colori dei piani 10-11 (V9938)
        ld a,(p_ring)
        or a
        jr z,p2_c
        ld hl,0x74E0            ; piani 14-15 (V9958)
p2_c:   call vram_w
        pop hl
        ld bc,0x2098
        otir
p2_at:  ld a,(p_dead)
        or a
        jr nz,p2_hide
        ld hl,(p_x)
        ld de,(p_cam)
        or a
        sbc hl,de
        ld a,h
        or a
        jr nz,p2_hide
        ld a,l
        cp 241
        jr nc,p2_hide
        ld d,a                  ; x sullo schermo
        ld hl,(p_y)
        ld a,l
        dec a
        ld e,a
        ld hl,p2attr
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),P2PAT
        inc hl
        ld (hl),0
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),P2PAT+4
        inc hl
        ld (hl),0
        ret
p2_hide:
        ld hl,hide_attr
        ld de,p2attr
        ld bc,8
        ldir
        ret

; scritti dopo gli sprite dei nemici/HUD (dentro ent_sprites)
p2_attrs:
        ld a,(p_two)
        or a
        ret z
        ld hl,p2attr
        ld bc,0x0898
        otir
        ret

; due giocatori con sprite software: come play_2p ma senza sprite hardware; lascia il leader nel blocco attivo
play_2p_sw:
        xor a
        call p2_phys
        ld a,1
        call p2_phys
        call ent_update
        xor a
        call p2_hit
        ld a,1
        call p2_hit
        call p2_clamp
        ld a,1
        call hero_load
        call hero_calcframe
        ld a,1
        call hero_save
        xor a
        call hero_load
        call hero_calcframe
        xor a
        call hero_save
        call p2_leader
        call hero_load
        jp p2_anchor

; ------------------------------------------------------------------------- camera di gruppo (swcam.asm, segmento 3)
p2_clamp:
        ld bc,p2_clamp_i
        jp sw_tr
p2_anchor:
        ld bc,p2_anchor_i
        jp sw_tr
