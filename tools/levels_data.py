"""Progetto dei 10 livelli della campagna (usato da make_levels.py).

Ogni livello e' una griglia 48x12 costruita con poche primitive; poi `rows()` restituisce le 12 righe ASCII
(legenda in make_levels.py). Piani: terra (appoggio riga 9, pavimento riga 10), intermedio (appoggio riga 5, pavimento
riga 6) e alto (appoggio riga 1, pavimento riga 2). Una scala e' una colonna di 'H': dal piano terra a quello intermedio
occupa le righe 5-9 (buca il pavimento a riga 6), dal piano intermedio a quello alto le righe 1-5 (buca la riga 2).
"""
LW = 48


class G:
    def __init__(self):
        self.g = [["."] * LW for _ in range(12)]
        for x in range(LW):
            self.g[0][x] = "#"
        for y in range(12):
            self.g[y][0] = self.g[y][LW - 1] = "#"
        self.ground(1, LW - 2)

    def put(self, x, y, ch):
        self.g[y][x] = ch

    def ground(self, x0, x1):
        for x in range(x0, x1 + 1):
            self.g[10][x] = "G"
            self.g[11][x] = "D"

    def pit(self, x0, x1):
        for x in range(x0, x1 + 1):
            self.g[10][x] = "."
            self.g[11][x] = "."

    def floor(self, row, x0, x1, ch="#"):
        for x in range(x0, x1 + 1):
            self.g[row][x] = ch

    def beams(self, row, x0, x1):
        self.floor(row, x0, x1, "=")

    def wall(self, x, y0, y1, ch="#"):
        for y in range(y0, y1 + 1):
            self.g[y][x] = ch

    def ladder(self, x, y0, y1):
        for y in range(y0, y1 + 1):
            self.g[y][x] = "H"

    def line(self, y, x0, x1, ch, step=1):
        for x in range(x0, x1 + 1, step):
            self.g[y][x] = ch

    def gate(self, x, top=1):
        """portone alto 2 tile a terra con muro sopra (da riga `top`)"""
        self.wall(x, top, 7, "#")
        self.g[8][x] = "d"
        self.g[9][x] = "e"

    def rows(self):
        return ["".join(r) for r in self.g]


def L1():
    g = G()
    g.put(2, 9, "S")
    g.line(9, 4, 6, "o", 2)
    # piano intermedio con scala a sinistra
    g.ladder(8, 5, 9)
    g.floor(6, 9, 26)
    g.line(5, 12, 20, "o", 4)
    g.put(22, 5, "x")
    # discesa e terreno
    g.put(30, 9, "b")
    g.put(33, 9, "x")
    g.put(35, 9, "c")
    g.pit(38, 39)
    g.line(7, 38, 39, "o")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    return ("Courtyard", 0, g.rows())


def L2():
    g = G()
    g.put(2, 9, "S")
    g.line(9, 5, 7, "o", 1)
    # scala al piano intermedio, scala al piano alto con la chiave
    g.ladder(9, 5, 9)
    g.floor(6, 10, 30)
    g.ladder(12, 1, 5)
    g.floor(2, 13, 29)
    g.put(27, 1, "k")
    g.line(1, 15, 23, "o", 4)
    g.put(21, 5, "x")
    g.put(24, 5, "o")
    g.put(18, 9, "y")
    # spuntoni davanti al portone
    g.line(9, 33, 34, "^")
    g.put(32, 9, "c")
    g.gate(37)
    g.put(41, 9, "X")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    return ("Barracks", 0, g.rows())


def L3():
    g = G()
    g.put(2, 9, "S")
    g.put(7, 9, "y")
    g.pit(10, 12)
    g.line(7, 10, 12, "o")
    g.ladder(15, 5, 9)
    g.floor(6, 16, 34)
    g.line(5, 18, 32, "o", 3)
    g.put(24, 5, "y")
    g.put(29, 5, "Y")
    g.ladder(20, 1, 5)
    g.floor(2, 21, 33)
    g.put(31, 1, "g")
    g.line(1, 23, 29, "o", 3)
    g.put(36, 9, "c")
    g.line(9, 39, 40, "^")
    g.put(42, 9, "y")
    g.put(45, 8, "P")
    g.put(45, 9, "Q")
    return ("Infirmary", 0, g.rows())


def L4():
    g = G()
    g.put(2, 9, "S")
    g.pit(6, 8)
    g.line(7, 6, 8, "o")
    g.put(11, 9, "z")
    g.ladder(14, 5, 9)
    g.beams(6, 15, 22)
    g.floor(6, 23, 24)
    g.ladder(18, 1, 5)
    g.floor(2, 19, 36)
    g.put(24, 5, "x")
    g.line(5, 16, 22, "o", 3)
    g.line(1, 21, 35, "o", 4)
    g.put(34, 1, "k")
    g.wall(27, 6, 9, "#")
    g.put(26, 9, "c")
    g.pit(30, 32)
    g.line(7, 30, 32, "o")
    g.gate(39)
    g.put(43, 9, "Z")
    g.put(45, 8, "P")
    g.put(45, 9, "Q")
    return ("Guard Tower", 0, g.rows())


def L5():
    g = G()
    g.put(2, 9, "S")
    g.ladder(5, 5, 9)
    g.floor(6, 6, 20)
    g.line(5, 8, 18, "o", 3)
    g.put(13, 5, "z")
    g.ladder(21, 5, 9)
    g.floor(6, 22, 24, "b")
    g.floor(6, 25, 26, "R")
    g.floor(6, 27, 40)
    g.line(5, 28, 38, "o", 5)
    g.put(35, 5, "y")
    g.pit(14, 16)
    g.line(7, 14, 16, "o")
    g.put(30, 9, "x")
    g.put(33, 9, "c")
    g.line(9, 36, 37, "^")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    g.put(40, 9, "X")
    return ("Cellar", 0, g.rows())


def L6():
    g = G()
    g.put(2, 9, "S")
    g.ladder(6, 5, 9)
    g.floor(6, 7, 17)
    g.ladder(9, 1, 5)
    g.floor(2, 10, 24)
    g.line(1, 12, 22, "o", 2)
    g.put(20, 1, "g")
    g.put(14, 5, "x")
    g.line(5, 11, 17, "o", 3)
    g.pit(20, 22)
    g.beams(6, 19, 23)
    g.line(5, 19, 23, "o", 2)
    g.ladder(26, 1, 9)
    g.floor(6, 27, 40)
    g.floor(2, 27, 40)
    g.line(5, 29, 38, "o", 3)
    g.line(1, 29, 38, "o", 3)
    g.put(33, 1, "y")
    g.put(36, 5, "Y")
    g.put(30, 9, "z")
    g.put(33, 9, "c")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    return ("Library", 0, g.rows())


def L7():
    g = G()
    g.put(2, 9, "S")
    g.put(7, 9, "x")
    g.pit(10, 12)
    g.beams(8, 10, 12)
    g.line(7, 10, 12, "o")
    g.ladder(16, 5, 9)
    g.floor(6, 17, 30)
    g.put(22, 5, "W")
    g.line(5, 19, 29, "o", 5)
    g.ladder(32, 5, 9)
    g.floor(6, 33, 34)
    g.ladder(34, 1, 5)
    g.floor(2, 35, 45)
    g.line(1, 37, 43, "o", 3)
    g.put(44, 1, "k")
    g.put(25, 9, "c")
    g.line(9, 27, 28, "^")
    g.gate(40, 3)
    g.wall(46, 1, 5)
    g.put(43, 9, "Z")
    g.put(45, 8, "P")
    g.put(45, 9, "Q")
    return ("Armory", 0, g.rows())


def L8():
    g = G()
    g.put(2, 9, "S")
    g.ladder(5, 5, 9)
    g.floor(6, 6, 14)
    g.ladder(8, 1, 5)
    g.floor(2, 9, 22)
    g.line(1, 11, 21, "o", 2)
    g.put(16, 1, "Z")
    g.line(5, 10, 14, "o", 2)
    g.pit(18, 20)
    g.beams(6, 17, 21)
    g.line(5, 17, 21, "o", 2)
    g.floor(6, 22, 30)
    g.ladder(31, 5, 9)
    g.put(25, 5, "z")
    g.put(26, 9, "y")
    g.put(29, 9, "c")
    g.floor(6, 32, 44)
    g.floor(2, 32, 44)
    g.ladder(36, 1, 5)
    g.line(5, 34, 42, "o", 4)
    g.put(40, 1, "g")
    g.put(40, 5, "W")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    return ("Barracks II", 0, g.rows())


def L9():
    g = G()
    g.put(2, 9, "S")
    g.put(6, 9, "X")
    g.pit(9, 11)
    g.line(7, 9, 11, "o")
    g.ladder(14, 5, 9)
    g.floor(6, 15, 22)
    g.ladder(17, 1, 5)
    g.floor(2, 18, 28)
    g.put(25, 1, "y")
    g.line(1, 20, 27, "o", 3)
    g.put(19, 5, "x")
    g.pit(25, 27)
    g.beams(6, 24, 28)
    g.floor(6, 29, 34)
    g.line(5, 24, 33, "o", 3)
    g.ladder(35, 5, 9)
    g.put(31, 5, "Z")
    g.put(30, 9, "c")
    g.line(9, 32, 33, "^")
    g.gate(38)
    g.put(41, 9, "W")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    g.put(27, 1, "k")
    return ("Dungeon", 0, g.rows())


def L10():
    g = G()
    g.put(2, 9, "S")
    g.ladder(5, 5, 9)
    g.floor(6, 6, 16)
    g.ladder(8, 1, 5)
    g.floor(2, 9, 20)
    g.put(14, 1, "k")
    g.line(1, 11, 19, "o", 2)
    g.put(17, 1, "Z")
    g.put(11, 5, "x")
    g.pit(13, 15)
    g.line(7, 13, 15, "o")
    g.floor(6, 19, 21, "=")
    g.floor(6, 22, 28)
    g.ladder(23, 1, 5)
    g.floor(2, 24, 33)
    g.line(1, 26, 29, "o", 3)
    g.put(31, 1, "g")
    g.put(32, 1, "y")
    g.put(27, 5, "z")
    g.put(26, 9, "c")
    g.line(9, 29, 30, "^")
    g.gate(34)
    g.put(36, 9, "W")
    g.put(44, 8, "P")
    g.put(44, 9, "Q")
    return ("Throne Room", 0, g.rows())


LEVELS = [f() for f in (L1, L2, L3, L4, L5, L6, L7, L8, L9, L10)]
