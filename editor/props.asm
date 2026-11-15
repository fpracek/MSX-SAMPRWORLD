; props.asm - proprieta' dei nemici (INVIO su un goblin/pipistrello nell'editor).
; Ogni nemico piazzato puo' avere un record nella tabella EPT (chiave = colonna, riga del tile); la tabella viaggia nella
; bozza in flash e nel blob del livello (n_ent record da 8 byte subito dopo l'intestazione: docs/LEVEL.md).
; Un nemico senza record usa i valori predefiniti (pattuglia, velocita' 1, raggio illimitato, 1 vita).
;   record: +0 colonna, +1 riga, +2 IA (0 pattuglia, 1 dormiglione, 2 inseguitore, 3 pauroso), +3 velocita' (1-3),
;           +4 raggio di pattuglia in tile (0 = illimitato), +5 vita (1-3), +6 distanza di rilevamento in tile (1-15)
EPT     equ 0xC600              ; 16 record x 8 byte (subito dopo la mappa: emap_save salva tutto insieme)
ept_n   equ 0xC680
ept_i   equ 0xC681
ep_sel  equ 0xC682
ep_i    equ 0xC683
ep_rec  equ 0xC684              ; 2 byte
ENP     equ 0xC690              ; proprieta' dei nemici in gioco: 8 entita' x 8 byte (vedi enemy.asm)
EP_MAX  equ 16
EP_LEN  equ 8

; B = colonna, C = riga -> HL = record, CF=1 se manca
ept_find:
        ld hl,EPT
        ld a,(ept_n)
        or a
        jr z,epf_no
        ld d,a
epf_l:  ld a,(hl)
        cp b
        jr nz,epf_n
        inc hl
        ld a,(hl)
        dec hl
        cp c
        ret z
epf_n:  ld a,l
        add a,EP_LEN
        ld l,a
        dec d
        jr nz,epf_l
epf_no: scf
        ret

; B = colonna, C = riga -> HL = record (lo crea con i valori predefiniti); CF=1 se la tabella e' piena
ept_get:
        call ept_find
        ret nc
        ld a,(ept_n)
        cp EP_MAX
        ccf
        ret c
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,EPT
        add hl,de
        push hl
        ld (hl),b
        inc hl
        ld (hl),c
        inc hl
        ld (hl),0               ; IA: pattuglia
        inc hl
        ld (hl),1               ; velocita'
        inc hl
        ld (hl),0               ; raggio: illimitato
        inc hl
        ld (hl),1               ; vita
        inc hl
        ld (hl),6               ; rilevamento
        inc hl
        ld (hl),0
        ld hl,ept_n
        inc (hl)
        pop hl
        or a
        ret

; toglie i record il cui tile non e' piu' un nemico
ept_prune:
        xor a
        ld (ept_i),a
epp_l:  ld a,(ept_i)
        ld hl,ept_n
        cp (hl)
        ret nc
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,EPT
        add hl,de
        push hl
        ld b,(hl)
        inc hl
        ld h,(hl)               ; riga
        ld l,0
        srl h
        rr l                    ; riga * 128
        ld e,b
        ld d,0
        add hl,de
        ld de,MAP
        add hl,de
        ld a,(hl)
        cp T_GOBLIN
        jr z,epp_k
        cp T_BAT
        jr z,epp_k
        pop de                  ; da togliere: ci si copia sopra l'ultimo record
        ld hl,ept_n
        dec (hl)
        ld a,(hl)
        add a,a
        add a,a
        add a,a
        ld l,a
        ld h,EPT>>8
        ld bc,EP_LEN
        ldir
        jr epp_l
epp_k:  pop hl
        ld hl,ept_i
        inc (hl)
        jr epp_l

; ingresso in pagina 1: l'interfaccia sta nel segmento 3 (swprops.asm)
do_eprops:
        ld bc,do_eprops_i
        jp seg3_tr
