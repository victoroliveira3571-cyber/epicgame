"""Gera os fundos em pixel art das cenas do Pomodoro (estilo Ninja Adventure, 1:1).

Cada cena tem duas camadas em game/assets/custom/pomodoro/:
  <cena>.png     fundo (fica atrás do herói)
  <cena>_fg.png  frente (mesa/banco que cobre as pernas do herói), com transparência

Tamanho 400x208 (múltiplos de 16 na largura e altura). O StudyScene desenha em escala 3
(1200x624) e sobe 12 px, então: x_cena = 3*x_arte e y_cena = 3*y_arte - 12.
As posições de mesa, cadeira etc. batem com onde o herói vetorial é desenhado.

Uso (da pasta game/):  python3 tools/gen_pomodoro_bg.py
"""
import os, random
from PIL import Image, ImageDraw
from pixelkit import *

W, H = 400, 208
OUTDIR = "assets/custom/pomodoro/"
PROPS = "assets/ninja/props/"
BOOK_PAL = [C("8c2f39"), C("2f5d62"), C("c7923e"), C("3d3a6b"), C("5b7a3a"), C("a8543a"), C("6b3a5a"), C("d6c08a")]
WOOD = [C("94603a"), C("b9814e"), C("6f4529"), C("4a2d1a")]   # tampo, brilho, frente, sombra


def prop(name):
    return Image.open(PROPS + name + ".png").convert("RGBA")


# ================================================================ peças comuns
def floor_planks(im, y0, colors, seam):
    vgrad(im, 0, y0, W - 1, H - 1, colors)
    r = random.Random(y0)
    y = y0 + 1
    row = 0
    while y < H:
        hline(im, 0, W - 1, y, seam)
        x = (row * 37) % 60
        while x < W:
            vline(im, x, y + 1, min(H - 1, y + 7), seam)
            x += 50 + r.randint(0, 20)
        y += 8
        row += 1
    hline(im, 0, W - 1, y0, OUT)


def bookcase(im, x0, y0, x1, y1, rows, seed, extras=None):
    box(im, x0, y0, x1, y1, C("2d1b12"))
    inner_h = (y1 - y0 - 4) // rows
    for r in range(rows):
        sy = y0 + 2 + r * inner_h
        rect(im, x0 + 3, sy + 1, x1 - 3, sy + inner_h - 3, C("1a100a"))
        if extras and r in extras:
            extras[r](im, x0 + 4, sy + 2, x1 - 4, sy + inner_h - 3)
        else:
            books(im, x0 + 4, sy + 3, x1 - 4, sy + inner_h - 3, seed + r * 7, BOOK_PAL)
        rect(im, x0 + 1, sy + inner_h - 2, x1 - 1, sy + inner_h, C("6b4430"))
        hline(im, x0 + 1, x1 - 1, sy + inner_h - 2, C("8a5a3e"))
        hline(im, x0 + 1, x1 - 1, sy + inner_h + 1, OUT)


def desk(bg, fg, x0, x1, top, legs_to, wood=WOOD):
    """Tampo no fundo (o braço do herói passa por cima) e a frente/pernas na camada da frente."""
    box(bg, x0, top, x1, top + 7, wood[0], wood[1], wood[3])
    box(fg, x0 + 4, top + 7, x1 - 4, top + 22, wood[2], mix(wood[2], (255, 255, 255, 255), 0.12), wood[3])
    hline(fg, x0 + 5, x1 - 5, top + 8, wood[3])
    for lx in (x0 + 8, x1 - 15):
        box(fg, lx, top + 22, lx + 7, legs_to, wood[2], None, wood[3])
    # gaveta
    box(fg, (x0 + x1) // 2 - 14, top + 11, (x0 + x1) // 2 + 14, top + 18, wood[0], wood[1], wood[3])
    rect(fg, (x0 + x1) // 2 - 2, top + 14, (x0 + x1) // 2 + 1, top + 15, C("e8c070"))


def chair_back(im, x, seat_y):
    box(im, x, seat_y - 46, x + 6, seat_y + 2, C("5d3a22"), C("7a4e2c"), C("3a2414"))
    box(im, x - 2, seat_y, x + 40, seat_y + 4, C("6a4228"), C("8a5a36"), C("3a2414"))
    box(im, x + 1, seat_y + 4, x + 5, seat_y + 30, C("4a2d1a"))
    box(im, x + 33, seat_y + 4, x + 37, seat_y + 30, C("4a2d1a"))


def mug(im, x, y):
    """Caneca com o fundo em (x, y)."""
    box(im, x - 4, y - 7, x + 4, y, C("c9a06a"), C("e2c28c"), C("8a6a40"))
    rect(im, x - 3, y - 6, x + 3, y - 6, C("5a3218"))
    rect(im, x + 5, y - 5, x + 6, y - 2, OUT)
    px(im, x + 5, y - 4, C("c9a06a"))


def open_book(im, x, y):
    poly(im, [(x - 1, y + 3), (x + 15, y + 1), (x + 32, y + 3), (x + 32, y + 5), (x - 1, y + 5)], C("6b2f34"))
    poly(im, [(x, y), (x + 15, y - 3), (x + 15, y + 2), (x, y + 3)], C("f6ecd2"), OUT)
    poly(im, [(x + 16, y - 3), (x + 31, y), (x + 31, y + 3), (x + 16, y + 2)], C("fff6dc"), OUT)
    for k in range(2):
        hline(im, x + 3, x + 12, y + k * 1 - 0, C("b8ae94"))
        hline(im, x + 19, x + 28, y + k * 1 - 0, C("b8ae94"))


def candle(im, x, base_y, h=12):
    box(im, x - 3, base_y - h, x + 3, base_y, C("f1e5c6"), C("fffaf0"), C("cdbf9e"))
    vline(im, x, base_y - h - 2, base_y - h, C("3a2a1a"))
    box(im, x - 5, base_y - 1, x + 5, base_y + 1, C("c9a24a"), None, C("8a6a2a"))


def cat(im, x, y, fur, dark):
    """Gato dormindo (pixel) com a base em y."""
    ellipse(im, x - 13, y - 9, x + 11, y, OUT)
    ellipse(im, x - 12, y - 8, x + 10, y - 1, fur)
    ellipse(im, x - 19, y - 9, x - 9, y - 1, OUT)
    ellipse(im, x - 18, y - 8, x - 10, y - 2, fur)
    poly(im, [(x - 18, y - 6), (x - 17, y - 11), (x - 15, y - 7)], OUT)
    poly(im, [(x - 13, y - 7), (x - 11, y - 11), (x - 10, y - 6)], OUT)
    hline(im, x - 17, x - 16, y - 5, dark)
    hline(im, x - 13, x - 12, y - 5, dark)
    for k in range(3):
        vline(im, x - 4 + k * 5, y - 7, y - 4, dark)
    rect(im, x + 10, y - 4, x + 15, y - 2, OUT)
    rect(im, x + 10, y - 3, x + 14, y - 3, fur)


def owl(im, x, y):
    hline(im, x - 12, x + 12, y + 12, C("6a4630"))
    hline(im, x - 12, x + 12, y + 13, OUT)
    ellipse(im, x - 8, y - 6, x + 8, y + 12, OUT)
    ellipse(im, x - 7, y - 5, x + 7, y + 11, C("8a6a4a"))
    ellipse(im, x - 5, y + 1, x + 5, y + 10, C("d6c0a0"))
    for sx in (-3, 3):
        ellipse(im, x + sx - 3, y - 4, x + sx + 2, y + 1, OUT)
        ellipse(im, x + sx - 2, y - 3, x + sx + 1, y, C("f4e8a0"))
        px(im, x + sx, y - 2, OUT)
    poly(im, [(x - 7, y - 5), (x - 6, y - 9), (x - 3, y - 6)], OUT)
    poly(im, [(x + 7, y - 5), (x + 6, y - 9), (x + 3, y - 6)], OUT)
    px(im, x, y + 1, C("e0a040"))
    px(im, x, y + 2, C("e0a040"))


def hanging_plant(im, x, y_top, length):
    vline(im, x, 0, y_top, C("2a1a10"))
    box(im, x - 9, y_top, x + 9, y_top + 10, C("a8543a"), C("c86a4a"), C("7a3a28"))
    r = random.Random(x)
    for k in range(9):
        lx = x - 10 + k * 2 + r.randint(-1, 1)
        ln = r.randint(length // 2, length)
        for j in range(ln):
            px(im, lx + (1 if (j // 4) % 2 else 0), y_top + 9 + j, C("3f8a48") if j % 3 else C("2c6a36"))
        px(im, lx, y_top + 9 + ln, C("57b254"))


def lamp(im, x, base_y, shade):
    box(im, x - 7, base_y - 2, x + 7, base_y, C("2a2a2a"))
    for k in range(18):
        px(im, x - k // 6, base_y - 3 - k, C("c9a24a"))
    for k in range(9):
        px(im, x - 3 + k, base_y - 21 - k // 2, C("c9a24a"))
    poly(im, [(x + 2, base_y - 30), (x + 14, base_y - 28), (x + 18, base_y - 21), (x + 5, base_y - 21)], shade, OUT)


def glow_patch(im, cx, cy, r, color, strength=0.35):
    """Clarão em 3 anéis chapados (faixas de luz, sem degradê suave)."""
    p = im.load()
    for y in range(max(0, cy - r), min(H, cy + r + 1)):
        for x in range(max(0, cx - r), min(W, cx + r + 1)):
            if p[x, y][3] == 0:
                continue
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / r
            if d < 0.36:
                t = strength
            elif d < 0.68:
                t = strength * 0.6
            elif d < 1.0:
                t = strength * 0.3
            else:
                continue
            p[x, y] = mix(p[x, y], color, t)


def light_poly(im, pts, color, strength=0.18):
    """Facho de luz chapado (só no chão, para não sujar a parede)."""
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    m = mask.load()
    p = im.load()
    for y in range(160, H):
        for x in range(W):
            if m[x, y]:
                p[x, y] = mix(p[x, y], color, strength)


def cloud(im, x, y, w, c, shade):
    for i in range(0, w, 7):
        r = 6 + (i * 13 % 5)
        ellipse(im, x + i - r, y - r, x + i + r, y + r // 2, c)
    hline(im, x - 6, x + w + 4, y + 3, shade)


# ================================================================ LIVRARIA
def livraria():
    bg, fg = canvas(W, H), canvas(W, H)
    vgrad(bg, 0, 0, W - 1, 160, [C("3a2418"), C("4a2c1e"), C("5b3a28")])
    box(bg, -2, 0, W + 1, 6, C("2d1b12"), C("4a3022"))
    # janela em arco com sol da tarde
    sky = canvas(W, H)
    vgrad(sky, 150, 2, 250, 104, [C("ffe6a8"), C("ffd78a"), C("f9b468"), C("f6a35a")])
    ellipse(sky, 212, 50, 232, 70, C("fff4c8"))
    cloud(sky, 160, 34, 22, C("fff8e8"), C("f0d8b0"))
    cloud(sky, 206, 84, 26, C("fff0d8"), C("f0c898"))
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    d.rectangle([152, 52, 248, 104], fill=255)
    d.ellipse([152, 4, 248, 100], fill=255)
    bg.paste(sky, (0, 0), mask)
    ring = Image.new("L", (W, H), 0)
    ImageDraw.Draw(ring).ellipse([148, 0, 252, 104], fill=255)
    ImageDraw.Draw(ring).ellipse([152, 4, 248, 100], fill=0)
    ImageDraw.Draw(ring).rectangle([152, 52, 248, 104], fill=0)
    bg.paste(Image.new("RGBA", (W, H), C("3a2418")), (0, 0), ring)
    rect(bg, 148, 52, 151, 106, C("3a2418"))
    rect(bg, 249, 52, 252, 106, C("3a2418"))
    rect(bg, 198, 4, 201, 104, C("3a2418"))
    rect(bg, 152, 66, 248, 68, C("3a2418"))
    box(bg, 144, 104, 256, 109, C("5a3a28"), C("7a4e32"), C("3a2418"))
    # estantes
    bookcase(bg, 0, 6, 106, 161, 5, 11)
    bookcase(bg, 293, 6, 399, 161, 5, 53)
    floor_planks(bg, 160, [C("6b4630"), C("5a3a26"), C("3d2618")], C("2e1c12"))
    light_poly(bg, [(156, 110), (246, 110), (330, 190), (186, 190)], C("ffe2a0"), 0.22)
    # escada encostada
    for k in range(130):
        y = 26 + k
        x = 100 + k * 24 // 130
        px(bg, x, y, C("a8743f"))
        px(bg, x + 1, y, OUT)
        px(bg, x + 10, y, C("a8743f"))
        px(bg, x + 11, y, OUT)
        if k % 14 == 0:
            hline(bg, x + 1, x + 10, y, C("7a4e2c"))
    # lanterna
    vline(bg, 200, 0, 12, C("2a1a10"))
    box(bg, 195, 12, 205, 27, C("c58a3a"), C("e0a85a"), C("8a5a2a"))
    rect(bg, 197, 15, 203, 24, C("ffe8a0"))
    glow_patch(bg, 200, 22, 30, C("ffd27a"), 0.22)
    # cadeira, mesa e coisas na mesa
    chair_back(bg, 137, 153)
    desk(bg, fg, 172, 348, 140, 190)
    # sem livro aberto na mesa: o herói lê o livro que segura (evita livro duplicado)
    for k, c in enumerate([C("8c2f39"), C("2f5d62"), C("c7923e"), C("3d3a6b")]):
        box(bg, 258 + k, 133 - k * 6, 290 - k, 139 - k * 6, c, mix(c, C("ffffff"), 0.25), mix(c, C("000000"), 0.3))
    mug(bg, 234, 140)
    lamp(bg, 312, 140, C("7a9a52"))
    glow_patch(bg, 318, 124, 22, C("ffe4a0"), 0.2)
    cat(bg, 333, 140, C("d98f4a"), C("8a4a20"))
    return bg, fg


# ================================================================ CAFETERIA
def cafeteria():
    bg, fg = canvas(W, H), canvas(W, H)
    vgrad(bg, 0, 0, W - 1, 30, [C("1e140e"), C("2a1a12"), C("3a2418")])
    # parede de pedra
    rect(bg, 0, 31, W - 1, 160, C("4a3b36"))
    r = random.Random(4)
    stone = [C("6b5a52"), C("625249"), C("71605a"), C("5e4f48")]
    for row in range(10):
        y = 33 + row * 13
        off = 0 if row % 2 == 0 else 13
        x = -off
        while x < W:
            w = 24 + r.randint(0, 6)
            c = stone[r.randrange(len(stone))]
            rect(bg, x + 1, y + 1, x + w - 1, y + 11, c)
            hline(bg, x + 2, x + w - 3, y + 2, mix(c, C("ffffff"), 0.12))
            hline(bg, x + 1, x + w - 1, y + 11, mix(c, C("000000"), 0.25))
            x += w + 1
    box(bg, -2, 26, W + 1, 34, C("3a2418"), C("6a4630"), C("241610"))
    for x in (72, 208):
        box(bg, x, 30, x + 8, 160, C("3a2418"), None, C("241610"))
        vline(bg, x + 2, 31, 159, C("5a3a28"))
    # janela com a vila ao entardecer
    vgrad(bg, 27, 54, 90, 127, [C("5b7fb8"), C("8f9fc8"), C("e8b07a"), C("f0b472")])
    ellipse(bg, 62, 62, 74, 74, C("fff0c8"))
    for i in range(5):
        hx = 29 + i * 12
        hh = 14 + (i * 7) % 12
        rect(bg, hx, 127 - hh, hx + 10, 127, C("2a2438"))
        poly(bg, [(hx - 1, 127 - hh), (hx + 5, 120 - hh), (hx + 11, 127 - hh)], C("3a2f4a"))
        rect(bg, hx + 4, 131 - hh, hx + 6, 133 - hh, C("ffd27a"))
    for (bx, by) in ((40, 70), (52, 64), (80, 76)):
        px(bg, bx - 1, by - 1, C("2a2438"))
        px(bg, bx, by, C("2a2438"))
        px(bg, bx + 1, by - 1, C("2a2438"))
    rect(bg, 24, 51, 93, 53, C("2a1a12"))
    rect(bg, 24, 128, 93, 131, C("2a1a12"))
    rect(bg, 24, 51, 26, 131, C("2a1a12"))
    rect(bg, 91, 51, 93, 131, C("2a1a12"))
    rect(bg, 57, 54, 59, 127, C("2a1a12"))
    rect(bg, 27, 89, 90, 91, C("2a1a12"))
    box(bg, 20, 130, 97, 134, C("5a3a28"), C("7a4e32"), C("2a1a12"))
        # lareira (o fogo é animado por cima)
    fx0, fx1 = 300, 388
    box(bg, fx0, 56, fx1, 161, C("5a4a44"))
    for row in range(8):
        y = 58 + row * 12
        off = 0 if row % 2 == 0 else 8
        for x in range(fx0 + 2 - off, fx1 - 2, 16):
            if x >= fx0 + 1:
                rect(bg, x + 1, y + 1, min(fx1 - 2, x + 14), y + 10, C("6a5650") if (x + row) % 3 else C("7a645a"))
    box(bg, fx0 - 6, 48, fx1 + 6, 56, C("7a645a"), C("9a847a"), C("4a3a34"))
    rect(bg, 314, 98, 372, 160, C("120c0c"))
    ellipse(bg, 314, 84, 372, 112, C("120c0c"))
    for k, (x0, x1) in enumerate(((316, 350), (330, 366))):
        box(bg, x0, 153 - k * 3, x1, 158 - k * 3, C("6a4428"), C("8a5a36"), C("3a2418"))
    glow_patch(bg, 343, 140, 60, C("ff9a40"), 0.4)
    # ervas e panelas na viga
    for i in range(6):
        hx = 108 + i * 24
        vline(bg, hx, 34, 44, C("2a1a12"))
        if i % 3 == 0:
            box(bg, hx - 5, 44, hx + 5, 52, C("8a8a92"), C("aaaab4"), C("5a5a62"))
        elif i % 3 == 1:
            for k in range(3):
                for j in range(12):
                    px(bg, hx - 2 + k * 2, 44 + j, C("5b8a3a") if j % 3 else C("3e6a2a"))
        else:
            ellipse(bg, hx - 3, 44, hx + 3, 53, C("f1e3c4"), OUT)
    # lustre (as chamas são animadas)
    vline(bg, 203, 30, 38, C("1d1410"))
    for k in range(41):
        px(bg, 183 + k, 46 - abs(20 - k) // 4, C("2a1d16"))
        px(bg, 183 + k, 47 - abs(20 - k) // 4, OUT)
    for k in range(5):
        cx = 185 + k * 9
        cy = 42 - abs(2 - k)
        box(bg, cx - 1, cy - 5, cx + 1, cy, C("f4e8c8"))
    floor_planks(bg, 160, [C("5a3a26"), C("47301f"), C("2e1c12")], C("221510"))
    # barris
    for bx in (14, 40):
        box(bg, bx - 11, 140, bx + 11, 176, C("7a4e2c"), C("9a6a3c"), C("4a2d1a"))
        hline(bg, bx - 10, bx + 10, 147, C("3a2418"))
        hline(bg, bx - 10, bx + 10, 168, C("3a2418"))
        vline(bg, bx - 6, 142, 174, C("8a5a34"))
    # banco e mesa
    box(bg, 140, 152, 197, 157, C("6a4228"), C("8a5a36"), C("3a2414"))
    box(bg, 145, 157, 150, 188, C("4a2d1a"))
    box(bg, 186, 157, 191, 188, C("4a2d1a"))
    desk(bg, fg, 180, 296, 145, 198, [C("8a5a36"), C("b07a4a"), C("5a361f"), C("3a2414")])
    poly(bg, [(187, 146), (222, 146), (226, 141), (191, 141)], C("f4e8c8"), OUT)
    box(bg, 249, 140, 273, 146, C("e6d5b0"), C("fff2d8"), C("b8a888"))
    ellipse(bg, 252, 133, 270, 144, OUT)
    ellipse(bg, 253, 134, 269, 143, C("c58a4a"))
    hline(bg, 256, 266, 136, C("e0a868"))
    candle(bg, 284, 145, 16)
    mug(bg, 237, 145)
    # caldeirão na frente do fogo (camada da frente)
    vline(fg, 312, 70, 116, C("2a2a2a"))
    hline(fg, 312, 330, 116, C("2a2a2a"))
    ellipse(fg, 318, 116, 344, 136, OUT)
    ellipse(fg, 319, 117, 343, 135, C("2e2e34"))
    ellipse(fg, 320, 116, 342, 121, C("5a8a4a"))
    hline(fg, 322, 340, 118, C("7ab05a"))
    return bg, fg


# ================================================================ NATUREZA
def natureza():
    bg, fg = canvas(W, H), canvas(W, H)
    vgrad(bg, 0, 0, W - 1, 130, [C("5fb4e8"), C("79c6ee"), C("a8dcf0"), C("e8f2d8"), C("fdf1c4")])
    # sol com halo pontilhado
    glow_patch(bg, 310, 44, 40, C("fff6c8"), 0.45)
    ellipse(bg, 293, 27, 327, 61, C("fff6cc"))
    ellipse(bg, 297, 31, 323, 57, C("ffe892"))
    clouds = raw("FX/Particle/Clouds.png")
    paste(bg, clouds, 20, 12)
    paste(bg, clouds.resize((52, 24), Image.NEAREST), 220, 22)
    cloud(bg, 120, 46, 30, C("ffffff"), C("dfe8f0"))
    # montanhas ao longe
    poly(bg, [(0, 112), (40, 78), (78, 98), (132, 64), (186, 102), (240, 82), (300, 108), (350, 84), (400, 104), (400, 124), (0, 124)], C("8aa6cf"))
    for (mx, my) in ((132, 64), (40, 78), (240, 82), (350, 84)):
        poly(bg, [(mx - 8, my + 8), (mx, my), (mx + 8, my + 8), (mx + 4, my + 6), (mx, my + 9), (mx - 4, my + 6)], C("e6eef8"))
    poly(bg, [(0, 118), (52, 98), (110, 114), (172, 92), (252, 116), (320, 96), (400, 118), (400, 130), (0, 130)], C("6c9a8c"))
    # colinas
    pts = [(0, 207)] + [(x, int(126 + 6 * __import__("math").sin(x / 16.0) + 4 * __import__("math").sin(x / 37.0))) for x in range(0, 401, 4)] + [(400, 207)]
    poly(bg, pts, C("7fbf5a"))
    # lago
    vgrad(bg, 150, 131, W - 1, 151, [C("8ad4f0"), C("6cc3e8"), C("3f95c4")])
    hline(bg, 150, W - 1, 131, C("dff4ff"))
    poly(bg, [(150, 131), (146, 151), (150, 151)], C("e8d8a0"))
    for i in range(14):
        x = 160 + i * 17 % 230
        hline(bg, x, x + 6, 134 + (i * 5) % 14, C("bfe8ff"))
    # pradaria
    vgrad(bg, 0, 148, W - 1, H - 1, [C("8ccb5e"), C("74b84f"), C("5aa448"), C("4f9a42")])
    edge = [(0, 152)] + [(x, 148 + (2 if (x // 8) % 2 else 0)) for x in range(0, 401, 8)] + [(400, 152), (400, 160), (0, 160)]
    poly(bg, edge, C("86c45a"))
    r = random.Random(9)
    for _ in range(150):
        gx, gy = r.randint(0, W - 1), r.randint(154, H - 1)
        if 128 < gx < 285 and 168 < gy < 194:
            continue
        c = C("3f8a38") if r.random() < 0.6 else C("5aa84a")
        px(bg, gx, gy, c)
        px(bg, gx - 1, gy - 1, c)
        px(bg, gx + 1, gy - 1, c)
    for _ in range(40):
        fx, fy = r.randint(0, W - 1), r.randint(156, H - 1)
        if 128 < fx < 285 and 166 < fy < 196:
            continue
        c = [C("ffffff"), C("ffd54a"), C("ff7a9a"), C("b58cff")][r.randrange(4)]
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            px(bg, fx + dx, fy + dy, c)
        px(bg, fx, fy, C("ffb020"))
    # árvore grande
    tx = 83
    box(bg, tx - 7, 108, tx + 7, 178, C("6a4630"), None, C("4a2d1a"))
    vline(bg, tx - 3, 110, 176, C("8a5e40"))
    poly(bg, [(tx - 7, 172), (tx - 15, 180), (tx + 15, 180), (tx + 7, 172)], C("6a4630"), OUT)
    greens = [C("2f7a3a"), C("3f9a44"), C("57b254"), C("86d46a")]
    blobs = [(-30, -6, 24), (0, -18, 28), (30, -6, 24), (-18, 14, 22), (18, 14, 22), (0, 4, 26)]
    for (dx, dy, rr) in blobs:
        ellipse(bg, tx + dx - rr - 1, 90 + dy - rr - 1, tx + dx + rr + 1, 90 + dy + rr + 1, OUT)
    for layer, g in enumerate(greens[:3]):
        for (dx, dy, rr) in blobs:
            rr2 = rr - layer * 5
            ellipse(bg, tx + dx - rr2 - layer * 2, 90 + dy - rr2 - layer * 3, tx + dx + rr2 - layer * 2, 90 + dy + rr2 - layer * 3, g)
    rr = random.Random(21)
    for k in range(26):
        hx = tx - 36 + rr.randint(0, 60)
        hy = 64 + rr.randint(0, 30)
        if bg.getpixel((hx, hy)) in (greens[1], greens[2]):
            px(bg, hx, hy, greens[3])
            px(bg, hx + 1, hy, greens[3])
    ellipse(bg, tx - 50, 176, tx + 50, 184, C("4a8a3a"))
    # sombra da copa e manchas de luz
    for k in range(8):
        sx = 110 + k * 22
        ellipse(bg, sx, 186 + (k % 3) * 5, sx + 10, 189 + (k % 3) * 5, C("a4dc78"))
    # manta, cesto e chá
    poly(bg, [(147, 173), (260, 173), (277, 191), (133, 191)], C("c4453d"), OUT)
    for k in range(9):
        x = 151 + k * 14
        poly(bg, [(x, 174), (x + 5, 174), (x + 3 - k // 3, 190), (x - 2 - k // 3, 190)], C("e8e0d0"))
    for y in (179, 185):
        hline(bg, 140, 270, y, C("e8e0d0"))
    box(bg, 233, 168, 257, 181, C("b9854a"), C("d8a868"), C("7a5230"))
    for k in range(25):
        px(bg, 233 + k, 168 - int(8 * (1 - ((k - 12) / 12.0) ** 2)), C("7a5230"))
    box(bg, 260, 174, 270, 184, C("f4f0e4"), C("ffffff"), C("c8c0b0"))
    px(bg, 271, 177, OUT)
    px(bg, 272, 178, OUT)
    return bg, fg


# ================================================================ TORRE DE ESTUDO (dia e noite)
def estudo(noite):
    bg, fg = canvas(W, H), canvas(W, H)
    if noite:
        vgrad(bg, 0, 0, W - 1, 160, [C("171a33"), C("1c1f3a"), C("23264a")])
        wains = [C("2c2440"), C("3a2a3a")]
    else:
        vgrad(bg, 0, 0, W - 1, 160, [C("b48a64"), C("c9a27a"), C("d4b089")])
        wains = [C("6b4430"), C("8a5a3e")]
    # lambri
    rect(bg, 0, 118, W - 1, 160, wains[0])
    hline(bg, 0, W - 1, 118, OUT)
    hline(bg, 0, W - 1, 119, wains[1])
    for x in range(0, W, 32):
        vline(bg, x, 120, 159, OUT)
        vline(bg, x + 1, 120, 159, wains[1])
    # janela
    wx0, wy0, wx1, wy1 = 110, 27, 237, 127
    if noite:
        vgrad(bg, wx0, wy0, wx1, wy1, [C("0d1230"), C("1a2350"), C("2b3668")])
        stars(bg, wx0 + 2, wy0 + 2, wx1 - 2, wy0 + 60, 50, 3, [C("ffffe8"), C("c8d8ff"), C("fff2b0")])
        glow_patch(bg, 200, 50, 26, C("c8d8ff"), 0.4)
        ellipse(bg, 189, 39, 211, 61, C("f0f4ff"))
        ellipse(bg, 195, 35, 217, 57, C("141a3c"))
        for i in range(4):
            cloud(bg, 116 + i * 30, 78 + (i % 2) * 14, 18, C("3a4478"), C("2a3264"))
    else:
        vgrad(bg, wx0, wy0, wx1, wy1, [C("6ab8ec"), C("8fd0f2"), C("cfeaf2")])
        cloud(bg, 122, 50, 26, C("ffffff"), C("dfe8f0"))
        cloud(bg, 178, 40, 20, C("ffffff"), C("dfe8f0"))
        poly(bg, [(wx0, 110), (140, 96), (170, 106), (205, 92), (wx1, 104), (wx1, wy1), (wx0, wy1)], C("7fbf5a"))
        box(bg, 210, 76, 222, 104, C("b8a890"), C("d8c8b0"), C("8a7a64"))
        poly(bg, [(208, 76), (216, 64), (224, 76)], C("a8543a"), OUT)
        rect(bg, 215, 84, 217, 88, OUT)
    for (a, b, c, d) in ((wx0 - 4, wy0 - 4, wx1 + 4, wy0 - 1), (wx0 - 4, wy1 + 1, wx1 + 4, wy1 + 4),
                         (wx0 - 4, wy0 - 4, wx0 - 1, wy1 + 4), (wx1 + 1, wy0 - 4, wx1 + 4, wy1 + 4),
                         (172, wy0, 175, wy1), (wx0, 74, wx1, 77)):
        rect(bg, a, b, c, d, C("4a3022"))
    box(bg, wx0 - 8, wy1 + 3, wx1 + 8, wy1 + 8, C("5a3a28"), C("7a4e32"), C("3a2418"))
    # estante com globo e poções
    def globe(im, x0, y0, x1, y1):
        ellipse(im, x0 + 2, y0 + 2, x0 + 22, y1 - 3, OUT)
        ellipse(im, x0 + 3, y0 + 3, x0 + 21, y1 - 4, C("3a6a9a"))
        ellipse(im, x0 + 6, y0 + 7, x0 + 13, y0 + 13, C("8ab87a"))
        rect(im, x0 + 11, y1 - 3, x0 + 13, y1, C("c9a24a"))
        for k, c in enumerate((C("6ad0a0"), C("d06a9a"), C("6aa0d0"))):
            bx = x0 + 34 + k * 14
            box(im, bx, y0 + 8, bx + 9, y1, c, mix(c, C("ffffff"), 0.35), mix(c, C("000000"), 0.3))
            rect(im, bx + 3, y0 + 5, bx + 6, y0 + 8, C("c8b090"))
    bookcase(bg, 283, 24, 383, 161, 4, 77, {1: globe})
    owl(bg, 362, 13)
    floor_planks(bg, 160, [C("3a2a3a"), C("2c202c"), C("1c141c")] if noite else [C("7a5236"), C("6a462e"), C("4a2e1e")], C("140e14") if noite else C("3a2414"))
    if noite:
        light_poly(bg, [(110, 128), (237, 128), (300, 190), (60, 190)], C("8aa0ff"), 0.12)
    else:
        light_poly(bg, [(110, 128), (237, 128), (300, 190), (60, 190)], C("fff0c0"), 0.22)
    # tapete
    ellipse(bg, 78, 168, 268, 190, OUT)
    ellipse(bg, 79, 169, 267, 189, C("5a2a4a"))
    ellipse(bg, 92, 172, 254, 186, C("7a3a5a"))
    ellipse(bg, 110, 175, 236, 183, C("5a2a4a"))
    # plantas penduradas
    hanging_plant(bg, 30, 40, 26)
    hanging_plant(bg, 70, 52, 20)
    # cadeira, mesa e objetos
    chair_back(bg, 127, 151)
    desk(bg, fg, 162, 350, 143, 192, [C("7a4e30"), C("a06c44"), C("55341f"), C("33200f")])
    poly(bg, [(173, 145), (213, 145), (217, 139), (178, 139)], C("efe3c2"), OUT)
    for k in range(3):
        box(bg, 233 + k * 2, 138 - k * 4, 270 + k * 2, 143 - k * 4, C("efe3c2"), C("fffaf0"), C("c8b898"))
    mug(bg, 293, 144)
    box(bg, 314, 136, 320, 143, C("1a1a2a"))
    line(bg, (318, 136), (325, 122), C("f5f0e6"))
    candle(bg, 334, 143, 14)
    if noite:
        glow_patch(bg, 334, 126, 40, C("ffb860"), 0.3)
    return bg, fg


def limit_palette(im, n=32):
    """Reduz para no máximo n cores (sem pontilhado), mantendo a transparência."""
    alpha = im.getchannel("A")
    q = im.convert("RGB").quantize(colors=n, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(alpha.point(lambda a: 255 if a > 0 else 0))
    return q


def save(name, pair):
    bg, fg = limit_palette(pair[0]), limit_palette(pair[1], 16)
    bg.save(OUTDIR + name + ".png")
    if fg.getbbox():
        fg.save(OUTDIR + name + "_fg.png")
    elif os.path.exists(OUTDIR + name + "_fg.png"):
        os.remove(OUTDIR + name + "_fg.png")
    print(f"{name}: {count_colors(bg)} cores no fundo, {count_colors(fg)} na frente")


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    save("livraria", livraria())
    save("cafeteria", cafeteria())
    save("natureza", natureza())
    save("estudo", estudo(False))
    save("estudo_noite", estudo(True))
