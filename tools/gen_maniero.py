"""SamPr World - convertitore della grafica de "Il Maniero" (Nicola Brogelli) per SCREEN 5 (MSX2, 16 colori).

Ingressi (assets/maniero/src/): castle-tileset.png (blocchi 16x16), sprite.png (sprite 16x16).
Uscite (assets/maniero/):
  palette.bin     16 colori x 2 byte, formato registro paletta MSX2 (byte0 = 0RRR0BBB, byte1 = 00000GGG)
  palette.json    i 16 colori (r,g,b 0-7); si puo' correggere a mano e rilanciare con --palette palette.json
  tiles.png       blocchi 16x16 unici, 16 per riga, palette indicizzata (trasparente = 0 = cielo)
  tiles.bin       pixel SCREEN 5: 128 byte per tile (pixel sinistro = nibble alto), come assets/tiles.bin
  tiles.json      catalogo: id, cella d'origine, nome e classe da compilare a mano
  sprites.png     frame 16x16 degli sprite, indicizzati (0 = trasparente)
  sprites.json    catalogo dei frame (cella d'origine, colori per riga)
  preview.png     confronto originale / convertito (tile e sprite)

Regola: l'indice 0 e' il cielo (trasparente per sprite e livello): nessun pixel opaco di uno sprite viene mappato su 0.
L'indice 1 e' il colore piu' scuro (contorno). Gli altri 14 colori vengono scelti con k-means pesato (9 bit per canale).
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "assets", "maniero")
SRC = os.path.join(ROOT, "src")
SKY = (0, 0, 1)            # sfondo del livello (trasparente): notte nel castello, come nel Maniero
TRANSP = (255, 0, 255)


def load_cells(path, cw=16, ch=16):
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    cells = []
    for cy in range(im.size[1] // ch):
        for cx in range(im.size[0] // cw):
            c = arr[cy * ch:(cy + 1) * ch, cx * cw:(cx + 1) * cw].copy()
            op = (c[:, :, 3] > 0) & ~((c[:, :, 0] == 255) & (c[:, :, 1] == 0) & (c[:, :, 2] == 255))
            if op.any():
                cells.append(((cx, cy), c, op))
    return cells


def to9(rgb):
    return tuple(int(v) >> 5 for v in rgb[:3])


def kmeans(pts, w, k, iters=40):
    """k-means pesato, inizializzazione farthest-point"""
    pts = pts.astype(float)
    cent = [pts[np.argmax(w)]]
    for _ in range(k - 1):
        d = np.min([((pts - c) ** 2).sum(1) for c in cent], axis=0) * w
        cent.append(pts[np.argmax(d)])
    cent = np.array(cent)
    for _ in range(iters):
        d = ((pts[:, None, :] - cent[None]) ** 2).sum(2)
        lab = d.argmin(1)
        for j in range(k):
            m = lab == j
            if m.any():
                cent[j] = (pts[m] * w[m, None]).sum(0) / w[m].sum()
    return cent


def build_palette(cells_all):
    hist = {}
    for _, c, op in cells_all:
        for p in c[op]:
            k = to9(p)
            hist[k] = hist.get(k, 0) + 1
    cols = np.array(list(hist.keys()))
    wts = np.array([hist[tuple(c)] for c in cols], float)
    dark = tuple(int(v) for v in cols[np.argmin(cols.sum(1))])   # il piu' scuro = contorno
    pal = [SKY, dark]
    # fuori dal k-means: il cielo, il contorno e i quasi-neri (si mappano sul contorno)
    keep = [i for i, c in enumerate(cols) if tuple(c) != SKY and sum((int(c[j]) - dark[j]) ** 2 for j in range(3)) > 4]
    cent = kmeans(cols[keep], np.sqrt(wts[keep]), 14)     # sqrt: i colori rari ma vistosi (oro, rosso) non spariscono
    new = []
    for c in cent:
        t = tuple(min(7, max(0, int(round(v)))) for v in c)
        while t in new or t in (SKY, dark):               # evita doppioni
            t = tuple(min(7, v + 1) if i == 0 else v for i, v in enumerate(t))
        new.append(t)
    # slot compatibili coi RUOLI della vecchia palette (testo bianco = 15, rosso = 12, oro = 11...): ogni colore nuovo va
    # nello slot 2..15 il cui vecchio colore gli e' piu' vicino (assegnamento ottimo), cosi' il codice e gli sprite
    # hardware esistenti, che usano quegli indici, restano ragionevoli.
    from scipy.optimize import linear_sum_assignment
    import gen_tiles
    old = gen_tiles.PAL[2:]
    cost = np.array([[sum((a - b) ** 2 for a, b in zip(n, o)) for o in old] for n in new])
    r, c = linear_sum_assignment(cost)
    pal = [SKY, dark] + [None] * 14
    for i, j in zip(r, c):
        pal[2 + j] = new[i]
    return pal


def nearest(pal, rgb9, allow0):
    best, bd = 0, 1e9
    for i, c in enumerate(pal):
        if i == 0 and not allow0:
            continue
        d = (2 * (c[0] - rgb9[0]) ** 2) + (4 * (c[1] - rgb9[1]) ** 2) + (3 * (c[2] - rgb9[2]) ** 2)
        if d < bd:
            best, bd = i, d
    return best


def quantize(cell, op, pal, cache):
    out = np.zeros((16, 16), np.uint8)
    for y in range(16):
        for x in range(16):
            if op[y, x]:
                k = to9(cell[y, x])
                if k not in cache:
                    cache[k] = nearest(pal, k, False)
                out[y, x] = cache[k]
    return out


def pack(idx):
    b = bytearray()
    for y in range(16):
        for x in range(0, 16, 2):
            b.append((int(idx[y, x]) << 4) | int(idx[y, x + 1]))
    return bytes(b)


def write_palette(pal):
    out = bytearray()
    for r, g, b in pal:
        out += bytes([(r << 4) | b, g])
    return bytes(out)


def indexed_png(sheet, pal, path):
    im = Image.fromarray(sheet, "P")
    flat = []
    for r, g, b in pal:
        flat += [r * 255 // 7, g * 255 // 7, b * 255 // 7]
    im.putpalette(flat + [0] * (768 - len(flat)))
    im.save(path)


def rgb_of(idx, pal):
    out = np.zeros(idx.shape + (3,), np.uint8)
    for i, (r, g, b) in enumerate(pal):
        out[idx == i] = (r * 255 // 7, g * 255 // 7, b * 255 // 7)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--palette", help="palette.json corretta a mano (16 colori r,g,b 0-7)")
    a = ap.parse_args()
    tcells = load_cells(os.path.join(SRC, "castle-tileset.png"))
    scells = load_cells(os.path.join(SRC, "sprite.png"))
    if a.palette:
        pal = [tuple(c) for c in json.load(open(a.palette))["colors"]]
    else:
        pal = build_palette(tcells + scells)
    cache = {}
    # ---- tile: blocchi 16x16 unici (la trasparenza diventa cielo = 0) ----
    tiles, tmeta, seen = [], [], {}
    for (cx, cy), c, op in tcells:
        idx = quantize(c, op, pal, cache)
        key = idx.tobytes()
        if key in seen:
            continue
        seen[key] = len(tiles)
        tiles.append(idx)
        tmeta.append({"id": len(tiles) - 1, "cell": [cx, cy], "name": "", "class": "", "replaces": ""})
    # ---- tile extra composti da 4 tile 8x8 della tavola MANIERO.png (cuore: id 36,37 / 38,39) ----
    msheet = Image.open(os.path.join(SRC, "MANIERO.png")).convert("RGBA")
    for name, ids in (("Heart", (36, 37, 38, 39)),):
        im16 = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        for k, t in enumerate(ids):
            im16.alpha_composite(msheet.crop(((t % 32) * 8, (t // 32) * 8, (t % 32) * 8 + 8, (t // 32) * 8 + 8)), ((k % 2) * 8, (k // 2) * 8))
        arr = np.array(im16)
        op = (arr[:, :, 3] > 0) & ~((arr[:, :, 0] == 255) & (arr[:, :, 1] == 0) & (arr[:, :, 2] == 255))
        idx = quantize(arr, op, pal, cache)
        tiles.append(idx)
        tmeta.append({"id": len(tiles) - 1, "cell": [-1, len(tiles)], "name": name, "class": "pickup", "replaces": "POTION"})
    nt = len(tiles)
    rows = (nt + 15) // 16
    sheet = np.zeros((rows * 16, 256), np.uint8)
    for i, t in enumerate(tiles):
        sheet[(i // 16) * 16:(i // 16) * 16 + 16, (i % 16) * 16:(i % 16) * 16 + 16] = t
    # ---- sprite ----
    sprites, smeta = [], []
    for (cx, cy), c, op in scells:
        idx = quantize(c, op, pal, cache)
        cols_row = [len(set(int(v) for v in idx[y] if v)) for y in range(16)]
        sprites.append(idx)
        smeta.append({"id": len(sprites) - 1, "cell": [cx, cy], "max_colors_per_row": max(cols_row)})
    ns = len(sprites)
    srows = (ns + 15) // 16
    ssheet = np.zeros((srows * 16, 256), np.uint8)
    for i, s in enumerate(sprites):
        ssheet[(i // 16) * 16:(i // 16) * 16 + 16, (i % 16) * 16:(i % 16) * 16 + 16] = s
    os.makedirs(ROOT, exist_ok=True)
    open(os.path.join(ROOT, "palette.bin"), "wb").write(write_palette(pal))
    json.dump({"colors": [list(c) for c in pal]}, open(os.path.join(ROOT, "palette.json"), "w"), indent=1)
    open(os.path.join(ROOT, "tiles.bin"), "wb").write(b"".join(pack(t) for t in tiles))
    indexed_png(sheet, pal, os.path.join(ROOT, "tiles.png"))
    indexed_png(ssheet, pal, os.path.join(ROOT, "sprites.png"))
    old = os.path.join(ROOT, "tiles.json")
    if os.path.exists(old):                               # conserva nomi e classi inseriti a mano
        prev = {tuple(m["cell"]): m for m in json.load(open(old))}
        for m in tmeta:
            p = prev.get(tuple(m["cell"]))
            if p:
                m["name"], m["class"], m["replaces"] = p.get("name", ""), p.get("class", ""), p.get("replaces", "")
    json.dump(tmeta, open(old, "w"), indent=1)
    json.dump(smeta, open(os.path.join(ROOT, "sprites.json"), "w"), indent=1)
    # ---- anteprima: originale sopra, convertito sotto ----
    S = 3
    sky = tuple(v * 255 // 7 for v in SKY)

    def sheet_rgb(cells, w, h):
        im = Image.new("RGB", (w, h), sky)
        for i, (_, c, op) in enumerate(cells):
            tile = Image.fromarray(c, "RGBA")
            im.paste(tile, ((i % 16) * 16, (i // 16) * 16), tile)
        return im
    th = max(rows, (len(tcells) + 15) // 16) * 16
    sh = max(srows, (len(scells) + 15) // 16) * 16
    orig_t = sheet_rgb(tcells, 256, th)
    conv_t = Image.fromarray(rgb_of(sheet, pal), "RGB")
    conv_t_full = Image.new("RGB", (256, th), sky)
    conv_t_full.paste(conv_t, (0, 0))
    orig_s = sheet_rgb(scells, 256, sh)
    conv_s = Image.new("RGB", (256, sh), sky)
    rs = Image.fromarray(rgb_of(ssheet, pal), "RGB")
    mask = Image.fromarray(((ssheet > 0) * 255).astype(np.uint8), "L")
    conv_s.paste(rs, (0, 0), mask)
    strip = Image.new("RGB", (256, 16), (0, 0, 0))
    for i, (r, g, b) in enumerate(pal):
        strip.paste((r * 255 // 7, g * 255 // 7, b * 255 // 7), (i * 16, 0, i * 16 + 16, 16))
    H = th + sh
    out = Image.new("RGB", (256 * 2 + 8, H + 24), (30, 30, 30))
    out.paste(orig_t, (0, 0)); out.paste(orig_s, (0, th))
    out.paste(conv_t_full, (264, 0)); out.paste(conv_s, (264, th))
    out.paste(strip, (264, H + 4))
    out = out.resize((out.size[0] * 2, out.size[1] * 2), Image.NEAREST)
    out.save(os.path.join(ROOT, "preview.png"))
    # tavola con gli id sovrapposti (per compilare nomi e classi in tiles.json)
    from PIL import ImageDraw
    lab = Image.fromarray(rgb_of(sheet, pal), "RGB").resize((256 * 3, rows * 16 * 3), Image.NEAREST)
    dr = ImageDraw.Draw(lab)
    for i in range(nt):
        x, y = (i % 16) * 48, (i // 16) * 48
        dr.rectangle((x, y, x + 47, y + 47), outline=(255, 255, 255))
        dr.text((x + 2, y + 1), str(i), fill=(255, 255, 0))
    lab.save(os.path.join(ROOT, "tiles_labeled.png"))
    print("palette: %s" % " ".join("%d%d%d" % c for c in pal))
    print("tile unici: %d (%d righe da 16) ; frame sprite: %d" % (nt, rows, ns))
    mc = {}
    for m in smeta:
        mc[m["max_colors_per_row"]] = mc.get(m["max_colors_per_row"], 0) + 1
    print("sprite, colori massimi per riga -> numero di frame:", dict(sorted(mc.items())))


if __name__ == "__main__":
    sys.exit(main())
