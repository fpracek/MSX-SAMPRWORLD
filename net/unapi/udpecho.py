"""Server UDP di echo per i test del bridge (solo loopback, esce da solo dopo 120 s)."""
import socket
import time

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(("127.0.0.1", 9000))
s.settimeout(1.0)
log = open(r"E:\TEMP\Claude\MSXMAKER\unapi\udpecho2.log", "w")
t0 = time.time()
while time.time() - t0 < 240:
    try:
        data, addr = s.recvfrom(1500)
    except socket.timeout:
        continue
    log.write("rx %r da %s\n" % (data, addr))
    log.flush()
    s.sendto(data, addr)
log.close()
