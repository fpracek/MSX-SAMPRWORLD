"""SamPr World - i 10 livelli fissi della campagna (sempre presenti nella ROM).

Ogni livello e' composto da segmenti collaudati (buche, muri, spuntoni, scale, nemici, ponti, lava con pietre friabili,
chiave + portone...) con dimensioni sempre entro i limiti della fisica dell'eroe: salto massimo ~3 tile in altezza,
buche fino a 3 tile. Uscite: assets/levels/NN.lvl (formato livello v1), assets/campaign.bin (segmento 6 della ROM:
directory + blob) e anteprime in assets/levels/NN.png.

Tile: terra a riga 10-11 (cima = riga 10), l'eroe cammina sulla riga 9, partenza (1,9), portale (121,8-9).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import level  # noqa: E402

OUT = os.path.join(HERE, "..", "assets")
T = {m.group(1): int(m.group(2)) for m in re.finditer(r"^T_(\w+)\s+equ\s+(\d+)", open(os.path.join(OUT, "tileset.inc")).read(), re.M)}
W, H, GR = 128, 12, 10


class Lv:
    def __init__(self, theme, title):
        self.g = [[0] * W for _ in range(H)]
        self.theme, self.title = theme, title
        self.c = 0
        self.busy = set()                       # colonne occupate da pericoli/nemici (niente decorazioni)
        top, under = {"prato": ("GRASS", "DIRT"), "grotta": ("STONE", "STONE"), "castello": ("BRICK", "BRICK")}[theme]
        for x in range(W):
            self.g[10][x], self.g[11][x] = T[top], T[under]
        if theme in ("grotta", "castello"):
            for x in range(W):
                self.g[0][x] = self.g[1][x] = T["CRYST" if theme == "grotta" else "BRICK"]
        if theme == "castello":
            for y in range(2, 10):
                for x in range(W):
                    self.g[y][x] = T["CWALL"]
        self.block = T["STONE" if theme != "castello" else "BRICK"]
        self.plat = T["WOODP" if theme == "prato" else "LEDGE"]

    def put(self, x, y, t):
        self.g[y][x] = T[t] if isinstance(t, str) else t

    # ---- segmenti ----
    def flat(self, n): self.c += n

    def pit(self, n):
        for i in range(n):
            self.g[10][self.c + i] = self.g[11][self.c + i] = 0
            self.put(self.c + i, 7, "COIN")
            self.busy.add(self.c + i)
        self.c += n

    def wall(self, h):
        for k in range(h):
            self.g[9 - k][self.c] = self.block
        self.busy.add(self.c)
        self.c += 2

    def steps(self):
        for i, h in enumerate((1, 2, 2, 1)):
            for k in range(h):
                self.g[9 - k][self.c + i] = self.block
            self.busy.add(self.c + i)
        self.c += 5

    def spikes(self, n):
        for i in range(n):
            self.put(self.c + i, 9, "SPIKES")
            self.busy.add(self.c + i)
        self.c += n

    def goblin(self):
        self.put(self.c + 3, 9, "GOBLIN")
        self.busy.update(range(self.c, self.c + 8))
        self.c += 8

    def bat(self, row=5):
        self.put(self.c + 4, row, "BAT")
        self.c += 8

    def platform(self, n, row=6):
        for i in range(n):
            self.g[row][self.c + i] = self.plat
            self.put(self.c + i, row - 1, "COIN")
        self.c += n + 2

    def runeblock(self):
        self.put(self.c, 6, "BREAK")
        self.put(self.c + 1, 6, "RUNE")
        self.put(self.c + 2, 6, "BREAK")
        self.c += 4

    def spring(self):
        self.put(self.c, 9, "SPRING")
        for i in range(4):
            self.g[4][self.c + 2 + i] = self.plat
        self.put(self.c + 3, 3, "GEM")
        self.put(self.c + 4, 3, "GEM")
        self.busy.add(self.c)
        self.c += 7

    def checkpoint(self):
        self.put(self.c, 9, "CHKPT")
        self.c += 2

    def water(self, n):
        for i in range(n):
            self.g[10][self.c + i] = T["BRIDGE"]
            self.g[11][self.c + i] = T["WATER"]
            self.busy.add(self.c + i)
        self.c += n

    def lavahop(self, n):                       # n dispari: lava con pietre friabili a colonne alterne
        assert n % 2 == 1
        for i in range(n):
            self.g[10][self.c + i] = T["CRUMB"] if i % 2 else T["LAVAT"]
            self.g[11][self.c + i] = T["LAVA"]
            self.busy.add(self.c + i)
        self.c += n

    def keydoor(self):
        self.put(self.c, 9, "KEY")
        d = self.c + 12
        for y in range(2, 8):
            self.g[y][d] = self.block
        self.put(d, 8, "DOORT")
        self.put(d, 9, "DOORB")
        self.busy.update(range(d - 1, d + 2))
        self.c = d + 3

    # ---- fine livello ----
    def finish(self):
        assert self.c <= 114, "%s troppo lungo: %d" % (self.title, self.c)
        self.put(1, 9, "START")
        self.put(121, 8, "PORTT")
        self.put(121, 9, "PORTB")
        self.put(119, 9, "TORCH")
        self.put(123, 9, "TORCH")
        # decorazioni solo in celle libere e lontane dai pericoli
        import random
        r = random.Random(sum(map(ord, self.title)))
        dec = {"prato": ["BUSH", "FLOWER", "FENCE", "SIGN", "TRUNK", "SHROOM"],
               "grotta": ["CRYDEC", "SHROOM", "BONES", "TORCH"],
               "castello": ["TORCH", "BONES", "PILLAR", "TORCH"]}[self.theme]
        for x in range(4, 118):
            if self.g[9][x] == 0 or self.g[9][x] == T["CWALL"]:
                if all(abs(x - b) > 2 for b in self.busy) and self.g[10][x] in (T["GRASS"], T["STONE"], T["BRICK"]) and r.random() < 0.12:
                    self.g[9][x] = T[r.choice(dec)]
        if self.theme == "castello":
            for x in range(6, 118, 9):
                if self.g[5][x] == T["CWALL"]:
                    self.g[5][x] = T["WINDOW"]
                if self.g[4][x + 4] == T["CWALL"]:
                    self.g[4][x + 4] = T["BANNER"]
        if self.theme == "prato":
            for x in range(3, 120, 14):
                self.put(x, 1 + (x % 3), "CLOUD")
        if self.title.startswith("Dragon"):
            self.put(110, 9, "DRAGON")
        return bytes(t for row in self.g for t in row)


LEVELS = [
    ("Starter Meadow", "prato", "flat6 platform4 flat3 pit2 flat4 runeblock flat4 goblin flat2 steps flat4 checkpoint flat2 pit3 flat4 bat goblin flat3 wall1 flat3"),
    ("Sunny Hills", "prato", "flat6 spring flat2 pit2 flat3 goblin goblin flat2 wall2 flat4 pit3 flat3 platform5 flat2 bat checkpoint flat3 spikes2 flat4 goblin steps flat3 pit2 flat3"),
    ("Enchanted Forest", "prato", "flat6 bat flat3 goblin flat3 pit3 flat3 wall2 flat3 spikes2 flat3 keydoor flat3 checkpoint goblin flat3 steps pit2 flat3"),
    ("Crystal Cave", "grotta", "flat6 spikes2 flat4 water8 flat3 goblin flat3 pit3 flat3 runeblock flat3 checkpoint flat2 bat flat3 steps flat6 spikes2 flat3"),
    ("Underground Lake", "grotta", "flat6 water12 flat3 bat bat flat3 lavahop5 flat4 goblin flat3 checkpoint spikes2 flat3 water8 flat4 pit2 flat3"),
    ("Deep Mine", "grotta", "flat6 keydoor flat3 goblin goblin flat3 spikes2 flat3 pit3 flat3 bat checkpoint flat3 wall2 flat3 lavahop7 flat3 steps flat3"),
    ("Castle Gate", "castello", "flat6 goblin flat3 wall2 flat3 goblin flat2 pit3 flat3 spikes2 flat3 checkpoint bat flat3 steps goblin flat3 wall1 flat3 pit2 flat3 goblin flat3"),
    ("Lava Moat", "castello", "flat6 lavahop5 flat3 goblin flat3 bat bat flat3 lavahop7 flat3 checkpoint spikes2 flat3 keydoor flat3 goblin flat2 steps flat3"),
    ("Goblin Tower", "castello", "flat6 goblin goblin flat3 steps wall2 flat3 goblin flat3 pit3 flat3 spikes2 goblin checkpoint flat3 keydoor flat3 bat goblin flat3"),
    ("Dragon's Lair", "castello", "flat6 goblin flat3 lavahop5 flat3 bat flat3 spikes2 flat3 wall2 flat2 goblin flat2 checkpoint flat2 pit3 flat3 keydoor flat2 bat goblin flat2 steps flat3 lavahop3 flat3"),
]


def build(spec):
    title, theme, seq = spec
    lv = Lv(theme, title)
    for tok in seq.split():
        m = re.match(r"([a-z]+)(\d*)", tok)
        name, n = m.group(1), m.group(2)
        fn = getattr(lv, name)
        fn(int(n)) if n else fn()
    return lv.finish()


def main():
    os.makedirs(os.path.join(OUT, "levels"), exist_ok=True)
    blobs = []
    for i, spec in enumerate(LEVELS):
        tiles = build(spec)
        blob = level.encode(W, H, tiles, (1, 9), {"prato": 0, "grotta": 1, "castello": 2}[spec[1]], spec[0])
        open(os.path.join(OUT, "levels", "%02d.lvl" % (i + 1)), "wb").write(blob)
        blobs.append((spec[0], blob))
        print("%2d %-24s %4d byte" % (i + 1, spec[0], len(blob)))
    # segmento 6: byte 0 = numero di livelli; voci da 20 byte (offset, lunghezza, titolo[16]); poi i blob
    n = len(blobs)
    dire, data = bytearray([n]), bytearray()
    base = 1 + 20 * n
    for title, blob in blobs:
        dire += (base + len(data)).to_bytes(2, "little") + len(blob).to_bytes(2, "little") + title.encode("ascii")[:16].ljust(16, b"\0")
        data += blob
    seg = bytes(dire) + bytes(data)
    assert len(seg) <= 8192, len(seg)
    open(os.path.join(OUT, "campaign.bin"), "wb").write(seg.ljust(8192, bytes([255])))
    print("campaign.bin: %d byte usati su 8192" % len(seg))


if __name__ == "__main__":
    main()
