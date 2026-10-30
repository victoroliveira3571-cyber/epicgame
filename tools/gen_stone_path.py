"""Gera assets/custom/tiles/TilesetFloorStone.png: o TilesetFloor do Ninja Adventure com o
caminho de terra (bloco da linha 7) trocado por calçamento de pedra, mantendo a borda de grama
e o formato do autotile. Uso (da pasta game/): python3 tools/gen_stone_path.py"""
import random
from PIL import Image

SRC = "assets/ninja/tiles/TilesetFloor.png"
OUT = "assets/custom/tiles/TilesetFloorStone.png"
DIRT = {(211, 134, 95): "c", (189, 121, 89): "d", (173, 112, 75): "d", (230, 165, 120): "c"}
STONES = [(168, 164, 158), (156, 150, 146), (178, 172, 162), (148, 146, 150)]
GAP = (104, 98, 98)
HI = (196, 190, 180)


def stone_at(x, y):
    """Padrão de pedras retangulares em fileiras desencontradas (repete a cada 16 px)."""
    row = (y % 16) // 4
    off = 4 if row % 2 else 0
    lx = (x + off) % 8
    ly = y % 4
    if ly == 3 or lx == 7:
        return GAP
    r = random.Random(((x + off) // 8) * 31 + (y // 4) * 17)
    c = r.choice(STONES)
    return HI if (ly == 0 and lx < 3) else c


im = Image.open(SRC).convert("RGBA")
p = im.load()
for y in range(7 * 16, 14 * 16):
    for x in range(0, 11 * 16):
        r, g, b, a = p[x, y]
        if a and (r, g, b) in DIRT:
            s = stone_at(x, y)
            if DIRT[(r, g, b)] == "d":   # sombra perto da grama
                s = tuple(int(v * 0.86) for v in s)
            p[x, y] = s + (255,)
im.save(OUT)
print("ok", OUT)
