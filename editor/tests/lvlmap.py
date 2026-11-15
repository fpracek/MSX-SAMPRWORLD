"""Converte i livelli della campagna (assets/levels/NN.lvl) in elenchi di tile per i test Tcl (tests/maps/NN.txt)."""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(here, "..", "..", "tools"))
import level
src = os.path.join(here, "..", "..", "assets", "levels")
os.makedirs(os.path.join(here, "maps"), exist_ok=True)
for f in sorted(os.listdir(src)):
    if f.endswith(".lvl"):
        d = level.decode(open(os.path.join(src, f), "rb").read())
        open(os.path.join(here, "maps", f.replace(".lvl", ".txt")), "w").write(" ".join(str(t) for t in d["tiles"]))
print("ok")
