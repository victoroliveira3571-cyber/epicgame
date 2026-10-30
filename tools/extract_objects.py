"""Acha objetos (componentes conectados) num tileset e salva uma folha rotulada.
Uso: python3 extract_objects.py <tileset.png> <saida_prefixo> [dilatacao]"""
import sys, json
import numpy as np
from PIL import Image, ImageDraw
from collections import deque

src, out = sys.argv[1], sys.argv[2]
dil = int(sys.argv[3]) if len(sys.argv) > 3 else 1
im = Image.open(src).convert("RGBA")
a = np.array(im)[:, :, 3] > 0
m = a.copy()
for _ in range(dil):
    n = m.copy()
    n[1:, :] |= m[:-1, :]; n[:-1, :] |= m[1:, :]; n[:, 1:] |= m[:, :-1]; n[:, :-1] |= m[:, 1:]
    m = n
H, W = m.shape
seen = np.zeros_like(m)
objs = []
for y in range(H):
    for x in range(W):
        if m[y, x] and not seen[y, x]:
            q = deque([(y, x)]); seen[y, x] = True
            x0 = x1 = x; y0 = y1 = y
            while q:
                cy, cx = q.popleft()
                x0 = min(x0, cx); x1 = max(x1, cx); y0 = min(y0, cy); y1 = max(y1, cy)
                for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
                    ny, nx = cy+dy, cx+dx
                    if 0 <= ny < H and 0 <= nx < W and m[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True; q.append((ny, nx))
            # recorta ao conteúdo real (sem a dilatação)
            sub = a[y0:y1+1, x0:x1+1]
            ys, xs = np.where(sub)
            if len(ys) < 12:
                continue
            objs.append((int(x0+xs.min()), int(y0+ys.min()), int(x0+xs.max()+1), int(y0+ys.max()+1)))
objs.sort(key=lambda o: (o[1]//8, o[0]))
json.dump(objs, open(out + ".json", "w"))
print(len(objs), "objetos")
# folha rotulada
S = 2
cols_w = 1100
x = y = 4; rowh = 0
items = []
for i, (x0, y0, x1, y1) in enumerate(objs):
    w, h = (x1-x0)*S, (y1-y0)*S
    if x + w + 4 > cols_w:
        x = 4; y += rowh + 16; rowh = 0
    items.append((i, x, y, (x0, y0, x1, y1)))
    x += max(w, 28) + 8; rowh = max(rowh, h)
sheet = Image.new("RGBA", (cols_w, y + rowh + 20), (70, 70, 82, 255))
d = ImageDraw.Draw(sheet)
for i, px, py, bb in items:
    c = im.crop(bb).resize(((bb[2]-bb[0])*S, (bb[3]-bb[1])*S), Image.NEAREST)
    sheet.alpha_composite(c, (px, py + 10))
    d.text((px, py - 2), str(i), fill=(255, 255, 0, 255))
sheet.save(out + "_sheet.png"); print(sheet.size)
