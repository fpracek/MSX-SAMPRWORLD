"""SamPr World - musica e effetti per l'SCC della Yamanooto.

Produce il blocco audio (messo a offset 2048 del segmento 4 della ROM, vedi gen_sprites.py):
  +0   righe del brano (2 byte)      +2  frame per riga      +3 riservato
  +4   4 forme d'onda da 32 byte (lead quadra, basso triangolo, arpeggio impulso, effetti quadra)
  +132 tabella periodi SCC, 96 note x 2 byte (indice n = nota MIDI 23+n: 1 = C1)
  +324 12 effetti x 8 byte: periodo(2) delta/frame(2, con segno) volume decremento frame successivo(0xFF = fine)
  +420 brano: per ogni riga 3 byte (lead, basso, arpeggio): 0 = silenzio, 0xFE = continua, altro = nota
Periodo SCC = 111860.8 / frequenza - 1.   Brano: re minore, 8 battute x 8 crome (64 righe), in loop.
"""
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name):
    n = NAMES[name[0]]
    i = 1
    while name[i] in "#b":
        n += 1 if name[i] == "#" else -1
        i += 1
    return 12 * (int(name[i:]) + 1) + n


def idx(name):
    n = midi(name) - 23
    assert 1 <= n < 96, name
    return n


def period(m):
    f = 440.0 * 2 ** ((m - 69) / 12.0)
    return max(1, min(4095, round(111860.8 / f) - 1))


def waves():
    sq = [90] * 16 + [-90] * 16
    tri = [int(-120 + 240 * abs(16 - i) / 16) if False else int(round(-120 + (240 * (i / 16 if i < 16 else (32 - i) / 16)))) for i in range(32)]
    pulse = [90] * 8 + [-90] * 24
    sq2 = [100] * 16 + [-100] * 16
    return [bytes(v & 255 for v in w) for w in (sq, tri, pulse, sq2)]


# battute: (accordo radice, terza, quinta) per arpeggio e basso
CH = {"Dm": ("D", ["D4", "F4", "A4"], "D2", "A2"), "Bb": ("Bb", ["Bb3", "D4", "F4"], "Bb1", "F2"),
      "F": ("F", ["F3", "A3", "C4"], "F2", "C3"), "C": ("C", ["C4", "E4", "G4"], "C2", "G2"),
      "A": ("A", ["A3", "C#4", "E4"], "A1", "E2")}
PROG = ["Dm", "Bb", "F", "C", "Dm", "Bb", "A", "Dm"]
MELODY = [  # (nota, righe); una battuta = 8 righe
    [("A4", 2), ("D5", 2), ("F5", 2), ("E5", 1), ("D5", 1)],
    [("D5", 2), ("Bb4", 2), ("D5", 2), ("C5", 1), ("Bb4", 1)],
    [("C5", 2), ("A4", 2), ("C5", 2), ("D5", 1), ("C5", 1)],
    [("E5", 4), ("G5", 2), ("E5", 2)],
    [("F5", 2), ("A5", 2), ("G5", 2), ("F5", 2)],
    [("G5", 2), ("F5", 2), ("D5", 2), ("Bb4", 2)],
    [("C#5", 2), ("E5", 2), ("A5", 4)],
    [("D5", 4), (None, 2), ("A4", 2)],
]


def song():
    rows = []
    for b, chord in enumerate(PROG):
        root, tones, bass, fifth = CH[chord]
        lead = []
        for n, ln in MELODY[b]:
            lead += [idx(n) if n else 0] + [0xFE if n else 0] * (ln - 1)
        assert len(lead) == 8
        arp = [idx(tones[i]) for i in (0, 1, 2, 1, 0, 1, 2, 1)]
        bs = [idx(bass), 0xFE, idx(bass), 0xFE, idx(bass), 0xFE, idx(fifth), 0xFE]
        for r in range(8):
            rows.append(bytes([lead[r], bs[r], arp[r]]))
    return rows


# effetti: periodo, delta, volume, decremento, frame, successivo
SFX = [
    (400, -14, 12, 0, 10, 0xFF),     # 0 salto
    (105, 0, 12, 0, 3, 2),           # 1 moneta (1/2)
    (70, 0, 12, 1, 9, 0xFF),         # 2 moneta (2/2)
    (600, 22, 13, 1, 10, 0xFF),      # 3 schiacciato
    (300, 12, 12, 1, 8, 0xFF),       # 4 blocco colpito
    (200, 11, 13, 0, 30, 0xFF),      # 5 morte
    (106, 0, 12, 0, 5, 7),           # 6 vittoria C6
    (85, 0, 12, 0, 5, 8),            # 7 E6
    (71, 0, 12, 0, 5, 9),            # 8 G6
    (53, 0, 13, 1, 18, 0xFF),        # 9 C7
    (80, -3, 12, 0, 6, 11),          # 10 chiave / portone (1/2)
    (58, -1, 12, 1, 10, 0xFF),       # 11 (2/2)
]


def build():
    out = bytearray()
    rows = song()
    out += len(rows).to_bytes(2, "little") + bytes([8, 0])
    for w in waves():
        assert len(w) == 32
        out += w
    assert len(out) == 132
    for n in range(96):
        out += period(23 + n).to_bytes(2, "little") if n else (0).to_bytes(2, "little")
    assert len(out) == 324
    for p, d, v, dec, fr, nxt in SFX:
        out += p.to_bytes(2, "little") + (d & 0xFFFF).to_bytes(2, "little") + bytes([v, dec, fr, nxt])
    out += bytes(8 * (12 - len(SFX)))
    assert len(out) == 420
    for r in rows:
        out += r
    return bytes(out), len(rows)


if __name__ == "__main__":
    blob, n = build()
    open(os.path.join(OUT, "audio.bin"), "wb").write(blob)
    print("audio.bin: %d byte, %d righe di brano, %d effetti" % (len(blob), n, len(SFX)))
