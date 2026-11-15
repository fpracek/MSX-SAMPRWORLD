"""SamPr World - sprite SOFTWARE compilati (triplo buffer, solo V9958): un frame = codice Z80 che scrive in VRAM
solo i pixel opachi (SCREEN 5: 2 pixel per byte, quindi lo sprite sta su x pari).

Uscita: editor/swhero.inc (sjasmplus), da includere nel segmento 3 della ROM (finestra A000).

Convenzione di chiamata di ogni frame (variante A: lo sprite non attraversa il confine di 16 KB della VRAM):
    C = 0x98
    DE = indirizzo VRAM dell'angolo in alto a sinistra: (indirizzo & 0x3FFF) | 0x4000   (R#14 gia' impostato dal chiamante)
Il codice imposta l'indirizzo a ogni "run" (spostamento relativo al run precedente) e scrive i dati con OUTI da una
tabella di dati (HL). Il pixel trasparente di un byte mezzo opaco viene riempito col nero (contorno): i bordi
diventano al massimo 1 px piu' spessi.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_sprites as G  # noqa: E402

OUT = os.path.join(HERE, "..", "editor", "swhero.inc")


def frame_rows(fr, cmap=None):
    """-> 16 righe da 16 pixel (indici palette, 0 = trasparente), con i byte mezzo opachi completati col nero."""
    rows = []
    for row in fr:
        px = []
        for ch in row:
            c = G.C[ch]
            if cmap and c in cmap:
                c = cmap[c]
            px.append(c)
        for k in range(0, 16, 2):
            a, b = px[k], px[k + 1]
            if (a == 0) != (b == 0):
                if a == 0:
                    px[k] = 1
                else:
                    px[k + 1] = 1
        rows.append(px)
    return rows


def runs_of(rows):
    """-> lista di (riga, byte iniziale, [byte dati])"""
    out = []
    for y, px in enumerate(rows):
        k = 0
        while k < 16:
            if px[k] == 0:
                k += 2
                continue
            s = k
            data = []
            while k < 16 and px[k] != 0:
                data.append((px[k] << 4) | px[k + 1])
                k += 2
            out.append((y, s // 2, data))
    return out


def emit_frame(name, rows, lines):
    runs = runs_of(rows)
    lines.append("%s:" % name)
    lines.append("        ld hl,%s_d" % name)
    prev = 0
    data = []
    cyc = 0
    for (y, b, d) in runs:
        pos = y * 128 + b
        delta = pos - prev
        prev = pos
        lines.append("        ld a,e : add a,%d : ld e,a : out (0x99),a : ld a,d : adc a,%d : ld d,a : out (0x99),a"
                     % (delta & 255, delta >> 8))
        lines.append("        " + " : ".join(["outi"] * len(d)))
        data += d
        cyc += 52 + 18 * len(d)
    lines.append("        ret")
    lines.append("%s_d:   db %s" % (name, ",".join(str(x) for x in data)))
    return len(runs), len(data), cyc


def main():
    frames = G.FRAMES + [G.mirror(f) for f in G.FRAMES]
    lines = ["; generato da tools/gen_swsprites.py - NON modificare a mano",
             "; sprite software compilati dell'eroe (8 frame: 4 a destra + 4 specchiati)"]
    tot = 0
    for i, fr in enumerate(frames):
        n, nb, cyc = emit_frame("swh%d" % i, frame_rows(fr), lines)
        print("swh%d: %d run, %d byte, ~%d cicli" % (i, n, nb, cyc))
        tot += cyc
    lines.append("swh_tab: dw " + ",".join("swh%d" % i for i in range(len(frames))))
    open(OUT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("media ~%d cicli/frame, scritto %s" % (tot // len(frames), os.path.normpath(OUT)))


if __name__ == "__main__":
    main()
