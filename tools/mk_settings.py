"""Genera un record impostazioni di rete da 128 byte (formato in docs/FLASH.md).

Uso:  python mk_settings.py <uscita.bin> [host] [porta] [utente] [chiave]
Senza argomenti produce il record di SVILUPPO: server localhost:9100, utente di prova (valori segnaposto).
"""
import struct
import sys


def fixed(s, n):
    b = s.encode("ascii")
    assert len(b) < n or n == 16 and len(b) <= 16
    return b[:n].ljust(n, b"\0")


def record(host="localhost", port=9100, user="testuser", key="TESTKEY-0123456", server_ip=(0, 0, 0, 0), seq=1):
    r = bytearray(128)
    r[0:2] = b"NS"
    r[2] = seq
    r[3] = 0                                  # DHCP / configurazione della scheda
    r[0x14:0x18] = bytes(server_ip)
    r[0x18:0x1A] = struct.pack("<H", port)
    r[0x1A:0x1A + 28] = fixed(host, 28)
    r[0x36:0x36 + 12] = fixed(user, 12)
    r[0x42:0x42 + 16] = fixed(key, 16)
    r[127] = (-sum(r[:127])) & 255
    assert sum(r) & 255 == 0
    return bytes(r)


if __name__ == "__main__":
    out = sys.argv[1]
    a = sys.argv[2:]
    kw = {}
    if len(a) > 0: kw["host"] = a[0]
    if len(a) > 1: kw["port"] = int(a[1])
    if len(a) > 2: kw["user"] = a[2]
    if len(a) > 3: kw["key"] = a[3]
    open(out, "wb").write(record(**kw))
    print("scritto", out)
