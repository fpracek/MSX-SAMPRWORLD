"""SamPr World - generatore del tileset fantasy (16x16, SCREEN 5 = 4 bit/pixel, 16 colori).

Uscite (cartella assets/):
  tiles.png        foglio 16 colonne, palette indicizzata (anche per editarlo a mano)
  tiles.bin        pixel SCREEN 5: 128 byte per tile (2 pixel per byte, pixel sinistro = nibble alto)
  palette.bin      16 colori x 2 byte, formato registro paletta MSX2: byte0 = 0RRR0BBB, byte1 = 00000GGG
  tiles_preview.png  anteprima ingrandita con etichette
  tileset.inc      costanti asm (T_xxx) e tabella delle proprieta' (una per tile)
  catalog.json     catalogo completo (id, nome, categoria, classe, descrizione)
"""
import json
import os
import random

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

# --- palette fantasy, 3 bit per canale (0-7) come l'MSX2 -------------------------------
PAL = [
    (2, 4, 7),  # 0  cielo (colore "trasparente" del livello)
    (0, 0, 1),  # 1  contorno quasi nero
    (0, 3, 1),  # 2  verde scuro
    (2, 5, 1),  # 3  verde erba
    (4, 7, 2),  # 4  verde chiaro
    (2, 1, 0),  # 5  marrone scuro
    (4, 2, 1),  # 6  marrone
    (6, 4, 2),  # 7  sabbia / legno chiaro
    (2, 2, 3),  # 8  pietra scura
    (4, 4, 5),  # 9  pietra
    (6, 6, 7),  # 10 pietra chiara
    (7, 6, 0),  # 11 oro
    (6, 1, 1),  # 12 rosso
    (4, 2, 6),  # 13 viola magico
    (1, 5, 7),  # 14 ciano cristallo / acqua
    (7, 7, 7),  # 15 bianco
]
SKY, BLK, DKG, GRN, LGR, DBR, BRN, SND, DST, STN, LST, GLD, RED, PUR, CYN, WHT = range(16)

# --- classi di collisione (nibble basso della proprieta') ------------------------------
EMPTY, SOLID, ONEWAY, HAZARD, LIQUID, CLIMB, HIT, PICKUP, TRIGGER, DECOR = range(10)
CLASS_NAMES = ["vuoto", "solido", "piattaforma", "pericolo", "liquido", "scalabile",
               "colpibile", "oggetto", "marcatore", "decorazione"]


class Tile:
    def __init__(self, fill=SKY):
        self.p = [[fill] * 16 for _ in range(16)]

    def px(self, x, y, c):
        if 0 <= x < 16 and 0 <= y < 16:
            self.p[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c)

    def frame(self, x0, y0, x1, y1, c):
        for x in range(x0, x1 + 1):
            self.px(x, y0, c)
            self.px(x, y1, c)
        for y in range(y0, y1 + 1):
            self.px(x0, y, c)
            self.px(x1, y, c)

    def disc(self, cx, cy, r, c):
        for y in range(16):
            for x in range(16):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            self.px(round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)

    def speckle(self, seed, cols, n, box=(0, 0, 15, 15)):
        r = random.Random(seed)
        for _ in range(n):
            self.px(r.randint(box[0], box[2]), r.randint(box[1], box[3]), r.choice(cols))

    def paste(self, other, keyc=SKY):
        for y in range(16):
            for x in range(16):
                if other.p[y][x] != keyc:
                    self.p[y][x] = other.p[y][x]


# ===== generatori =======================================================================
def bricks(base, light, dark, mortar, seed=1, bw=8, bh=4):
    t = Tile(base)
    for row in range(16 // bh):
        y0 = row * bh
        off = (bw // 2) if row % 2 else 0
        for y in range(y0, y0 + bh):
            for x in range(16):
                if y == y0 + bh - 1:
                    t.px(x, y, mortar)
        for bx in range(-1, 3):
            xm = bx * bw + off
            for y in range(y0, y0 + bh - 1):
                t.px(xm, y, mortar)
        for x in range(16):
            if t.p[y0][x] == base:
                t.px(x, y0, light)
    t.speckle(seed, [dark, light], 14)
    return t


def grass_top():
    t = Tile(DBR)
    t.rect(0, 0, 15, 15, BRN)
    t.speckle(3, [DBR, DBR, SND], 30, (0, 6, 15, 15))
    t.rect(0, 0, 15, 4, GRN)
    t.rect(0, 0, 15, 1, LGR)
    for x in range(16):
        d = (x * 7 + 3) % 4
        t.rect(x, 5, x, 5 + (1 if d < 2 else 2), GRN if d else DKG)
    for x in (1, 5, 9, 13):
        t.px(x, 0, SKY)
        t.px(x + 1, 0, LGR)
    t.speckle(9, [DKG, LGR], 6, (0, 1, 15, 4))
    return t


def dirt():
    t = Tile(BRN)
    t.speckle(5, [DBR, SND, DBR], 38)
    for (x, y) in ((3, 4), (11, 9), (6, 12)):
        t.rect(x, y, x + 1, y + 1, STN)
        t.px(x, y, LST)
    return t


def stone():
    t = bricks(STN, LST, DST, DST, 11, 16, 5)
    t.speckle(21, [DST, LST], 14)
    return t


def castle_brick():
    return bricks(DST, STN, BLK, BLK, 7)


def castle_wall():
    """parete di sfondo (non solida): mattoni piu' scuri, senza luci."""
    t = bricks(DST, DST, BLK, BLK, 17)
    t.speckle(2, [BLK], 10)
    return t


def mossy():
    t = stone()
    for x, y in ((0, 0), (1, 0), (2, 0), (3, 1), (9, 0), (10, 0), (11, 0), (12, 1), (13, 1),
                 (0, 1), (0, 2), (15, 4), (14, 5), (15, 5), (4, 7), (5, 7), (5, 8), (11, 11), (12, 11), (12, 12)):
        t.px(x, y, GRN if (x + y) % 3 else DKG)
    t.px(1, 1, LGR)
    t.px(10, 1, LGR)
    t.px(5, 8, LGR)
    return t


def crate():
    t = Tile(BRN)
    t.frame(0, 0, 15, 15, DBR)
    t.frame(1, 1, 14, 14, SND)
    t.frame(2, 2, 13, 13, BRN)
    t.line(2, 2, 13, 13, DBR)
    t.line(13, 2, 2, 13, DBR)
    t.rect(0, 0, 1, 1, BLK)
    for x, y in ((1, 1), (14, 1), (1, 14), (14, 14)):
        t.px(x, y, STN)
    return t


def crystal_block():
    t = Tile(PUR)
    t.frame(0, 0, 15, 15, BLK)
    t.frame(1, 1, 14, 14, CYN)
    t.rect(2, 2, 13, 13, PUR)
    t.line(3, 12, 8, 3, CYN)
    t.line(4, 12, 9, 3, CYN)
    t.px(11, 4, WHT)
    t.px(12, 5, WHT)
    t.px(11, 5, CYN)
    t.rect(10, 10, 12, 12, DST)
    return t


def gold_block():
    t = Tile(GLD)
    t.frame(0, 0, 15, 15, DBR)
    t.frame(1, 1, 14, 14, WHT)
    t.rect(2, 2, 13, 13, GLD)
    t.line(2, 13, 13, 13, BRN)
    t.line(13, 2, 13, 13, BRN)
    t.px(4, 4, WHT)
    t.px(5, 4, WHT)
    t.px(4, 5, WHT)
    t.speckle(4, [BRN], 6, (3, 6, 12, 12))
    return t


def wood_platform():
    t = Tile(SKY)
    t.rect(0, 0, 15, 5, BRN)
    t.rect(0, 0, 15, 0, SND)
    t.rect(0, 5, 15, 5, DBR)
    for x in (0, 5, 10):
        t.rect(x, 0, x, 5, DBR)
    for x in (2, 7, 12):
        t.px(x, 2, BLK)
    t.rect(0, 6, 15, 6, BLK)
    return t


def rope_bridge():
    t = Tile(SKY)
    t.rect(0, 5, 15, 7, BRN)
    t.rect(0, 5, 15, 5, SND)
    t.rect(0, 7, 15, 7, DBR)
    for x in (3, 7, 11, 15):
        t.rect(x, 5, x, 7, BLK)
    t.line(0, 0, 7, 4, SND)
    t.line(8, 4, 15, 0, SND)
    return t


def stone_ledge():
    t = Tile(SKY)
    t.rect(0, 0, 15, 4, STN)
    t.rect(0, 0, 15, 0, LST)
    t.rect(0, 4, 15, 4, DST)
    t.rect(0, 5, 15, 5, BLK)
    for x in (4, 11):
        t.rect(x, 1, x, 3, DST)
    t.rect(2, 6, 13, 6, DST)
    t.rect(5, 7, 10, 7, DST)
    return t


def rune_block():
    t = Tile(DST)
    t.frame(0, 0, 15, 15, BLK)
    t.frame(1, 1, 14, 14, LST)
    t.rect(2, 2, 13, 13, DST)
    t.line(2, 13, 13, 13, BLK)
    t.line(13, 2, 13, 13, BLK)
    t.rect(2, 2, 2, 12, STN)
    # runa luminosa (stile "fehu"): asta + due rami
    t.rect(7, 3, 8, 12, CYN)
    t.line(8, 4, 12, 2, CYN)
    t.line(8, 7, 12, 5, CYN)
    t.px(7, 3, WHT)
    t.px(7, 6, WHT)
    t.px(4, 4, PUR)
    t.px(11, 11, PUR)
    t.px(4, 11, PUR)
    return t


def breakable():
    t = Tile(STN)
    t.frame(0, 0, 15, 15, BLK)
    t.rect(1, 1, 14, 14, STN)
    t.rect(1, 1, 14, 1, LST)
    t.rect(1, 1, 1, 14, LST)
    t.rect(1, 14, 14, 14, DST)
    t.rect(14, 1, 14, 14, DST)
    for (x, y) in ((8, 1), (7, 2), (8, 3), (6, 4), (7, 5), (5, 6), (6, 7), (4, 8), (5, 9), (3, 10),
                   (4, 11), (3, 12), (2, 13)):
        t.px(x, y, BLK)
    for (x, y) in ((8, 6), (9, 6), (10, 7), (11, 8), (10, 9), (11, 10), (12, 11)):
        t.px(x, y, BLK)
    t.px(12, 4, DST)
    t.px(3, 3, DST)
    return t


def spring():
    t = Tile(SKY)
    t.rect(6, 9, 9, 15, SND)
    t.rect(6, 9, 6, 15, WHT)
    t.rect(9, 9, 9, 15, BRN)
    t.rect(4, 14, 11, 15, DKG)
    t.rect(3, 5, 12, 8, PUR)
    t.rect(5, 3, 10, 4, PUR)
    t.rect(7, 2, 8, 2, PUR)
    t.rect(2, 7, 13, 8, PUR)
    t.rect(2, 8, 13, 8, BLK)
    t.rect(5, 4, 6, 5, GLD)
    t.rect(9, 6, 10, 7, GLD)
    t.px(4, 7, GLD)
    t.px(12, 7, CYN)
    t.px(8, 3, CYN)
    return t


def checkpoint():
    t = Tile(SKY)
    t.rect(1, 0, 14, 1, BRN)
    t.rect(1, 0, 14, 0, SND)
    t.disc(1, 1, 1, GLD)
    t.disc(14, 1, 1, GLD)
    t.rect(3, 2, 12, 10, PUR)
    t.line(3, 11, 7, 14, PUR)
    t.line(12, 11, 8, 14, PUR)
    t.rect(4, 11, 11, 11, PUR)
    t.rect(5, 12, 10, 12, PUR)
    t.rect(6, 13, 9, 13, PUR)
    t.rect(7, 14, 8, 14, PUR)
    t.rect(3, 2, 3, 10, DST)
    t.rect(12, 2, 12, 10, DST)
    t.disc(7.5, 6, 2, GLD)
    t.px(7, 6, PUR)
    t.px(8, 6, PUR)
    t.rect(7, 3, 8, 3, GLD)
    return t


def mushroom_deco():
    t = Tile(SKY)
    t.rect(7, 8, 8, 14, SND)
    t.rect(7, 8, 7, 14, WHT)
    t.rect(4, 4, 11, 7, CYN)
    t.rect(5, 3, 10, 3, CYN)
    t.rect(6, 2, 9, 2, CYN)
    t.rect(3, 6, 12, 7, CYN)
    t.rect(3, 7, 12, 7, DST)
    t.rect(5, 4, 6, 5, WHT)
    t.px(9, 5, WHT)
    t.px(11, 6, WHT)
    t.rect(4, 15, 11, 15, DKG)
    t.px(2, 14, GLD)
    t.px(13, 13, GLD)
    return t


def rune_used():
    t = Tile(STN)
    t.frame(0, 0, 15, 15, BLK)
    t.frame(1, 1, 14, 14, DST)
    t.rect(2, 2, 13, 13, DST)
    t.speckle(31, [STN, BLK], 10, (2, 2, 13, 13))
    return t


def crumble():
    t = Tile(SND)
    t.frame(0, 0, 15, 15, BRN)
    t.rect(1, 1, 14, 14, SND)
    t.line(3, 1, 6, 6, DBR)
    t.line(6, 6, 4, 9, DBR)
    t.line(4, 9, 8, 14, DBR)
    t.line(11, 1, 9, 5, DBR)
    t.line(9, 5, 12, 9, DBR)
    t.line(12, 9, 11, 14, DBR)
    t.speckle(5, [BRN], 8)
    return t


def spikes():
    t = Tile(SKY)
    for i in range(4):
        x = i * 4
        t.line(x, 15, x + 1, 7, STN)
        t.line(x + 3, 15, x + 2, 7, STN)
        t.rect(x + 1, 8, x + 2, 15, STN)
        t.px(x + 1, 7, WHT)
        t.px(x + 1, 9, LST)
        t.px(x + 2, 12, DST)
        t.px(x + 3, 14, DST)
    t.rect(0, 15, 15, 15, BLK)
    return t


def lava_top():
    t = Tile(RED)
    t.rect(0, 0, 15, 15, RED)
    for x in range(16):
        h = 2 + (3 if (x // 3) % 2 else 0)
        t.rect(x, 0, x, h - 1, SKY)
        t.rect(x, h, x, h + 1, GLD)
    t.speckle(5, [GLD], 6, (0, 6, 15, 15))
    t.speckle(6, [DBR], 4, (0, 8, 15, 15))
    return t


def lava():
    t = Tile(RED)
    t.speckle(8, [GLD, GLD, DBR, BRN], 28)
    t.line(2, 10, 6, 6, GLD)
    t.line(9, 14, 13, 10, GLD)
    return t


def water_top():
    t = Tile(CYN)
    for x in range(16):
        y = 1 + ((x // 2) % 2)
        t.rect(x, 0, x, y - 1, SKY)
        t.px(x, y, WHT)
    t.speckle(3, [WHT, DST], 8, (0, 4, 15, 15))
    t.rect(0, 6, 15, 15, CYN)
    t.speckle(4, [DST, WHT], 9, (0, 6, 15, 15))
    return t


def water():
    t = Tile(CYN)
    t.speckle(12, [DST, WHT, DST], 22)
    t.line(2, 6, 6, 6, WHT)
    t.line(9, 12, 13, 12, WHT)
    return t


def ladder():
    t = Tile(SKY)
    t.rect(3, 0, 4, 15, BRN)
    t.rect(11, 0, 12, 15, BRN)
    t.rect(3, 0, 3, 15, SND)
    t.rect(11, 0, 11, 15, SND)
    for y in (2, 7, 12):
        t.rect(5, y, 10, y + 1, BRN)
        t.rect(5, y, 10, y, SND)
    return t


def vine():
    t = Tile(SKY)
    x = 8
    for y in range(16):
        x = 7 + (1 if (y // 4) % 2 else 0)
        t.px(x, y, DKG)
        t.px(x + 1, y, GRN)
    for y, d in ((2, -1), (7, 1), (12, -1)):
        bx = 8 + (d * 3)
        t.rect(min(bx, 8), y, max(bx, 8), y, DKG)
        t.disc(bx, y, 1, LGR)
        t.px(bx, y, GRN)
    return t


def door(top):
    t = Tile(SKY)
    t.rect(1, 0 if top else 0, 14, 15, BRN)
    t.rect(0, 0, 0, 15, BLK)
    t.rect(15, 0, 15, 15, BLK)
    if top:
        t.rect(2, 3, 13, 15, BRN)
        t.rect(0, 0, 15, 2, STN)
        t.rect(2, 2, 13, 2, BLK)
        t.rect(0, 0, 15, 0, LST)
        t.rect(1, 1, 14, 1, STN)
        t.rect(3, 4, 12, 15, DBR)
        t.line(3, 4, 12, 4, BRN)
        t.rect(7, 4, 8, 15, BLK)
        t.rect(3, 5, 6, 15, BRN)
        t.rect(9, 5, 12, 15, BRN)
    else:
        t.rect(3, 0, 6, 15, BRN)
        t.rect(9, 0, 12, 15, BRN)
        t.rect(7, 0, 8, 15, BLK)
        t.rect(3, 0, 12, 0, DBR)
        t.rect(2, 0, 2, 15, STN)
        t.rect(13, 0, 13, 15, STN)
        t.rect(0, 0, 1, 15, STN)
        t.rect(14, 0, 15, 15, STN)
        t.px(6, 8, GLD)
        t.px(9, 8, GLD)
        t.rect(3, 6, 6, 6, DBR)
        t.rect(9, 6, 12, 6, DBR)
        t.rect(3, 11, 6, 11, DBR)
        t.rect(9, 11, 12, 11, DBR)
    return t


def coin():
    t = Tile(SKY)
    t.disc(7.5, 7.5, 6, BLK)
    t.disc(7.5, 7.5, 5, GLD)
    t.rect(6, 4, 9, 11, WHT)
    t.rect(7, 4, 8, 11, GLD)
    t.px(4, 5, WHT)
    t.px(4, 6, WHT)
    t.px(10, 11, BRN)
    t.px(9, 12, BRN)
    return t


def gem():
    t = Tile(SKY)
    pts = [(7, 2), (8, 2), (5, 4), (10, 4), (3, 6), (12, 6), (4, 8), (11, 8), (5, 10), (10, 10),
           (6, 12), (9, 12), (7, 13), (8, 13)]
    for y in range(3, 14):
        w = 3 + (y - 3) // 1 if y <= 6 else 6 - int((y - 6) * 0.85)
        w = min(w, 6)
        t.rect(8 - w, y, 7 + w, y, CYN)
    t.rect(5, 3, 10, 3, WHT)
    t.line(3, 6, 12, 6, WHT)
    t.line(2, 6, 7, 13, DST)
    t.line(13, 6, 8, 13, DST)
    t.rect(6, 4, 9, 5, WHT)
    t.px(6, 8, WHT)
    return t


def key():
    t = Tile(SKY)
    t.disc(5, 5, 3, BLK)
    t.disc(5, 5, 2, GLD)
    t.px(5, 5, SKY)
    t.rect(7, 7, 9, 8, GLD)
    t.line(8, 7, 13, 12, GLD)
    t.line(9, 7, 14, 12, GLD)
    t.line(12, 12, 12, 14, GLD)
    t.line(14, 12, 14, 14, GLD)
    t.px(4, 4, WHT)
    return t


def potion():
    t = Tile(SKY)
    t.rect(6, 1, 9, 2, SND)
    t.rect(7, 3, 8, 5, WHT)
    t.rect(4, 6, 11, 14, BLK)
    t.rect(5, 7, 10, 13, RED)
    t.rect(5, 7, 6, 12, WHT)
    t.rect(9, 11, 10, 13, DST)
    t.rect(6, 9, 9, 10, PUR)
    return t


def chest():
    t = Tile(SKY)
    t.rect(1, 5, 14, 14, BLK)
    t.rect(2, 6, 13, 13, BRN)
    t.rect(2, 9, 13, 9, BLK)
    t.rect(2, 6, 13, 7, SND)
    t.rect(2, 10, 13, 13, DBR)
    t.rect(2, 4, 13, 5, BLK)
    t.rect(3, 4, 12, 4, BRN)
    t.rect(7, 8, 8, 11, GLD)
    t.px(7, 9, BLK)
    t.rect(2, 6, 3, 13, STN)
    t.rect(12, 6, 13, 13, STN)
    return t


def portal(top):
    t = Tile(SKY)
    if top:
        t.rect(2, 3, 13, 15, PUR)
        t.rect(2, 0, 13, 2, STN)
        t.rect(0, 0, 15, 0, LST)
        t.rect(4, 2, 11, 3, STN)
        t.rect(0, 0, 1, 15, STN)
        t.rect(14, 0, 15, 15, STN)
        t.rect(0, 0, 1, 0, LST)
        t.rect(2, 4, 13, 15, PUR)
        t.speckle(2, [CYN, WHT, BLK], 12, (2, 4, 13, 15))
        t.rect(2, 3, 13, 3, DST)
    else:
        t.rect(2, 0, 13, 15, PUR)
        t.rect(0, 0, 1, 15, STN)
        t.rect(14, 0, 15, 15, STN)
        t.speckle(3, [CYN, WHT, BLK], 12, (2, 0, 13, 15))
        t.rect(0, 14, 15, 15, DST)
    return t


def start_flag():
    t = Tile(SKY)
    t.rect(5, 0, 5, 15, SND)
    t.rect(6, 1, 12, 5, RED)
    t.rect(6, 1, 12, 1, WHT)
    t.px(13, 3, RED)
    t.px(13, 4, SKY)
    t.rect(7, 9, 11, 15, STN)
    t.rect(5, 15, 12, 15, DST)
    t.px(8, 3, GLD)
    return t


def torch():
    t = Tile(SKY)
    t.rect(7, 8, 8, 15, BRN)
    t.rect(7, 8, 7, 15, SND)
    t.rect(6, 7, 9, 8, STN)
    t.rect(7, 4, 8, 6, RED)
    t.rect(7, 2, 8, 5, GLD)
    t.px(7, 1, GLD)
    t.px(8, 3, WHT)
    t.px(7, 6, GLD)
    t.px(6, 5, RED)
    t.px(9, 5, RED)
    return t


def tree_trunk():
    t = Tile(SKY)
    t.rect(5, 0, 10, 15, BRN)
    t.rect(5, 0, 5, 15, DBR)
    t.rect(10, 0, 10, 15, DBR)
    t.rect(6, 0, 6, 15, SND)
    t.speckle(2, [DBR], 6, (6, 0, 9, 15))
    t.rect(3, 14, 4, 15, DBR)
    t.rect(11, 14, 12, 15, DBR)
    return t


def tree_leaves():
    t = Tile(SKY)
    t.disc(8, 8, 8, DKG)
    t.disc(7, 7, 6, GRN)
    t.disc(6, 6, 3, LGR)
    t.speckle(3, [LGR, DKG], 14, (2, 2, 13, 13))
    return t


def bush():
    t = Tile(SKY)
    t.disc(4.5, 11, 4, DKG)
    t.disc(10.5, 11, 5, DKG)
    t.disc(8, 8, 4, DKG)
    t.rect(0, 13, 15, 15, DKG)
    t.disc(4.5, 10.5, 3, GRN)
    t.disc(10.5, 10.5, 4, GRN)
    t.disc(8, 8, 3, GRN)
    t.px(8, 6, LGR)
    t.px(5, 9, LGR)
    t.px(11, 8, LGR)
    t.rect(0, 15, 15, 15, GRN)
    return t


def fence():
    t = Tile(SKY)
    t.rect(1, 6, 14, 7, BRN)
    t.rect(1, 11, 14, 12, BRN)
    t.rect(1, 6, 14, 6, SND)
    t.rect(1, 11, 14, 11, SND)
    for x in (2, 10):
        t.rect(x, 3, x + 2, 15, BRN)
        t.rect(x, 3, x, 15, SND)
        t.rect(x, 3, x + 2, 3, DBR)
        t.px(x + 1, 2, BRN)
    return t


def flowers():
    t = Tile(SKY)
    for x, c in ((3, RED), (8, WHT), (12, GLD)):
        t.rect(x, 9, x, 15, DKG)
        t.disc(x, 8, 1, c)
        t.px(x, 8, GLD if c != GLD else WHT)
    t.rect(1, 14, 5, 15, GRN)
    t.rect(7, 14, 14, 15, GRN)
    t.px(5, 12, GRN)
    t.px(10, 12, GRN)
    return t


def bones():
    t = Tile(SKY)
    t.disc(6, 11, 3, WHT)
    t.rect(4, 13, 8, 14, WHT)
    t.px(5, 11, BLK)
    t.px(7, 11, BLK)
    t.px(6, 13, BLK)
    t.line(9, 15, 14, 12, WHT)
    t.line(9, 14, 14, 11, LST)
    t.disc(14, 11, 1, WHT)
    t.rect(0, 15, 15, 15, DST)
    return t


def wall_banner():
    t = Tile(DST)
    t.rect(0, 0, 15, 15, DST)
    t.rect(4, 0, 11, 11, RED)
    t.line(4, 11, 7, 14, RED)
    t.line(11, 11, 8, 14, RED)
    t.rect(7, 12, 8, 14, RED)
    t.rect(4, 0, 11, 1, GLD)
    t.rect(7, 3, 8, 9, GLD)
    t.rect(5, 5, 10, 6, GLD)
    t.rect(4, 2, 4, 11, DBR)
    return t


def arch_window():
    t = bricks(DST, DST, BLK, BLK, 17)
    t.rect(4, 4, 11, 14, BLK)
    t.disc(7.5, 6, 3.5, BLK)
    t.rect(4, 14, 11, 15, STN)
    t.rect(3, 5, 3, 14, STN)
    t.rect(12, 5, 12, 14, STN)
    t.rect(6, 5, 9, 12, PUR)
    t.rect(7, 5, 8, 12, CYN)
    t.px(7, 6, WHT)
    t.px(7, 7, WHT)
    return t


def crystal_deco():
    t = Tile(SKY)
    t.rect(7, 4, 8, 15, CYN)
    t.rect(7, 4, 7, 15, WHT)
    t.px(7, 3, CYN)
    t.px(8, 3, CYN)
    t.rect(3, 9, 4, 15, PUR)
    t.rect(3, 9, 3, 15, CYN)
    t.px(3, 8, PUR)
    t.rect(11, 7, 12, 15, PUR)
    t.rect(11, 7, 11, 15, CYN)
    t.px(11, 6, PUR)
    t.rect(2, 15, 13, 15, DST)
    t.px(8, 4, DST)
    return t


def sign():
    t = Tile(SKY)
    t.rect(7, 9, 8, 15, BRN)
    t.rect(2, 2, 13, 9, BRN)
    t.frame(2, 2, 13, 9, DBR)
    t.rect(3, 3, 12, 8, SND)
    t.line(4, 5, 11, 5, DBR)
    t.line(4, 7, 9, 7, DBR)
    t.px(12, 3, SND)
    return t


def cloud():
    t = Tile(SKY)
    t.disc(4.5, 9, 3, WHT)
    t.disc(8.5, 7, 4, WHT)
    t.disc(12, 9, 3, WHT)
    t.rect(2, 9, 13, 11, WHT)
    t.rect(2, 11, 13, 11, LST)
    t.rect(5, 10, 6, 10, LST)
    return t


def skull_pillar():
    t = Tile(SKY)
    t.rect(4, 0, 11, 15, STN)
    t.rect(4, 0, 4, 15, LST)
    t.rect(11, 0, 11, 15, DST)
    t.rect(3, 0, 12, 1, LST)
    t.rect(3, 14, 12, 15, DST)
    t.rect(7, 4, 8, 11, DST)
    t.speckle(3, [DST], 6, (5, 2, 10, 13))
    return t


def dragon_statue():
    t = Tile(SKY)
    t.rect(3, 14, 12, 15, DST)
    t.rect(4, 12, 11, 13, STN)
    t.rect(6, 6, 9, 11, STN)
    t.rect(5, 4, 11, 6, STN)
    t.rect(10, 5, 13, 6, STN)
    t.px(8, 4, GLD)
    t.line(5, 4, 4, 1, STN)
    t.line(10, 4, 11, 1, STN)
    t.rect(6, 6, 6, 11, LST)
    t.px(12, 5, RED)
    t.rect(2, 7, 5, 9, DST)
    t.line(2, 7, 0, 5, DST)
    return t


# (id, nome, categoria, classe, funzione, descrizione)
CATALOG = [
    ("EMPTY", "Vuoto", "base", EMPTY, lambda: Tile(SKY), "Cielo / nessun blocco"),
    ("GRASS", "Terra erbosa", "terreno", SOLID, grass_top, "Terreno con erba in cima"),
    ("DIRT", "Terra", "terreno", SOLID, dirt, "Riempimento sotto l'erba"),
    ("STONE", "Pietra", "terreno", SOLID, stone, "Blocco di roccia grezza"),
    ("BRICK", "Mattone del castello", "terreno", SOLID, castle_brick, "Muri e torri"),
    ("MOSSY", "Pietra muschiosa", "terreno", SOLID, mossy, "Rovine antiche"),
    ("CRATE", "Cassa di legno", "terreno", SOLID, crate, "Solida, decorativa"),
    ("CRYST", "Blocco di cristallo", "terreno", SOLID, crystal_block, "Caverne magiche"),
    ("GOLDB", "Blocco d'oro", "terreno", SOLID, gold_block, "Solido e lucente"),
    ("CWALL", "Parete del castello", "sfondo", DECOR, castle_wall, "Sfondo non solido"),
    ("WOODP", "Piattaforma di legno", "piattaforme", ONEWAY, wood_platform, "Si salta da sotto"),
    ("BRIDGE", "Ponte di corda", "piattaforme", ONEWAY, rope_bridge, "Si salta da sotto"),
    ("LEDGE", "Cornice di pietra", "piattaforme", ONEWAY, stone_ledge, "Si salta da sotto"),
    ("RUNE", "Blocco runico", "speciali", HIT, rune_block, "Colpito da sotto rilascia un oggetto"),
    ("RUNEU", "Blocco runico usato", "speciali", SOLID, rune_used, "Dopo l'uso"),
    ("BREAK", "Pietra fessurata", "speciali", HIT, breakable, "Si rompe da sotto"),
    ("CRUMB", "Blocco friabile", "speciali", HIT, crumble, "Crolla dopo il passaggio"),
    ("SPRING", "Fungo molla viola", "speciali", TRIGGER, spring, "Rimbalzo alto"),
    ("SPIKES", "Spuntoni", "pericoli", HAZARD, spikes, "Uccidono al contatto"),
    ("LAVAT", "Lava (superficie)", "pericoli", HAZARD, lava_top, "Uccide al contatto"),
    ("LAVA", "Lava", "pericoli", HAZARD, lava, "Riempimento"),
    ("WATERT", "Acqua (superficie)", "liquidi", LIQUID, water_top, "Nuoto, movimento lento"),
    ("WATER", "Acqua", "liquidi", LIQUID, water, "Riempimento"),
    ("LADDER", "Scala di legno", "scalabili", CLIMB, ladder, "Su e giu'"),
    ("VINE", "Rampicante", "scalabili", CLIMB, vine, "Su e giu'"),
    ("DOORT", "Portone (alto)", "speciali", TRIGGER, lambda: door(True), "Si apre con la chiave"),
    ("DOORB", "Portone (basso)", "speciali", TRIGGER, lambda: door(False), "Si apre con la chiave"),
    ("COIN", "Moneta d'oro", "oggetti", PICKUP, coin, "Punti"),
    ("GEM", "Gemma", "oggetti", PICKUP, gem, "Molti punti"),
    ("KEY", "Chiave", "oggetti", PICKUP, key, "Apre i portoni"),
    ("POTION", "Pozione", "oggetti", PICKUP, potion, "Ricarica un cuore"),
    ("CHEST", "Forziere", "oggetti", HIT, chest, "Contiene un tesoro"),
    ("CHKPT", "Stendardo checkpoint", "marcatori", TRIGGER, checkpoint, "Punto di ripresa"),
    ("PORTT", "Portale (alto)", "marcatori", TRIGGER, lambda: portal(True), "Fine del livello"),
    ("PORTB", "Portale (basso)", "marcatori", TRIGGER, lambda: portal(False), "Fine del livello"),
    ("START", "Partenza", "marcatori", TRIGGER, start_flag, "Dove inizia l'eroe"),
    ("TORCH", "Torcia", "decorazioni", DECOR, torch, "Animata in gioco"),
    ("TRUNK", "Tronco", "decorazioni", DECOR, tree_trunk, "Albero"),
    ("LEAVES", "Chioma", "decorazioni", DECOR, tree_leaves, "Albero"),
    ("BUSH", "Cespuglio", "decorazioni", DECOR, bush, ""),
    ("FENCE", "Staccionata", "decorazioni", DECOR, fence, ""),
    ("FLOWER", "Fiori", "decorazioni", DECOR, flowers, ""),
    ("BONES", "Teschio e ossa", "decorazioni", DECOR, bones, ""),
    ("BANNER", "Arazzo", "decorazioni", DECOR, wall_banner, "Su parete del castello"),
    ("WINDOW", "Finestra ad arco", "decorazioni", DECOR, arch_window, "Su parete del castello"),
    ("CRYDEC", "Cristalli", "decorazioni", DECOR, crystal_deco, ""),
    ("SHROOM", "Fungo", "decorazioni", DECOR, mushroom_deco, ""),
    ("SIGN", "Cartello", "decorazioni", DECOR, sign, ""),
    ("CLOUD", "Nuvola", "decorazioni", DECOR, cloud, ""),
    ("PILLAR", "Colonna", "decorazioni", DECOR, skull_pillar, ""),
    ("DRAGON", "Statua del drago", "decorazioni", DECOR, dragon_statue, ""),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    n = len(CATALOG)
    assert n <= 256
    tiles = [c[4]() for c in CATALOG]

    # --- png indicizzato, 16 tile per riga ---
    cols = 16
    rows = (n + cols - 1) // cols
    img = Image.new("P", (cols * 16, rows * 16), 0)
    flat = []
    for r, g, b in PAL:
        flat += [r * 255 // 7, g * 255 // 7, b * 255 // 7]
    img.putpalette(flat + [0] * (768 - len(flat)))
    for i, t in enumerate(tiles):
        ox, oy = (i % cols) * 16, (i // cols) * 16
        for y in range(16):
            for x in range(16):
                img.putpixel((ox + x, oy + y), t.p[y][x])
    img.save(os.path.join(OUT, "tiles.png"))

    # --- binari ---
    with open(os.path.join(OUT, "tiles.bin"), "wb") as f:
        for t in tiles:
            for y in range(16):
                for x in range(0, 16, 2):
                    f.write(bytes([(t.p[y][x] << 4) | t.p[y][x + 1]]))
    with open(os.path.join(OUT, "palette.bin"), "wb") as f:
        for r, g, b in PAL:
            f.write(bytes([(r << 4) | b, g]))

    # --- include asm ---
    with open(os.path.join(OUT, "tileset.inc"), "w") as f:
        f.write("; generato da tools/gen_tiles.py - non modificare a mano\n")
        for i, c in enumerate(CATALOG):
            f.write("T_%-7s equ %d\n" % (c[0], i))
        f.write("T_COUNT   equ %d\n\n" % n)
        for i, name in enumerate(CLASS_NAMES):
            f.write("C_%-8s equ %d\n" % (name.upper().replace("'", ""), i))
        f.write("\n; classe di collisione di ogni tile (1 byte per tile)\ntile_class:\n")
        for i in range(0, n, 16):
            f.write("        db " + ",".join(str(c[3]) for c in CATALOG[i:i + 16]) + "\n")

    # --- nomi per l'editor (stride 24 byte, ASCII, zero-terminati) ---
    with open(os.path.join(OUT, "tilenames.inc"), "w") as f:
        f.write("; generato da tools/gen_tiles.py - nomi dei tile, 24 byte ciascuno\ntile_names:\n")
        for c in CATALOG:
            nm = c[1].encode("ascii")
            assert len(nm) < 24
            f.write('        db "%s"%s\n' % (c[1], ",0" * (24 - len(nm))))

    # --- catalogo ---
    cat = [{"id": i, "key": c[0], "nome": c[1], "categoria": c[2], "classe": CLASS_NAMES[c[3]],
            "descrizione": c[5]} for i, c in enumerate(CATALOG)]
    with open(os.path.join(OUT, "catalog.json"), "w", encoding="utf-8") as f:
        json.dump(cat, f, indent=1, ensure_ascii=False)

    # --- anteprima: 4x, sfondo cielo, etichette per categoria ---
    S, per_row = 4, 8
    cell_w, cell_h = 16 * S + 56, 16 * S + 18
    rows_p = (n + per_row - 1) // per_row
    pv = Image.new("RGB", (per_row * cell_w, rows_p * cell_h), (24, 24, 32))
    d = ImageDraw.Draw(pv)
    rgb = [(r * 255 // 7, g * 255 // 7, b * 255 // 7) for r, g, b in PAL]
    for i, t in enumerate(tiles):
        ox, oy = (i % per_row) * cell_w + 4, (i // per_row) * cell_h + 2
        for y in range(16):
            for x in range(16):
                d.rectangle([ox + x * S, oy + y * S, ox + x * S + S - 1, oy + y * S + S - 1],
                            fill=rgb[t.p[y][x]])
        d.text((ox, oy + 16 * S + 2), "%02d %s" % (i, CATALOG[i][0]), fill=(230, 230, 230))
    pv.save(os.path.join(OUT, "tiles_preview.png"))

    # --- scena di prova 20x8 che usa i blocchi, per giudicare l'insieme ---
    W, H = 20, 9
    sc = [[0] * W for _ in range(H)]
    T = {c[0]: i for i, c in enumerate(CATALOG)}
    for x in range(W):
        sc[7][x] = T["GRASS"]
        sc[8][x] = T["DIRT"]
    for x in range(W):
        sc[0][x] = T["EMPTY"]
    for x in (8, 9):
        sc[7][x] = T["WATERT"]
        sc[8][x] = T["WATER"]
    sc[7][14] = T["LAVAT"]
    sc[8][14] = T["LAVA"]
    sc[6][5] = T["SPIKES"]
    sc[6][2] = T["TRUNK"]
    sc[5][2] = T["TRUNK"]
    sc[4][2] = T["LEAVES"]
    sc[4][1] = T["LEAVES"]
    sc[4][3] = T["LEAVES"]
    sc[6][4] = T["BUSH"]
    sc[6][1] = T["START"]
    sc[4][7] = T["RUNE"]
    sc[4][8] = T["BREAK"]
    sc[4][9] = T["RUNE"]
    sc[3][12] = T["WOODP"]
    sc[3][13] = T["WOODP"]
    sc[2][12] = T["COIN"]
    sc[2][13] = T["GEM"]
    sc[6][11] = T["SPRING"]
    sc[6][16] = T["TORCH"]
    for y in range(3, 7):
        sc[y][17] = T["BRICK"]
        sc[y][18] = T["BRICK"]
        sc[y][19] = T["BRICK"]
    sc[2][17] = T["PILLAR"]
    sc[6][15] = T["CHKPT"]
    sc[1][4] = T["CLOUD"]
    sc[1][14] = T["CLOUD"]
    sc[6][6] = T["FENCE"]
    sc[6][3] = T["FLOWER"]
    sc[6][10] = T["SHROOM"]
    sc[6][13] = T["CHEST"]
    sp = Image.new("RGB", (W * 16 * 3, H * 16 * 3))
    d = ImageDraw.Draw(sp)
    for ty in range(H):
        for tx in range(W):
            t = tiles[sc[ty][tx]]
            for y in range(16):
                for x in range(16):
                    d.rectangle([(tx * 16 + x) * 3, (ty * 16 + y) * 3, (tx * 16 + x) * 3 + 2,
                                 (ty * 16 + y) * 3 + 2], fill=rgb[t.p[y][x]])
    sp.save(os.path.join(OUT, "scene_preview.png"))
    print("%d tile generati in %s" % (n, os.path.abspath(OUT)))


if __name__ == "__main__":
    main()
