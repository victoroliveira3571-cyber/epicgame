#!/usr/bin/env python3
"""Recorta os móveis dos packs LPC baixados pelo Victor (31/10/2026) para assets/custom/props/.

Fontes (em "Recursos baixados por mim/"): upholstery.png, LPC_house_interior.zip (interior.png),
tables_&amp;_stools-1.2.zip (mesas brancas, recoloridas aqui para madeira). Uso:
  python3 tools/build_lpc_furniture.py <pasta com upholstery.png, interior.png e tables_&_stools-white.png>
As caixas de recorte (x0, y0, x1, y1) são em pixels da folha original; o recorte é aparado pelo alfa.
Licenças: CC-BY-SA 3.0 / GPL (interior, estofados), CC-BY 3.0 / OGA-BY 3.0 (mesas). Créditos na tela Créditos do jogo.
"""
import sys
from pathlib import Path
from PIL import Image

SRC = Path(sys.argv[1])
OUT = Path(__file__).resolve().parent.parent / "assets" / "custom" / "props"
UPH = Image.open(SRC / "upholstery.png").convert("RGBA")
INT = Image.open(SRC / "interior.png").convert("RGBA")
TAB = Image.open(SRC / "tables_&_stools-white.png").convert("RGBA")
LIN = Image.open(SRC / "table_linen.png").convert("RGBA")

# nome do prop -> (folha, caixa)
CROPS = {
    "lpc_poltrona": (UPH, (128, 160, 160, 192)),
    "lpc_sofa": (UPH, (128, 225, 192, 256)),
    "lpc_sofa_veludo": (UPH, (128, 258, 192, 288)),
    "lpc_sofa_imperial": (UPH, (127, 329, 191, 369)),
    "lpc_banco_estofado": (UPH, (196, 197, 253, 219)),
    "lpc_cadeira": (UPH, (35, 197, 61, 224)),
    "lpc_pufe": (UPH, (229, 324, 253, 346)),
    "lpc_abajur": (UPH, (4, 64, 28, 95)),
    "lpc_comoda": (INT, (96, 192, 128, 256)),
    "lpc_louceiro": (INT, (64, 192, 96, 256)),
    "lpc_armario": (INT, (0, 192, 32, 256)),
    "lpc_barris": (INT, (35, 266, 96, 311)),
    "lpc_lareira_tijolos": (INT, (352, 128, 384, 161)),
    "lpc_mesa_toalha": (LIN, (0, 0, 64, 64)),
}
# mesas brancas do pack de mesas, recoloridas para madeira
WOOD_CROPS = {
    "lpc_mesa_redonda": (TAB, (36, 15, 92, 64)),
    "lpc_mesa_centro": (TAB, (96, 105, 128, 130)),
}


def wood(im: Image.Image) -> Image.Image:
    """Troca o cinza/branco das mesas por uma rampa de madeira (mantém o contorno escuro)."""
    ramp = [(40, 24, 16), (84, 52, 30), (122, 78, 44), (160, 108, 62), (190, 134, 80)]
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (r * 3 + g * 6 + b) / 10 / 255.0
            pos = max(0.0, min(0.999, lum)) * (len(ramp) - 1)
            i = int(pos)
            f = pos - i
            c0, c1 = ramp[i], ramp[i + 1]
            px[x, y] = tuple(int(c0[k] + (c1[k] - c0[k]) * f) for k in range(3)) + (a,)
    return im


def half(im: Image.Image) -> Image.Image:
    """O LPC é desenhado em tiles de 32 px; o jogo usa tiles de 16 px. Reduz à metade (média de cada bloco 2x2)
    e firma o alfa para não sobrar borda semitransparente."""
    w, h = (im.width + 1) // 2 * 2, (im.height + 1) // 2 * 2
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(im, (0, 0))
    small = canvas.resize((w // 2, h // 2), Image.BOX)
    px = small.load()
    for y in range(small.height):
        for x in range(small.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 110 else (0, 0, 0, 0)
    return small


def save(name: str, im: Image.Image) -> None:
    im = im.crop(im.getchannel("A").getbbox())
    im = half(im)
    im = im.crop(im.getchannel("A").getbbox())
    im.save(OUT / f"{name}.png")
    print(name, im.size)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (sheet, box) in CROPS.items():
        save(name, sheet.crop(box))
    for name, (sheet, box) in WOOD_CROPS.items():
        save(name, wood(sheet.crop(box)))
