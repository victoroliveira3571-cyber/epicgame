"""Divisórias da casa (game/assets/custom/props/divisoria_*.png), v2.9.
Uso (da pasta game/):  python3 tools/gen_divisorias.py
"""
from PIL import Image, ImageDraw

OUT = "assets/custom/props/"
OUTLINE = (40, 26, 18, 255)


def wood(w=48, h=28):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 2, w - 1, h - 1], fill=OUTLINE)
    d.rectangle([1, 3, w - 2, h - 2], fill=(150, 98, 56, 255))
    for x in range(4, w - 3, 8):          # tábuas
        d.line([x, 4, x, h - 3], fill=(120, 76, 42, 255))
        d.line([x + 1, 4, x + 1, h - 3], fill=(176, 120, 72, 255))
    d.rectangle([0, 2, w - 1, 5], fill=(110, 70, 40, 255), outline=OUTLINE)       # travessa de cima
    d.rectangle([0, h - 5, w - 1, h - 1], fill=(110, 70, 40, 255), outline=OUTLINE)  # rodapé
    d.rectangle([w // 2 - 3, h // 2 - 3, w // 2 + 3, h // 2 + 3], outline=OUTLINE, fill=(200, 160, 90, 255))
    return im


def stone(w=48, h=28):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 2, w - 1, h - 1], fill=OUTLINE)
    d.rectangle([1, 3, w - 2, h - 2], fill=(150, 150, 160, 255))
    for row, y in enumerate(range(3, h - 2, 9)):   # blocos
        d.line([1, y, w - 2, y], fill=(96, 96, 108, 255))
        off = 0 if row % 2 == 0 else 8
        for x in range(1 + off, w - 2, 16):
            d.line([x, y, x, y + 9], fill=(96, 96, 108, 255))
        d.line([1, y + 1, w - 2, y + 1], fill=(184, 184, 196, 255))
    d.rectangle([0, 2, w - 1, 5], fill=(120, 120, 132, 255), outline=OUTLINE)
    return im


for name, im in [("divisoria_madeira", wood()), ("divisoria_pedra", stone())]:
    im.save(OUT + name + ".png")
    print(name, im.size)
