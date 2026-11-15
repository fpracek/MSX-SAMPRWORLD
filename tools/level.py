"""Codec del formato livello v1 (vedi docs/LEVEL.md). Stesso CRC16 del server e del client MSX."""
import struct


def crc16(data: bytes) -> int:
    crc = 0xFFFF
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def rle_encode(tiles: bytes) -> bytes:
    out, i = bytearray(), 0
    while i < len(tiles):
        t, n = tiles[i], 1
        assert t < 0x40
        while i + n < len(tiles) and tiles[i + n] == t and n < 255:
            n += 1
        if n >= 3:
            out += bytes([0x80 | t, n])
        else:
            out += bytes([t]) * n
        i += n
    return bytes(out)


def rle_decode(data: bytes, count: int) -> bytes:
    out, i = bytearray(), 0
    while len(out) < count:
        b = data[i]
        if b & 0x80:
            out += bytes([b & 0x3F]) * data[i + 1]
            i += 2
        else:
            out.append(b)
            i += 1
    assert len(out) == count, "mappa di lunghezza errata"
    return bytes(out)


def encode(w, h, tiles, start=(0, 0), theme=0, title="", ents=()):
    assert len(tiles) == w * h and 1 <= h <= 16 and 1 <= w <= 255
    hdr = b"LV" + bytes([1, w, h, start[0], start[1], theme])
    hdr += title.encode("ascii")[:16].ljust(16, b"\0")
    hdr += bytes([len(ents)]) + b"".join(bytes(e) for e in ents)
    body = hdr + rle_encode(bytes(tiles))
    return body + struct.pack("<H", crc16(body))


def decode(blob: bytes):
    assert blob[:2] == b"LV" and blob[2] == 1, "formato non riconosciuto"
    assert crc16(blob[:-2]) == struct.unpack("<H", blob[-2:])[0], "CRC errato"
    w, h, sx, sy, theme = blob[3:8]
    title = blob[8:24].split(b"\0")[0].decode("ascii")
    n = blob[24]
    ents = [tuple(blob[25 + 3 * i:28 + 3 * i]) for i in range(n)]
    tiles = rle_decode(blob[25 + 3 * n:-2], w * h)
    return dict(w=w, h=h, start=(sx, sy), theme=theme, title=title, ents=ents, tiles=tiles)


if __name__ == "__main__":
    import os, random, sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "net", "server"))
    import levelserver as ls
    r = random.Random(1)
    # livello tipico: cielo, terreno, qualche blocco
    w, h = 128, 12
    t = bytearray(w * h)
    for x in range(w):
        t[11 * w + x] = 1
        t[10 * w + x] = 2 if x % 9 else 3
    for _ in range(60):
        t[r.randrange(w * h)] = r.randrange(0, 51)
    b = encode(w, h, bytes(t), (2, 9), 0, "Prova", [(1, 20, 9), (2, 40, 9)])
    d = decode(b)
    assert d["tiles"] == bytes(t) and d["title"] == "Prova" and d["ents"][1] == (2, 40, 9)
    assert ls.valid_blob(b), "il server deve accettarlo"
    worst = encode(w, h, bytes(r.randrange(0, 51) for _ in range(w * h)))
    assert len(worst) < ls.MAX_SIZE
    print("livello tipico %d byte (raw %d), caso peggiore %d byte: OK" % (len(b), w * h, len(worst)))
