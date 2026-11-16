"""SamPr World - i 10 livelli fissi della campagna (sempre presenti nella ROM, segmento 6).

Ogni livello e' largo al massimo 48 colonne (tre schermate di scorrimento orizzontale), alto 12, su piu' piani collegati da
scale: piano terra (appoggio riga 9), piano intermedio (riga 5) e piano alto (riga 1). Le scale di un piano si appoggiano al
pavimento sottostante e bucano il pavimento sopra (come in Il Maniero). Il resto della mappa (colonne 48-127) e' vuoto:
il motore limita la camera all'ultima colonna non vuota.

Il progetto di ogni livello e' una pianta ASCII (vedi LEVELS): la legenda e' in LEGEND. Uscite: assets/levels/NN.lvl (formato
livello v1 con i record dei nemici, docs/LEVEL.md), assets/campaign.bin (segmento 6: directory + blob), assets/levels/NN.png
(anteprima) e editor/tests/maps/NN.txt (mappa per i test). Il programma verifica con lo stesso modello dell'editor
(editor/swreach.asm: salto 3 righe, scale, molle) che partenza, uscita e tutti gli oggetti siano raggiungibili.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import level  # noqa: E402

ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "assets")
INC = open(os.path.join(OUT, "tileset.inc"), encoding="utf-8").read()
T = {m.group(1): int(m.group(2)) for m in re.finditer(r"^T_(\w+)\s+equ\s+(\d+)", INC, re.M)}
CLASSES = []
for m in re.finditer(r"^\s+db ([0-9,]+)$", INC.split("tile_class:")[1], re.M):
    CLASSES += [int(v) for v in m.group(1).split(",")]
W, H = 128, 12
LW = 32                                   # larghezza dei livelli originali (2 schermate)

# legenda: carattere -> tile (le travi '=' diventano L/M/R, i nemici sono gestiti a parte)
LEGEND = {
    ".": 0, "#": T["BRICK"], "b": T["STONE"], "G": T["GRASS"], "D": T["DIRT"], "H": T["LADDER"],
    "o": T["COIN"], "g": T["GEM"], "p": T["POTION"], "k": T["KEY"], "^": T["SPIKES"], "S": T["START"], "P": T["PORTT"], "Q": T["PORTB"],
    "c": T["CHKPT"], "R": T["RUNE"], "B": T["BREAK"], "d": T["DOORT"], "e": T["DOORB"], "s": T["SPRING"],
    "w": T["CWALL"], "t": T["TORCH"], "n": T["BANNER"], "i": T["WINDOW"],
    "r": T["M51"], "C": T["CRATE"], "V": T["M53"], "K": T["M24"], "L": T["M25"],
}
BEAM = {"L": T["M54"], "M": T["M55"], "R": T["M56"]}
# nemici: carattere -> (tile marcatore, IA, velocita', raggio, vita, rilevamento, sprite)
#   sprite: 0 quello del tipo, 1 soldato, 2 medico, 3 poliziotto; IA: 0 pattuglia, 1 dormiglione, 2 inseguitore, 3 pauroso
ENEMY = {
    "x": ("GOBLIN", 0, 1, 0, 1, 6, 1),      # soldato di pattuglia
    "y": ("GOBLIN", 0, 1, 0, 1, 6, 2),      # medico
    "z": ("GOBLIN", 0, 2, 0, 1, 6, 3),      # poliziotto veloce
    "X": ("GOBLIN", 1, 1, 0, 1, 5, 1),      # soldato dormiglione
    "Z": ("GOBLIN", 2, 1, 0, 1, 5, 3),      # poliziotto inseguitore
    "Y": ("GOBLIN", 3, 2, 0, 1, 5, 2),      # medico pauroso
    "W": ("GOBLIN", 0, 1, 0, 2, 6, 3),      # poliziotto con 2 vite
    "v": ("BAT", 0, 1, 0, 1, 6, 0),         # pipistrello (medico volante)
}


def parse(rows):
    assert len(rows) == 12, len(rows)
    for r in rows:
        assert len(r) == len(rows[0]), (len(r), r)
    return [list(r) if isinstance(r, str) else r for r in rows]


def build(spec):
    title, theme, rows = spec[:3]
    extra = spec[3] if len(spec) > 3 else {}
    rows = parse(rows)
    g = [[0] * W for _ in range(H)]
    ents = []
    start = None
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if isinstance(ch, int):                      # indice del foglio de Il Maniero (assets/maniero/tiles.json)
                g[y][x] = _game_tile(ch)
            elif ch in ENEMY:
                tile, ai, sp, rg, hp, det, spr = ENEMY[ch]
                g[y][x] = T[tile]
                ents.append((x, y, ai, sp, rg, hp, det, spr))
            elif ch == "=":
                left = x > 0 and r[x - 1] == "="
                right = x + 1 < LW and r[x + 1] == "="
                g[y][x] = BEAM["M" if (left and right) or not (left or right) else ("R" if left else "L")]
            elif ch in LEGEND:
                g[y][x] = LEGEND[ch]
                if ch == "S":
                    start = (x, y)
            else:
                raise ValueError("carattere '%s' sconosciuto in %s riga %d" % (ch, title, y))
    assert start, title + ": manca la partenza"
    tiles = bytes(t for row in g for t in row)
    return tiles, ents, start, g


# ------------------------------------------------------------------------- verifica (modello di editor/swreach.asm)
def cls(t):
    return CLASSES[t] if t < len(CLASSES) else 0


def check(title, g):
    def tile(c, r):
        return g[r][c] if 0 <= c < W and 0 <= r < H else 0xFF

    def stand(c, r):
        if r >= H - 1:
            return False
        if tile(c, r + 1) == 0xFF or cls(tile(c, r + 1)) not in (1, 2, 6):
            return False
        t = tile(c, r)
        return t != 0xFF and cls(t) not in (1, 2, 3, 6)

    low = [255] * W
    rch = [255] * W

    def upd(c, r):
        e = 7 if tile(c, r) == T["SPRING"] else 3
        a = max(r - e, 0)
        ch = False
        if a < rch[c]:
            rch[c] = a
            ch = True
        if r < low[c]:
            low[c] = r
            ch = True
        return ch

    sx = sy = None
    for y in range(H):
        for x in range(W):
            if g[y][x] == T["START"]:
                sx, sy = x, y
    r = sy
    while r < H and not stand(sx, r):
        r += 1
    assert r < H, title + ": la partenza non poggia"
    upd(sx, r)
    changed = True

    def col(c):
        ch = False
        lo, hi = max(c - 4, 0), min(c + 4, W - 1)
        t = 255
        for k in range(lo, hi + 1):
            if k != c and rch[k] < t:
                t = rch[k]
        if t != 255:
            for rr in range(t, H - 1):
                if stand(c, rr) and upd(c, rr):
                    ch = True
        return ch

    def lad(c):
        if low[c] == 255 or cls(tile(c, low[c])) != 5:
            return False
        r0 = low[c]
        r = r0
        while r > 0 and cls(tile(c, r - 1)) == 5:
            r -= 1
        return r < r0 and upd(c, r)

    while changed:
        changed = False
        for c in list(range(W)) + list(range(W - 1, -1, -1)):
            if col(c):
                changed = True
            if lad(c):
                changed = True

    def coin_ok(c, r):
        for k in range(max(c - 2, 0), min(c + 2, W - 1) + 1):
            a = low[k]
            if a == 255:
                continue
            d = a - r
            if d < 0 or d < 4:
                return True
            if d == 4 and cls(tile(c, r + 1)) not in (1, 6):
                return True
        return False

    bad = []
    for y in range(H):
        for x in range(W):
            if T["COIN"] <= g[y][x] <= T["COIN"] + 3 and not coin_ok(x, y):
                bad.append((x, y))
    ex = [(x, y) for y in range(H) for x in range(W) if g[y][x] == T["PORTB"]]
    exit_ok = all(coin_ok(x, H - 1) for x, _ in ex) if ex else False
    return bad, exit_ok


# ------------------------------------------------------------------------- percorso per il bot di collaudo
def plan(g, start_xy):
    """BFS sui punti d'appoggio: camminata, caduta, salto di buche (<=3) e di gradini (<=2), scale. Restituisce
    [('run', col, riga) | ('up', col, riga) | ('down', col, riga)] da partenza a chiave (se c'e') e a uscita."""
    def tile(c, r):
        return g[r][c] if 0 <= c < W and 0 <= r < H else 0xFF

    state = {"open": False}

    def full(c, r):
        t = tile(c, r)
        return t == 0xFF or cls(t) in (1, 6) or (not state["open"] and t in (T["DOORT"], T["DOORB"]))

    def stand(c, r):
        return r < H - 1 and tile(c, r + 1) != 0xFF and cls(tile(c, r + 1)) in (1, 2, 6) and not full(c, r) and cls(tile(c, r)) != 3

    def ladder(c, r):
        return cls(tile(c, r)) == 5

    def moves(c, r):
        out = []
        for d in (-1, 1):
            n = c + d
            blocked = full(n, r)
            if blocked:
                pass
            elif stand(n, r):
                out.append((n, r, "run"))
            elif not ladder(n, r) and cls(tile(n, r)) != 3:
                rr = r
                while rr < H - 1 and not full(n, rr + 1) and not stand(n, rr):
                    rr += 1
                    if cls(tile(n, rr)) == 3:
                        break
                if rr < H - 1 and stand(n, rr) and rr > r:
                    out.append((n, rr, "run"))
            if ladder(n, r) and not blocked:
                out.append((n, r, "run"))
            for k in (2, 3, 4):                       # salto di una buca
                m = c + d * k
                if stand(m, r) and all(not full(c + d * j, r) for j in range(1, k + 1)) and not stand(c + d, r):
                    out.append((m, r, "run"))
                    break
            for k in (2, 3):                          # salto di una buca verso un gradino piu' alto di una riga
                m = c + d * k
                if stand(m, r - 1) and not full(m, r - 1) and all(not full(c + d * j, r) and not full(c + d * j, r - 1) for j in range(1, k))                         and not stand(c + d, r):
                    out.append((m, r - 1, "run"))
                    break
            for up in (1, 2):                         # gradino
                if stand(n, r - up) if not full(n, r - up) else False:
                    if all(not full(c, r - j) for j in range(1, up + 1)):
                        out.append((n, r - up, "run"))
        if ladder(c, r):
            rt = r
            while ladder(c, rt - 1):
                rt -= 1
            rb = r
            while ladder(c, rb + 1):
                rb += 1
            if rt != r:
                out.append((c, rt, "up"))
            if rb != r:
                out.append((c, rb, "down"))
        return out

    def bfs(src, goal):
        prev = {src: None}
        q = [src]
        while q:
            cur = q.pop(0)
            if goal(cur):
                path = []
                while cur:
                    path.append(cur)
                    cur = prev[cur][0] if prev[cur] else None
                return path[::-1], prev
            for (c, r, kind) in moves(*cur):
                if (c, r) not in prev:
                    prev[(c, r)] = ((cur), kind)
                    q.append((c, r))
        return None, prev

    def leg(src, goal):
        prev = {src: None}
        q = [src]
        found = None
        while q:
            cur = q.pop(0)
            if goal(cur):
                found = cur
                break
            for (c, r, kind) in moves(*cur):
                if (c, r) not in prev:
                    prev[(c, r)] = (cur, kind)
                    q.append((c, r))
        if not found:
            import os as _o
            if _o.environ.get("PLANDBG"):
                print("visitati:", len(prev), "goal non raggiunto")
            return None
        steps = []
        cur = found
        while prev[cur]:
            p, kind = prev[cur]
            steps.append((kind, cur[0], cur[1]))
            cur = p
        return steps[::-1]

    sx, sy = start_xy
    r = sy
    while not stand(sx, r):
        r += 1
    cur = (sx, r)
    goals = []
    for y in range(H):
        for x in range(W):
            if g[y][x] == T["KEY"]:
                goals.append((x, y))
    ex = [(x, y) for y in range(H) for x in range(W) if g[y][x] == T["PORTB"]]
    goals.append(ex[0])
    state["open"] = False                             # insieme raggiungibile a portoni chiusi (il portone deve servire)
    seen0 = {cur: None}
    q = [cur]
    while q:
        n = q.pop(0)
        for (c, r, kind) in moves(*n):
            if (c, r) not in seen0:
                seen0[(c, r)] = n
                q.append((c, r))
    plan.closed = set(seen0)
    plan.exit = (ex[0][0], ex[0][1])
    plan.has_key = any(g[y][x] == T["KEY"] for y in range(H) for x in range(W))
    state["open"] = True                              # insieme raggiungibile con i portoni aperti (per le monete)
    seen = {cur: None}
    q = [cur]
    while q:
        n = q.pop(0)
        for (c, r, kind) in moves(*n):
            if (c, r) not in seen:
                seen[(c, r)] = n
                q.append((c, r))
    plan.reach = set(seen)
    def compact(route):               # le camminate consecutive nello stesso verso diventano una sola corsa
        out = []
        for kind, c, r in route:
            if kind == "run" and out and out[-1][0] == "run" and (c - out[-1][1]) * (out[-1][1] - (out[-2][1] if len(out) > 1 and out[-2][0] == "run" else out[-1][1])) >= 0 and out[-1][2] == r:
                out[-1] = ("run", c, r)
            else:
                out.append((kind, c, r))
        return out

    out = []
    for gi, (gx, gy) in enumerate(goals):
        state["open"] = gi == len(goals) - 1 and len(goals) > 1          # il portone si apre dopo aver preso la chiave
        steps = leg(cur, lambda n, gx=gx, gy=gy: n[0] == gx and n[1] == gy)
        if steps is None and os.environ.get("PLANDBG"):
            print("   leg fallita: da", cur, "a", (gx, gy), "porte aperte:", state["open"])
        if steps is None:
            return None
        out += compact(steps)                  # ogni tappa (chiave, uscita) resta una fermata del percorso
        cur = (steps[-1][1], steps[-1][2]) if steps else cur
    return out


# ------------------------------------------------------------------------- livelli
def frame(rows, left=True, right=True):
    return rows


import json as _json  # noqa: E402

_orig = _json.load(open(os.path.join(HERE, "levels_orig.json")))
_tj = {m["id"]: m for m in _json.load(open(os.path.join(OUT, "maniero", "tiles.json")))}


def _game_tile(i):
    """indice nel foglio de Il Maniero (tiles.json) -> id del tile nel gioco (sostituito o accodato)"""
    m = _tj[int(i)]
    return T[m["replaces"]] if m["replaces"] else T["M%02d" % int(i)]


LEVELS = [(lv["title"], 0, lv["rows"]) for lv in _orig["levels"]]


def preview(g, ents, path):
    from PIL import Image
    sheet = Image.open(os.path.join(OUT, "tiles.png")).convert("RGB")
    im = Image.new("RGB", (LW * 16, H * 16), (36, 72, 255))
    for y in range(H):
        for x in range(LW):
            t = g[y][x]
            if t:
                sx, sy = (t % 16) * 16, (t // 16) * 16
                im.paste(sheet.crop((sx, sy, sx + 16, sy + 16)), (x * 16, y * 16))
    im.save(path)


def main():
    os.makedirs(os.path.join(OUT, "levels"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "editor", "tests", "maps"), exist_ok=True)
    blobs = []
    ok = True
    for i, spec in enumerate(LEVELS):
        tiles, ents, start, g = build(spec)
        bad, exit_ok = check(spec[0], g)
        status = "OK" if not bad and exit_ok else "PROBLEMI"
        if bad or not exit_ok:
            ok = False
        blob = level.encode(W, H, tiles, start, 0, spec[0], ents)
        open(os.path.join(OUT, "levels", "%02d.lvl" % (i + 1)), "wb").write(blob)
        open(os.path.join(ROOT, "editor", "tests", "maps", "%02d.txt" % (i + 1)), "w").write(" ".join(str(t) for t in tiles))
        preview(g, ents, os.path.join(OUT, "levels", "%02d.png" % (i + 1)))
        open(os.path.join(ROOT, "editor", "tests", "maps", "%02d.ents" % (i + 1)), "w").write(
            chr(10).join(" ".join(str(v) for v in e) for e in ents))
        route = plan(g, start)
        miss = []
        if route is not None:
            for y in range(H):
                for x in range(W):
                    if T["COIN"] <= g[y][x] <= T["COIN"] + 3 and not any(
                            (x + dx, y + dy) in plan.reach for dx in (-2, -1, 0, 1, 2) for dy in range(0, 4)):
                        miss.append((x, y))
            if miss:
                print("   oggetti fuori dal percorso del bot:", miss)
                ok = False
            if plan.has_key and plan.exit in plan.closed and any(T["DOORT"] in row for row in g):
                print("   il portone si puo' aggirare (uscita raggiungibile senza chiave)")
                ok = False
        open(os.path.join(ROOT, "editor", "tests", "maps", "%02d.route" % (i + 1)), "w").write(
            chr(10).join("%s %d %d" % w for w in route) if route else "NONE")
        if route is None:
            ok = False
            print("   percorso del bot: NESSUNO (livello %d)" % (i + 1))
        blobs.append((spec[0], blob))
        print("%2d %-22s %4d byte, %d nemici, monete irraggiungibili: %s, uscita %s -> %s"
              % (i + 1, spec[0], len(blob), len(ents), bad, "raggiungibile" if exit_ok else "NO", status))
    open(os.path.join(ROOT, "editor", "tests", "maps", "classes.txt"), "w").write(" ".join(str(c) for c in CLASSES))
    if os.path.exists(os.path.join(HERE, "levels_rom.json")) and not os.environ.get("OLDLEVELS"):
        import make_tall                         # la campagna e' quella della ROM di Il Maniero (livelli alti)
        blobs = make_tall.tall_levels()
    n = len(blobs)
    dire, data = bytearray([n]), bytearray()
    base = 1 + 20 * n
    for title, blob in blobs:
        dire += (base + len(data)).to_bytes(2, "little") + len(blob).to_bytes(2, "little") + title.encode("ascii")[:16].ljust(16, b"\0")
        data += blob
    seg = bytes(dire) + bytes(data)
    assert len(seg) <= 8192, len(seg)
    open(os.path.join(OUT, "campaign.bin"), "wb").write(seg.ljust(8192, bytes([255])))
    print("campaign.bin: %d byte usati su 8192" % len(seg))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
