"""Gera os fundos em pixel art das cenas do Pomodoro (estilo Ninja Adventure, 1:1).

Cada cena tem duas camadas em game/assets/custom/pomodoro/:
  <cena>.png     fundo (fica atrás do herói)
  <cena>_fg.png  frente (mesa/banco que cobre as pernas do herói), com transparência

Tamanho 400x208 (múltiplos de 16 na largura e altura). O StudyScene desenha em escala 3
(1200x624) e sobe 12 px, então: x_cena = 3*x_arte e y_cena = 3*y_arte - 12.
Mesa, cadeira e herói formam um grupo centralizado em x ~ 200 (StudyScene.LAYOUT usa as mesmas
coordenadas: quadril do herói em HIP[cena]). Caneca e livro NÃO são pintados: o StudyScene
desenha os dois (um na mão, o outro na mesa) para o herói poder trocar.

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
# quadril do herói (x, y) em pixels de arte; cadeira em x-23, tampo da mesa de x+12 em diante
HIP = {"livraria": (145, 148), "cafeteria": (145, 153), "estudo": (145, 151), "natureza": (165, 177),
       "casa": (145, 150), "taverna": (145, 153), "cela": (145, 151)}


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


def wall_clock(im, x, y):
    """Relógio de pêndulo na parede, com o centro do mostrador em (x, y)."""
    box(im, x - 9, y - 11, x + 9, y + 30, C("5a3a22"), C("7a4e2c"), C("3a2414"))
    ellipse(im, x - 7, y - 7, x + 7, y + 7, OUT)
    ellipse(im, x - 6, y - 6, x + 6, y + 6, C("f4ead0"))
    for (dx, dy) in ((0, -5), (5, 0), (0, 5), (-5, 0)):
        px(im, x + dx, y + dy, C("5a3a22"))
    vline(im, x, y - 4, y, OUT)
    hline(im, x, x + 3, y, OUT)
    rect(im, x - 5, y + 10, x + 5, y + 27, C("2a1a10"))
    vline(im, x, y + 10, y + 22, C("c9a24a"))
    ellipse(im, x - 3, y + 21, x + 3, y + 26, C("c9a24a"), OUT)


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
    # escada encostada na estante da esquerda
    for k in range(130):
        y = 26 + k
        x = 64 + k * 24 // 130
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
    # cadeira, mesa e coisas na mesa (caneca e livro: StudyScene)
    hx, hy = HIP["livraria"]
    chair_back(bg, hx - 23, hy + 5)
    desk(bg, fg, hx + 12, hx + 146, hy - 8, 190)
    for k, c in enumerate([C("8c2f39"), C("2f5d62"), C("c7923e"), C("3d3a6b")]):
        box(bg, 205 + k, 133 - k * 6, 235 - k, 139 - k * 6, c, mix(c, C("ffffff"), 0.25), mix(c, C("000000"), 0.3))
    lamp(bg, 250, 140, C("7a9a52"))
    glow_patch(bg, 256, 124, 22, C("ffe4a0"), 0.2)
    cat(bg, 280, 140, C("d98f4a"), C("8a4a20"))
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
    # banco e mesa (caneca e livro: StudyScene)
    hx, hy = HIP["cafeteria"]
    box(bg, hx - 22, hy - 1, hx + 18, hy + 4, C("6a4228"), C("8a5a36"), C("3a2414"))
    box(bg, hx - 17, hy + 4, hx - 12, 188, C("4a2d1a"))
    desk(bg, fg, hx + 12, hx + 138, hy - 8, 198, [C("8a5a36"), C("b07a4a"), C("5a361f"), C("3a2414")])
    box(bg, 234, 140, 258, 146, C("e6d5b0"), C("fff2d8"), C("b8a888"))
    ellipse(bg, 237, 133, 255, 144, OUT)
    ellipse(bg, 238, 134, 254, 143, C("c58a4a"))
    hline(bg, 241, 251, 136, C("e0a868"))
    candle(bg, 270, 145, 16)
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
    # manta e cesto (caneca e livro: StudyScene)
    poly(bg, [(147, 173), (260, 173), (277, 191), (133, 191)], C("c4453d"), OUT)
    for k in range(9):
        x = 151 + k * 14
        poly(bg, [(x, 174), (x + 5, 174), (x + 3 - k // 3, 190), (x - 2 - k // 3, 190)], C("e8e0d0"))
    for y in (179, 185):
        hline(bg, 140, 270, y, C("e8e0d0"))
    box(bg, 232, 168, 256, 181, C("b9854a"), C("d8a868"), C("7a5230"))
    for k in range(25):
        px(bg, 232 + k, 168 - int(8 * (1 - ((k - 12) / 12.0) ** 2)), C("7a5230"))
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
    wx0, wy0, wx1, wy1 = 137, 27, 264, 127
    if noite:
        vgrad(bg, wx0, wy0, wx1, wy1, [C("0d1230"), C("1a2350"), C("2b3668")])
        stars(bg, wx0 + 2, wy0 + 2, wx1 - 2, wy0 + 60, 50, 3, [C("ffffe8"), C("c8d8ff"), C("fff2b0")])
        glow_patch(bg, 227, 50, 26, C("c8d8ff"), 0.4)
        ellipse(bg, 216, 39, 238, 61, C("f0f4ff"))
        ellipse(bg, 222, 35, 244, 57, C("141a3c"))
        for i in range(4):
            cloud(bg, 143 + i * 30, 78 + (i % 2) * 14, 18, C("3a4478"), C("2a3264"))
    else:
        vgrad(bg, wx0, wy0, wx1, wy1, [C("6ab8ec"), C("8fd0f2"), C("cfeaf2")])
        cloud(bg, 149, 50, 26, C("ffffff"), C("dfe8f0"))
        cloud(bg, 205, 40, 20, C("ffffff"), C("dfe8f0"))
        poly(bg, [(wx0, 110), (167, 96), (197, 106), (232, 92), (wx1, 104), (wx1, wy1), (wx0, wy1)], C("7fbf5a"))
        box(bg, 237, 76, 249, 104, C("b8a890"), C("d8c8b0"), C("8a7a64"))
        poly(bg, [(235, 76), (243, 64), (251, 76)], C("a8543a"), OUT)
        rect(bg, 242, 84, 244, 88, OUT)
    for (a, b, c, d) in ((wx0 - 4, wy0 - 4, wx1 + 4, wy0 - 1), (wx0 - 4, wy1 + 1, wx1 + 4, wy1 + 4),
                         (wx0 - 4, wy0 - 4, wx0 - 1, wy1 + 4), (wx1 + 1, wy0 - 4, wx1 + 4, wy1 + 4),
                         ((wx0 + wx1) // 2 - 1, wy0, (wx0 + wx1) // 2 + 2, wy1), (wx0, 74, wx1, 77)):
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
    bookcase(bg, 296, 24, 392, 161, 4, 77, {1: globe})
    owl(bg, 374, 13)
    floor_planks(bg, 160, [C("3a2a3a"), C("2c202c"), C("1c141c")] if noite else [C("7a5236"), C("6a462e"), C("4a2e1e")], C("140e14") if noite else C("3a2414"))
    if noite:
        light_poly(bg, [(137, 128), (264, 128), (327, 190), (87, 190)], C("8aa0ff"), 0.12)
    else:
        light_poly(bg, [(137, 128), (264, 128), (327, 190), (87, 190)], C("fff0c0"), 0.22)
    # tapete centralizado
    ellipse(bg, 105, 168, 295, 190, OUT)
    ellipse(bg, 106, 169, 294, 189, C("5a2a4a"))
    ellipse(bg, 119, 172, 281, 186, C("7a3a5a"))
    ellipse(bg, 137, 175, 263, 183, C("5a2a4a"))
    # plantas penduradas e relógio de parede (o tique-taque do Pomodoro)
    hanging_plant(bg, 26, 40, 26)
    hanging_plant(bg, 62, 52, 20)
    wall_clock(bg, 104, 58)
    # cadeira, mesa e objetos (caneca e livro: StudyScene)
    hx, hy = HIP["estudo"]
    chair_back(bg, hx - 23, hy)
    desk(bg, fg, hx + 12, hx + 146, hy - 8, 192, [C("7a4e30"), C("a06c44"), C("55341f"), C("33200f")])
    for k in range(3):
        box(bg, 222 + k * 2, 138 - k * 4, 254 + k * 2, 143 - k * 4, C("efe3c2"), C("fffaf0"), C("c8b898"))
    box(bg, 262, 136, 268, 143, C("1a1a2a"))
    line(bg, (266, 136), (273, 122), C("f5f0e6"))
    candle(bg, 280, 143, 14)
    if noite:
        glow_patch(bg, 280, 126, 40, C("ffb860"), 0.3)
    return bg, fg


# ================================================================ CASA (quarto do herói)
def casa():
    bg, fg = canvas(W, H), canvas(W, H)
    # papel de parede listrado e lambri
    rect(bg, 0, 0, W - 1, 160, C("c9b48a"))
    for x in range(0, W, 12):
        rect(bg, x, 0, x + 5, 118, C("bfa87e"))
    box(bg, -2, 0, W + 1, 5, C("6b4430"), C("8a5a3e"))
    rect(bg, 0, 118, W - 1, 160, C("7a5236"))
    hline(bg, 0, W - 1, 118, OUT)
    hline(bg, 0, W - 1, 119, C("9a6a44"))
    for x in range(0, W, 26):
        vline(bg, x, 120, 159, OUT)
        vline(bg, x + 1, 120, 159, C("8a5e3e"))
    # janela central com cortinas (fim de tarde)
    wx0, wy0, wx1, wy1 = 152, 28, 248, 104
    vgrad(bg, wx0, wy0, wx1, wy1, [C("7aa8e0"), C("a8c4ea"), C("f4c890"), C("f0a070")])
    cloud(bg, 160, 50, 22, C("fff4e8"), C("e8d0c0"))
    for i in range(6):
        hx = 154 + i * 16
        hh = 8 + (i * 5) % 9
        rect(bg, hx, wy1 - hh, hx + 12, wy1, C("4a3a5a"))
        rect(bg, hx + 5, wy1 - hh + 3, hx + 6, wy1 - hh + 4, C("ffd27a"))
    for (a, b, c, d) in ((wx0 - 4, wy0 - 4, wx1 + 4, wy0 - 1), (wx0 - 4, wy1 + 1, wx1 + 4, wy1 + 4),
                         (wx0 - 4, wy0 - 4, wx0 - 1, wy1 + 4), (wx1 + 1, wy0 - 4, wx1 + 4, wy1 + 4),
                         (198, wy0, 201, wy1), (wx0, 64, wx1, 66)):
        rect(bg, a, b, c, d, C("5a3a28"))
    box(bg, wx0 - 8, wy1 + 3, wx1 + 8, wy1 + 8, C("6a4430"), C("8a5a3e"), C("3a2418"))
    hline(bg, wx0 - 14, wx1 + 14, wy0 - 9, C("3a2418"))
    for side in (0, 1):
        x0 = wx0 - 14 if side == 0 else wx1 - 6
        box(bg, x0, wy0 - 8, x0 + 20, wy1 + 14, C("b8454a"), C("d8656a"), C("7a2a30"))
        for k in range(3):
            vline(bg, x0 + 5 + k * 5, wy0 - 6, wy1 + 12, C("9a3a40"))
    # cama à esquerda
    box(bg, 6, 108, 16, 168, C("6a4228"), C("8a5a36"), C("3a2414"))
    box(bg, 14, 136, 92, 162, C("e8dcc8"), C("fff6e8"), C("b8a890"))
    box(bg, 18, 126, 40, 138, C("f4f0e4"), C("ffffff"), C("c8c0b0"))
    box(bg, 38, 132, 92, 160, C("4a6a9a"), C("6a8aba"), C("2a4a6a"))
    for k in range(4):
        hline(bg, 40, 90, 138 + k * 6, C("3a5a8a"))
    box(bg, 88, 128, 96, 168, C("6a4228"), C("8a5a36"), C("3a2414"))
    # quadro acima da cama
    box(bg, 30, 52, 74, 84, C("8a5a36"), C("b07a4a"), C("3a2418"))
    vgrad(bg, 34, 56, 70, 80, [C("8fd0f2"), C("cfeaf2")])
    poly(bg, [(34, 80), (48, 64), (58, 74), (64, 68), (70, 80)], C("5a9a4a"))
    # estante com plantas e livros à direita
    bookcase(bg, 300, 40, 372, 161, 4, 91)
    hanging_plant(bg, 350, 22, 18)
    # vaso grande
    box(bg, 378, 140, 396, 160, C("a8543a"), C("c86a4a"), C("7a3a28"))
    for k in range(7):
        ellipse(bg, 374 + k * 3, 110 + (k % 3) * 6, 384 + k * 3, 126 + (k % 3) * 6, C("3f8a48"), OUT)
    ellipse(bg, 380, 112, 392, 124, C("57b254"))
    floor_planks(bg, 160, [C("8a5a3a"), C("7a4e32"), C("5a3a26")], C("3a2414"))
    light_poly(bg, [(152, 108), (248, 108), (300, 190), (110, 190)], C("ffe2a0"), 0.18)
    # tapete redondo
    ellipse(bg, 120, 170, 280, 190, OUT)
    ellipse(bg, 121, 171, 279, 189, C("c8803a"))
    ellipse(bg, 140, 174, 260, 186, C("e0a050"))
    # luminária do teto
    vline(bg, 200, 0, 10, C("2a1a10"))
    poly(bg, [(192, 18), (208, 18), (204, 10), (196, 10)], C("e8c070"), OUT)
    glow_patch(bg, 200, 24, 26, C("ffe4a0"), 0.18)
    # cadeira, mesa e objetos (caneca e livro: StudyScene)
    hx, hy = HIP["casa"]
    chair_back(bg, hx - 23, hy + 3)
    desk(bg, fg, hx + 12, hx + 146, hy - 8, 192, [C("a06c44"), C("c08a5a"), C("7a4e30"), C("4a2d1a")])
    for k, c in enumerate([C("3d3a6b"), C("8c2f39"), C("c7923e")]):
        box(bg, 214 + k, 136 - k * 5, 238 - k, 141 - k * 5, c, mix(c, C("ffffff"), 0.25), mix(c, C("000000"), 0.3))
    box(bg, 246, 134, 254, 141, C("6a8aba"), None, C("2a4a6a"))
    for k in range(4):
        vline(bg, 247 + k * 2, 128, 133, [C("e8c070"), C("ff7a6a"), C("8ee28e"), C("7cc4ff")][k])
    lamp(bg, 272, 142, C("e8a050"))
    glow_patch(bg, 278, 126, 22, C("ffe4a0"), 0.2)
    return bg, fg


# ================================================================ TAVERNA (à noite)
def taverna():
    bg, fg = canvas(W, H), canvas(W, H)
    # parede de tábuas verticais
    r = random.Random(12)
    rect(bg, 0, 0, W - 1, 160, C("5a3a26"))
    x = 0
    while x < W:
        w = 9 + r.randint(0, 4)
        c = [C("5a3a26"), C("63412b"), C("543522"), C("6a4630")][r.randrange(4)]
        rect(bg, x, 24, x + w - 2, 160, c)
        vline(bg, x + w - 1, 24, 160, C("3a2418"))
        if r.random() < 0.4:
            px(bg, x + 3, 40 + r.randint(0, 90), C("3a2418"))
        x += w
    # teto e vigas
    vgrad(bg, 0, 0, W - 1, 24, [C("1e140e"), C("2a1a12")])
    box(bg, -2, 20, W + 1, 28, C("3a2418"), C("6a4630"), C("1e140e"))
    for bx in (60, 200, 340):
        box(bg, bx - 4, 28, bx + 4, 160, C("3a2418"), C("5a3a28"), C("1e140e"))
    # lanternas penduradas (a chama é animada)
    for lx in (130, 270):
        vline(bg, lx, 28, 40, C("1d1410"))
        box(bg, lx - 5, 40, lx + 5, 54, C("2a2a30"), None, OUT)
        rect(bg, lx - 3, 43, lx + 3, 51, C("ffd27a"))
        glow_patch(bg, lx, 48, 34, C("ffb860"), 0.25)
    # janela da noite à esquerda
    vgrad(bg, 18, 50, 46, 100, [C("0d1230"), C("1a2350"), C("2b3668")])
    stars(bg, 19, 51, 45, 80, 14, 5, [C("ffffe8"), C("c8d8ff")])
    ellipse(bg, 30, 58, 40, 68, C("f0f4ff"))
    for (a, b, c, d) in ((14, 46, 50, 49), (14, 100, 50, 103), (14, 46, 17, 103), (47, 46, 50, 103), (31, 50, 33, 100)):
        rect(bg, a, b, c, d, C("2a1a12"))
    # escudo e bandeiras
    box(bg, 88, 50, 112, 74, C("8a8a92"), C("b8b8c0"), C("4a4a52"))
    poly(bg, [(92, 54), (108, 54), (108, 64), (100, 72), (92, 64)], C("b8454a"), OUT)
    for k, c in enumerate((C("2f5d62"), C("c7923e"))):
        bx0 = 150 + k * 80
        poly(bg, [(bx0, 30), (bx0 + 16, 30), (bx0 + 16, 58), (bx0 + 8, 52), (bx0, 58)], c, OUT)
        rect(bg, bx0 + 6, 36, bx0 + 10, 40, C("f4e8c8"))
    # prateleiras de garrafas atrás do balcão
    for row in range(3):
        y = 62 + row * 18
        box(bg, 262, y + 12, 396, y + 15, C("6a4428"), C("8a5a36"), C("3a2418"))
        for k in range(10):
            gx = 266 + k * 13 + (row * 5) % 7
            c = [C("3a7a4a"), C("8a3a3a"), C("c8a040"), C("4a5a8a"), C("6a3a6a")][(k + row) % 5]
            box(bg, gx, y + 3, gx + 5, y + 11, c, mix(c, C("ffffff"), 0.35), mix(c, C("000000"), 0.35))
            rect(bg, gx + 2, y, gx + 3, y + 2, C("c8b090"))
    # balcão do bar
    box(bg, 256, 120, 400, 128, C("8a5a36"), C("b07a4a"), C("3a2414"))
    box(bg, 260, 128, 400, 160, C("6a4228"), C("7a4e30"), C("3a2414"))
    for x in range(272, 400, 22):
        vline(bg, x, 130, 158, C("4a2d1a"))
    for (mx, my) in ((282, 119), (318, 119), (360, 119)):
        mug(bg, mx, my)
    # barris empilhados
    for (bx, by) in ((14, 176), (40, 176), (27, 150)):
        box(bg, bx - 11, by - 26, bx + 11, by, C("7a4e2c"), C("9a6a3c"), C("4a2d1a"))
        hline(bg, bx - 10, bx + 10, by - 20, C("3a2418"))
        hline(bg, bx - 10, bx + 10, by - 6, C("3a2418"))
        ellipse(bg, bx - 4, by - 16, bx + 4, by - 10, C("5a3a20"), OUT)
    floor_planks(bg, 160, [C("4a301f"), C("3d2818"), C("2a1a10")], C("1e140e"))
    glow_patch(bg, 200, 175, 60, C("ffb860"), 0.12)
    # banco e mesa do herói
    hx, hy = HIP["taverna"]
    box(bg, hx - 22, hy - 1, hx + 18, hy + 4, C("6a4228"), C("8a5a36"), C("3a2414"))
    box(bg, hx - 17, hy + 4, hx - 12, 188, C("4a2d1a"))
    desk(bg, fg, hx + 12, hx + 138, hy - 8, 198, [C("8a5a36"), C("b07a4a"), C("5a361f"), C("3a2414")])
    box(bg, 222, 140, 246, 146, C("e6d5b0"), C("fff2d8"), C("b8a888"))
    ellipse(bg, 226, 134, 242, 144, C("c58a4a"), OUT)
    box(bg, 252, 134, 262, 146, C("b8b8c0"), C("e0e0e8"), C("6a6a72"))
    candle(bg, 272, 145, 14)
    return bg, fg


# ================================================================ CELA (cumprindo a pena estudando)
def cela():
    bg, fg = canvas(W, H), canvas(W, H)
    # parede de pedra em blocos
    rect(bg, 0, 0, W - 1, 160, C("3a3842"))
    r = random.Random(9)
    for row in range(0, 160, 12):
        off = 0 if (row // 12) % 2 == 0 else 14
        for x in range(-off, W, 28):
            c = [C("4c4a56"), C("45434e"), C("524f5c"), C("403e48")][r.randint(0, 3)]
            box(bg, max(0, x + 1), row + 1, min(W - 1, x + 26), row + 11, c, mix(c, C("ffffff"), 0.08), mix(c, C("000000"), 0.25), outline=C("26242c"))
    # musgo e manchas de umidade
    for i in range(14):
        x, y = r.randint(0, W - 8), r.randint(100, 156)
        rect(bg, x, y, x + r.randint(2, 6), y + 1, C("3e5a44"))
    # janela gradeada no alto, com lua
    wx0, wy0, wx1, wy1 = 238, 22, 302, 66
    vgrad(bg, wx0, wy0, wx1, wy1, [C("0d1230"), C("1a2350"), C("2b3668")])
    stars(bg, wx0 + 2, wy0 + 2, wx1 - 2, wy1 - 6, 14, 5, [C("ffffe8"), C("c8d8ff")])
    glow_patch(bg, 286, 34, 16, C("c8d8ff"), 0.4)
    ellipse(bg, 280, 28, 292, 40, C("f0f4ff"))
    for k in range(5):
        rect(bg, wx0 + 6 + k * 12, wy0, wx0 + 8 + k * 12, wy1, C("18181f"))
    for (a, b, c, d) in ((wx0 - 3, wy0 - 3, wx1 + 3, wy0 - 1), (wx0 - 3, wy1 + 1, wx1 + 3, wy1 + 3),
                         (wx0 - 3, wy0 - 3, wx0 - 1, wy1 + 3), (wx1 + 1, wy0 - 3, wx1 + 3, wy1 + 3)):
        rect(bg, a, b, c, d, C("26242c"))
    # tocha na parede
    box(bg, 204, 84, 208, 104, C("3a2418"), None, C("1e140c"))
    box(bg, 200, 80, 212, 84, C("5a5a64"), C("7a7a84"), C("3a3a44"))
    poly(bg, [(201, 80), (211, 80), (206, 66)], C("ff9a2e"))
    poly(bg, [(203, 80), (209, 80), (206, 72)], C("ffe08a"))
    glow_patch(bg, 206, 76, 46, C("ffa040"), 0.32)
    # correntes penduradas
    for cx in (40, 52):
        for k in range(7):
            ellipse(bg, cx - 2, 20 + k * 6, cx + 2, 25 + k * 6, C("6a6a74"))
    # catre de palha (direita)
    box(bg, 318, 136, 392, 150, C("5a4630"), C("7a6040"), C("3a2a1a"))
    for k in range(10):
        line(bg, (322 + k * 7, 134), (319 + k * 7, 140), C("c8a85a"))
    rect(bg, 318, 130, 392, 136, C("b89a52"))
    box(bg, 322, 150, 326, 160, C("3a2a1a"))
    box(bg, 384, 150, 388, 160, C("3a2a1a"))
    # chão de pedra
    vgrad(bg, 0, 160, W - 1, H - 1, [C("34323a"), C("2a2830"), C("1c1a22")])
    hline(bg, 0, W - 1, 160, OUT)
    for y in range(166, H, 9):
        hline(bg, 0, W - 1, y, C("16141a"))
        for x in range((y * 13) % 40, W, 40):
            vline(bg, x, y + 1, min(H - 1, y + 8), C("16141a"))
    # luar entrando pela janela
    light_poly(bg, [(238, 66), (302, 66), (360, 190), (180, 190)], C("8aa0ff"), 0.10)
    # grade da cela na frente, à esquerda (camada da frente: cobre só a borda, não o herói)
    for k in range(5):
        bx = 6 + k * 14
        box(fg, bx, 0, bx + 4, H - 1, C("18181f"), C("4a4a56"), C("0c0c12"))
    box(fg, 0, 40, 76, 44, C("18181f"), C("4a4a56"), C("0c0c12"))
    box(fg, 0, 150, 76, 154, C("18181f"), C("4a4a56"), C("0c0c12"))
    # cadeira e mesa rústica (mesma escala das outras cenas), vela e caneca de lata
    hx, hy = HIP["cela"]
    chair_back(bg, hx - 23, hy)
    desk(bg, fg, hx + 12, hx + 120, hy - 8, 192, [C("6f5a48"), C("8a7660"), C("4a3a2c"), C("2a1e14")])
    candle(bg, 252, 143, 12)
    glow_patch(bg, 252, 128, 34, C("ffb860"), 0.3)
    for k in range(2):
        box(bg, 216 + k * 2, 138 - k * 4, 240 + k * 2, 143 - k * 4, C("d8ccb0"), C("efe3c2"), C("a89878"))
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
    import sys
    os.makedirs(OUTDIR, exist_ok=True)
    if len(sys.argv) > 1:          # só as cenas pedidas: python3 tools/gen_pomodoro_bg.py cela
        for name in sys.argv[1:]:
            save(name, globals()[name]())
        sys.exit(0)
    save("livraria", livraria())
    save("cafeteria", cafeteria())
    save("natureza", natureza())
    save("estudo", estudo(False))
    save("estudo_noite", estudo(True))
    save("casa", casa())
    save("taverna", taverna())
