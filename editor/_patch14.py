def rd(p): return open(p, encoding='utf-8', newline='').read()
def wr(p, s): open(p, 'w', encoding='utf-8', newline='').write(s)
def rep(s, a, b, n=1):
    assert s.count(a) == n, (s.count(a), a[:70])
    return s.replace(a, b)
e = rd('editor.asm')
e = rep(e, "        call CHGMOD\n        di\n", "        call CHGMOD\n        di\n        call detect_vdp         ; V9958 (MSX2+) = scroll hardware, V9938 = scroll a passi\n")
e = rep(e, '        include "scroll.asm"\n', '        include "scroll.asm"\n        include "ring.asm"\n')
wr('editor.asm', e)
p = rd('play.asm')
p = rep(p, "        ; camera sul punto di ripartenza (pari, entro la mappa), ridisegno completo sulla pagina 0\n        call vdp_wait\n", "        ; camera sul punto di ripartenza (pari, entro la mappa), ridisegno completo sulla pagina 0\n        call vdp_wait\n        ld a,(p_ring)\n        or a\n        jp nz,ring_respawn_cam  ; V9958: anello hardware\n")
p = rep(p, "        call ent_vram\n", "        call ent_vram\n        ld a,(p_ring)\n        or a\n        call nz,ring_start\n")
p = rep(p, "play_end:\n", "play_end:\n        ld a,(p_ring)\n        or a\n        call nz,ring_off\n")
p = rep(p, "pl_loop:\n        call vwait\n        call scroll_flip\n", "pl_loop:\n        call vwait\n        ld a,(p_ring)\n        or a\n        jr z,pl_v38\n        call ring_frame         ; V9958: camera, registri di scroll e colonne entranti nel vblank\n        jr pl_vc\npl_v38: call scroll_flip\npl_vc:\n")
p = rep(p, "        call scroll_update\n", "        ld a,(p_ring)\n        or a\n        call z,scroll_update\n")
p = rep(p, "play_status:\n", "play_status:\n        ld a,(p_ring)\n        or a\n        jp nz,hud_update        ; V9958: punteggio con gli sprite\n")
wr('play.asm', p)
s = rd('scroll.asm')
s = rep(s, "cell_changed:\n", "cell_changed:\n        ld a,(p_ring)\n        or a\n        jp nz,ring_cell\n")
wr('scroll.asm', s)
n = rd('enemy.asm')
n = rep(n, "        ld a,216                ; fine della lista sprite\n        out (0x98),a\n        ret\n\nsintab", "        ld a,(p_ring)\n        or a\n        jp nz,hud_attr          ; V9958: seguono i 6 sprite dell'HUD, poi il terminatore\n        ld a,216                ; fine della lista sprite\n        out (0x98),a\n        ret\n\nsintab")
wr('enemy.asm', n)
r = rd('ring.asm')
r += '''
ring_start:
        call ring_on
        jp hud_init
'''
wr('ring.asm', r)
