"""Stampa in ASCII un livello (anteprima per il debug): python showlevel.py NN [col0 col1]"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import level
n = sys.argv[1]; c0 = int(sys.argv[2]) if len(sys.argv) > 2 else 0; c1 = int(sys.argv[3]) if len(sys.argv) > 3 else 128
d = level.decode(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "levels", "%s.lvl" % n), "rb").read())
t = d["tiles"]
ch = {0: '.', 1: 'G', 2: 'D', 3: '#', 4: 'B', 5: 'M', 6: 'X', 7: 'C', 9: ':', 10: '=', 11: '~', 12: '-', 13: 'R', 14: 'r', 15: 'x', 16: 'k', 17: 'S', 18: '^', 19: 'L', 20: 'l', 21: 'w', 22: 'W',
      25: 'D', 26: 'd', 27: 'o', 28: '*', 29: 'K', 32: 'F', 33: 'P', 34: 'p', 35: '@', 36: 'i', 41: 'f', 46: 'm', 51: 'g', 52: 'b'}
print(d["title"], "cols %d..%d (ruler every 10)" % (c0, c1))
print("".join(str((c // 10) % 10) if c % 10 == 0 else " " for c in range(c0, c1)))
for r in range(2, 12):
    print("".join(ch.get(t[r * 128 + c], '?') for c in range(c0, c1)))
