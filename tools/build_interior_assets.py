"""Recorta móveis do TilesetElement (Ninja Adventure, CC0) e gera pisos/paredes de interior.
Uso: python3 tools/build_interior_assets.py   (rodar da pasta game/; precisa do JSON gerado por
extract_objects.py em ../scratch ou use --regen para recalcular)"""
import json, sys, os
import numpy as np
from PIL import Image, ImageDraw
from collections import deque

SRC = "assets/ninja/tiles/TilesetElement.png"
OUT = "assets/ninja/props/"
os.makedirs("assets/interior", exist_ok=True)
im = Image.open(SRC).convert("RGBA")

def objects(img, dil=0):
    a = np.array(img)[:, :, 3] > 0
    H, W = a.shape
    seen = np.zeros_like(a); objs = []
    for y in range(H):
        for x in range(W):
            if a[y, x] and not seen[y, x]:
                q = deque([(y, x)]); seen[y, x] = True
                x0 = x1 = x; y0 = y1 = y; n = 0
                while q:
                    cy, cx = q.popleft(); n += 1
                    x0 = min(x0, cx); x1 = max(x1, cx); y0 = min(y0, cy); y1 = max(y1, cy)
                    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny, nx = cy+dy, cx+dx
                        if 0 <= ny < H and 0 <= nx < W and a[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True; q.append((ny, nx))
                if n >= 12: objs.append((x0, y0, x1+1, y1+1))
    objs.sort(key=lambda o: (o[1]//8, o[0]))
    return objs

objs = objects(im)
def crop(i): return im.crop(objs[i])

NAMED = {"i_table": 15, "i_sofa": 34, "i_chest": 43, "i_pot": 44, "i_crate": 45, "i_board": 46, "i_desk_paper": 11,
         "i_basket": 47, "i_counter": 54, "i_awning": 50, "i_stool": 13, "i_stool2": 35, "i_armchair": 14,
         "i_barrel": 5, "i_barrel2": 1, "i_sack": 4, "i_bowl1": 19, "i_bowl2": 22, "i_bowl3": 23,
         "i_laundry": 30, "i_rack": 29, "i_mug": 61, "i_painting": 57, "i_wash": 6}
for name, i in NAMED.items():
    crop(i).save(OUT + name + ".png")
t = crop(15); t.crop((0, 0, 17, t.size[1])).save(OUT + "i_table.png")        # o objeto 15 inclui um boneco ao lado

# tapete grande (parte direita do objeto 36) e faixa de armários (objeto 40, separada por colunas vazias)
rug = crop(36); rug.crop((16, 0, rug.size[0], rug.size[1])).save(OUT + "i_rug_big.png")
strip = crop(40)
# os móveis da faixa se encostam; limites medidos na folha ampliada (x0, x1)
RANGES = {"i_dresser": (0, 15), "i_cabinet": (15, 31), "i_bookshelf_s": (31, 48), "i_shelf_s": (48, 64), "i_stool_w": (64, 80),
          "i_dresser_wide": (80, 111), "i_bookcase": (111, 143), "i_shelf_big": (143, 176)}
parts = []
for n, (x0, x1) in RANGES.items():
    strip.crop((x0, 0, x1, strip.size[1])).save(OUT + n + ".png")
    parts.append((x0, x1))
print("props recortados; partes da faixa:", parts)

# ---------------------------------------------------------- pisos e paredes (16x16 por tile)
OUTLINE = (19, 27, 27, 255)
def tile_img(w, h): return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def wood_floor(path, base, dark, light):
    t = tile_img(64, 64); d = ImageDraw.Draw(t)
    for row in range(4):
        y = row * 16
        shade = [base, light, base, tuple(int((a+b)/2) for a, b in zip(base[:3], dark[:3])) + (255,)][row % 4]
        d.rectangle([0, y, 63, y + 15], fill=shade)
        off = 0 if row % 2 == 0 else 32
        for x in range(-32, 96, 64):
            d.line([(x + off, y), (x + off, y + 15)], fill=dark, width=1)
        d.line([(0, y + 15), (63, y + 15)], fill=tuple(int(c * 0.75) for c in dark[:3]) + (255,))
        d.line([(0, y), (63, y)], fill=tuple(min(255, int(c * 1.12)) for c in shade[:3]) + (255,))
        for k in range(3):
            gx = (row * 23 + k * 21) % 60
            d.line([(gx, y + 5 + k * 3), (gx + 8, y + 5 + k * 3)], fill=tuple(int(c * 0.9) for c in shade[:3]) + (255,))
    t.save(path)

def stone_floor(path, base, dark, light):
    t = tile_img(64, 64); d = ImageDraw.Draw(t); d.rectangle([0, 0, 63, 63], fill=base)
    for gy in range(0, 64, 16):
        for gx in range(0, 64, 16):
            shade = light if (gx // 16 + gy // 16) % 2 == 0 else base
            d.rectangle([gx, gy, gx + 15, gy + 15], fill=shade)
            d.line([(gx, gy), (gx + 15, gy)], fill=dark); d.line([(gx, gy), (gx, gy + 15)], fill=dark)
            d.point((gx + 4, gy + 5), fill=dark); d.point((gx + 11, gy + 10), fill=dark)
    t.save(path)

def wall_face(path, base, dark, light, beam):
    # 16 de largura x 32 de altura: rodapé, parede com tijolos e faixa superior de madeira
    t = tile_img(16, 32); d = ImageDraw.Draw(t)
    d.rectangle([0, 0, 15, 31], fill=base)
    for y in range(4, 26, 6):
        d.line([(0, y), (15, y)], fill=dark)
        off = 0 if (y // 6) % 2 == 0 else 8
        for x in (off, off + 16):
            d.line([(x, y), (x, y + 5)], fill=dark)
    d.rectangle([0, 0, 15, 3], fill=beam); d.line([(0, 3), (15, 3)], fill=OUTLINE)
    d.line([(0, 0), (15, 0)], fill=light)
    d.rectangle([0, 26, 15, 31], fill=beam); d.line([(0, 26), (15, 26)], fill=OUTLINE); d.line([(0, 27), (15, 27)], fill=light)
    t.save(path)

wood_floor("assets/interior/floor_wood.png", (181, 117, 72, 255), (128, 76, 48, 255), (200, 133, 82, 255))
wood_floor("assets/interior/floor_wood_dark.png", (140, 88, 58, 255), (96, 58, 42, 255), (156, 99, 66, 255))
stone_floor("assets/interior/floor_stone.png", (150, 128, 108, 255), (108, 88, 74, 255), (166, 144, 122, 255))
wall_face("assets/interior/wall_cream.png", (222, 190, 150, 255), (190, 152, 112, 255), (240, 214, 176, 255), (150, 88, 58, 255))
wall_face("assets/interior/wall_stone.png", (128, 112, 104, 255), (92, 78, 74, 255), (150, 134, 124, 255), (96, 60, 46, 255))
wall_face("assets/interior/wall_red.png", (176, 84, 70, 255), (138, 58, 50, 255), (200, 106, 88, 255), (92, 56, 44, 255))
print("pisos e paredes gerados")

# folha de conferência
names = list(NAMED) + ["i_rug_big", "i_dresser", "i_cabinet", "i_bookshelf_s", "i_shelf_s", "i_stool_w", "i_dresser_wide", "i_bookcase", "i_shelf_big"]
sheet = Image.new("RGBA", (1100, 300), (70, 110, 90, 255)); dr = ImageDraw.Draw(sheet); x = y = 4; rh = 0
for n in names:
    p = Image.open(OUT + n + ".png").convert("RGBA"); p = p.resize((p.size[0]*3, p.size[1]*3), Image.NEAREST)
    if x + p.size[0] > 1090: x = 4; y += rh + 14; rh = 0
    sheet.alpha_composite(p, (x, y + 10)); dr.text((x, y), n[2:], fill=(255, 255, 0, 255)); x += max(p.size[0], 40) + 6; rh = max(rh, p.size[1] + 10)
sheet.save(os.environ.get("SHEET", "/tmp/interior_sheet.png"))
