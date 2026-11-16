"""SamPr World - carattere ridefinito dell'HUD (font di Il Maniero, N. Brogelli): 64 glifi 8x8 (ASCII 32-95, solo maiuscole)
+ 4 icone (64 cuore, 65 chiave, 66 casella munizioni vuota, 67 piena) in SCREEN 5 (4 byte per riga, 8 righe = 32 byte per
glifo). Lettere: riempimento = indice 15, contorno nero = indice 1; il trasparente diventa nero (le fasce dell'HUD sono su
fondo nero). Il motore (editor/tall.asm, hud) sostituisce l'indice 15 con il colore dello schema; le icone (64-67) hanno i
loro colori. Uscita: editor/hudfont.inc (dentro il segmento ROM 3, finestra A000)."""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
im = Image.open(os.path.join(ROOT, "assets", "maniero", "src", "font1.png")).convert("RGBA")
lines = ["; generato da tools/gen_hudfont.py - NON modificare a mano: font dell'HUD (ASCII 32-95 + 4 icone), 32 byte per glifo",
         "hudfont:"]
for g in range(64):
    gx, gy = (g % 32) * 8, (g // 32) * 8
    rows = []
    for y in range(8):
        px = []
        for x in range(8):
            r, gg, b, a = im.getpixel((gx + x, gy + y))
            if a == 0 or (r, gg, b) == (255, 0, 255):
                px.append(1)
            elif (r, gg, b) == (255, 255, 255):
                px.append(15)
            else:
                px.append(1)
        rows += [(px[i] << 4) | px[i + 1] for i in range(0, 8, 2)]
    lines.append("        db " + ",".join(str(v) for v in rows))
ICONS = [
    ["........", ".99.99..", "9999999.", "9999999.", ".99999..", "..999...", "...9....", "........"],                 # cuore (7 px + vuoto)
    ["........", "..BBBB..", ".B....B.", ".B....B.", "..BBBB..", "...B....", "...BB...", "...B...."],                 # chiave
    ["........", ".AAAAAA.", ".A....A.", ".A....A.", ".A....A.", ".A....A.", ".AAAAAA.", "........"],                 # munizioni vuote
    ["........", ".AAAAAA.", ".AAAAAA.", ".AAAAAA.", ".AAAAAA.", ".AAAAAA.", ".AAAAAA.", "........"],                 # munizioni piene
]
ICOL = {".": 1, "9": 9, "B": 11, "A": 10}
for ic in ICONS:
    rows = []
    for ln in ic:
        px = [ICOL[c] for c in ln]
        rows += [(px[i] << 4) | px[i + 1] for i in range(0, 8, 2)]
    lines.append("        db " + ",".join(str(v) for v in rows))
lines += ["hudfont_end:"]
open(os.path.join(ROOT, "editor", "hudfont.inc"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("68 glifi, %d byte" % (68 * 32))
