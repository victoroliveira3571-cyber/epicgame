"""Paisagens em pixel art (320x192, cabem em 2x na tela de 640x360) em game/assets/custom/paisagem/:
campo_dia, mar_entardecer e montanhas_noite. Usadas atrás da tela de escolha de classe.
Uso (da pasta game/):  python3 tools/gen_paisagem.py
"""
import math, os, random
from PIL import Image
from pixelkit import *

W, H = 320, 192
OUTDIR = "assets/custom/paisagem/"


def finish(im, n=32):
    q = im.convert("RGB").quantize(colors=n, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    return q


def cloud(im, x, y, w, c, shade):
    for i in range(0, w, 6):
        r = 5 + (i * 13 % 4)
        ellipse(im, x + i - r, y - r, x + i + r, y + r // 2, c)
    hline(im, x - 5, x + w + 3, y + 2, shade)


def ridge(im, base, amp, seed, color, snow=None, step=4):
    r = random.Random(seed)
    pts = [(0, H)]
    ph = [r.uniform(0, 6) for _ in range(3)]
    for x in range(0, W + step, step):
        y = base + amp * (math.sin(x / 31.0 + ph[0]) * 0.6 + math.sin(x / 13.0 + ph[1]) * 0.3 + math.sin(x / 57.0 + ph[2]) * 0.5)
        pts.append((x, int(y)))
    pts.append((W, H))
    poly(im, pts, color)
    if snow:
        for (x, y) in pts[1:-1]:
            if y < base - amp * 0.75:
                rect(im, x - 2, y, x + 2, y + 1, snow)


def grass(im, y0, seed, colors, flowers):
    r = random.Random(seed)
    for _ in range(170):
        x, y = r.randint(0, W - 1), r.randint(y0, H - 1)
        c = colors[r.randrange(len(colors))]
        px(im, x, y, c); px(im, x - 1, y - 1, c); px(im, x + 1, y - 1, c)
    for _ in range(26):
        x, y = r.randint(2, W - 3), r.randint(y0 + 6, H - 3)
        c = flowers[r.randrange(len(flowers))]
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            px(im, x + dx, y + dy, c)
        px(im, x, y, C("ffb020"))


def tree(im, x, base, scale=1):
    box(im, x - 3, base - 26 * scale, x + 3, base, C("6a4630"), None, C("4a2d1a"))
    for (dx, dy, rr) in ((-12, -30, 11), (0, -38, 13), (12, -30, 11), (0, -26, 12)):
        ellipse(im, x + dx - rr - 1, base + dy * scale - rr - 1, x + dx + rr + 1, base + dy * scale + rr + 1, OUT)
    for k, g in enumerate((C("2f7a3a"), C("3f9a44"), C("57b254"))):
        for (dx, dy, rr) in ((-12, -30, 11), (0, -38, 13), (12, -30, 11), (0, -26, 12)):
            rr2 = rr - k * 3
            ellipse(im, x + dx - rr2 - k, base + dy * scale - rr2 - k * 2, x + dx + rr2 - k, base + dy * scale + rr2 - k * 2, g)


def campo_dia():
    im = canvas(W, H)
    vgrad(im, 0, 0, W - 1, 140, [C("5fb4e8"), C("79c6ee"), C("a8dcf0"), C("e8f2d8"), C("fdf1c4")])
    ellipse(im, 236, 22, 262, 48, C("fff6cc"))
    ellipse(im, 239, 25, 259, 45, C("ffe892"))
    cloud(im, 40, 30, 28, C("ffffff"), C("dfe8f0"))
    cloud(im, 150, 48, 20, C("ffffff"), C("dfe8f0"))
    cloud(im, 270, 70, 24, C("ffffff"), C("dfe8f0"))
    ridge(im, 112, 16, 1, C("8aa6cf"), C("e6eef8"))
    ridge(im, 124, 10, 2, C("6c9a8c"))
    ridge(im, 138, 8, 3, C("7fbf5a"))
    vgrad(im, 0, 150, W - 1, H - 1, [C("8ccb5e"), C("74b84f"), C("5aa448")])
    rect(im, 0, 146, W - 1, 149, C("7fbf5a"))
    for x, b in ((36, 160), (84, 152), (270, 158)):
        tree(im, x, b)
    # trilha de terra
    poly(im, [(140, H), (172, H), (166, 150), (152, 150)], C("c9965e"), OUT)
    grass(im, 152, 5, [C("3f8a38"), C("5aa84a")], [C("ffffff"), C("ffd54a"), C("ff7a9a"), C("b58cff")])
    return im


def mar_entardecer():
    im = canvas(W, H)
    vgrad(im, 0, 0, W - 1, 104, [C("2c3a78"), C("6a4a8a"), C("d8607a"), C("f69a58"), C("ffd07a")])
    ellipse(im, 130, 78, 190, 138, C("ffe8a0"))
    ellipse(im, 138, 86, 182, 130, C("fff4c8"))
    for i, (x, y, w) in enumerate(((20, 30, 30), (200, 22, 36), (250, 56, 26))):
        cloud(im, x, y, w, C("f6a080"), C("c4607a"))
    stars(im, 0, 0, W - 1, 40, 25, 8, [C("ffffe8"), C("ffd9e8")])
    vgrad(im, 0, 104, W - 1, H - 1, [C("f69a58"), C("c8607a"), C("5a4a8a"), C("2c3a78")])
    hline(im, 0, W - 1, 104, C("ffe8a0"))
    for i in range(16):
        y = 108 + i * 3
        w = 10 + i * 3
        hline(im, 160 - w // 2, 160 + w // 2, y, C("ffe8a0") if i % 2 == 0 else C("f6a058"))
    r = random.Random(3)
    for _ in range(36):
        x, y = r.randint(0, W - 1), r.randint(108, 148)
        hline(im, x, x + r.randint(3, 8), y, C("ffd9a0") if r.random() < 0.4 else C("8a5a9a"))
    # costa com palmeiras e pedras
    poly(im, [(0, H), (0, 150), (60, 146), (120, 158), (180, 162), (240, 152), (320, 158), (320, H)], C("2a2438"))
    poly(im, [(0, H), (0, 168), (80, 164), (160, 172), (240, 166), (320, 170), (320, H)], C("3a2f4a"))
    for x, b in ((40, 152), (270, 156)):
        for k in range(26):
            px(im, x + k // 8, b - k, C("14101c"))
        for a in (-1, 1):
            for k in range(14):
                px(im, x + 3 + a * k, b - 26 + (k // 3) * 1 - (k // 5), C("14101c"))
                px(im, x + 3 + a * k, b - 25 + (k // 3), C("14101c"))
    return im


def montanhas_noite():
    im = canvas(W, H)
    vgrad(im, 0, 0, W - 1, 150, [C("0d1230"), C("171d48"), C("243064"), C("3a4a88")])
    stars(im, 0, 0, W - 1, 110, 90, 12, [C("ffffe8"), C("c8d8ff"), C("fff2b0")])
    for y in range(18, 50):
        for x in range(232, 270):
            in_disc = ((x - 249) ** 2 + (y - 35) ** 2) <= 13 ** 2
            in_cut = ((x - 255) ** 2 + (y - 31) ** 2) <= 13 ** 2
            if in_disc and not in_cut:
                px(im, x, y, C("e8eeff"))
    for (x, y) in ((40, 30), (150, 18), (90, 60)):
        px(im, x, y, C("ffffff")); px(im, x + 1, y, C("c8d8ff")); px(im, x, y + 1, C("c8d8ff"))
    ridge(im, 112, 24, 4, C("2a3a78"), C("8aa0e0"))
    ridge(im, 128, 14, 5, C("1e2a5a"))
    ridge(im, 144, 10, 6, C("162048"))
    # lago espelhando a lua
    vgrad(im, 0, 150, W - 1, 175, [C("243064"), C("1a2450"), C("121a40")])
    for i in range(10):
        y = 152 + i * 2
        w = 6 + i * 2
        hline(im, 250 - w // 2, 250 + w // 2, y, C("c8d8ff") if i % 2 == 0 else C("6a7ac8"))
    # pinheiros em silhueta
    for x, b in ((24, 186), (50, 190), (270, 188), (300, 184), (292, 192)):
        for k in range(5):
            w = 3 + k * 3
            poly(im, [(x - w, b - 36 + k * 7 + 6), (x, b - 36 + k * 7 - 4), (x + w, b - 36 + k * 7 + 6)], C("0a1028"))
        rect(im, x - 1, b - 6, x + 1, b, C("0a1028"))
    vgrad(im, 0, 176, W - 1, H - 1, [C("162048"), C("0a1028")])
    return im


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    for name, fn in (("campo_dia", campo_dia), ("mar_entardecer", mar_entardecer), ("montanhas_noite", montanhas_noite)):
        im = finish(fn())
        im.save(OUTDIR + name + ".png")
        print(f"{name}: {im.size}, {count_colors(im)} cores")
