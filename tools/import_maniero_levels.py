"""Importa i livelli originali de Il Maniero (N. Brogelli) nella griglia 16x16 di SamPr World.

Ogni livello originale e' una mappa di tile 8x8 (64x25 = 512x200 px). Si ridisegna con gli stessi tile (tavola MANIERO.png),
si scartano gli 8 px alti in cima (il soffitto: 192 px = 12 righe da 16) e per ogni cella 16x16 si sceglie, fra i tile 16x16
di assets/maniero/tiles.png, quello piu' somigliante (pixel uguali nella palette del gioco). Le celle senza una buona
corrispondenza vengono segnate per la revisione a mano. I nemici si leggono dagli array C originali.
Uscita: tools/levels_orig.json (griglie di id tile 12x32 + nemici) e un'anteprima assets/levels/orig_NN.png.
"""
import json
import os
import re
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_maniero as GM  # noqa: E402

ROOT = os.path.join(HERE, "..")
SRC = os.path.join(ROOT, "assets", "maniero", "src")
LV = os.path.join(SRC, "levels")
PAL = [tuple(c) for c in json.load(open(os.path.join(ROOT, "assets", "maniero", "palette.json")))["colors"]]


def level_tiles(n):
    s = open(os.path.join(LV, "level%03d.h" % n), encoding="utf-8", errors="ignore").read()
    body = s[s.index("{"):]
    return [0 if t == "OOOO" else int(t) for t in re.findall(r"OOOO|\d+", body)]


def render(n, sheet):
    L = level_tiles(n)
    W = 64
    H = len(L) // W
    im = Image.new("RGBA", (W * 8, H * 8), (0, 0, 0, 0))
    for i, t in enumerate(L):
        if t:
            sx, sy = (t % 32) * 8, (t // 32) * 8
            im.alpha_composite(sheet.crop((sx, sy, sx + 8, sy + 8)), ((i % W) * 8, (i // W) * 8))
    return im


def to_index(im):
    arr = np.array(im)
    op = (arr[:, :, 3] > 0) & ~((arr[:, :, 0] == 255) & (arr[:, :, 1] == 0) & (arr[:, :, 2] == 255))
    out = np.zeros(op.shape, np.uint8)
    cache = {}
    for y in range(op.shape[0]):
        for x in range(op.shape[1]):
            if op[y, x]:
                k = GM.to9(arr[y, x])
                if k not in cache:
                    cache[k] = GM.nearest(PAL, k, False)
                out[y, x] = cache[k]
    return out


def parse_enemies(n):
    txt = open(os.path.join(LV, "ilmaniero_s2%d_b1.c" % (0 if n <= 4 else 1)), encoding="utf-8", errors="ignore").read()
    m = re.search(r"level%02dManieroEnemies\[\]\s*=\s*\{(.*?)\};" % n, txt, re.S)
    out = []
    if m:
        for line in m.group(1).splitlines():
            line = line.split("//")[0]
            mm = re.match(r"\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)", line)
            if mm:
                out.append(dict(type=int(mm.group(1)), x=int(mm.group(2)), y=int(mm.group(3)), range=int(mm.group(4)),
                                ai=mm.group(7), speed=int(mm.group(8)), detect=int(mm.group(10)), health=int(mm.group(11)),
                                frames=mm.group(5)))
    return out


ITEMS = {  # nome del tile -> (carattere, soglia)
    "Gold coin": ("o", 0.9), "Key": ("k", 0.9), "Heart": ("p", 0.9), "Barrel": ("r", 0.9), "Wooden crate": ("C", 0.9),
    "Flower vase": ("V", 0.9), "Chest left": ("K", 0.9), "Chest right": ("L", 0.9), "Wooden ladder": ("H", 0.8), "Wooden ladder B": ("H", 0.6),
}


def sheet_tile(ids):
    """tile 16x16 composto da 4 tile 8x8 della tavola, indicizzato nella palette del gioco"""
    msheet = Image.open(os.path.join(SRC, "MANIERO.png")).convert("RGBA")
    im16 = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for k, t in enumerate(ids):
        im16.alpha_composite(msheet.crop(((t % 32) * 8, (t // 32) * 8, (t % 32) * 8 + 8, (t // 32) * 8 + 8)), ((k % 2) * 8, (k // 2) * 8))
    return to_index(im16)


COIN_TPL = None
# ritocchi a mano dove l'originale (griglia di 8 px, salto piu' alto) non e' giocabile con la fisica di SamPr World
# o dove il riconoscimento fallisce (tile sfalsati di mezza cella): (x, y, tile/carattere) per livello
def _beam(x0, x1, y):
    out = [(x0, y, 13)]
    out += [(x, y, 54 if x == x0 + 1 else (56 if x == x1 - 1 else 55)) for x in range(x0 + 1, x1)]
    return out + [(x1, y, 13)]


PATCHES = {
    5: [(30, 7, 0), (30, 8, 0), (30, 9, 0), (30, 10, 0)],                          # montante di legno accanto alla porta
    6: [(30, 7, 0), (30, 8, 0), (30, 9, 0), (30, 10, 0), (17, 5, 13), (24, 5, 13),
        (18, 5, 54), (20, 5, 55), (21, 5, 55), (22, 5, 55), (23, 5, 56)],           # piattaforma con la porta d'uscita (nell'originale a mezza cella)
    4: [(3, 6, "H"), (3, 7, "H"), (3, 8, "H"), (3, 9, "H"), (3, 10, "H"),          # scala a sinistra verso il ripiano con il forziere
        (16, 5, "H"), (16, 6, "H"),                                                # la scala centrale attraversa la trave
        (30, 7, 0), (30, 8, 0),                                                    # montante di legno vicino alla porta
        (28, 7, "H"), (28, 8, "H"), (28, 9, "H"), (28, 10, "H"),
        (10, 3, "."), (15, 4, "p")]                                                  # il cuore in alto: spostato dove si raggiunge                   # scala per la moneta sopra il mattone
       + _beam(4, 9, 10) + _beam(22, 27, 10),                                      # travi basse (nell'originale a mezza cella)
}


def find_items(idx, timgs, tj):
    """cerca gli oggetti (monete, chiavi, cuori, botti...) con il confronto di modello su una griglia di 8 px:
    -> lista (x, y, carattere); le coordinate sono in pixel del livello ritagliato (192 righe)"""
    found = []
    taken = np.zeros(idx.shape, bool)
    tpl = {}
    for name, v in ITEMS.items():
        tpl[name] = (v, timgs[[m["id"] for m in tj if m["name"] == name][0]])
    tpl["Coin (level)"] = (("o", 0.8), COIN_TPL)
    del tpl["Gold coin"]
    d_top = [m["id"] for m in tj if m["name"] == "Gate (top)"][0]
    d_bot = [m["id"] for m in tj if m["name"] == "Gate (bottom)"][0]
    door = np.vstack([timgs[d_top], timgs[d_bot]])                         # 16x32: porta
    for y in range(0, 192 - 31, 4):
        for x in range(0, 512 - 15, 4):
            blk = idx[y:y + 32, x:x + 16]
            md = door != 0
            if ((blk == door) & md).sum() / md.sum() >= 0.8 and not taken[y:y + 32, x:x + 16].any():
                found.append((x, y, "D"))
                taken[y:y + 32, x:x + 16] = True
    for name, ((ch, thr), t) in tpl.items():
        mt = t != 0
        n = int(mt.sum())
        if not n:
            continue
        # il tile ha spesso margini vuoti: si cerca nelle posizioni a passi di 8 px (e 4 px sui bordi)
        for y in range(0, 192 - 15, 4):
            for x in range(0, 512 - 15, 4):
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
    sheet = Image.open(os.path.join(SRC, "MANIERO.png")).convert("RGBA")
    tiles_png = Image.open(os.path.join(ROOT, "assets", "maniero", "tiles.png"))
    tj = json.load(open(os.path.join(ROOT, "assets", "maniero", "tiles.json")))
    timgs = []
    for m in tj:
        i = m["id"]
        timgs.append(np.array(tiles_png.crop(((i % 16) * 16, (i // 16) * 16, (i % 16) * 16 + 16, (i // 16) * 16 + 16))))
    names = {m["id"]: m for m in tj}
    used = set(".#bGDHogpk^SPQcRBdesw!tniWxyzXZYvrCVKL=")           # caratteri gia' usati da make_levels.py
    import string
    pool = [c for c in "afhjlmqu" + string.ascii_letters + string.digits + "@$%&*+-:;<>?_" if c not in used]
    result = []
    for n in range(1, 8):
        im = render(n, sheet)
        idx = to_index(im)[8:200, :]                     # via gli 8 px del soffitto: 192 righe
        global COIN_TPL
        if COIN_TPL is None:                             # la moneta dei livelli: modello preso dal livello 1 (cella 6-7, riga 10)
            COIN_TPL = idx[160:176, 104:120].copy()
        grid = []
        for cy in range(12):
            row = []
            for cx in range(32):
                blk = idx[cy * 16:(cy + 1) * 16, cx * 16:(cx + 1) * 16]
                if not blk.any():
                    row.append(-1)
                    continue
                best, bs = -1, -1.0
                mb = blk != 0
                for k, t in enumerate(timgs):
                    mt = t != 0
                    un = int((mt | mb).sum())
                    sc = ((blk == t) & mt).sum() / un if un else 0.0
                    if sc > bs:
                        best, bs = k, float(sc)
                row.append((best, bs))
            grid.append(row)
        ens = parse_enemies(n)
        items = find_items(idx, timgs, tj)
        result.append(dict(level=n, grid=grid, enemies=ens, items=items, idx=idx))

    # ---- pulizia: ogni cella e' un carattere speciale o l'indice k del tile (foglio tiles.json) ----
    out_levels = []
    KEEP_DECOR = ("banner", "grate", "vase", "chair", "window")
    for lv in result:
        rows = []
        for cy in range(12):
            r = []
            for cx in range(32):
                c = lv["grid"][cy][cx]
                if c == -1:
                    r.append(".")
                    continue
                k, sc = c
                m = names[k]
                cl, nm = m["class"], m["name"].lower()
                if nm.startswith("gate") or nm.startswith("doorway") or "door" in nm:
                    r.append(".")
                elif cl == "climb":
                    r.append(".")                        # le scale si cercano con il confronto di modello (stanno a meta' cella)
                elif cl in ("solid", "oneway"):
                    r.append(k if sc >= 0.5 else ".")
                elif cl == "decor" and any(w in nm for w in KEEP_DECOR) and sc >= 0.65:
                    r.append(k)
                else:
                    r.append(".")
            rows.append(r)
        for (x, y, ch) in lv["items"]:                  # al centro della cella piu' vicina
            cx, cy = min(31, (x + 8) // 16), min(11, (y + 8) // 16)
            if rows[cy][cx] == ".":
                rows[cy][cx] = ch
        idx = lv["idx"]
        for cx in range(32):                            # il tile di cima della scala e' mezzo sfasato: lo si cerca sopra la prima 'H'
            col = [cy for cy in range(12) if rows[cy][cx] == "H"]
            if col and min(col) > 0 and rows[min(col) - 1][cx] == ".":
                cy = min(col) - 1
                reg = idx[cy * 16:(cy + 1) * 16, cx * 16:(cx + 1) * 16]
                if (reg[6:16, 1:5] != 0).sum() >= 30:
                    rows[cy][cx] = "H"
        out_levels.append(dict(level=lv["level"], rows=rows, enemies=lv["enemies"], items=lv["items"]))

    # ---- assemblaggio: partenza, uscita, nemici ----
    sprite_of = {"MILITARY": 1, "POLICEMAN": 3, "DOCTOR": 2}
    final = []
    for lv in out_levels:
        rows = [list(r) for r in lv["rows"]]
        doors = sorted((x, y) for (x, y, ch) in lv["items"] if ch == "D")
        for (x, y, ch) in lv["items"]:
            if ch == "D":
                cx, cy = min(31, (x + 8) // 16), min(10, (y + 8) // 16)
                if cx > 8 or len(doors) == 1:
                    rows[cy][cx], rows[cy + 1][cx] = "P", "Q"     # uscita (porta di destra)
                else:
                    rows[cy + 1][min(cx + 1, 31)] = "S"           # entrata: la partenza accanto alla porta
        if not any("S" in r for r in rows):
            rows[10][1] = "S"
        for (x, y, v) in PATCHES.get(lv["level"], []):
            rows[y][x] = v
        for e in lv["enemies"]:
            cx, cy = min(31, e["x"] // 16), min(10, (e["y"] - 8) // 16)
            m = re.search(r"ENEMY_([A-Z]+)_ANIM", e["frames"])
            sp = sprite_of.get(m.group(1) if m else "MILITARY", 1)
            ch = {1: "x", 2: "y", 3: "z"}[sp] if e["speed"] < 2 else "z"
            rows[cy][cx] = ch
        final.append(dict(title="Manor %d" % lv["level"], rows=rows))
    json.dump(dict(levels=final), open(os.path.join(HERE, "levels_orig.json"), "w"))
    for lv in final:
        print("livello %d: %d celle" % (int(lv["title"].split()[1]), sum(1 for r in lv["rows"] for c in r if c != ".")))
    return


if __name__ == "__main__":
    main()
