"""Livelli ALTI della campagna (da tools/levels_rom.json, importati dalla ROM di Il Maniero con import_rom_levels.py).

Ogni livello e' 32x32 celle 16x16 (512x512 px) con scorrimento verticale a finestra (docs/TALL.md). Formato blob = livello v1
con h = 32 e mappa RLE di 64x32 tile (stride 64, le colonne 32-63 vuote). Si accoda ai livelli di make_levels.py: questo
modulo fornisce `tall_levels()` -> [(titolo, blob)] e salva anteprime in assets/levels/tall_N.png.
"""
import json
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import level  # noqa: E402
import make_levels as ML  # noqa: E402

ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "assets")
TW, TH = 32, 32            # celle del livello
BW = 64                    # stride di BIG nel motore
TITLES = ["Cellar", "Cellar II", "Great Hall", "Tower"]
SPRITE = {0x22: ("x", 1), 0x58: ("z", 3), 0x48: ("y", 2), 0x78: ("z", 3)}      # frameL -> (carattere, sprite)

# ritocchi a mano per livello (numero di stage 1..4): (colonna, riga, tile/carattere)
PATCHES = {}


def build(lv, patches):
    rows = [list(r) for r in lv["rows"]]
    for (x, y, v) in patches:
        rows[y][x] = v
    # uscita: la porta trovata nell'immagine (la piu' alta)
    if lv["doors"]:
        dx, dy = lv["doors"][0]
        cx, cy = min(TW - 1, (dx + 8) // 16), min(TH - 2, (dy + 8) // 16)
        rows[cy][cx], rows[cy + 1][cx] = "P", "Q"
    # partenza in basso a sinistra: la prima cella libera con pavimento sotto
    sx, sy = None, TH - 3
    for c in range(2, TW):
        t = rows[sy][c]
        if t == "." and rows[sy + 1][c] != "." and not isinstance(rows[sy + 1][c], str):
            sx = c
            break
    assert sx is not None, "partenza"
    rows[sy][sx] = "S"
    ents = []
    for e in lv["enemies"]:
        ch, spr = SPRITE.get(e["frameL"], ("x", 1))
        cx, cy = min(TW - 1, e["x"] // 16), min(TH - 2, e["y"] // 16)
        ai, sp, hp = 0, 1, 1
        rows[cy][cx] = ch
        ents.append((cx, cy, ai, sp, 0, hp, 6, spr))
    return rows, (sx, sy), ents


def encode(tiles, start, title, ents):
    assert len(tiles) == BW * TH and len(ents) <= 16
    hdr = b"LV" + bytes([1, BW, TH, start[0], start[1], 0]) + title.encode("ascii")[:16].ljust(16, b"\0")
    hdr += bytes([len(ents)]) + b"".join(bytes(e) for e in ents)
    body = hdr + level.rle_encode(bytes(tiles))
    return body + struct.pack("<H", level.crc16(body))


def preview(g, path):
    from PIL import Image
    sheet = Image.open(os.path.join(OUT, "tiles.png")).convert("RGB")
    im = Image.new("RGB", (TW * 16, TH * 16), (36, 72, 255))
    for y in range(TH):
        for x in range(TW):
            t = g[y][x]
            if t:
                sx, sy = (t % 16) * 16, (t // 16) * 16
                im.paste(sheet.crop((sx, sy, sx + 16, sy + 16)), (x * 16, y * 16))
    im.save(path)


def tall_levels():
    data = json.load(open(os.path.join(HERE, "levels_rom.json")))["levels"]
    out = []
    for i, lv in enumerate(data):
        rows, start, ents = build(lv, PATCHES.get(lv["stage"], []))
        g = [[0] * BW for _ in range(TH)]
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if isinstance(ch, int):
                    g[y][x] = ML._game_tile(ch)
                elif ch == ".":
                    g[y][x] = 0
                elif ch in ML.ENEMY:
                    g[y][x] = ML.T[ML.ENEMY[ch][0]]
                else:
                    g[y][x] = ML.LEGEND[ch]
        tiles = bytes(t for r in g for t in r)
        maps = os.path.join(ROOT, "editor", "tests", "maps")
        os.makedirs(maps, exist_ok=True)
        open(os.path.join(maps, "tall_%d.txt" % (i + 1)), "w").write(" ".join(str(t) for t in tiles))
        open(os.path.join(maps, "tall_%d.ents" % (i + 1)), "w").write("")
        ow, oh = ML.W, ML.H
        ML.W, ML.H = BW, TH
        route = ML.plan(g, start)
        ML.W, ML.H = ow, oh
        open(os.path.join(maps, "tall_%d.route" % (i + 1)), "w").write(chr(10).join("%s %d %d" % w for w in route) if route else "NONE")
        blob = encode(tiles, start, TITLES[i], ents)
        os.makedirs(os.path.join(OUT, "levels"), exist_ok=True)
        open(os.path.join(OUT, "levels", "tall_%d.lvl" % (i + 1)), "wb").write(blob)
        preview(g, os.path.join(OUT, "levels", "tall_%d.png" % (i + 1)))
        out.append((TITLES[i], blob))
        print("tall %d %-12s %4d byte, %d nemici, partenza %s" % (i + 1, TITLES[i], len(blob), len(ents), start))
    return out


if __name__ == "__main__":
    tall_levels()
