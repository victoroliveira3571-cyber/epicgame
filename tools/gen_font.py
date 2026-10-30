#!/usr/bin/env python3
"""Gera a fonte pixel do jogo (BMFont) com acentos do português.
Glifos 5x7 desenhados à mão abaixo; acentos compostos por código.
Saída: game/assets/ui/pf12.fnt/.png (1x), pf24 (2x), pf36 (3x)."""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui")
os.makedirs(OUT, exist_ok=True)

# Cada glifo: 7 linhas "principais" (altura de maiúscula) separadas por "/",
# opcionalmente seguidas de "|" + linhas de descendente ("p", "g"...).
G = {}


def g(ch, rows):
    G[ch] = rows


# ---- maiúsculas
g("A", ".###./#...#/#...#/#####/#...#/#...#/#...#")
g("B", "####./#...#/#...#/####./#...#/#...#/####.")
g("C", ".###./#...#/#..../#..../#..../#...#/.###.")
g("D", "####./#...#/#...#/#...#/#...#/#...#/####.")
g("E", "#####/#..../#..../####./#..../#..../#####")
g("F", "#####/#..../#..../####./#..../#..../#....")
g("G", ".###./#...#/#..../#.###/#...#/#...#/.###.")
g("H", "#...#/#...#/#...#/#####/#...#/#...#/#...#")
g("I", ".###./..#../..#../..#../..#../..#../.###.")
g("J", "..###/...#./...#./...#./...#./#..#./.##..")
g("K", "#...#/#..#./#.#../##.../#.#../#..#./#...#")
g("L", "#..../#..../#..../#..../#..../#..../#####")
g("M", "#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#")
g("N", "#...#/##..#/##..#/#.#.#/#..##/#..##/#...#")
g("O", ".###./#...#/#...#/#...#/#...#/#...#/.###.")
g("P", "####./#...#/#...#/####./#..../#..../#....")
g("Q", ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#")
g("R", "####./#...#/#...#/####./#.#../#..#./#...#")
g("S", ".####/#..../#..../.###./....#/....#/####.")
g("T", "#####/..#../..#../..#../..#../..#../..#..")
g("U", "#...#/#...#/#...#/#...#/#...#/#...#/.###.")
g("V", "#...#/#...#/#...#/#...#/#...#/.#.#./..#..")
g("W", "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#")
g("X", "#...#/#...#/.#.#./..#../.#.#./#...#/#...#")
g("Y", "#...#/#...#/.#.#./..#../..#../..#../..#..")
g("Z", "#####/....#/...#./..#../.#.../#..../#####")
# ---- minúsculas
g("a", "...../...../.###./....#/.####/#...#/.####")
g("b", "#..../#..../####./#...#/#...#/#...#/####.")
g("c", "...../...../.###./#...#/#..../#...#/.###.")
g("d", "....#/....#/.####/#...#/#...#/#...#/.####")
g("e", "...../...../.###./#...#/#####/#..../.###.")
g("f", "..##./.#..#/.#.../###../.#.../.#.../.#...")
g("g", "...../...../.####/#...#/#...#/#...#/.####|....#/.###.")
g("h", "#..../#..../####./#...#/#...#/#...#/#...#")
g("i", "..#../...../.##../..#../..#../..#../.###.")
g("j", "...#./...../..##./...#./...#./...#./...#.|#..#./.##..")
g("k", "#..../#..../#..#./#.#../##.../#.#../#..#.")
g("l", ".##../..#../..#../..#../..#../..#../.###.")
g("m", "...../...../##.#./#.#.#/#.#.#/#...#/#...#")
g("n", "...../...../####./#...#/#...#/#...#/#...#")
g("o", "...../...../.###./#...#/#...#/#...#/.###.")
g("p", "...../...../####./#...#/#...#/#...#/####.|#..../#....")
g("q", "...../...../.####/#...#/#...#/#...#/.####|....#/....#")
g("r", "...../...../#.##./##..#/#..../#..../#....")
g("s", "...../...../.####/#..../.###./....#/####.")
g("t", ".#.../.#.../###../.#.../.#.../.#..#/..##.")
g("u", "...../...../#...#/#...#/#...#/#...#/.####")
g("v", "...../...../#...#/#...#/#...#/.#.#./..#..")
g("w", "...../...../#...#/#...#/#.#.#/#.#.#/.#.#.")
g("x", "...../...../#...#/.#.#./..#../.#.#./#...#")
g("y", "...../...../#...#/#...#/#...#/#...#/.####|....#/.###.")
g("z", "...../...../#####/...#./..#../.#.../#####")
# ---- dígitos
g("0", ".###./#...#/#..##/#.#.#/##..#/#...#/.###.")
g("1", "..#../.##../..#../..#../..#../..#../.###.")
g("2", ".###./#...#/....#/...#./..#../.#.../#####")
g("3", ".###./#...#/....#/..##./....#/#...#/.###.")
g("4", "...#./..##./.#.#./#..#./#####/...#./...#.")
g("5", "#####/#..../####./....#/....#/#...#/.###.")
g("6", ".###./#..../#..../####./#...#/#...#/.###.")
g("7", "#####/....#/...#./..#../.#.../.#.../.#...")
g("8", ".###./#...#/#...#/.###./#...#/#...#/.###.")
g("9", ".###./#...#/#...#/.####/....#/....#/.###.")
# ---- pontuação
g("!", "..#../..#../..#../..#../..#../...../..#..")
g('"', ".#.#./.#.#./...../...../...../...../.....")
g("'", "..#../..#../...../...../...../...../.....")
g("#", ".#.#./#####/.#.#./.#.#./#####/.#.#./.....")
g("%", "##..#/##..#/...#./..#../.#.../#..##/#..##")
g("&", ".##../#..#./#..#./.##../#.#.#/#..#./.##.#")
g("(", "...#./..#../.#.../.#.../.#.../..#../...#.")
g(")", ".#.../..#../...#./...#./...#./..#../.#...")
g("*", "...../#.#.#/.###./#####/.###./#.#.#/.....")
g("+", "...../..#../..#../#####/..#../..#../.....")
g(",", "...../...../...../...../...../..#../.#...")
g("-", "...../...../...../#####/...../...../.....")
g(".", "...../...../...../...../...../...../..#..")
g("/", "....#/....#/...#./..#../.#.../#..../#....")
g(":", "...../...../..#../...../...../..#../.....")
g(";", "...../...../..#../...../...../..#../.#...")
g("<", "...#./..#../.#.../#..../.#.../..#../...#.")
g("=", "...../...../#####/...../#####/...../.....")
g(">", ".#.../..#../...#./....#/...#./..#../.#...")
g("?", ".###./#...#/....#/...#./..#../...../..#..")
g("@", ".###./#...#/#.###/#.#.#/#.###/#..../.###.")
g("[", ".###./.#.../.#.../.#.../.#.../.#.../.###.")
g("]", ".###./...#./...#./...#./...#./...#./.###.")
g("_", "...../...../...../...../...../...../.....|#####/.....")
g("°", ".##../.##../...../...../...../...../.....")
g("•", "...../...../.###./.###./.###./...../.....")
g("×", "...../...../#...#/.#.#./..#../.#.#./#...#")
g("|", "..#../..#../..#../..#../..#../..#../..#..|..#../.....")
g("\\", "#..../#..../.#.../..#../...#./....#/....#")
g("$", "..#../.####/#.#../.###./..#.#/####./..#..")
g("{", "..##./..#../.#.../##.../.#.../..#../..##.")
g("}", ".##../..#../...#./...##/...#./..#../.##..")
g("~", "...../...../.#..#/#.##./...../...../.....")
g("^", "..#../.#.#./#...#/...../...../...../.....")
g("`", ".#.../..#../...../...../...../...../.....")

# ---- acentos (posição relativa ao topo do glifo: duas linhas acima)
ACCENTS = {
    "acute": ["...#.", "..#.."],
    "grave": [".#...", "..#.."],
    "circ": ["..#..", ".#.#."],
    "tilde": [".##.#", "#..#."],
    "diaer": [".....", ".#.#."],
}
# (maiúscula/minúscula) -> acento: letras acentuadas do português
COMPOSE = {
    "á": ("a", "acute"), "à": ("a", "grave"), "â": ("a", "circ"), "ã": ("a", "tilde"), "ä": ("a", "diaer"),
    "é": ("e", "acute"), "è": ("e", "grave"), "ê": ("e", "circ"), "ë": ("e", "diaer"),
    "í": ("ı", "acute"), "ì": ("ı", "grave"), "î": ("ı", "circ"), "ï": ("ı", "diaer"),
    "ó": ("o", "acute"), "ò": ("o", "grave"), "ô": ("o", "circ"), "õ": ("o", "tilde"), "ö": ("o", "diaer"),
    "ú": ("u", "acute"), "ù": ("u", "grave"), "û": ("u", "circ"), "ü": ("u", "diaer"),
    "Á": ("A", "acute"), "À": ("A", "grave"), "Â": ("A", "circ"), "Ã": ("A", "tilde"),
    "É": ("E", "acute"), "È": ("E", "grave"), "Ê": ("E", "circ"),
    "Í": ("I", "acute"), "Ì": ("I", "grave"), "Î": ("I", "circ"),
    "Ó": ("O", "acute"), "Ò": ("O", "grave"), "Ô": ("O", "circ"), "Õ": ("O", "tilde"),
    "Ú": ("U", "acute"), "Ù": ("U", "grave"), "Û": ("U", "circ"),
}
g("ı", "...../...../.##../..#../..#../..#../.###.")  # i sem ponto
CEDILLA = {"ç": "c", "Ç": "C"}

CELL_W = 5
ROWS = 12          # linhas totais da célula
CAP_TOP = 3        # primeira linha de maiúscula
ASCENT = 10        # linha de base (distância do topo)


def glyph_bitmap(ch):
    """Retorna matriz ROWS x CELL_W (listas de 0/1)."""
    grid = [[0] * CELL_W for _ in range(ROWS)]

    def put(rows, top):
        for r, line in enumerate(rows):
            for c, v in enumerate(line):
                if v == "#" and 0 <= top + r < ROWS and 0 <= c < CELL_W:
                    grid[top + r][c] = 1

    if ch in COMPOSE:
        base, acc = COMPOSE[ch]
        main = G[base].split("|")[0].split("/")
        put(main, CAP_TOP)
        is_lower = base.islower() or base == "ı"
        # acima da maiúscula: linhas 1-2; acima de minúscula de altura x (topo = linha 5): linhas 3-4
        if base == "ı":
            # sem ponto: linha do ponto vira o acento
            accent_top = CAP_TOP
        elif is_lower and base not in "bdfhklt":
            accent_top = CAP_TOP
        else:
            accent_top = CAP_TOP - 2
        if is_lower and base not in "bdfhklt":
            # minúscula de altura x: acento nas linhas 3 e 4 (acima do topo do "x-height" = linha 5)
            put(ACCENTS[acc], 3 if base != "ı" else 3)
        else:
            put(ACCENTS[acc], 1)
        return grid
    if ch in CEDILLA:
        base = CEDILLA[ch]
        main = G[base].split("|")[0].split("/")
        put(main, CAP_TOP)
        put(["..#..", ".##.."], CAP_TOP + 7)
        return grid
    spec = G[ch]
    parts = spec.split("|")
    put(parts[0].split("/"), CAP_TOP)
    if len(parts) > 1:
        put(parts[1].split("/"), CAP_TOP + 7)
    return grid


def glyph_width(ch):
    # largura real: última coluna usada +1 (mínimo 1)
    bm = glyph_bitmap(ch)
    cols = [c for r in bm for c, v in enumerate(r) if v]
    return (max(cols) + 1) if cols else 3


def all_chars():
    chars = list(G.keys()) + list(COMPOSE.keys()) + list(CEDILLA.keys())
    chars = [c for c in chars if c != "ı"]
    return sorted(set(chars))


def build(scale, name):
    chars = all_chars()
    cw = (CELL_W + 1) * scale
    ch_h = ROWS * scale
    cols = 16
    rows = (len(chars) + 1 + cols - 1) // cols
    atlas = Image.new("RGBA", (cols * cw, rows * ch_h), (0, 0, 0, 0))
    lines = []
    entries = []
    for i, ch in enumerate(chars):
        bm = glyph_bitmap(ch)
        w = glyph_width(ch)
        ox, oy = (i % cols) * cw, (i // cols) * ch_h
        for r in range(ROWS):
            for c in range(CELL_W):
                if bm[r][c]:
                    for dy in range(scale):
                        for dx in range(scale):
                            atlas.putpixel((ox + c * scale + dx, oy + r * scale + dy), (255, 255, 255, 255))
        entries.append((ord(ch), ox, oy, w * scale, ch_h, (w + 1) * scale))
    # espaço
    sp = len(chars)
    ox, oy = (sp % cols) * cw, (sp // cols) * ch_h
    entries.append((32, ox, oy, 1, ch_h, 3 * scale + scale))
    atlas.save(os.path.join(OUT, f"{name}.png"))
    with open(os.path.join(OUT, f"{name}.fnt"), "w") as f:
        f.write(f'info face="PixelFont" size={12 * scale} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0 outline=0\n')
        f.write(f"common lineHeight={ch_h} base={ASCENT * scale} scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0\n")
        f.write(f'page id=0 file="{name}.png"\n')
        f.write(f"chars count={len(entries)}\n")
        for (cid, x, y, w, h, adv) in entries:
            f.write(f"char id={cid} x={x} y={y} width={w} height={h} xoffset=0 yoffset=0 xadvance={adv} page=0 chnl=15\n")


for s, n in ((1, "pf12"), (2, "pf24"), (3, "pf36")):
    build(s, n)
print("fonte ok:", len(all_chars()) + 1, "glifos")

# prévia
txt = "Guilda dos Aventureiros - Nível 5! áàâãéêíóôõúç ÁÉÍÓÚÇ Poção de Vida 0123456789 +-%/ ?:;,."
atlas = Image.open(os.path.join(OUT, "pf12.png"))
chars = all_chars()
cw = 6; chh = ROWS
cols = 16
img = Image.new("RGBA", (len(txt) * 6 + 8, 40), (42, 29, 46, 255))
x = 4
fnt = {}
for line in open(os.path.join(OUT, "pf12.fnt")):
    if line.startswith("char "):
        d = dict(p.split("=") for p in line.split()[1:])
        fnt[int(d["id"])] = d
for chx in txt:
    d = fnt.get(ord(chx))
    if d:
        gl = atlas.crop((int(d["x"]), int(d["y"]), int(d["x"]) + int(d["width"]), int(d["y"]) + int(d["height"])))
        img.alpha_composite(gl, (x, 6))
        x += int(d["xadvance"])
img = img.resize((img.width * 2, img.height * 2), Image.NEAREST)
img.save("/private/tmp/claude-501/-Users-victor-Desktop-EPICGAME/e3184624-fc7c-45f0-b2d1-ae52c5b12071/scratchpad/font_preview.png")
