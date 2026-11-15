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
    print("hero.bin: %d byte (%d frame x %d layer x 48)" % (len(blob), len(frames), LAYERS))


if __name__ == "__main__":
    main()
