"""Importa i livelli ALTI (64x64 tile da 8 px = 512x512 px, con scrolling verticale) estratti dalla ROM di Il Maniero
(assets/maniero/rom/rom_levelN.bin + stages.json) nella griglia 32x32 di celle 16x16 di SamPr World.

Stesso metodo di import_maniero_levels.py (ridisegno con MANIERO.png e confronto con i tile 16x16 di assets/maniero/tiles.png,
oggetti a confronto di modello su griglia da 4 px), ma senza ritagli: la mappa intera. Uscita: tools/levels_rom.json
(righe 32x32 di id tile / caratteri, nemici dalla tabella RAM) e anteprime assets/maniero/rom/imp_N.png.
"""
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import import_maniero_levels as I  # noqa: E402

ROOT = os.path.join(HERE, "..")
ROM = os.path.join(ROOT, "assets", "maniero", "rom")
RW, RH = 32, 32


def render_map(v, sheet):
    im = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    for i, t in enumerate(v):
        if t:
            sx, sy = (t % 32) * 8, (t // 32) * 8
            im.alpha_composite(sheet.crop((sx, sy, sx + 8, sy + 8)), ((i % 64) * 8, (i // 64) * 8))
    return im


def find_items(idx, timgs, tj):
    """come I.find_items ma sull'altezza reale dell'immagine"""
    H, W = idx.shape
    found = []
    taken = np.zeros(idx.shape, bool)
    tpl = {}
    for name, v in I.ITEMS.items():
        tpl[name] = (v, timgs[[m["id"] for m in tj if m["name"] == name][0]])
    tpl["Coin (level)"] = (("o", 0.8), I.COIN_TPL)
    del tpl["Gold coin"]
    d_top = [m["id"] for m in tj if m["name"] == "Gate (top)"][0]
    d_bot = [m["id"] for m in tj if m["name"] == "Gate (bottom)"][0]
    door = np.vstack([timgs[d_top], timgs[d_bot]])
    md = door != 0
    for y in range(0, H - 31, 4):
        for x in range(0, W - 15, 4):
            blk = idx[y:y + 32, x:x + 16]
            if ((blk == door) & md).sum() / md.sum() >= 0.8 and not taken[y:y + 32, x:x + 16].any():
                found.append((x, y, "D"))
                taken[y:y + 32, x:x + 16] = True
    for name, ((ch, thr), t) in tpl.items():
        mt = t != 0
        n = int(mt.sum())
        if not n:
            continue
        for y in range(0, H - 15, 4):
            for x in range(0, W - 15, 4):
                if taken[y:y + 16, x:x + 16].any():
                    continue
                blk = idx[y:y + 16, x:x + 16]
                sc = ((blk == t) & mt).sum() / n
                ext = (blk != 0).sum() - ((blk != 0) & mt).sum()
                if sc >= thr and (ext < n * 0.4 or ch == "k"):
                    found.append((x, y, ch))
                    taken[y:y + 16, x:x + 16] = True
    return found


def main():
    sheet = Image.open(os.path.join(I.SRC, "MANIERO.png")).convert("RGBA")
    tiles_png = Image.open(os.path.join(ROOT, "assets", "maniero", "tiles.png"))
    tj = json.load(open(os.path.join(ROOT, "assets", "maniero", "tiles.json")))
    timgs = []
    for m in tj:
        i = m["id"]
        timgs.append(np.array(tiles_png.crop(((i % 16) * 16, (i // 16) * 16, (i % 16) * 16 + 16, (i // 16) * 16 + 16))))
    names = {m["id"]: m for m in tj}
    # modello della moneta del livello: dal livello 1 originale (come import_maniero_levels)
    idx1 = I.to_index(I.render(1, sheet))[8:200, :]
    I.COIN_TPL = idx1[160:176, 104:120].copy()
    stages = json.load(open(os.path.join(ROM, "stages.json")))
    out = []
    for st in stages:
        n = st["stage"]
        v = struct.unpack("<4096H", open(os.path.join(ROM, "rom_level%d.bin" % {1: 1, 2: 1, 3: 2, 4: 3}[n]), "rb").read())
        idx = I.to_index(render_map(v, sheet))
        rows = [["."] * RW for _ in range(RH)]
        for cy in range(RH):
            for cx in range(RW):
                blk = idx[cy * 16:(cy + 1) * 16, cx * 16:(cx + 1) * 16]
                if not blk.any():
                    continue
                mb = blk != 0
                best, bs = -1, -1.0
                for k, t in enumerate(timgs):
                    mt = t != 0
                    un = int((mt | mb).sum())
                    sc = ((blk == t) & mt).sum() / un if un else 0.0
                    if sc > bs:
                        best, bs = k, float(sc)
                m = names[best]
                cl, nm = m["class"], m["name"].lower()
                if nm.startswith("gate") or nm.startswith("doorway") or "door" in nm or cl == "climb":
                    continue
                if cl in ("solid", "oneway") and bs >= 0.5:
                    rows[cy][cx] = best
                elif cl == "decor" and any(w in nm for w in ("banner", "grate", "vase", "chair", "window")) and bs >= 0.65:
                    rows[cy][cx] = best
        items = find_items(idx, timgs, tj)
        for (x, y, ch) in items:
            cx, cy = min(RW - 1, (x + 8) // 16), min(RH - 1, (y + 8) // 16)
            if ch != "D" and rows[cy][cx] == ".":
                rows[cy][cx] = ch
        # il tile di cima delle scale e' sfalsato di mezza cella: si cerca sopra la prima 'H'
        for cx in range(RW):
            col = [cy for cy in range(RH) if rows[cy][cx] == "H"]
            if col and min(col) > 0 and rows[min(col) - 1][cx] == ".":
                cy = min(col) - 1
                reg = idx[cy * 16:(cy + 1) * 16, cx * 16:(cx + 1) * 16]
                if (reg[6:16, 1:5] != 0).sum() >= 30:
                    rows[cy][cx] = "H"
        doors = sorted((y, x) for (x, y, ch) in items if ch == "D")
        out.append(dict(stage=n, rows=rows, enemies=st["enemies"], coins=st["coins"], doors=[(x, y) for y, x in doors]))
        Image.fromarray(np.where(idx[:, :, None] > 0, 255, 0).astype(np.uint8).repeat(3, axis=2)).save(
            os.path.join(ROM, "imp_mask_%d.png" % n))
        print("stage", n, "oggetti", len(items), "porte", doors)
    json.dump(dict(levels=out), open(os.path.join(HERE, "levels_rom.json"), "w"))


if __name__ == "__main__":
    main()
