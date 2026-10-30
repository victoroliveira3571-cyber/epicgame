"""Móveis, decoração e placas em pixel art (game/assets/custom/props/), no estilo Ninja Adventure.
Os arquivos com nome furn_*.png SUBSTITUEM os de assets/ninja/props/ (o Interior.gd procura aqui primeiro).
A cama vem recortada do pacote (raw_assets/.../tileset_bed.png, CC0); o resto é desenhado por código.

Uso (da pasta game/):  python3 tools/gen_props.py
"""
import os
from PIL import Image
from pixelkit import *

OUTDIR = "assets/custom/props/"
WOOD, WOOD_L, WOOD_D = C("94603a"), C("b9814e"), C("5a361f")
BOOK_PAL = [C("8c2f39"), C("2f5d62"), C("c7923e"), C("3d3a6b"), C("5b7a3a"), C("a8543a"), C("6b3a5a"), C("d6c08a")]


def save(name, im):
    im.save(OUTDIR + name + ".png")
    print(f"{name}: {im.size[0]}x{im.size[1]}, {count_colors(im)} cores")


def cama():
    """Cama de casal vermelha (recorte do pacote Ninja Adventure)."""
    return raw("Backgrounds/Tilesets/tileset_bed.png", (0, 48, 32, 96))


def mesa():
    im = canvas(48, 28)
    box(im, 2, 4, 45, 12, WOOD, WOOD_L, WOOD_D)
    poly(im, [(4, 12), (43, 12), (45, 20), (2, 20)], C("c4453d"), OUT)           # toalha
    for x in range(6, 44, 5):
        vline(im, x, 13, 19, C("e8e0d0"))
    hline(im, 2, 45, 20, OUT)
    for lx in (4, 40):
        box(im, lx, 20, lx + 3, 27, WOOD_D)
    ellipse(im, 20, 1, 29, 6, OUT)                                               # pão
    ellipse(im, 21, 2, 28, 5, C("c58a4a"))
    box(im, 34, 1, 38, 5, C("f1e5c6"))
    px(im, 36, 0, C("ffb02e"))
    return im


def estante():
    im = canvas(24, 34)
    box(im, 0, 0, 23, 33, C("2d1b12"), C("4a3022"))
    for r in range(3):
        y = 3 + r * 10
        rect(im, 2, y, 21, y + 8, C("1a100a"))
        books(im, 3, y + 1, 20, y + 8, 5 + r, BOOK_PAL)
        rect(im, 1, y + 9, 22, y + 10, C("6b4430"))
    box(im, 1, 31, 22, 33, WOOD_D)
    return im


def lareira():
    im = canvas(28, 30)
    box(im, 0, 8, 27, 29, C("5a4a44"), C("7a645a"))
    for r in range(4):
        for x in range(2 + (r % 2) * 4, 26, 8):
            rect(im, x, 10 + r * 5, x + 5, 13 + r * 5, C("6a5650"))
    box(im, 4, 14, 23, 29, C("120c0c"))
    ellipse(im, 4, 11, 23, 20, C("120c0c"))
    box(im, 0, 3, 27, 8, C("7a645a"), C("9a847a"), C("4a3a34"))
    box(im, 6, 25, 21, 28, C("3a2418"))
    for (cx, hh) in ((9, 8), (14, 11), (19, 7)):
        poly(im, [(cx - 3, 26), (cx, 26 - hh), (cx + 3, 26)], C("e8531e"))
        poly(im, [(cx - 2, 26), (cx, 26 - hh + 3), (cx + 2, 26)], C("ffb02e"))
        px(im, cx, 25, C("ffe27a"))
    return im


def planta():
    im = canvas(18, 30)
    box(im, 4, 20, 13, 29, C("a8543a"), C("c86a4a"), C("7a3a28"))
    rect(im, 3, 19, 14, 21, C("c86a4a"))
    hline(im, 3, 14, 19, OUT)
    leaf = [C("2c6a36"), C("3f8a48"), C("57b254")]
    for (x, y, dx) in ((9, 18, -6), (9, 18, 6), (9, 17, -3), (9, 17, 3), (9, 17, 0)):
        for k in range(10):
            xx, yy = x + int(dx * k / 6), y - k - (abs(dx) // 3)
            for w in range(2):
                px(im, xx + w, yy, leaf[(k + w) % 3])
        px(im, x + dx, y - 11 - abs(dx) // 3, leaf[2])
    return outline_sprite(im).crop((1, 1, 19, 31)) if False else im


def relogio():
    """Relógio de pé."""
    im = canvas(16, 34)
    box(im, 2, 0, 13, 33, C("6a4630"), C("8a5e40"), C("3a2418"))
    box(im, 4, 3, 11, 10, C("f4ecd2"), None, C("b8a888"))
    px(im, 7, 6, OUT); px(im, 7, 5, OUT); px(im, 8, 6, OUT); px(im, 9, 7, OUT)
    rect(im, 4, 13, 11, 28, C("2d1b12"))
    vline(im, 7, 14, 21, C("c9a24a"))
    ellipse(im, 5, 21, 9, 25, C("e0b84a"), OUT)
    rect(im, 3, 30, 12, 33, C("3a2418"))
    return im


def trofeu():
    im = canvas(26, 32)
    box(im, 0, 0, 25, 31, C("6a4630"), C("8a5e40"), C("3a2418"))
    rect(im, 3, 3, 22, 26, C("1d3a42"))
    for x in range(4, 22, 5):
        vline(im, x, 3, 26, C("2c5a66"))
    rect(im, 4, 18, 21, 19, C("6a4630"))
    # taça e medalhas
    ellipse(im, 8, 6, 17, 13, C("e0b84a"), OUT)
    rect(im, 11, 13, 14, 16, C("c9a24a"))
    rect(im, 9, 16, 16, 17, C("e0b84a"))
    for (x, c) in ((6, C("c4453d")), (11, C("3f95c4")), (16, C("57b254"))):
        ellipse(im, x, 21, x + 4, 25, c, OUT)
    return im


def tapete():
    im = canvas(52, 34)
    ellipse(im, 0, 0, 51, 33, OUT)
    ellipse(im, 1, 1, 50, 32, C("a8433a"))
    ellipse(im, 5, 4, 46, 29, C("e8c070"))
    ellipse(im, 7, 6, 44, 27, C("c4453d"))
    ellipse(im, 15, 11, 36, 22, C("e8c070"))
    ellipse(im, 18, 13, 33, 20, C("a8433a"))
    for x in range(8, 44, 7):
        px(im, x, 3, C("ffe4a0")); px(im, x, 30, C("ffe4a0"))
    return im


def sign(icon):
    """Placa de madeira pendurada 20x24 com um símbolo (sem texto)."""
    im = canvas(20, 26)
    vline(im, 4, 0, 4, OUT); vline(im, 15, 0, 4, OUT)
    box(im, 1, 4, 18, 24, WOOD, WOOD_L, WOOD_D)
    rect(im, 3, 6, 16, 22, C("d8b078"))
    hline(im, 3, 16, 6, C("f0d098"))
    if icon == "espada":
        line(im, (5, 20), (14, 8), C("c8d0d8"), 2)
        line(im, (4, 15), (9, 20), C("8a5a2a"), 2)
    elif icon == "tigela":
        ellipse(im, 5, 13, 14, 20, OUT)
        ellipse(im, 6, 14, 13, 19, C("e8e0d0"))
        rect(im, 7, 11, 12, 14, C("d98f4a"))
        for x in (8, 11):
            px(im, x, 8, C("ffffff")); px(im, x, 9, C("e8e8e8"))
    elif icon == "livro":
        box(im, 5, 9, 15, 19, C("2f5d62"), C("4a8a92"), C("1a3a40"))
        rect(im, 7, 11, 13, 13, C("e8c070"))
    elif icon == "cama":
        box(im, 4, 12, 16, 20, C("c4453d"), C("e8605a"), C("8a2a2a"))
        rect(im, 4, 9, 8, 12, C("f4ecd2"))
    elif icon == "martelo":
        rect(im, 5, 8, 14, 11, C("8a8a92"))
        line(im, (10, 11), (10, 21), C("8a5a2a"), 2)
    return im


def quadro_missoes():
    """Quadro de avisos com pergaminhos pregados (36x30)."""
    im = canvas(36, 30)
    box(im, 0, 0, 35, 29, WOOD_D, WOOD_L)
    rect(im, 3, 3, 32, 26, C("c89a62"))
    for (x, y, w, h, c) in ((5, 5, 9, 11, C("f4ecd2")), (16, 6, 8, 9, C("efe3c2")), (26, 5, 5, 12, C("f4ecd2")), (7, 18, 10, 7, C("efe3c2")), (20, 17, 10, 8, C("f4ecd2"))):
        box(im, x, y, x + w, y + h, c, None, mix(c, (0, 0, 0, 255), 0.18))
        px(im, x + w // 2, y, C("c4453d"))
        for k in range(2, h - 2, 3):
            hline(im, x + 2, x + w - 2, y + k, mix(c, (0, 0, 0, 255), 0.35))
    box(im, 2, 27, 33, 29, WOOD_D)
    return im


def cadeira():
    im = canvas(16, 22)
    box(im, 2, 0, 13, 12, WOOD, WOOD_L, WOOD_D)
    rect(im, 4, 2, 11, 9, C("a8433a"))
    box(im, 1, 11, 14, 15, WOOD, WOOD_L, WOOD_D)
    for lx in (2, 11):
        box(im, lx, 15, lx + 2, 21, WOOD_D)
    return im


def lampiao():
    """Lampião de mesa (14x22)."""
    im = canvas(14, 22)
    box(im, 2, 17, 11, 21, C("3a2a1a"), C("5a4a3a"))
    box(im, 4, 6, 9, 17, C("c58a3a"), C("e0a85a"), C("8a5a2a"))
    rect(im, 5, 8, 8, 15, C("ffe8a0"))
    poly(im, [(3, 6), (10, 6), (7, 1), (6, 1)], C("8a5a2a"), OUT)
    return im


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    save("furn_cama", cama())
    save("furn_mesa", mesa())
    save("furn_estante", estante())
    save("furn_lareira", lareira())
    save("furn_planta", planta())
    save("furn_relogio", relogio())
    save("furn_trofeu", trofeu())
    save("furn_tapete", tapete())
    for n in ("espada", "tigela", "livro", "cama", "martelo"):
        save("placa_" + n, sign(n))
    save("quadro_missoes", quadro_missoes())
    save("cadeira", cadeira())
    save("lampiao", lampiao())
