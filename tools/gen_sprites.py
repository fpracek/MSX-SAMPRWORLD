"""SamPr World - sprite dell'eroe (16x16, sprite MSX2 modo 2: un colore per riga per ogni sprite).

Ogni frame viene scomposto in LAYERS sprite sovrapposti: per ogni riga i colori distinti vanno ognuno su un layer.
Uscite in assets/:
  hero.bin          per ogni frame (8: 4 verso destra + 4 specchiati): per layer 32 byte pattern + 16 byte colori
  hero_preview.png  anteprima ingrandita dei frame
Frame: 0 fermo, 1 corsa A, 2 corsa B, 3 salto (poi gli stessi 4 specchiati = verso sinistra).
"""
import os

from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
LAYERS = 4
# colori (indici della palette del gioco, vedi gen_tiles.py)
C = {".": 0, "o": 1, "s": 9, "S": 10, "r": 12, "k": 7, "b": 14, "B": 13, "g": 11, "d": 5, "n": 6, "w": 15}

FRAMES = [
    # 0 fermo (verso destra)
    ["......oooo......",
     ".....oSSSso.r...",
     "....osSSSsso.r..",
     "....osssssso....",
     "....oskkkkso....",
     "....okokkoko....",
     ".....okkkko.....",
     "....oobbbboo....",
     "...okobbbbbok...",
     "...okobggbbok...",
     "...okobbbbbo....",
     "....oobbbboo....",
     "....odddddo.....",
     "....odo.odo.....",
     "...onno.onno....",
     "...oooo.oooo...."],
    # 1 corsa A
    ["......oooo......",
     ".....oSSSso.r...",
     "....osSSSsso.r..",
     "....osssssso....",
     "....oskkkkso....",
     "....okokkoko....",
     ".....okkkko.....",
     "...ooobbbboo....",
     "..okkobbbbbo....",
     "..okkobggbbo....",
     "...ooobbbbbo....",
     "....oobbbboo....",
     "....oddddddo....",
     "...odo...odo....",
     "..onno....onno..",
     "..oooo....oooo.."],
    # 2 corsa B
    ["......oooo......",
     ".....oSSSso.r...",
     "....osSSSsso.r..",
     "....osssssso....",
     "....oskkkkso....",
     "....okokkoko....",
     ".....okkkko.....",
     "....oobbbboo....",
     "....obbbbbbook..",
     "....obbggbbokk..",
     "....obbbbbbook..",
     "....oobbbboo....",
     ".....odddo......",
     ".....odddo......",
     ".....onnno......",
     ".....ooooo......"],
    # 3 salto
    ["......oooo..r...",
     ".....oSSSso.r...",
     "....osSSSsso....",
     "....osssssso....",
     "....oskkkkso....",
     "..o.okokkoko.o..",
     ".okoo.okkko.okk.",
     ".okkoobbbboookk.",
     "..ookobbbbokoo..",
     "....oobggboo....",
     ".....obbbbo.....",
     "....oddddddo....",
     "...odo....odo...",
     "..onno....onno..",
     "..oooo....oooo..",
     "................"],
]


# ---- nemici: 2 layer ('o' = contorno/occhi nel layer nero, 'f' = riempimento nel layer colorato) ----
GOB_A = ["................",
         "..oo........oo..",
         "..ofo.oooo.ofo..",
         "...ofoffffofo...",
         "....offffffo....",
         "...offoffoffo...",
         "...offffffffo...",
         "...offooooffo...",
         "....offffffo....",
         ".....oofffo.....",
         "....offffffo....",
         "...offffffffo...",
         "...oofffffoo....",
         "....offoffo.....",
         "...offo.offo....",
         "...ooo...ooo...."]
GOB_B = GOB_A[:12] + ["....oofffoo.....",
                      ".....offfo......",
                      ".....ofofo......",
                      ".....ooooo......"]
BAT_A = ["................",
         "o..............o",
         "oo............oo",
         "ofo...o..o...ofo",
         "offo.offffo.offo",
         "offfoffoffoffffo",
         ".offfffffffffffo",
         "..offfffffffffo.",
         "...oofffffffoo..",
         ".....offffffo...",
         "......ofoffo....",
         ".......oooo.....",
         "................",
         "................",
         "................",
         "................"]
BAT_B = ["................",
         "................",
         "................",
         "......o....o....",
         ".....offo.offo..",
         "..oooffoffoffooo",
         ".offfffffffffffo",
         "offffffffffffffo",
         "oofffffffffffoo.",
         ".ooffffffffffoo.",
         "...offfoofffo...",
         "....ooffffoo....",
         ".....oooooo.....",
         "................",
         "................",
         "................"]
ENEMY_FRAMES = [GOB_A, GOB_B, [r[::-1] for r in GOB_A], [r[::-1] for r in GOB_B], BAT_A, BAT_B]
ENEMY_FILL = {"goblin": 3, "bat": 13}      # colore del riempimento (indice palette del gioco)


def enemy_bin():
    out = bytearray()
    for fr in ENEMY_FRAMES:
        assert len(fr) == 16 and all(len(r) == 16 for r in fr), fr
        for ch in "of":                       # layer 0 = contorno, layer 1 = riempimento
            pat = []
            for row in fr:
                bits = 0
                for x, c in enumerate(row):
                    if c == ch:
                        bits |= 0x8000 >> x
                pat.append(bits)
            q = [(b >> 8) & 255 for b in pat[:8]] + [(b >> 8) & 255 for b in pat[8:]] +                 [b & 255 for b in pat[:8]] + [b & 255 for b in pat[8:]]
            out += bytes(q)
    return bytes(out)


# ---- HUD a sprite (modalita' scroll hardware V9958: le righe di stato scorrerebbero con la mappa) ----
DIGITS = ["01110,10001,10011,10101,11001,10001,01110", "00100,01100,00100,00100,00100,00100,01110",
          "01110,10001,00001,00010,00100,01000,11111", "11110,00001,00001,01110,00001,00001,11110",
          "00010,00110,01010,10010,11111,00010,00010", "11111,10000,11110,00001,00001,10001,01110",
          "00110,01000,10000,11110,10001,10001,01110", "11111,00001,00010,00100,01000,01000,01000",
          "01110,10001,10001,01110,10001,10001,01110", "01110,10001,10001,01111,00001,00010,01100"]
ICON_COIN = ["................", ".....######.....", "...##########...", "..############..", ".######..######.", ".#####....#####.",
             ".#####....#####.", ".#####....#####.", ".#####....#####.", ".#####....#####.", ".######..######.", "..############..",
             "...##########...", ".....######.....", "................", "................"]
ICON_KEY = ["................", "...######.......", "..########......", "..###..###......", "..###..###......", "..########......",
            "...######.......", ".....###........", ".....###........", ".....#####......", ".....###........", ".....#####......",
            ".....###........", "................", "................", "................"]
ICON_SKULL = ["................", "....########....", "...##########...", "..############..", "..##..####..##..", "..##..####..##..",
              "..############..", "...####..####...", "....########....", ".....#.##.#.....", ".....######.....", ".....#.##.#.....",
              "................", "................", "................", "................"]


def hud_bin():
    out = bytearray()
    for d in DIGITS:                                   # 8 byte per cifra (5 colonne a sinistra, 7 righe)
        rows = d.split(",")
        for r in range(8):
            out.append(int(rows[r].ljust(8, "0"), 2) if r < 7 else 0)
    for icon in (ICON_COIN, ICON_KEY, ICON_SKULL):    # pattern sprite 16x16: UL, LL, UR, LR
        pat = [int(r.replace("#", "1").replace(".", "0"), 2) for r in icon]
        out += bytes([(b >> 8) & 255 for b in pat[:8]] + [(b >> 8) & 255 for b in pat[8:]] +
                     [b & 255 for b in pat[:8]] + [b & 255 for b in pat[8:]])
    assert len(out) == 80 + 96
    return bytes(out)


def mirror(rows):
    return [r[::-1] for r in rows]


def build():
    frames = FRAMES + [mirror(f) for f in FRAMES]
    out = bytearray()
    for fr in frames:
        layers = [[0] * 16 for _ in range(LAYERS)]       # pattern: per layer 16 righe da 16 bit
        colors = [[0] * 16 for _ in range(LAYERS)]
        for y, row in enumerate(fr):
            assert len(row) == 16, (y, row)
            cols = []
            for ch in row:
                c = C[ch]
                if c and c not in cols:
                    cols.append(c)
            assert len(cols) <= LAYERS, "troppi colori sulla riga %d: %s" % (y, row)
            for li, c in enumerate(cols):
                bits = 0
                for x, ch in enumerate(row):
                    if C[ch] == c:
                        bits |= 0x8000 >> x
                layers[li][y] = bits
                colors[li][y] = c
        for li in range(LAYERS):
            pat = layers[li]
            # sprite 16x16: quadranti SS (alto-sx), SD..: ordine = alto-sx, basso-sx, alto-dx, basso-dx
            q = [(b >> 8) & 255 for b in pat[:8]] + [(b >> 8) & 255 for b in pat[8:]] + \
                [b & 255 for b in pat[:8]] + [b & 255 for b in pat[8:]]
            out += bytes(q)
            out += bytes(colors[li])
    return frames, bytes(out)


def main():
    frames, blob = build()
    open(os.path.join(OUT, "hero.bin"), "wb").write(blob)
    eb = enemy_bin()
    import gen_music
    audio, _ = gen_music.build()
    seg = (blob + eb).ljust(2048, bytes([255])) + audio       # audio a offset 2048
    seg = seg.ljust(3072, bytes([255])) + hud_bin()           # HUD a sprite a offset 3072
    assert len(seg) <= 8192
    open(os.path.join(OUT, "sprites.bin"), "wb").write(seg.ljust(8192, bytes([255])))   # segmento 4 della ROM
    sys_pal = [(2, 4, 7), (0, 0, 1), (0, 3, 1), (2, 5, 1), (4, 7, 2), (2, 1, 0), (4, 2, 1), (6, 4, 2), (2, 2, 3),
               (4, 4, 5), (6, 6, 7), (7, 6, 0), (6, 1, 1), (4, 2, 6), (1, 5, 7), (7, 7, 7)]
    rgb = [(r * 255 // 7, g * 255 // 7, b * 255 // 7) for r, g, b in sys_pal]
    S = 8
    im = Image.new("RGB", (len(frames) * (16 * S + 8), 16 * S + 8), (40, 120, 255))
    for i, fr in enumerate(frames):
        for y, row in enumerate(fr):
            for x, ch in enumerate(row):
                c = C[ch]
                if c:
                    for dy in range(S):
                        for dx in range(S):
                            im.putpixel((i * (16 * S + 8) + 4 + x * S + dx, 4 + y * S + dy), rgb[c])
    im.save(os.path.join(OUT, "hero_preview.png"))
    # anteprima nemici
    ims = Image.new("RGB", (len(ENEMY_FRAMES) * (16 * S + 8), 16 * S + 8), (40, 120, 255))
    for i, fr in enumerate(ENEMY_FRAMES):
        fill = rgb[ENEMY_FILL["bat"] if i >= 4 else ENEMY_FILL["goblin"]]
        for y, row in enumerate(fr):
            for x, ch in enumerate(row):
                if ch in "of":
                    col = rgb[1] if ch == "o" else fill
                    for dy in range(S):
                        for dx in range(S):
                            ims.putpixel((i * (16 * S + 8) + 4 + x * S + dx, 4 + y * S + dy), col)
    ims.save(os.path.join(OUT, "enemies_preview.png"))
    print("hero.bin: %d byte (%d frame x %d layer x 48)" % (len(blob), len(frames), LAYERS))


if __name__ == "__main__":
    main()
