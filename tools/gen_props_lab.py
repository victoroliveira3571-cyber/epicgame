"""Props do Laboratório do Dr. Faísca (game/assets/custom/props/p_lab_*.png), estilo Ninja Adventure.
Uso (da pasta game/):  python3 tools/gen_props_lab.py
"""
from PIL import Image
from pixelkit import *

OUTDIR = "assets/custom/props/"
GLASS = C("bfe6f0")
LIQ = [C("6ae07a"), C("e06aa8"), C("6aa8e0"), C("e0c86a"), C("a86ae0")]


def save(name, im):
    im.save(OUTDIR + name + ".png")
    print(name, im.size)


def flask(im, x, base_y, h, liq, round_=True):
    """Frasco: gargalo fino e bojo (redondo ou reto) com líquido e brilho."""
    if round_:
        ellipse(im, x - 5, base_y - 10, x + 5, base_y, OUT)
        ellipse(im, x - 4, base_y - 9, x + 4, base_y - 1, GLASS)
        ellipse(im, x - 4, base_y - 6, x + 4, base_y - 1, liq)
        rect(im, x - 1, base_y - h, x + 1, base_y - 9, OUT)
        rect(im, x, base_y - h + 1, x, base_y - 10, GLASS)
    else:
        box(im, x - 3, base_y - h, x + 3, base_y, GLASS)
        rect(im, x - 2, base_y - h // 2, x + 2, base_y - 1, liq)
    px(im, x - 2, base_y - 7, C("ffffff"))


def bancada():
    im = canvas(64, 34)
    box(im, 0, 14, 63, 20, C("7a5a3a"), C("9a7a52"), C("4a3020"))
    box(im, 2, 20, 61, 33, C("5a4028"), None, C("3a2414"))
    box(im, 24, 23, 40, 30, C("7a5a3a"), C("9a7a52"), C("4a3020"))
    flask(im, 8, 14, 13, LIQ[0])
    flask(im, 18, 14, 10, LIQ[1], False)
    flask(im, 46, 14, 14, LIQ[2])
    flask(im, 56, 14, 9, LIQ[3], False)
    # suporte com tubos
    rect(im, 28, 4, 29, 14, OUT)
    rect(im, 26, 4, 38, 5, OUT)
    for k, c in enumerate(LIQ[:3]):
        box(im, 30 + k * 3, 6, 31 + k * 3, 13, c)
    return im


def caldeirao():
    im = canvas(30, 30)
    ellipse(im, 2, 10, 27, 28, OUT)
    ellipse(im, 3, 11, 26, 27, C("3a3a44"))
    ellipse(im, 5, 10, 24, 15, C("6ae07a"))
    ellipse(im, 7, 11, 22, 14, C("a8f0b0"))
    for x in (9, 15, 20):
        ellipse(im, x - 2, 4 + (x % 3) * 2, x + 2, 8 + (x % 3) * 2, C("a8f0b0"), OUT)
    for x in (6, 22):
        box(im, x - 2, 25, x + 2, 29, C("2a2a30"))
    return im


def bobina():
    im = canvas(20, 44)
    box(im, 3, 36, 16, 43, C("4a4a54"), C("6a6a74"), C("2a2a30"))
    for y in range(12, 36, 3):
        rect(im, 6, y, 13, y + 1, C("c8843a"))
        hline(im, 6, 13, y + 2, C("7a4a1a"))
    ellipse(im, 3, 2, 16, 13, OUT)
    ellipse(im, 4, 3, 15, 12, C("b8c0cc"))
    px(im, 7, 5, C("ffffff"))
    return im


def quadro():
    im = canvas(56, 32)
    box(im, 0, 0, 55, 31, C("5a3a22"))
    rect(im, 3, 3, 52, 28, C("1e3a2e"))
    chalk = C("e8f0e0")
    for y, w in ((7, 30), (12, 22), (17, 36), (22, 18)):
        hline(im, 6, 6 + w, y, chalk)
    ellipse(im, 38, 6, 48, 16, None, chalk)
    line(im, (40, 20), (50, 25), chalk)
    line(im, (50, 20), (40, 25), chalk)
    return im


def estante_potes():
    im = canvas(40, 40)
    box(im, 0, 0, 39, 39, C("4a2e1c"))
    for r in range(3):
        y = 4 + r * 12
        rect(im, 2, y, 37, y + 10, C("2a1a10"))
        for k in range(5):
            flask(im, 6 + k * 7, y + 10, 8 + (k + r) % 3, LIQ[(k + r) % len(LIQ)], k % 2 == 0)
        rect(im, 1, y + 10, 38, y + 11, C("7a5a3a"))
    return im


if __name__ == "__main__":
    save("p_lab_bancada", bancada())
    save("p_lab_caldeirao", caldeirao())
    save("p_lab_bobina", bobina())
    save("p_lab_quadro", quadro())
    save("p_lab_potes", estante_potes())
