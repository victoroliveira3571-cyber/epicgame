"""Pequeno kit de pixel art (Pillow) no estilo do Ninja Adventure: contorno escuro grosso,
sombras simples, degradês com pontilhado (dither) e nada de antialiasing.
Usado pelos geradores gen_pomodoro_bg.py, gen_pomodoro_fx.py, gen_paisagem.py e gen_props.py."""
from PIL import Image, ImageDraw
import random

RAW = "/Users/victor/Desktop/EPICGAME/raw_assets/ninja-adventure/Ninja Adventure - Asset Pack/"
OUT = (19, 27, 27, 255)          # contorno do pacote
CLEAR = (0, 0, 0, 0)


def C(hexstr, a=255):
    h = hexstr.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (255,)


def canvas(w, h, fill=CLEAR):
    return Image.new("RGBA", (w, h), fill)


def rect(im, x0, y0, x1, y1, c):
    """Retângulo cheio com cantos inclusivos."""
    if x1 < x0 or y1 < y0:
        return
    ImageDraw.Draw(im).rectangle([x0, y0, x1, y1], fill=c)


def hline(im, x0, x1, y, c):
    rect(im, x0, y, x1, y, c)


def vline(im, x, y0, y1, c):
    rect(im, x, y0, x, y1, c)


def px(im, x, y, c):
    if 0 <= x < im.size[0] and 0 <= y < im.size[1]:
        im.putpixel((x, y), c)


BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def vgrad(im, x0, y0, x1, y1, colors):
    """Degradê vertical em faixas com pontilhado ordenado entre elas (sem interpolar cores)."""
    n = len(colors) - 1
    h = max(1, y1 - y0)
    for y in range(y0, y1 + 1):
        t = (y - y0) / h * n
        i = min(int(t), n - 1)
        f = t - i
        for x in range(x0, x1 + 1):
            thr = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            px(im, x, y, colors[i + 1] if f > thr else colors[i])


def hgrad(im, x0, y0, x1, y1, colors):
    n = len(colors) - 1
    w = max(1, x1 - x0)
    for x in range(x0, x1 + 1):
        t = (x - x0) / w * n
        i = min(int(t), n - 1)
        f = t - i
        for y in range(y0, y1 + 1):
            thr = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            px(im, x, y, colors[i + 1] if f > thr else colors[i])


def box(im, x0, y0, x1, y1, fill, light=None, dark=None, outline=OUT):
    """Objeto sólido: contorno escuro, faixa clara no topo e sombra embaixo/à direita."""
    rect(im, x0, y0, x1, y1, outline)
    rect(im, x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)
    if light:
        hline(im, x0 + 1, x1 - 1, y0 + 1, light)
    if dark:
        hline(im, x0 + 1, x1 - 1, y1 - 1, dark)
        vline(im, x1 - 1, y0 + 1, y1 - 1, dark)


def ellipse(im, x0, y0, x1, y1, fill, outline=None):
    ImageDraw.Draw(im).ellipse([x0, y0, x1, y1], fill=fill, outline=outline)


def poly(im, pts, fill, outline=None):
    ImageDraw.Draw(im).polygon(pts, fill=fill, outline=outline)


def line(im, a, b, c, w=1):
    ImageDraw.Draw(im).line([a, b], fill=c, width=w)


def outline_sprite(sp, c=OUT):
    """Acrescenta 1 px de contorno em volta dos pixels opacos (sprite com transparência)."""
    w, h = sp.size
    out = Image.new("RGBA", (w + 2, h + 2), CLEAR)
    out.paste(sp, (1, 1))
    src = out.copy()
    sp2 = src.load()
    o = out.load()
    for y in range(h + 2):
        for x in range(w + 2):
            if sp2[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w + 2 and 0 <= ny < h + 2 and sp2[nx, ny][3] > 0:
                        o[x, y] = c
                        break
    return out


def paste(im, sp, x, y):
    """Cola um sprite com transparência (x, y = canto superior esquerdo)."""
    im.alpha_composite(sp, (int(x), int(y)))


def paste_bottom(im, sp, cx, by):
    """Cola com o centro de baixo em (cx, by)."""
    paste(im, sp, cx - sp.size[0] // 2, by - sp.size[1])


def raw(rel, box_=None):
    sp = Image.open(RAW + rel).convert("RGBA")
    return sp.crop(box_) if box_ else sp


def books(im, x0, y0, x1, y1, seed, palette):
    """Fileira de livros em pé (lombadas de 3 a 5 px, alturas variadas)."""
    r = random.Random(seed)
    x = x0
    while x <= x1 - 3:
        w = r.randint(3, 5)
        if x + w > x1:
            break
        if r.random() < 0.08:
            x += w
            continue
        h = r.randint(int((y1 - y0) * 0.6), y1 - y0)
        c = palette[r.randrange(len(palette))]
        rect(im, x, y1 - h, x + w - 1, y1, OUT)
        rect(im, x + 1, y1 - h + 1, x + w - 2, y1 - 1, c)
        hline(im, x + 1, x + w - 2, y1 - h + 3, mix(c, (255, 230, 150, 255), 0.45))
        x += w
    return im


def stars(im, x0, y0, x1, y1, n, seed, colors):
    r = random.Random(seed)
    for _ in range(n):
        x, y = r.randint(x0, x1), r.randint(y0, y1)
        c = colors[r.randrange(len(colors))]
        px(im, x, y, c)
        if r.random() < 0.15:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                px(im, x + dx, y + dy, mix(c, (0, 0, 0, 255), 0.5))


def count_colors(im):
    return len({p for p in im.getdata() if p[3] > 0})


def outline_same(sp, c=OUT):
    """Contorno de 1 px por fora, sem aumentar a imagem (a margem do quadro precisa ficar livre)."""
    w, h = sp.size
    src = sp.load()
    out = sp.copy()
    o = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        o[x, y] = c
                        break
    return out
