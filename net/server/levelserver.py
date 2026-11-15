"""Server UDP dei livelli per MSXMAKER (solo libreria standard).

Protocollo (tutti i numeri a piu' byte sono little-endian, stringhe a larghezza fissa
riempite con 0). Ogni risposta = codice richiesta | 0x80, poi lo stesso rid.

  01 LIST   : 01 rid page
     -> 81 rid status total2 page count  (count record da 22 byte)
        record: id2 size2 title16 rating1 flags1
  02 GET    : 02 rid id2 off2 maxlen
     -> 82 rid status id2 off2 total2 len data[len]
  03 PUTBEG : 03 rid user12 key16 title16 size2
     -> 83 rid status upid
  04 PUTCHK : 04 rid upid off2 len data[len]
     -> 84 rid status
  05 PUTEND : 05 rid upid
     -> 85 rid status newid2

status: 0 ok, 1 autenticazione, 2 formato, 3 troppo grande, 4 upload sconosciuto,
        5 offset fuori sequenza, 6 livello inesistente, 7 limite utente, 9 richiesta errata

Un livello e' un blob opaco: "LV" ... CRC16 (CCITT-FALSE, little-endian) negli ultimi 2 byte.
Nota di sicurezza: UDP in chiaro, la chiave viaggia in chiaro (da sostituire con
challenge-response prima di un uso pubblico).
"""
import json
import os
import socket
import struct
import sys
import time

HOST = "127.0.0.1"
PORT = 9100
HERE = os.path.dirname(os.path.abspath(__file__))
STORE = os.path.join(HERE, "store")
MAX_SIZE = 4096
PAGE = 6
MAX_PER_USER = 50
UPLOAD_TTL = 60


def crc16(data: bytes) -> int:
    crc = 0xFFFF
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def valid_blob(blob: bytes) -> bool:
    return (len(blob) >= 6 and blob[:2] == b"LV"
            and crc16(blob[:-2]) == int.from_bytes(blob[-2:], "little"))


def make_blob(payload: bytes) -> bytes:
    body = b"LV" + payload
    return body + crc16(body).to_bytes(2, "little")


def fixed(s: str, n: int) -> bytes:
    return s.encode("latin-1", "replace")[:n].ljust(n, b"\0")


def unfix(b: bytes) -> str:
    return b.split(b"\0", 1)[0].decode("latin-1")


class Store:
    def __init__(self, root):
        self.root = root
        os.makedirs(root, exist_ok=True)
        self.index_path = os.path.join(root, "index.json")
        self.users_path = os.path.join(root, "users.json")
        self.index = json.load(open(self.index_path)) if os.path.exists(self.index_path) else {}
        self.users = json.load(open(self.users_path)) if os.path.exists(self.users_path) else {}

    def save_index(self):
        json.dump(self.index, open(self.index_path, "w"), indent=1)

    def blob_path(self, lid):
        return os.path.join(self.root, "%05d.lvl" % lid)

    def next_id(self):
        return max([int(k) for k in self.index] + [0]) + 1

    def add(self, title, author, blob):
        lid = self.next_id()
        open(self.blob_path(lid), "wb").write(blob)
        self.index[str(lid)] = {"title": title, "author": author, "size": len(blob),
                                "rating": 0, "time": int(time.time())}
        self.save_index()
        return lid


class Server:
    def __init__(self, store, log=None):
        self.store = store
        self.uploads = {}          # (addr, upid) -> dict
        self.log = log or (lambda *a: None)

    # ---- gestori ----
    def handle(self, data: bytes, addr):
        if len(data) < 2:
            return None
        op, rid = data[0], data[1]
        fn = {1: self.h_list, 2: self.h_get, 3: self.h_putbeg,
              4: self.h_putchk, 5: self.h_putend}.get(op)
        if not fn:
            return bytes([op | 0x80, rid, 9])
        try:
            return fn(op, rid, data, addr)
        except (struct.error, IndexError):
            return bytes([op | 0x80, rid, 9])

    def h_list(self, op, rid, d, addr):
        page = d[2]
        ids = sorted(int(k) for k in self.store.index)
        chunk = ids[page * PAGE:(page + 1) * PAGE]
        out = bytearray([0x81, rid, 0])
        out += struct.pack("<HBB", len(ids), page, len(chunk))
        for lid in chunk:
            e = self.store.index[str(lid)]
            out += struct.pack("<HH", lid, e["size"]) + fixed(e["title"], 16)
            out += bytes([e.get("rating", 0) & 255, 0])
        return bytes(out)

    def h_get(self, op, rid, d, addr):
        lid, off, maxlen = struct.unpack_from("<HHB", d, 2)
        e = self.store.index.get(str(lid))
        if not e:
            return bytes([0x82, rid, 6])
        blob = open(self.store.blob_path(lid), "rb").read()
        maxlen = max(1, min(maxlen, 200))
        part = blob[off:off + maxlen]
        return bytes([0x82, rid, 0]) + struct.pack("<HHHB", lid, off, len(blob), len(part)) + part

    def authed(self, user, key):
        return self.store.users.get(user) == key

    def h_putbeg(self, op, rid, d, addr):
        user = unfix(d[2:14])
        key = unfix(d[14:30])
        title = unfix(d[30:46])
        (size,) = struct.unpack_from("<H", d, 46)
        if not self.authed(user, key):
            return bytes([0x83, rid, 1, 0])
        if size > MAX_SIZE or size < 6:
            return bytes([0x83, rid, 3, 0])
        mine = sum(1 for e in self.store.index.values() if e["author"] == user)
        if mine >= MAX_PER_USER:
            return bytes([0x83, rid, 7, 0])
        now = time.time()
        self.uploads = {k: v for k, v in self.uploads.items() if now - v["t"] < UPLOAD_TTL}
        upid = 1
        while (addr, upid) in self.uploads:
            upid += 1
        self.uploads[(addr, upid)] = {"user": user, "title": title, "size": size,
                                      "buf": bytearray(), "t": now}
        return bytes([0x83, rid, 0, upid])

    def h_putchk(self, op, rid, d, addr):
        upid = d[2]
        off, n = struct.unpack_from("<HB", d, 3)
        up = self.uploads.get((addr, upid))
        if not up:
            return bytes([0x84, rid, 4])
        if off < len(up["buf"]):          # ritrasmissione: gia' ricevuto
            return bytes([0x84, rid, 0])
        if off != len(up["buf"]):
            return bytes([0x84, rid, 5])
        up["buf"] += d[6:6 + n]
        up["t"] = time.time()
        return bytes([0x84, rid, 0])

    def h_putend(self, op, rid, d, addr):
        upid = d[2]
        up = self.uploads.get((addr, upid))
        if not up:
            return bytes([0x85, rid, 4, 0, 0])
        if len(up["buf"]) != up["size"] or not valid_blob(bytes(up["buf"])):
            del self.uploads[(addr, upid)]
            return bytes([0x85, rid, 2, 0, 0])
        lid = self.store.add(up["title"], up["user"], bytes(up["buf"]))
        del self.uploads[(addr, upid)]
        return bytes([0x85, rid, 0]) + struct.pack("<H", lid)


def seed(store):
    """Livelli di esempio + utente di prova (valori segnaposto)."""
    if not store.users:
        store.users = {"testuser": "TESTKEY-0123456"}
        json.dump(store.users, open(store.users_path, "w"), indent=1)
    if not store.index:
        store.add("Prato di partenza", "server", make_blob(bytes(range(256)) * 2))
        store.add("Grotta lunga", "server", make_blob(bytes((i * 7) & 255 for i in range(900))))
        store.add("Castello", "server", make_blob(bytes((i * 13 + 5) & 255 for i in range(1500))))


def main():
    host = sys.argv[1] if len(sys.argv) > 1 else HOST
    ttl = float(sys.argv[2]) if len(sys.argv) > 2 else 3600
    store = Store(STORE)
    seed(store)
    srv = Server(store)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((host, PORT))
    sock.settimeout(1.0)
    logf = open(os.path.join(HERE, "server.log"), "a")
    t0 = time.time()
    while time.time() - t0 < ttl:
        try:
            data, addr = sock.recvfrom(1500)
        except socket.timeout:
            continue
        resp = srv.handle(data, addr)
        logf.write("%s %s op=%02X -> %s\n" % (time.strftime("%H:%M:%S"), addr, data[0] if data else 0,
                                             resp[:3].hex() if resp else None))
        logf.flush()
        if resp:
            sock.sendto(resp, addr)


if __name__ == "__main__":
    main()
