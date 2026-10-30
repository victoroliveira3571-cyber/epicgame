#!/usr/bin/env python3
"""Gera os tiles de masmorra (4 biomas) no estilo pixel art grosso do Ninja Adventure.
Saída: game/assets/dungeon/s{N}_*.png
  s{N}_floor{0..3}.png  super-tiles 64x64 sem emenda (lajotas irregulares)
  s{N}_face{0,1}.png    parede vista de frente (16x16 com tijolos)
  s{N}_top.png          topo da parede (16x16)
  s{N}_decal{0..5}.png  detalhes soltos (rachadura, pedrinhas, musgo...)
"""
import os, random
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "dungeon")
os.makedirs(OUT, exist_ok=True)

STYLES = [
    # nome, chão, argamassa, face clara, face escura, topo, borda
    ("caverna", (96, 82, 90), (44, 36, 50), (128, 108, 100), (96, 80, 78), (36, 30, 42), (170, 146, 128)),
    ("cripta", (88, 98, 100), (34, 42, 50), (118, 132, 130), (84, 98, 98), (28, 34, 42), (170, 188, 182)),
    ("pantano", (78, 98, 70), (30, 44, 32), (102, 128, 88), (70, 92, 62), (22, 32, 24), (150, 182, 112)),
    ("forja", (112, 70, 66), (50, 26, 30), (160, 92, 74), (118, 60, 54), (36, 16, 20), (240, 150, 96)),
]
OUTLINE = (20, 20, 32)


def shade(c, f):
    return tuple(int(max(0, min(255, v * f))) for v in c)


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def voronoi_floor(style, seed, size=64, cells=6):
    rng = random.Random(seed)
    _, floor, mortar, *_ = style
    step = size / cells
    pts = []
    for gy in range(cells):
        for gx in range(cells):
            px = gx * step + rng.uniform(0.15, 0.85) * step
            py = gy * step + rng.uniform(0.15, 0.85) * step
            pts.append((px, py))
    cell_color = [shade(floor, rng.uniform(0.86, 1.1)) for _ in pts]
    img = np.zeros((size, size, 4), dtype=np.uint8)
    P = np.array(pts)
    ys, xs = np.mgrid[0:size, 0:size]
    best = np.full((size, size), 1e9); second = np.full((size, size), 1e9); idx = np.zeros((size, size), dtype=int)
    for k, (px, py) in enumerate(pts):
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d = np.hypot(xs + 0.5 - (px + ox), ys + 0.5 - (py + oy))
                better = d < best
                second = np.where(better, best, np.minimum(second, d))
                idx = np.where(better, k, idx)
                best = np.where(better, d, best)
    edge = second - best
    for y in range(size):
        for x in range(size):
            c = cell_color[idx[y, x]]
            e = edge[y, x]
            if e < 1.6:
                col = mortar
            elif e < 2.6:
                col = shade(c, 0.82)
            else:
                col = c
                # luz vinda de cima-esquerda: realça pixels perto da borda superior/esquerda da própria laje
                nx = (x - 1) % size; ny = (y - 1) % size
                if idx[ny, x] != idx[y, x] or idx[y, nx] != idx[y, x]:
                    col = shade(c, 1.12)
                if rng.random() < 0.06:
                    col = shade(c, rng.choice([0.9, 1.08]))
            img[y, x] = (*col, 255)
    return Image.fromarray(img, "RGBA")


def brick_face(style, variant, seed):
    _, floor, mortar, light, dark, top, lip = style
    rng = random.Random(seed)
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 255))
    px = im.load()
    # fundo de argamassa
    for y in range(16):
        for x in range(16):
            px[x, y] = (*mortar, 255)
    rows = [(2, 7), (8, 13)]  # faixas de tijolos (y inicial, y final)
    offsets = [0, 4]
    for r, (y0, y1) in enumerate(rows):
        off = offsets[r]
        for bx in range(-8 + off, 16, 8):
            base = shade(light if rng.random() > 0.35 else dark, rng.uniform(0.92, 1.08))
            for y in range(y0, y1):
                for x in range(bx + 1, bx + 7):
                    if 0 <= x < 16:
                        c = base
                        if y == y0:
                            c = shade(base, 1.18)   # luz no alto do tijolo
                        elif y == y1 - 1:
                            c = shade(base, 0.78)   # sombra embaixo
                        px[x, y] = (*c, 255)
            if variant == 1 and rng.random() < 0.5:
                cx = bx + rng.randint(2, 5); cy = rng.randint(y0 + 1, y1 - 2)
                if 0 <= cx < 16:
                    px[cx, cy] = (*shade(mortar, 1.0), 255)
    # borda superior (lábio claro, "tampa" da parede) e base escura
    for x in range(16):
        px[x, 0] = (*lip, 255)
        px[x, 1] = (*shade(lip, 0.8), 255)
        px[x, 14] = (*shade(dark, 0.55), 255)
        px[x, 15] = (*OUTLINE, 255)
    return im


def wall_top(style, seed):
    _, floor, mortar, light, dark, top, lip = style
    rng = random.Random(seed)
    im = Image.new("RGBA", (16, 16), (*top, 255))
    px = im.load()
    for y in range(16):
        for x in range(16):
            if rng.random() < 0.12:
                px[x, y] = (*shade(top, rng.choice([0.8, 1.35])), 255)
    return im


def decal(kind, style, seed):
    _, floor, mortar, light, dark, top, lip = style
    rng = random.Random(seed)
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = im.load()
    if kind == 0:  # rachadura
        x, y = rng.randint(3, 6), rng.randint(2, 5)
        for _ in range(14):
            px[x, y] = (*mortar, 255)
            x += rng.choice([0, 1, 1]); y += rng.choice([0, 1, 1])
            if x > 15 or y > 15:
                break
    elif kind == 1:  # pedrinhas
        for _ in range(4):
            x, y = rng.randint(2, 12), rng.randint(2, 12)
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                px[x + dx, y + dy] = (*shade(floor, 1.2), 255)
            px[x, y + 2] = (*mortar, 255); px[x + 1, y + 2] = (*mortar, 255)
    elif kind == 2:  # mancha (musgo / brasa)
        col = {"caverna": (96, 130, 80), "cripta": (80, 120, 100), "pantano": (60, 140, 70), "forja": (255, 150, 60)}[style[0]]
        for _ in range(26):
            x, y = rng.randint(2, 13), rng.randint(2, 13)
            px[x, y] = (*shade(col, rng.uniform(0.8, 1.15)), 255)
            if rng.random() < 0.5:
                px[x + 1, y] = (*shade(col, 0.8), 255)
    elif kind == 3:  # ossos
        for (x, y) in ((4, 8), (5, 7), (6, 6), (7, 5), (8, 4), (9, 4), (10, 5)):
            px[x, y] = (230, 224, 206, 255)
        for (x, y) in ((4, 9), (5, 8), (6, 7), (7, 6), (8, 5)):
            px[x, y] = (150, 142, 128, 255)
        px[10, 6] = (230, 224, 206, 255); px[11, 6] = (230, 224, 206, 255)
    elif kind == 4:  # poça
        col = (70, 120, 170) if style[0] != "forja" else (230, 90, 40)
        for y in range(7, 11):
            for x in range(3, 13):
                if (x - 7.5) ** 2 / 20 + (y - 8.5) ** 2 / 4 < 1:
                    px[x, y] = (*col, 200)
        px[5, 8] = (255, 255, 255, 200)
    else:  # entulho
        for _ in range(7):
            x, y = rng.randint(2, 12), rng.randint(2, 12)
            px[x, y] = (*shade(light, 0.9), 255); px[x + 1, y] = (*shade(dark, 0.8), 255)
            px[x, y + 1] = (*shade(dark, 0.6), 255)
    return im


for n, style in enumerate(STYLES):
    for v in range(4):
        voronoi_floor(style, seed=1000 * n + v).save(os.path.join(OUT, f"s{n}_floor{v}.png"))
    for v in range(2):
        brick_face(style, v, seed=77 * n + v).save(os.path.join(OUT, f"s{n}_face{v}.png"))
    wall_top(style, seed=5 + n).save(os.path.join(OUT, f"s{n}_top.png"))
    for k in range(6):
        decal(k, style, seed=900 + 10 * n + k).save(os.path.join(OUT, f"s{n}_decal{k}.png"))
print("ok", OUT)
