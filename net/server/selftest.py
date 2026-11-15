"""Self-test del protocollo livelli: server in-process (nessuna rete), store temporaneo."""
import struct
import tempfile

import levelserver as ls

tmp = tempfile.mkdtemp()
store = ls.Store(tmp)
ls.seed(store)
srv = ls.Server(store)
A = ("127.0.0.1", 5000)
rid = [0]


def req(op, payload):
    rid[0] += 1
    return srv.handle(bytes([op, rid[0]]) + payload, A)


# LIST
r = req(1, bytes([0]))
total, page, count = struct.unpack_from("<HBB", r, 3)
assert r[:3] == bytes([0x81, rid[0], 0]) and total == 3 and count == 3, r
print("LIST ok:", total, "livelli")

# GET completo del livello 2 a pezzi da 128
off, blob = 0, b""
while True:
    r = req(2, struct.pack("<HHB", 2, off, 128))
    assert r[2] == 0
    lid, o, tot, n = struct.unpack_from("<HHHB", r, 3)
    blob += r[10:10 + n]
    off += n
    if off >= tot:
        break
assert ls.valid_blob(blob) and len(blob) == tot
print("GET ok:", len(blob), "byte, CRC valido")

# PUT con chiave sbagliata
r = req(3, ls.fixed("testuser", 12) + ls.fixed("SBAGLIATA", 16) + ls.fixed("x", 16) + struct.pack("<H", 10))
assert r[2] == 1
print("PUT con chiave errata rifiutato")

# PUT corretto
newblob = ls.make_blob(bytes(i & 255 for i in range(300)))
r = req(3, ls.fixed("testuser", 12) + ls.fixed("TESTKEY-0123456", 16) + ls.fixed("Mio livello", 16)
        + struct.pack("<H", len(newblob)))
assert r[2] == 0
upid = r[3]
for o in range(0, len(newblob), 128):
    part = newblob[o:o + 128]
    r = req(4, bytes([upid]) + struct.pack("<HB", o, len(part)) + part)
    assert r[2] == 0
r = req(5, bytes([upid]))
assert r[2] == 0
newid = struct.unpack_from("<H", r, 3)[0]
print("PUT ok: nuovo id", newid)

# PUT con CRC rotto
bad = bytearray(newblob)
bad[10] ^= 1
r = req(3, ls.fixed("testuser", 12) + ls.fixed("TESTKEY-0123456", 16) + ls.fixed("rotto", 16)
        + struct.pack("<H", len(bad)))
upid = r[3]
r = req(4, bytes([upid]) + struct.pack("<HB", 0, 200) + bytes(bad[:200]))
r = req(4, bytes([upid]) + struct.pack("<HB", 200, len(bad) - 200) + bytes(bad[200:]))
r = req(5, bytes([upid]))
assert r[2] == 2
print("PUT con CRC rotto rifiutato")

# LIST finale
r = req(1, bytes([0]))
assert struct.unpack_from("<H", r, 3)[0] == 4
print("self-test: TUTTO OK")
