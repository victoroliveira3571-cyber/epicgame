"""Mais móveis e objetos em pixel art para os interiores (ferraria, loja de armas, costura, cozinha,
arena e miudezas), no mesmo estilo dos props de gen_props.py (contorno escuro, 3 tons, sem
antialiasing). Grava em game/assets/custom/props/ com prefixo p_.

Uso (da pasta game/):  python3 tools/gen_props2.py
"""
import random
from pixelkit import *

OUTDIR = "assets/custom/props/"
WOOD, WOOD_L, WOOD_D = C("94603a"), C("b9814e"), C("5a361f")
DARKW, DARKW_L, DARKW_D = C("5a3a28"), C("7a5038"), C("3a2418")
IRON, IRON_L, IRON_D = C("5d6470"), C("8a93a0"), C("363b44")
STEEL, STEEL_L = C("b8c2cc"), C("eef4f8")
GOLD, GOLD_L = C("d8a23a"), C("ffd36a")
FIRE = [C("8a1e12"), C("e8531e"), C("ffb02e"), C("ffe27a")]
STONE, STONE_L, STONE_D = C("6e6a72"), C("8e8a92"), C("4a464e")
CLOTHS = [C("c4453d"), C("3f6fc0"), C("57b254"), C("e8c070"), C("7a52a8"), C("e08fb0"), C("2f5d62"), C("d8c49a")]


def save(name, im):
    im.save(OUTDIR + "p_" + name + ".png")
    print(f"p_{name}: {im.size[0]}x{im.size[1]}")


# ------------------------------------------------------------------ Ferraria
def bigorna():
    im = canvas(24, 16)
    box(im, 7, 9, 16, 15, DARKW, DARKW_L, DARKW_D)          # toco
    poly(im, [(1, 3), (20, 3), (23, 5), (17, 6), (17, 9), (6, 9), (6, 6), (1, 5)], IRON, OUT)
    hline(im, 3, 19, 4, IRON_L)
    hline(im, 7, 16, 8, IRON_D)
    px(im, 21, 4, IRON_L)
    return im


def fornalha():
    im = canvas(34, 38)
    box(im, 1, 12, 32, 37, STONE, STONE_L, STONE_D)
    for r in range(5):
        for x in range(3 + (r % 2) * 4, 31, 8):
            rect(im, x, 14 + r * 5, x + 5, 16 + r * 5, C("7a767e"))
    box(im, 6, 0, 27, 12, STONE_D, STONE, C("2a262e"))       # chaminé
    box(im, 7, 19, 26, 33, C("140c0a"))
    ellipse(im, 7, 16, 26, 26, C("140c0a"))
    rect(im, 9, 27, 24, 32, C("3a2418"))
    for i, (cx, hh) in enumerate(((11, 8), (16, 11), (21, 9))):
        poly(im, [(cx - 3, 31), (cx, 31 - hh), (cx + 3, 31)], FIRE[1])
        poly(im, [(cx - 2, 31), (cx, 31 - hh + 4), (cx + 2, 31)], FIRE[2])
        px(im, cx, 30, FIRE[3])
    for x in range(9, 25, 3):
        px(im, x, 32, FIRE[2])
    box(im, 0, 34, 33, 37, STONE_D, STONE, C("2a262e"))
    return im


def rebolo():
    im = canvas(22, 20)
    box(im, 2, 12, 19, 19, WOOD, WOOD_L, WOOD_D)
    ellipse(im, 4, 0, 17, 13, OUT)
    ellipse(im, 5, 1, 16, 12, C("8e8a92"))
    ellipse(im, 8, 4, 13, 9, C("6e6a72"))
    px(im, 10, 6, OUT); px(im, 11, 6, OUT)
    line(im, (16, 7), (21, 4), WOOD_D, 1)
    return im


def tina_agua():
    im = canvas(20, 14)
    box(im, 1, 3, 18, 13, WOOD, WOOD_L, WOOD_D)
    for x in (5, 14):
        vline(im, x, 4, 12, IRON_D)
    ellipse(im, 2, 1, 17, 6, OUT)
    ellipse(im, 3, 2, 16, 5, C("3a6a9a"))
    hline(im, 6, 10, 3, C("8ac4e8"))
    return im


def ferramentas():
    """Painel de ferramentas na parede (martelos, tenaz, serra)."""
    im = canvas(34, 22)
    box(im, 0, 0, 33, 21, DARKW, DARKW_L, DARKW_D)
    for x in range(3, 32, 3):
        px(im, x, 3, C("2a1810"))
    # martelos
    for x in (4, 10):
        vline(im, x + 2, 6, 18, WOOD_L)
        box(im, x, 4, x + 4, 7, IRON, IRON_L)
    # tenaz
    line(im, (16, 5), (19, 18), IRON_D, 1)
    line(im, (19, 5), (16, 18), IRON_D, 1)
    # serra
    box(im, 23, 5, 30, 8, WOOD, WOOD_L)
    rect(im, 24, 9, 30, 15, STEEL)
    for y in range(9, 16, 2):
        px(im, 30, y, OUT)
    return im


def carvao():
    im = canvas(20, 9)
    ellipse(im, 0, 1, 19, 10, OUT)
    ellipse(im, 1, 2, 18, 10, C("2a2a30"))
    for (x, y) in ((4, 4), (8, 3), (12, 5), (15, 4), (6, 6), (10, 6)):
        px(im, x, y, C("4a4a54"))
    return im


def lingotes():
    im = canvas(18, 10)
    for i, (x, y) in enumerate(((1, 5), (7, 5), (13 - 1, 5), (4, 1), (10, 1))):
        poly(im, [(x, y + 3), (x + 1, y), (x + 5, y), (x + 6, y + 3)], [IRON_L, GOLD, STEEL, C("c87a4a"), IRON_L][i], OUT)
    return im


def fole():
    im = canvas(18, 12)
    poly(im, [(1, 6), (12, 1), (12, 11)], C("7a4a2a"), OUT)
    for x in range(4, 12, 3):
        vline(im, x, 4, 8, C("5a3418"))
    box(im, 12, 4, 17, 8, WOOD, WOOD_L, WOOD_D)
    return im


# ------------------------------------------------------------------ Loja de armas
def rack_espadas():
    im = canvas(32, 28)
    box(im, 0, 22, 31, 27, DARKW, DARKW_L, DARKW_D)
    vline(im, 1, 2, 22, OUT); vline(im, 30, 2, 22, OUT)
    box(im, 0, 1, 31, 4, DARKW, DARKW_L, DARKW_D)
    for i, x in enumerate(range(5, 30, 6)):
        col = [STEEL, C("c8d0d8"), GOLD_L if i == 2 else STEEL, IRON_L][i % 4]
        vline(im, x, 5, 18, OUT); vline(im, x + 1, 5, 18, col); vline(im, x + 2, 6, 18, OUT)
        hline(im, x - 1, x + 3, 19, GOLD if i == 2 else C("8a5a2a"))
        vline(im, x + 1, 20, 22, C("6a3a1a"))
    return im


def armadura():
    """Armadura de placas num suporte."""
    im = canvas(18, 32)
    vline(im, 8, 22, 30, DARKW); vline(im, 9, 22, 30, DARKW_D)
    box(im, 3, 29, 14, 31, DARKW, DARKW_L, DARKW_D)
    ellipse(im, 5, 0, 12, 8, IRON, OUT)                       # elmo
    rect(im, 6, 4, 11, 5, OUT)
    box(im, 2, 9, 15, 21, IRON, IRON_L, IRON_D)              # couraça
    vline(im, 8, 10, 20, IRON_L)
    box(im, 0, 9, 3, 15, IRON, IRON_L, IRON_D)
    box(im, 14, 9, 17, 15, IRON, IRON_L, IRON_D)
    hline(im, 3, 14, 17, GOLD)
    return im


def escudos_parede():
    im = canvas(34, 18)
    for i, (x, c) in enumerate(((0, C("c4453d")), (12, C("3f6fc0")), (24, C("57b254")))):
        poly(im, [(x + 1, 1), (x + 9, 1), (x + 9, 9), (x + 5, 16), (x + 1, 9)], c, OUT)
        vline(im, x + 5, 2, 14, GOLD)
        hline(im, x + 2, x + 8, 6, GOLD)
    return im


def lancas():
    im = canvas(16, 34)
    box(im, 1, 28, 14, 33, DARKW, DARKW_L, DARKW_D)
    for x in (3, 7, 11):
        vline(im, x, 6, 28, WOOD_L)
        vline(im, x + 1, 6, 28, WOOD_D)
        poly(im, [(x - 1, 6), (x + 1, 0), (x + 3, 6)], STEEL, OUT)
    box(im, 0, 16, 15, 18, DARKW, DARKW_L, DARKW_D)
    return im


def vitrine():
    """Balcão com vitrine de adagas e anéis."""
    im = canvas(44, 20)
    box(im, 0, 6, 43, 19, DARKW, DARKW_L, DARKW_D)
    rect(im, 3, 8, 40, 13, C("1a2a36"))
    for x in range(5, 39, 8):
        line(im, (x, 12), (x + 5, 9), STEEL, 1)
        px(im, x, 12, C("8a5a2a"))
    hline(im, 3, 40, 8, C("8ac4e8"))
    box(im, 0, 3, 43, 6, WOOD, WOOD_L, WOOD_D)
    box(im, 30, 0, 37, 3, GOLD, GOLD_L, C("8a6a1a"))          # caixinha de moedas
    return im


def barril_espadas():
    im = canvas(16, 24)
    for x, a in ((3, 0), (6, 1), (9, -1), (12, 1)):
        line(im, (x, 2 + abs(a)), (x + a, 12), STEEL, 1)
        hline(im, x - 1 + a, x + 1 + a, 11, C("8a5a2a"))
    box(im, 1, 11, 14, 23, WOOD, WOOD_L, WOOD_D)
    for y in (14, 20):
        hline(im, 1, 14, y, IRON_D)
    return im


def arcos_parede():
    im = canvas(28, 18)
    for x in (2, 12):
        for k in range(14):
            px(im, x + int(4 * (1 - ((k - 7) / 7.0) ** 2)), 2 + k, WOOD_D)
            px(im, x + 1 + int(4 * (1 - ((k - 7) / 7.0) ** 2)), 2 + k, WOOD_L)
        vline(im, x, 2, 15, C("e8e0d0"))
    # aljava com flechas
    box(im, 22, 6, 26, 17, C("8a5a36"), C("aa7a4a"), C("5a3a1e"))
    for x in (23, 25):
        vline(im, x, 1, 6, WOOD_L)
        px(im, x, 0, C("e8e0d0"))
    return im


# ------------------------------------------------------------------ Costura
def manequim():
    im = canvas(14, 30)
    vline(im, 6, 20, 28, DARKW); vline(im, 7, 20, 28, DARKW_D)
    box(im, 2, 27, 11, 29, DARKW, DARKW_L, DARKW_D)
    poly(im, [(3, 4), (10, 4), (12, 9), (10, 14), (12, 21), (1, 21), (3, 14), (1, 9)], C("e08fb0"), OUT)
    vline(im, 6, 5, 20, C("f0b0c8"))
    ellipse(im, 4, 0, 9, 4, C("d8c49a"), OUT)
    for y in (8, 12, 16):
        px(im, 7, y, GOLD)
    return im


def roca():
    """Roda de fiar."""
    im = canvas(24, 22)
    ellipse(im, 6, 0, 21, 15, OUT)
    ellipse(im, 7, 1, 20, 14, C("2a1810"))
    ellipse(im, 8, 2, 19, 13, WOOD)
    ellipse(im, 10, 4, 17, 11, C("2a1810"))
    for a in range(0, 360, 45):
        import math
        x = 13.5 + 3.5 * math.cos(math.radians(a))
        y = 7.5 + 3.5 * math.sin(math.radians(a))
        px(im, int(x), int(y), WOOD_L)
    line(im, (2, 21), (8, 12), WOOD_D, 1)
    line(im, (20, 21), (16, 12), WOOD_D, 1)
    box(im, 0, 17, 9, 20, WOOD, WOOD_L, WOOD_D)
    ellipse(im, 1, 13, 5, 17, C("e8e0d0"), OUT)
    return im


def tecidos():
    """Estante com rolos de tecido coloridos."""
    im = canvas(30, 26)
    box(im, 0, 0, 29, 25, DARKW, DARKW_L, DARKW_D)
    for r in range(2):
        y = 2 + r * 12
        rect(im, 2, y, 27, y + 10, C("1a100a"))
        for i in range(4):
            c = CLOTHS[(i + r * 4) % len(CLOTHS)]
            ellipse(im, 3 + i * 6, y + 2, 8 + i * 6, y + 9, c, OUT)
            px(im, 5 + i * 6, y + 5, mix(c, (255, 255, 255, 255), 0.4))
    return im


def mesa_costura():
    im = canvas(32, 20)
    box(im, 0, 5, 31, 11, WOOD, WOOD_L, WOOD_D)
    for x in (2, 27):
        box(im, x, 11, x + 2, 19, WOOD_D)
    # máquina de costura
    box(im, 8, 0, 22, 5, C("2a2a30"), C("4a4a54"))
    box(im, 18, 0, 22, 4, C("2a2a30"))
    hline(im, 9, 17, 1, GOLD)
    vline(im, 10, 5, 7, STEEL)
    # tecido sobre a mesa
    rect(im, 3, 6, 9, 9, C("e08fb0"))
    rect(im, 24, 6, 29, 9, C("3f6fc0"))
    return im


def novelos():
    im = canvas(16, 12)
    box(im, 0, 5, 15, 11, C("c8a060"), C("e0c080"), C("8a6a3a"))
    for x in range(2, 14, 3):
        vline(im, x, 6, 10, C("a8804a"))
    for (x, c) in ((2, CLOTHS[0]), (6, CLOTHS[1]), (10, CLOTHS[3])):
        ellipse(im, x, 0, x + 5, 6, c, OUT)
    line(im, (4, 3), (12, 10), C("e8e0d0"), 1)
    return im


def espelho():
    im = canvas(16, 32)
    box(im, 1, 0, 14, 27, DARKW, DARKW_L, DARKW_D)
    rect(im, 3, 2, 12, 25, C("9ac8e0"))
    for k in range(5):
        px(im, 4 + k, 6 + k * 2, C("e8f6ff"))
        px(im, 5 + k, 6 + k * 2, C("e8f6ff"))
    box(im, 3, 28, 12, 31, DARKW, DARKW_L, DARKW_D)
    return im


# ------------------------------------------------------------------ Casa e cozinha
def fogao():
    im = canvas(30, 26)
    box(im, 0, 6, 29, 25, IRON, IRON_L, IRON_D)
    box(im, 4, 12, 25, 23, C("1a1414"))
    rect(im, 6, 18, 23, 22, FIRE[1])
    for x in range(7, 23, 3):
        px(im, x, 17, FIRE[2])
    box(im, 0, 3, 29, 6, IRON_D, IRON)
    # panela
    box(im, 6, 0, 15, 4, C("4a4a54"), C("6a6a74"))
    for k in range(3):
        px(im, 9 + k * 2, -0 + 0, C("e8e8e8"))
    box(im, 18, 1, 25, 4, C("8a5a2a"), C("aa7a4a"))
    return im


def panelas():
    """Panelas e conchas penduradas (parede)."""
    im = canvas(28, 14)
    hline(im, 0, 27, 1, DARKW)
    hline(im, 0, 27, 2, DARKW_D)
    for i, x in enumerate((2, 10, 19)):
        vline(im, x + 3, 2, 4, OUT)
        ellipse(im, x, 4, x + 7, 11 - (i % 2) * 2, [C("c87a4a"), IRON, C("c87a4a")][i], OUT)
    vline(im, 26, 2, 11, STEEL)
    ellipse(im, 24, 10, 27, 13, STEEL, OUT)
    return im


def ervas():
    """Ervas secando penduradas (parede)."""
    im = canvas(26, 14)
    hline(im, 0, 25, 1, WOOD_D)
    for x in range(2, 25, 5):
        vline(im, x, 1, 4, C("c8b080"))
        g = [C("3f8a48"), C("57b254"), C("8a8a3a")][x % 3]
        poly(im, [(x - 2, 4), (x + 2, 4), (x + 1, 12), (x - 1, 12)], g, OUT)
    return im


def prateleira_potes():
    im = canvas(30, 16)
    box(im, 0, 12, 29, 15, WOOD, WOOD_L, WOOD_D)
    cols = [C("c4453d"), C("e8c070"), C("57b254"), C("3f6fc0"), C("a8543a")]
    x = 1
    for i in range(6):
        w = 4 if i % 2 else 3
        h = 6 + (i * 3) % 5
        box(im, x, 12 - h, x + w, 11, cols[i % 5], mix(cols[i % 5], (255, 255, 255, 255), 0.3))
        rect(im, x + 1, 12 - h - 1, x + w - 1, 12 - h, C("d8c49a"))
        x += w + 2
    return im


def janela():
    im = canvas(24, 20)
    box(im, 0, 0, 23, 19, WOOD, WOOD_L, WOOD_D)
    rect(im, 2, 2, 21, 17, C("9ad0f0"))
    vgrad(im, 2, 2, 21, 17, [C("bfe6ff"), C("8ac4e8"), C("6aa8d8")])
    vline(im, 11, 2, 17, WOOD_D)
    hline(im, 2, 21, 9, WOOD_D)
    for k in range(4):
        px(im, 4 + k, 4 + k, C("ffffff"))
    hline(im, -1, 24, 19, OUT)
    return im


def vaso_flores():
    im = canvas(12, 16)
    box(im, 3, 9, 8, 15, C("3f6fc0"), C("6a9ae0"), C("2a4a8a"))
    for (x, y, c) in ((5, 3, C("e05050")), (3, 5, C("ffd36a")), (7, 4, C("e08fb0")), (6, 6, C("ffffff"))):
        vline(im, x, y + 1, 9, C("3f8a48"))
        ellipse(im, x - 1, y - 1, x + 1, y + 1, c, OUT)
    return im


def vela():
    im = canvas(8, 12)
    box(im, 1, 9, 6, 11, GOLD, GOLD_L, C("8a6a1a"))
    box(im, 2, 4, 5, 9, C("f4ecd2"), None, C("c8b890"))
    px(im, 3, 2, FIRE[2]); px(im, 3, 3, FIRE[1]); px(im, 4, 3, FIRE[3])
    return im


def livros():
    im = canvas(14, 12)
    cols = [C("8c2f39"), C("2f5d62"), C("c7923e"), C("3d3a6b")]
    for i in range(4):
        box(im, 1 + (i % 2), 9 - i * 3, 12 - (i % 2), 11 - i * 3, cols[i], mix(cols[i], (255, 255, 255, 255), 0.25))
    return im


def caixotes():
    im = canvas(26, 26)
    for (x, y) in ((0, 12), (13, 12), (6, 0)):
        box(im, x, y, x + 12, y + 12, WOOD, WOOD_L, WOOD_D)
        line(im, (x + 1, y + 1), (x + 11, y + 11), WOOD_D, 1)
        rect(im, x + 1, y + 5, x + 11, y + 6, WOOD_L)
    return im


def banco():
    im = canvas(34, 12)
    box(im, 0, 2, 33, 6, WOOD, WOOD_L, WOOD_D)
    for x in (2, 29):
        box(im, x, 6, x + 2, 11, WOOD_D)
    return im


def estandarte(c=C("c4453d")):
    im = canvas(16, 32)
    hline(im, 0, 15, 0, GOLD)
    hline(im, 0, 15, 1, C("8a6a1a"))
    poly(im, [(2, 2), (13, 2), (13, 28), (8, 24), (2, 28)], c, OUT)
    ellipse(im, 4, 8, 11, 15, GOLD, OUT)
    px(im, 7, 11, c); px(im, 8, 11, c)
    return im


def boneco_treino():
    im = canvas(18, 30)
    vline(im, 8, 10, 29, WOOD_D); vline(im, 9, 10, 29, WOOD)
    hline(im, 1, 16, 13, WOOD_D); hline(im, 1, 16, 14, WOOD)
    ellipse(im, 4, 0, 13, 9, C("d8c49a"), OUT)
    poly(im, [(4, 10), (13, 10), (14, 22), (3, 22)], C("c8a060"), OUT)
    for y in (14, 18):
        hline(im, 4, 13, y, C("8a6a3a"))
    line(im, (6, 3), (8, 5), C("c4453d"), 1)
    line(im, (8, 3), (6, 5), C("c4453d"), 1)
    box(im, 5, 27, 12, 29, DARKW, DARKW_L, DARKW_D)
    return im


def arquibancada():
    im = canvas(64, 28)
    for r in range(3):
        y = 2 + r * 8
        box(im, r * 3, y, 63 - r * 3, y + 7, STONE, STONE_L, STONE_D)
        for x in range(4 + r * 3, 60 - r * 3, 9):
            vline(im, x, y + 1, y + 6, STONE_D)
    return im


def portao_arena():
    im = canvas(36, 36)
    box(im, 0, 0, 35, 35, STONE, STONE_L, STONE_D)
    rect(im, 5, 6, 30, 35, C("140c0a"))
    ellipse(im, 5, 2, 30, 14, C("140c0a"))
    for x in range(7, 30, 4):
        vline(im, x, 5, 35, IRON)
        px(im, x, 5, IRON_L)
    for y in (14, 24):
        hline(im, 6, 29, y, IRON_D)
    return im


def tocha_parede():
    im = canvas(10, 18)
    box(im, 3, 9, 6, 17, IRON, IRON_L, IRON_D)
    box(im, 1, 7, 8, 9, IRON_D)
    poly(im, [(1, 7), (4, 0), (8, 7)], FIRE[1])
    poly(im, [(3, 7), (4, 2), (6, 7)], FIRE[2])
    px(im, 4, 5, FIRE[3])
    return im


def cofre():
    im = canvas(16, 14)
    box(im, 0, 0, 15, 13, IRON_D, IRON, C("1a1e24"))
    ellipse(im, 5, 4, 10, 9, GOLD, OUT)
    px(im, 7, 6, OUT)
    return im


def cha():
    """Bule e xícaras sobre bandeja."""
    im = canvas(18, 10)
    box(im, 0, 7, 17, 9, WOOD, WOOD_L, WOOD_D)
    ellipse(im, 2, 1, 9, 7, C("f4ecd2"), OUT)
    rect(im, 9, 3, 11, 4, C("f4ecd2"))
    px(im, 5, 0, OUT)
    for x in (12, 15):
        box(im, x - 1, 4, x + 1, 6, C("f4ecd2"), None, C("c8b890"))
    return im


def planta_pequena():
    im = canvas(12, 14)
    box(im, 3, 8, 8, 13, C("a8543a"), C("c86a4a"), C("7a3a28"))
    for (x, y) in ((3, 2), (6, 0), (8, 3), (5, 4), (2, 5), (9, 6)):
        ellipse(im, x - 1, y, x + 2, y + 3, C("3f8a48"), OUT)
        px(im, x, y + 1, C("57b254"))
    return im


def mesa_redonda():
    im = canvas(26, 20)
    ellipse(im, 0, 0, 25, 11, OUT)
    ellipse(im, 1, 1, 24, 10, WOOD)
    ellipse(im, 3, 2, 22, 7, WOOD_L)
    box(im, 11, 10, 14, 18, WOOD_D)
    box(im, 6, 17, 19, 19, WOOD_D, WOOD)
    return im


def cama_simples():
    im = canvas(20, 32)
    box(im, 0, 0, 19, 31, WOOD, WOOD_L, WOOD_D)
    rect(im, 2, 2, 17, 29, C("e8e0d0"))
    box(im, 3, 3, 16, 9, C("f8f4ec"), None, C("c8c0b0"))
    rect(im, 2, 12, 17, 29, C("3f6fc0"))
    for y in range(14, 29, 4):
        hline(im, 2, 17, y, C("6a9ae0"))
    return im


def placa_arena():
    im = canvas(20, 26)
    vline(im, 4, 0, 4, OUT); vline(im, 15, 0, 4, OUT)
    box(im, 1, 4, 18, 24, WOOD, WOOD_L, WOOD_D)
    rect(im, 3, 6, 16, 22, C("d8b078"))
    line(im, (5, 8), (14, 20), C("c8d0d8"), 2)
    line(im, (14, 8), (5, 20), C("c8d0d8"), 2)
    return im


ALL = {
    "bigorna": bigorna, "fornalha": fornalha, "rebolo": rebolo, "tina_agua": tina_agua, "ferramentas": ferramentas,
    "carvao": carvao, "lingotes": lingotes, "fole": fole, "rack_espadas": rack_espadas, "armadura": armadura,
    "escudos_parede": escudos_parede, "lancas": lancas, "vitrine": vitrine, "barril_espadas": barril_espadas,
    "arcos_parede": arcos_parede, "manequim": manequim, "roca": roca, "tecidos": tecidos,
    "mesa_costura": mesa_costura, "novelos": novelos, "espelho": espelho, "fogao": fogao, "panelas": panelas,
    "ervas": ervas, "prateleira_potes": prateleira_potes, "janela": janela, "vaso_flores": vaso_flores,
    "vela": vela, "livros": livros, "caixotes": caixotes, "banco": banco, "estandarte": estandarte,
    "estandarte_azul": lambda: estandarte(C("3f6fc0")), "boneco_treino": boneco_treino,
    "arquibancada": arquibancada, "portao_arena": portao_arena, "tocha_parede": tocha_parede, "cofre": cofre,
    "cha": cha, "planta_pequena": planta_pequena, "mesa_redonda": mesa_redonda, "cama_simples": cama_simples,
    "placa_arena": placa_arena,
}

if __name__ == "__main__":
    random.seed(7)
    for name, fn in ALL.items():
        save(name, fn())
