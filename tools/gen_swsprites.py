"""SamPr World - sprite SOFTWARE compilati (triplo buffer, solo V9958): un frame = codice Z80 che scrive in VRAM
solo i pixel opachi (SCREEN 5: 2 pixel per byte, quindi lo sprite sta su x pari).

Ingressi: assets/maniero/src/sprite.png (Il Maniero, N. Brogelli) quantizzato con la palette di assets/maniero/palette.json
(vedi tools/gen_maniero.py). I frame si scelgono in FRAMES sotto (id di frame -> indice nella tavola 16 per riga).
Uscite (editor/): swfr10.inc, swfr11.inc = codice dei frame, uno per segmento ROM (finestra 8000, `disp 0x8000`);
                  swtab.inc = tabelle id -> (segmento, indirizzo), incluso nel segmento 3.

Convenzione di chiamata di ogni frame (variante A: lo sprite non attraversa il confine di 16 KB della VRAM):
    C = 0x98
    DE = indirizzo VRAM dell'angolo in alto a sinistra: (indirizzo & 0x3FFF) | 0x4000   (R#14 gia' impostato dal chiamante)
Il codice imposta l'indirizzo a ogni "run" (spostamento relativo al run precedente) e scrive i dati con OUTI da una
tabella di dati (HL). Il pixel trasparente di un byte mezzo opaco viene riempito col nero (contorno): i bordi
diventano al massimo 1 px piu' spessi.
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_maniero as GM  # noqa: E402

ROOT = os.path.join(HERE, "..")
OUTD = os.path.join(ROOT, "editor")
SEG_FIRST = 10                 # primo segmento ROM dei frame
SEG_MAX = 8000                 # byte utili per segmento (codice + dati)

# eroe: frame di camminata a destra / sinistra nella tavola (0-7 destra, 8-15 sinistra)
HERO_R = {"idle": 0, "runa": 2, "runb": 4, "jump": 6}
# giocatore 2: stesso eroe, abiti rossi (blu 14 -> rosso 12, blu scuro 13 -> marrone scuro 5)
P2_MAP = {14: 12, 13: 5}

# (nome, indice nella tavola, rimappatura colori)
FRAMES = []
for side, off in (("r", 0), ("l", 8)):
    for k in ("idle", "runa", "runb", "jump"):
        FRAMES.append(("h1%s_%s" % (side, k), HERO_R[k] + off, None))          # id 0-7: giocatore 1 (p_frame)
for side, off in (("r", 0), ("l", 8)):
    for k in ("idle", "runa", "runb", "jump"):
        FRAMES.append(("h2%s_%s" % (side, k), HERO_R[k] + off, P2_MAP))        # id 8-15: giocatore 2
for i in range(6):
    FRAMES.append(("gob_r%d" % i, 26 + i, None))                                # id 16-21: goblin (soldato) a destra
for i in range(6):
    FRAMES.append(("gob_l%d" % i, 34 + i, None))                                # id 22-27: a sinistra
for i in range(6):
    FRAMES.append(("bat_r%d" % i, 64 + i, None))                                # id 28-33: pipistrello (medico) a destra
for i in range(6):
    FRAMES.append(("bat_l%d" % i, 72 + i, None))                                # id 34-39: a sinistra
FR_HERO1, FR_HERO2, FR_GOB, FR_BAT = 0, 8, 16, 28                               # primi id (usati da swspr/enemy)


def load_frames():
    pal = [tuple(c) for c in json.load(open(os.path.join(ROOT, "assets", "maniero", "palette.json")))["colors"]]
    cells = {c[0]: c for c in GM.load_cells(os.path.join(ROOT, "assets", "maniero", "src", "sprite.png"))}
    cache = {}
    out = []
    for name, n, remap in FRAMES:
        _, c, op = cells[(n % 16, n // 16)]
        idx = GM.quantize(c, op, pal, cache)
        if remap:
            idx = idx.copy()
            for a, b in remap.items():
                idx[idx == a] = b
        out.append((name, pad_rows(idx)))
    return out


def pad_rows(idx):
    """16 righe da 16 pixel; un byte (2 pixel) mezzo opaco completa il pixel trasparente col nero (indice 1)"""
    rows = [[int(v) for v in r] for r in idx]
    for px in rows:
        for k in range(0, 16, 2):
            a, b = px[k], px[k + 1]
            if (a == 0) != (b == 0):
                if a == 0:
                    px[k] = 1
                else:
                    px[k + 1] = 1
    return rows


def runs_of(rows):
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


def emit_frame(name, rows):
    """-> (righe di asm, byte stimati)"""
    runs = runs_of(rows)
    lines = ["%s:" % name, "        ld hl,%s_d" % name]
    prev = 0
    data = []
    size = 3 + 1                                        # ld hl,nn + ret
    for (y, b, d) in runs:
        pos = y * 128 + b
        delta = pos - prev
        prev = pos
        lines.append("        ld a,e : add a,%d : ld e,a : out (0x99),a : ld a,d : adc a,%d : ld d,a : out (0x99),a"
                     % (delta & 255, delta >> 8))
        lines.append("        " + " : ".join(["outi"] * len(d)))
        data += d
        size += 12 + 2 * len(d)
    lines.append("        ret")
    lines.append("%s_d:   db %s" % (name, ",".join(str(x) for x in data)))
    return lines, size + len(data)


def main():
    frames = load_frames()
    segs = [[]]
    used = [0]
    where = []
    for i, (name, rows) in enumerate(frames):
        lines, size = emit_frame(name, rows)
        if used[-1] + size > SEG_MAX:
            segs.append([])
            used.append(0)
        segs[-1].append("\n".join(lines))
        used[-1] += size
        where.append(len(segs) - 1)
    for k, body in enumerate(segs):
        path = os.path.join(OUTD, "swfr%d.inc" % (SEG_FIRST + k))
        text = "; generato da tools/gen_swsprites.py - NON modificare a mano (segmento ROM %d, finestra 8000)\n" % (SEG_FIRST + k)
        text += "        disp 0x8000\n" + "\n".join(body) + "\nswfr%d_end:\n        ent\n" % (SEG_FIRST + k)
        open(path, "w", encoding="utf-8").write(text)
    tab = ["; generato da tools/gen_swsprites.py - NON modificare a mano: id di frame -> segmento e indirizzo (finestra 8000)",
           "SWF_COUNT equ %d" % len(frames)]
    for nm, v in (("SWF_HERO1", 0), ("SWF_HERO2", 8), ("SWF_GOB", 16), ("SWF_BAT", 28)):
        tab.append("%s equ %d" % (nm, v))
    tab.append("swf_adr: dw " + ",".join(f[0] for f in frames))
    tab.append("swf_seg: db " + ",".join(str(SEG_FIRST + w) for w in where))
    open(os.path.join(OUTD, "swtab.inc"), "w", encoding="utf-8").write("\n".join(tab) + "\n")
    print("frame: %d, segmenti: %s (byte per segmento: %s)" % (len(frames), [SEG_FIRST + k for k in range(len(segs))], used))


if __name__ == "__main__":
    main()
