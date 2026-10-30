"""Gera as animações em pixel art das cenas do Pomodoro (folhas de sprites horizontais)
em game/assets/custom/pomodoro/fx/, cada uma com um .json ao lado:
  {"frames": n, "w": largura_do_quadro, "h": altura, "fps": velocidade}

Uso (da pasta game/):  python3 tools/gen_pomodoro_fx.py
"""
import json, math, os
from PIL import Image
from pixelkit import *

OUTDIR = "assets/custom/pomodoro/fx/"
FIRE = [C("e8531e"), C("ff8a2a"), C("ffb02e"), C("ffe27a"), C("fff6d0")]


def sheet(name, frames, fps):
    w, h = frames[0].size
    out = canvas(w * len(frames), h)
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    out.save(OUTDIR + name + ".png")
    json.dump({"frames": len(frames), "w": w, "h": h, "fps": fps}, open(OUTDIR + name + ".json", "w"))
    print(f"{name}: {len(frames)} quadros de {w}x{h} a {fps} fps")


def flame(w, h, phase, sway, scale_h=1.0):
    """Uma chama em camadas (vermelho por fora, amarelo-claro no miolo)."""
    im = canvas(w, h)
    cx = w // 2
    layers = [(FIRE[0], 1.0, 0.5), (FIRE[1], 0.82, 0.42), (FIRE[3], 0.55, 0.3), (FIRE[4], 0.28, 0.18)]
    for col, hk, wk in layers:
        top = h - int(h * hk * scale_h)
        for y in range(top, h):
            t = (y - top) / max(1, h - top)              # 0 no topo, 1 na base
            half = max(0, int(round(w * wk * math.sin(min(1.0, t * 1.15) * math.pi * 0.5) * (0.6 + 0.4 * t))))
            off = int(round(sway * (1.0 - t) * math.sin(phase + y * 0.6)))
            for x in range(cx - half + off, cx + half + off + 1):
                px(im, x, y, col)
    return im


def vela():
    frames = []
    for i in range(6):
        ph = i / 6.0 * math.tau
        frames.append(flame(7, 12, ph, 1.2, 0.85 + 0.15 * math.sin(ph)))
    return frames


def vela_pequena():
    frames = []
    for i in range(6):
        ph = i / 6.0 * math.tau
        frames.append(flame(5, 7, ph, 1.0, 0.8 + 0.2 * math.sin(ph * 2)))
    return frames


def lareira():
    frames = []
    for i in range(8):
        im = canvas(40, 34)
        ph = i / 8.0 * math.tau
        for k, (cx, hh, ww) in enumerate(((8, 22, 14), (20, 32, 20), (32, 24, 14), (14, 18, 10), (27, 20, 10))):
            f = flame(ww, 34, ph + k * 1.7, 2.2, (hh / 34.0) * (0.85 + 0.15 * math.sin(ph * 1.5 + k)))
            im.alpha_composite(f, (cx - ww // 2, 0))
        # brasas subindo
        for k in range(4):
            y = int((34 - (i * 4 + k * 9) % 34))
            x = (k * 11 + i * 3) % 38 + 1
            if y < 14:
                px(im, x, y, FIRE[3] if k % 2 else FIRE[2])
        frames.append(im)
    return frames


def agua():
    frames = []
    for i in range(8):
        im = canvas(48, 8)
        for k in range(5):
            x = (k * 11 + i * 2) % 52 - 4
            y = (k * 3) % 7
            ln = 3 + (k + i) % 3
            c = C("dff4ff") if (k + i) % 2 else C("bfe8ff")
            hline(im, max(0, x), min(47, x + ln), y, c)
        frames.append(im)
    return frames


def folha():
    frames = []
    for i in range(8):
        im = canvas(9, 9)
        a = i / 8.0 * math.tau
        for t in range(-3, 4):
            x = int(round(4 + t * math.cos(a)))
            y = int(round(4 + t * math.sin(a) * 0.6))
            px(im, x, y, C("57b254") if abs(t) < 3 else C("2f7a3a"))
            if abs(t) < 2:
                px(im, x, y + 1, C("86d46a"))
        frames.append(outline_sprite(im).crop((1, 1, 10, 10)))
    return frames


def poeira():
    frames = []
    shapes = [[(2, 2)], [(2, 2), (1, 2), (3, 2)], [(2, 2), (2, 1), (2, 3), (1, 2), (3, 2)], [(2, 2), (2, 1), (2, 3), (1, 2), (3, 2), (0, 2), (4, 2), (2, 0), (2, 4)],
              [(2, 2), (2, 1), (2, 3), (1, 2), (3, 2)], [(2, 2), (1, 2), (3, 2)]]
    for sh in shapes:
        im = canvas(5, 5)
        for (x, y) in sh:
            px(im, x, y, C("fff2c0") if (x, y) == (2, 2) else C("ffd98a"))
        frames.append(im)
    return frames


def vapor():
    frames = []
    for i in range(8):
        im = canvas(10, 20)
        for k in range(3):
            ph = (i / 8.0 + k / 3.0) % 1.0
            y = int(19 - ph * 18)
            x = int(5 + math.sin(ph * 6.0 + k) * 2.5)
            r = 1 if ph < 0.4 else 2
            c = C("ffffff") if ph < 0.5 else C("e8eef0")
            if ph < 0.85:
                ellipse(im, x - r, y - r, x + r, y + r, c)
        frames.append(im)
    return frames


def chuva():
    frames = []
    for i in range(4):
        im = canvas(64, 64)
        for k in range(18):
            x = (k * 23 + i * 5) % 64
            y = (k * 37 + i * 16) % 64
            for j in range(5):
                px(im, (x - j // 2) % 64, (y + j) % 64, C("9fb8ff") if j else C("dfe8ff"))
        frames.append(im)
    return frames


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    sheet("vela", vela(), 10)
    sheet("vela_pequena", vela_pequena(), 10)
    sheet("lareira", lareira(), 10)
    sheet("agua", agua(), 6)
    sheet("folha", folha(), 8)
    sheet("poeira", poeira(), 6)
    sheet("vapor", vapor(), 8)
    sheet("chuva", chuva(), 12)
