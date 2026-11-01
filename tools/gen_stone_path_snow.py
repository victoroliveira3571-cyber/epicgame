"""Gera assets/custom/tiles/TilesetFloorStoneSnow.png: o calçamento de pedra (TilesetFloorStone.png) com a borda
de grama trocada pelas cores da neve do TilesetFloor (linha 19), para as cidades de neve (Pedralta, Vila da Neve).
PROVISÓRIO (ver PROVISORIOS.md). Uso (da pasta game/): python3 tools/gen_stone_path_snow.py"""
from PIL import Image

SRC = "assets/custom/tiles/TilesetFloorStone.png"
OUT = "assets/custom/tiles/TilesetFloorStoneSnow.png"
MAP = {
    (173, 188, 58): (242, 234, 241),   # grama clara -> neve
    (168, 161, 41): (210, 201, 201),   # grama escura -> sombra da neve
    (116, 163, 52): (226, 218, 228),
    (86, 134, 76): (190, 182, 190),
}

im = Image.open(SRC).convert("RGBA")
p = im.load()
for y in range(7 * 16, 14 * 16):
    for x in range(0, 11 * 16):
        r, g, b, a = p[x, y]
        if a and (r, g, b) in MAP:
            p[x, y] = MAP[(r, g, b)] + (a,)
im.save(OUT)
print("ok", OUT)
