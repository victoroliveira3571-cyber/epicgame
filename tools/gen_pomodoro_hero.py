"""Gera o herói em pixel art (humanoide, sentado) das cenas do Pomodoro, uma folha por classe/pose/assento:
  game/assets/custom/pomodoro/hero/<classe>_<pose>_<chair|ground>.png  (6 quadros de 72x72, lado a lado)
  + .json com frames, w, h, fps e o ponto do quadril (ax, ay) para o StudyScene posicionar.

Poses: write (escreve), read (lê), sip (toma da caneca). Segura caneta/livro/caneca no próprio sprite.
Uso (da pasta game/):  python3 tools/gen_pomodoro_hero.py
"""
import json, os
from PIL import Image, ImageDraw
from pixelkit import *

OUTDIR = "assets/custom/pomodoro/hero/"
FW = FH = 72
AX, AY = 26, 56          # quadril dentro do quadro
N = 6
FPS = 5

LOOKS = {
    "cavaleiro": dict(skin="deac86", hair="5b3a22", style="short", cloth="8795a0", cloth2="c4ced4", dark="4b5862", boots="3a2c28", extra="plate"),
    "paladino": dict(skin="e6b890", hair="e0b84e", style="medium", cloth="e1b23c", cloth2="f6eed0", dark="9c7420", boots="5b3a22", extra="tabard"),
    "assassino": dict(skin="d6a47c", hair="1e1f2c", style="hood", cloth="2e3040", cloth2="a23a54", dark="191a26", boots="15161e", extra="scarf"),
    "escudeiro": dict(skin="e0ac84", hair="c9522c", style="spiky", cloth="dcd6c4", cloth2="3a70aa", dark="9d977f", boots="4a3528", extra="vest"),
    "mago": dict(skin="e8bc98", hair="d8506c", style="long", cloth="6c4cac", cloth2="f3c452", dark="46307c", boots="3a2848", extra="robe"),
    "arqueiro": dict(skin="d9a47c", hair="c9522c", style="hood", cloth="4f8c4a", cloth2="8e5f2c", dark="33602f", boots="4a3322", extra="quiver"),
}


def shade(c, k):
    return mix(c, (0, 0, 0, 255) if k < 0 else (255, 255, 255, 255), abs(k))


def thick(im, a, b, w, c):
    d = ImageDraw.Draw(im)
    d.line([a, b], fill=c, width=w)
    r = w // 2
    d.ellipse([a[0] - r, a[1] - r, a[0] + r, a[1] + r - (1 if w % 2 == 0 else 0)], fill=c)
    d.ellipse([b[0] - r, b[1] - r, b[0] + r, b[1] + r - (1 if w % 2 == 0 else 0)], fill=c)


def hl(im, x0, y, x1, c):
    """Linha horizontal começando em (x0, y) e indo até x1."""
    hline(im, x0, x1, y, c)


def layer(fn):
    t = canvas(FW, FH)
    fn(t)
    return outline_same(t)


def frame(cls, pose, sit, i):
    L = LOOKS[cls]
    skin, skin_d = C(L["skin"]), shade(C(L["skin"]), -0.2)
    hair, hair_d = C(L["hair"]), shade(C(L["hair"]), -0.3)
    cloth, cloth2, dark, boots = C(L["cloth"]), C(L["cloth2"]), C(L["dark"]), C(L["boots"])
    style, extra = L["style"], L["extra"]
    im = canvas(FW, FH)

    def P(x, y):
        return (AX + int(x), AY + int(y))

    breath = 1 if i in (2, 3, 4) else 0
    blink = i == 4
    # ---- pernas (de frente para trás)
    if sit == "chair":
        knee, foot = (14, -1), (16, 16)
        def back_leg(t):
            thick(t, P(-1, -1), P(13, -2), 6, shade(dark, -0.25))
            thick(t, P(13, -2), P(15, 16), 5, shade(dark, -0.25))
            rect(t, *P(13, 15), *P(20, 18), shade(boots, -0.2))
        def front_leg(t):
            thick(t, P(0, 0), P(knee[0], knee[1]), 6, dark)
            thick(t, P(knee[0], knee[1]), P(foot[0], foot[1]), 5, dark)
            rect(t, *P(foot[0] - 2, 15), *P(foot[0] + 5, 18), boots)
            hl(t, *P(foot[0] - 2, 15), P(foot[0] + 5, 15)[0], C("6a5a50"))
    else:
        knee = (13, -13)
        def back_leg(t):
            thick(t, P(0, 0), P(34, 2), 6, shade(dark, -0.25))
            rect(t, *P(33, -1), *P(38, 4), shade(boots, -0.2))
        def front_leg(t):
            thick(t, P(0, 0), P(knee[0], knee[1]), 6, dark)
            thick(t, P(knee[0], knee[1]), P(28, 1), 5, dark)
            rect(t, *P(27, -3), *P(33, 3), boots)
    im.alpha_composite(layer(back_leg))
    im.alpha_composite(layer(front_leg))

    # ---- braço de trás (parcialmente escondido)
    sh = (2, -16 - breath)
    def back_arm(t):
        thick(t, P(*sh), P(7, -8), 4, shade(cloth, -0.3))
        thick(t, P(7, -8), P(13, -6), 3, shade(cloth, -0.3))
        rect(t, *P(13, -7), *P(15, -5), shade(skin, -0.2))
    im.alpha_composite(layer(back_arm))

    # ---- tronco
    top = -21 - breath
    def torso(t):
        poly(t, [P(-6, 1), P(6, 1), P(6, -10), P(5, top + 3), P(2, top), P(-4, top), P(-7, -9)], cloth)
        rect(t, *P(-6, -9), *P(-4, 0), shade(cloth, -0.18))        # lado das costas mais escuro
        hl(t, *P(-3, top + 1), P(4, top + 1)[0], shade(cloth, 0.18))
        if extra == "plate":
            poly(t, [P(-3, top + 3), P(5, top + 3), P(5, -7), P(1, -3), P(-3, -7)], cloth2)
            vline(t, *P(-1, top + 4), P(-1, -8)[1], C("ffffff"))
            rect(t, *P(-6, -4), *P(6, -3), dark)
            rect(t, *P(0, -5), *P(2, -2), C("e8c070"))
        elif extra == "tabard":
            rect(t, *P(-2, top + 2), *P(4, 1), cloth2)
            rect(t, *P(0, top + 5), *P(1, -5), cloth)
            rect(t, *P(-1, top + 7), *P(2, top + 8), cloth)
            rect(t, *P(-6, -4), *P(6, -3), dark)
        elif extra == "scarf":
            rect(t, *P(-3, top + 1), *P(6, top + 3), cloth2)
            poly(t, [P(-3, top + 2), P(-9, top + 9), P(-6, top + 10), P(-2, top + 4)], shade(cloth2, -0.2))
            rect(t, *P(-6, -4), *P(6, -3), dark)
        elif extra == "vest":
            poly(t, [P(-4, top + 2), P(5, top + 3), P(5, 1), P(-5, 1)], cloth2)
            vline(t, *P(1, top + 3), P(1, 0)[1], cloth)
            rect(t, *P(-6, -4), *P(6, -3), dark)
        elif extra == "robe":
            poly(t, [P(-7, 1), P(8, 1), P(5, -9), P(-5, -9)], shade(cloth, 0.05))
            poly(t, [P(-3, top + 2), P(5, top + 2), P(1, top + 8)], cloth2)
            rect(t, *P(-7, -5), *P(7, -4), cloth2)
        elif extra == "quiver":
            line(t, P(-5, top + 3), P(5, -5), cloth2, 2)
            rect(t, *P(-6, -4), *P(6, -3), cloth2)
            poly(t, [P(-9, top + 2), P(-5, top - 3), P(-2, top), P(-6, top + 7)], shade(cloth2, -0.3))
            for k in range(3):
                px(t, *P(-8 + k, top - 3 - k), C("e8e0d0"))
    im.alpha_composite(layer(torso))

    # ---- cabeça
    lean = 2 if pose == "write" else (1 if pose == "read" else 0)
    hx, hy = 1 + lean, -29 - breath + (1 if pose == "write" else 0)
    def head(t):
        rect(t, *P(hx - 2, hy + 5), *P(hx + 1, hy + 9), shade(skin, -0.12))           # pescoço
        ellipse(t, *P(hx - 5, hy - 6), *P(hx + 5, hy + 6), skin)
        ellipse(t, *P(hx - 5, hy - 6), *P(hx - 1, hy + 6), skin_d)                       # lado sombreado
        ellipse(t, *P(hx - 4, hy - 6), *P(hx + 5, hy + 6), skin)
        rect(t, *P(hx - 6, hy - 1), *P(hx - 5, hy + 2), skin_d)                          # orelha
        # nariz e queixo
        rect(t, *P(hx + 5, hy), *P(hx + 6, hy + 2), skin)
        px(t, *P(hx + 5, hy + 2), skin_d)
        hl(t, *P(hx + 1, hy + 5), P(hx + 3, hy + 5)[0], skin_d)
        # boca
        hl(t, *P(hx + 2, hy + 4), P(hx + 4, hy + 4)[0], C("a8553f") if pose != "sip" else C("8a3a2a"))
        # olho + sobrancelha
        ey = hy - 1 + (1 if pose in ("write", "read") else 0)
        if blink:
            hl(t, *P(hx + 2, ey + 1), P(hx + 4, ey + 1)[0], C("3a2418"))
        else:
            rect(t, *P(hx + 3, ey), *P(hx + 4, ey + 1), C("1a1a2e"))
            px(t, *P(hx + 2, ey), C("f4f4f4"))
        hl(t, *P(hx + 2, ey - 2), P(hx + 5, ey - 2)[0], hair_d)
        px(t, *P(hx + 1, hy + 2), shade(skin, 0.1) if False else skin)
    im.alpha_composite(layer(head))

    # ---- cabelo, capuz e chapéu
    def hairdo(t):
        if style == "hood":
            ellipse(t, *P(hx - 8, hy - 9), *P(hx + 6, hy + 8), cloth if cloth != dark else dark)
            ellipse(t, *P(hx - 3, hy - 4), *P(hx + 6, hy + 6), skin)         # abertura do rosto
            rect(t, *P(hx - 4, hy + 6), *P(hx + 2, hy + 9), cloth)
            if extra == "scarf":
                rect(t, *P(hx - 1, hy + 2), *P(hx + 6, hy + 6), cloth2)          # máscara
            hl(t, *P(hx - 3, hy - 5), P(hx + 4, hy - 5)[0], shade(cloth, 0.15))
            if LOOKS[cls]["hair"] == "c9522c":
                rect(t, *P(hx + 2, hy - 4), *P(hx + 5, hy - 3), hair)
            ey = hy - 1 + (1 if pose in ("write", "read") else 0)
            if not blink:
                rect(t, *P(hx + 3, ey), *P(hx + 4, ey + 1), C("1a1a2e"))
            return
        # massa de cabelo atrás e franja na frente
        ellipse(t, *P(hx - 7, hy - 8), *P(hx + 1, hy + 4), hair)            # atrás da cabeça
        ellipse(t, *P(hx - 6, hy - 9), *P(hx + 5, hy - 3), hair)            # topo (deixa o rosto livre)
        if style in ("long", "medium"):
            ln = 12 if style == "long" else 8
            poly(t, [P(hx - 7, hy - 3), P(hx - 8, hy + ln), P(hx - 2, hy + ln - 1), P(hx - 1, hy)], hair_d if style == "long" else hair)
        poly(t, [P(hx - 4, hy - 7), P(hx + 4, hy - 8), P(hx + 7, hy - 4), P(hx + 6, hy - 2), P(hx + 3, hy - 4), P(hx, hy - 5), P(hx - 3, hy - 2)], hair)
        hl(t, *P(hx - 2, hy - 7), P(hx + 3, hy - 7)[0], shade(hair, 0.28))
        if style == "spiky":
            for k in range(4):
                poly(t, [P(hx - 5 + k * 3, hy - 8), P(hx - 3 + k * 3, hy - 13 + (k % 2)), P(hx - 1 + k * 3, hy - 8)], hair)
            rect(t, *P(hx - 6, hy - 4), *P(hx + 6, hy - 3), cloth2)         # faixa
        if extra == "robe":                                                 # chapéu de mago
            ellipse(t, *P(hx - 9, hy - 10), *P(hx + 9, hy - 6), dark)
            poly(t, [P(hx - 6, hy - 8), P(hx + 6, hy - 8), P(hx + 2, hy - 20), P(hx - 1, hy - 24)], cloth)
            poly(t, [P(hx + 2, hy - 20), P(hx - 1, hy - 24), P(hx + 6, hy - 23)], shade(cloth, -0.1))
            rect(t, *P(hx - 6, hy - 9), *P(hx + 6, hy - 8), cloth2)
    im.alpha_composite(layer(hairdo))

    # ---- braço da frente + o que segura
    elbow = (8, -9)
    dx = [0, 1, 2, 1, 0, -1][i]
    if pose == "write":
        hand = (21 + dx, -9 + (-1 if i == 2 else 0))
    elif pose == "read":
        hand = (15, -17) if sit == "chair" else (24, -21)
        elbow = (9, -10)
    else:
        path = [(18, -14), (15, -21), (11, -27), (11, -27), (15, -21), (18, -14)]
        hand = path[i]
        elbow = (9, -11)
    def front_arm(t):
        thick(t, P(*sh), P(*elbow), 4, cloth)
        thick(t, P(*elbow), P(*hand), 3, cloth)
        rect(t, *P(hand[0] - 1, hand[1] - 1), *P(hand[0] + 1, hand[1] + 1), skin)
        hl(t, *P(hand[0] - 1, hand[1] + 1), P(hand[0] + 1, hand[1] + 1)[0], skin_d)
        if pose == "write":
            line(t, P(hand[0], hand[1]), P(hand[0] + 4, hand[1] - 6), C("f5f0e6"))
            px(t, *P(hand[0] + 4, hand[1] - 7), C("e9e1d0"))
            px(t, *P(hand[0] - 1, hand[1] + 1), C("20202a"))
        elif pose == "read":
            bx, by = hand
            book = [P(bx - 1, by - 4), P(bx + 11, by - 9), P(bx + 12, by + 3), P(bx, by + 5)]
            poly(t, book, C("fff3d4"))
            line(t, book[0], book[1], C("2f5d62"), 1)
            line(t, book[3], book[2], C("2f5d62"), 1)
            for k in range(3):
                line(t, P(bx + 2, by - 2 + k * 2), P(bx + 9, by - 5 + k * 2), C("a89f84"))
            if i in (3, 4):
                poly(t, [P(bx + 5, by - 7), P(bx + 11, by - 12), P(bx + 12, by - 8), P(bx + 6, by - 3)], C("efe3c2"))
        else:
            mx, my = hand
            rect(t, *P(mx + 1, my - 3), *P(mx + 6, my + 3), C("c9a06a"))
            hl(t, *P(mx + 1, my - 3), P(mx + 6, my - 3)[0], C("5a3218"))
            vline(t, *P(mx + 7, my - 2), P(mx + 7, my + 1)[1], C("c9a06a"))
    im.alpha_composite(layer(front_arm))
    return im


def sheet(cls, pose, sit):
    frames = [frame(cls, pose, sit, i) for i in range(N)]
    out = canvas(FW * N, FH)
    for i, f in enumerate(frames):
        out.paste(f, (i * FW, 0))
    name = f"{cls}_{pose}_{sit}"
    out.save(OUTDIR + name + ".png")
    json.dump({"frames": N, "w": FW, "h": FH, "fps": FPS, "ax": AX, "ay": AY}, open(OUTDIR + name + ".json", "w"))
    return out


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    combos = [("write", "chair"), ("read", "chair"), ("sip", "chair"), ("read", "ground"), ("sip", "ground")]
    n = 0
    for cls in LOOKS:
        for pose, sit in combos:
            sheet(cls, pose, sit)
            n += 1
    print(n, "folhas geradas em", OUTDIR)
