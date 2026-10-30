#!/usr/bin/env python3
"""Monta game/assets/ninja a partir do Ninja Adventure (CC0, pixel-boy).

Copia só o que o jogo usa, recorta props (casas, árvores, arbustos...) dos
tilesets e gera ícones 16x16 das armas. Pode rodar de novo a qualquer momento:
    python3 tools/build_assets.py            # monta tudo
    python3 tools/build_assets.py --preview  # também salva folhas de conferência
"""
import os, sys, shutil, json
from collections import deque
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(os.path.dirname(ROOT), "raw_assets", "ninja-adventure", "Ninja Adventure - Asset Pack")
DST = os.path.join(ROOT, "assets", "ninja")
PREVIEW = "--preview" in sys.argv
SP = "/private/tmp/claude-501/-Users-victor-Desktop-EPICGAME/e3184624-fc7c-45f0-b2d1-ae52c5b12071/scratchpad"


def src(*p): return os.path.join(SRC, *p)
def dst(*p):
    path = os.path.join(DST, *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def copy(s, d):
    shutil.copyfile(src(*s) if isinstance(s, (tuple, list)) else s, dst(*d) if isinstance(d, (tuple, list)) else d)


# ---------------------------------------------------------------- personagens
chars = sorted(os.listdir(src("Actor", "Character")))
for c in chars:
    base = src("Actor", "Character", c)
    if os.path.exists(os.path.join(base, "SpriteSheet.png")):
        copy((base, "SpriteSheet.png"), ("chars", c + ".png")) if False else shutil.copyfile(os.path.join(base, "SpriteSheet.png"), dst("chars", c + ".png"))
    if os.path.exists(os.path.join(base, "Faceset.png")):
        shutil.copyfile(os.path.join(base, "Faceset.png"), dst("chars", c + "_face.png"))

# ------------------------------------------------------------------ monstros
mons = sorted(os.listdir(src("Actor", "Monster")))
for m in mons:
    base = src("Actor", "Monster", m)
    sheet = [f for f in os.listdir(base) if f.endswith(".png") and f != "Faceset.png"]
    if sheet:
        shutil.copyfile(os.path.join(base, sheet[0]), dst("monsters", m.replace(" ", "") + ".png"))
    if os.path.exists(os.path.join(base, "Faceset.png")):
        shutil.copyfile(os.path.join(base, "Faceset.png"), dst("monsters", m.replace(" ", "") + "_face.png"))

# -------------------------------------------------------------------- chefes
BOSSES = ["GiantSlime", "GiantSlime2", "DemonCyclop", "DemonCyclop2", "GiantRacoon", "GiantRacoonGold",
          "GiantFrog", "GiantFrog2", "GiantBamboo", "GiantBamboo2", "GiantFlam", "GiantSpirit",
          "GiantBlueSamurai", "GiantRedSamurai", "SquidRed", "SquidGreen", "TenguRed", "TenguBlue"]
for b in BOSSES:
    base = src("Actor", "Boss", b)
    for f in os.listdir(base):
        if f.endswith(".png") and f not in ("Preview.png",):
            shutil.copyfile(os.path.join(base, f), dst("bosses", b + "_" + f))

# ------------------------------------------------------------------- animais
for a, f in {"Cat": "SpriteSheet.png", "CatBlack": "SpriteSheet.png", "CatOrange": "SpriteSheet.png", "Dog": "SpriteSheet.png",
             "DogBlack": "SpriteSheet.png", "Pig": "SpriteSheetPink.png", "Cow": "SpriteSheetWhite.png", "Frog": "SpriteSheet.png",
             "Hamster": "SpriteSheet.png", "Horse": "SpriteSheetBrown.png"}.items():
    p = src("Actor", "Animal", a, f)
    if os.path.exists(p):
        shutil.copyfile(p, dst("animals", a + ".png"))
for c in ["White", "Brown", "Black", "Cute"]:
    shutil.copyfile(src("Actor", "Animal", "Chicken", "SpriteSheet%s.png" % c), dst("animals", "Chicken%s.png" % c))

# --------------------------------------------------------------------- itens
for cat in ["Food", "Potion", "Resource", "Treasure", "Object", "Scroll", "Tool", "Projectile", "Other"]:
    base = src("Items", cat)
    for f in os.listdir(base):
        if f.endswith(".png"):
            shutil.copyfile(os.path.join(base, f), dst("items", cat.lower(), f.replace(" ", "")))

# armas: ícone 16x16 (arma na vertical) + sprite de mão
for w in os.listdir(src("Items", "Weapons")):
    base = src("Items", "Weapons", w)
    if not os.path.isdir(base):
        continue
    wn = w.replace(" ", "")
    if os.path.exists(os.path.join(base, "Sprite.png")):
        im = Image.open(os.path.join(base, "Sprite.png")).convert("RGBA")
        canvas = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        # gira 45 graus pra ficar com cara de ícone de inventário
        rot = im.rotate(-45, expand=True, resample=Image.NEAREST)
        bb = rot.getbbox()
        if bb:
            rot = rot.crop(bb)
        scale = 1
        canvas.alpha_composite(rot, ((16 - rot.width) // 2, (16 - rot.height) // 2))
        canvas.save(dst("weapons", wn + "_icon.png"))
        shutil.copyfile(os.path.join(base, "Sprite.png"), dst("weapons", wn + ".png"))
    if os.path.exists(os.path.join(base, "SpriteInHand.png")):
        shutil.copyfile(os.path.join(base, "SpriteInHand.png"), dst("weapons", wn + "_hand.png"))
    if os.path.exists(os.path.join(base, "Arrow.png")):
        shutil.copyfile(os.path.join(base, "Arrow.png"), dst("weapons", wn + "_arrow.png"))

# ---------------------------------------------------------- UI e ícones de skill
theme = src("Ui", "Theme", "Theme Wood")
for f in os.listdir(theme):
    if f.endswith(".png"):
        shutil.copyfile(os.path.join(theme, f), dst("ui", "theme", f))
for sub in ["Items & Weapon", "Job & Action", "Meteo", "Spell"]:
    base = src("Ui", "Skill Icon", sub)
    if os.path.isdir(base):
        for f in os.listdir(base):
            if f.endswith(".png") and "Disabled" not in f:
                shutil.copyfile(os.path.join(base, f), dst("skill_icons", sub.split(" ")[0].lower(), f))
for f in ["Heart.png", "Heart2.png", "Heart3.png", "IconHeart.png", "LifeBarMiniProgress.png", "LifeBarMiniUnder.png"]:
    shutil.copyfile(src("Ui", "Receptacle", f), dst("ui", "bars", f))
for sub in ["Receptacle Sphere", "Receptacle Rectangle"]:
    base = src("Ui", "Receptacle", sub)
    for f in os.listdir(base):
        if f.endswith(".png") and f != "Preview.png":
            shutil.copyfile(os.path.join(base, f), dst("ui", "bars", sub.split(" ")[1].lower() + "_" + f))
for f in os.listdir(src("Ui", "Dialog")):
    shutil.copyfile(src("Ui", "Dialog", f), dst("ui", "dialog", f))
for f in os.listdir(src("Ui", "Emote")):
    shutil.copyfile(src("Ui", "Emote", f), dst("ui", "emote", f))
shutil.copyfile(src("Ui", "Arrow.png"), dst("ui", "Arrow.png"))

# ----------------------------------------------------------------------- FX
for dp, dn, fn in os.walk(src("FX")):
    for f in fn:
        if f.endswith(".png") and "Preview" not in f:
            rel = os.path.relpath(os.path.join(dp, f), src("FX"))
            shutil.copyfile(os.path.join(dp, f), dst("fx", rel.replace(os.sep, "_").replace(" ", "")))

# ------------------------------------------------------------------- tilesets
TILESETS = ["TilesetField", "TilesetFloor", "TilesetNature", "TilesetHouse", "TilesetWater", "TilesetElement",
            "TilesetRelief", "TilesetFloorB", "TilesetDungeon", "TilesetHole"]
for t in TILESETS:
    shutil.copyfile(src("Backgrounds", "Tilesets", t + ".png"), dst("tiles", t + ".png"))
for t in ["TilesetInterior", "TilesetInteriorFloor", "TilesetWallSimple", "Elements"]:
    shutil.copyfile(src("Backgrounds", "Tilesets", "Interior", t + ".png"), dst("tiles", "Interior_" + t + ".png"))
for f in ["Flower", "Plant"]:
    shutil.copyfile(src("Backgrounds", "Animated", f, "SpriteSheet16x16.png"), dst("tiles", "Anim_" + f + ".png"))
shutil.copyfile(src("Backgrounds", "Animated", "Water Ripples", "SpriteSheet16x16.png"), dst("tiles", "Anim_Ripples.png"))
for col in ["Red", "Blue", "Green", "Yellow", "White", "Brown"]:
    shutil.copyfile(src("Backgrounds", "Animated", "Flag", "Flag%s16x16.png" % col), dst("tiles", "Flag%s.png" % col))

# --------------------------------------------------------------- recortes (props)
house = Image.open(src("Backgrounds", "Tilesets", "TilesetHouse.png")).convert("RGBA")
nature = Image.open(src("Backgrounds", "Tilesets", "TilesetNature.png")).convert("RGBA")
interior = Image.open(src("Backgrounds", "Tilesets", "Interior", "TilesetInterior.png")).convert("RGBA")
elements = Image.open(src("Backgrounds", "Tilesets", "Interior", "Elements.png")).convert("RGBA")
element_t = Image.open(src("Backgrounds", "Tilesets", "TilesetElement.png")).convert("RGBA")


def trim(im):
    bb = im.getbbox()
    return im.crop(bb) if bb else im


def tiles(img, tx, ty, tw, th, do_trim=True):
    c = img.crop((tx * 16, ty * 16, (tx + tw) * 16, (ty + th) * 16))
    return trim(c) if do_trim else c


def flood(img, seed):
    """Objeto conectado (sem dilatação) a partir de um ponto semente."""
    a = np.array(img)[:, :, 3] > 0
    H, W = a.shape
    x, y = seed
    if not a[y, x]:
        raise ValueError("semente vazia %s" % (seed,))
    seen = np.zeros_like(a)
    q = deque([(y, x)]); seen[y, x] = True
    x0 = x1 = x; y0 = y1 = y
    while q:
        cy, cx = q.popleft()
        x0 = min(x0, cx); x1 = max(x1, cx); y0 = min(y0, cy); y1 = max(y1, cy)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H and 0 <= nx < W and a[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    out = Image.new("RGBA", (x1 - x0 + 1, y1 - y0 + 1), (0, 0, 0, 0))
    mask = seen[y0:y1 + 1, x0:x1 + 1]
    src_c = np.array(img)[y0:y1 + 1, x0:x1 + 1]
    arr = np.zeros_like(src_c)
    arr[mask] = src_c[mask]
    return Image.fromarray(arr)


PROPS = {}
# --- prédios (tileset de casas, 16 px por tile; cada prédio tem 3 tiles de altura)
for name, (tx, tw) in {
    "casa_laranja": (0, 4), "casa_creme": (4, 4), "casa_laranja2": (8, 4), "salao_vermelho": (12, 4),
    "padaria": (16, 3), "estalagem": (19, 4), "forja": (23, 3), "casa_empena": (26, 3),
}.items():
    PROPS["b_" + name] = tiles(house, tx, 0, tw, 3)
# --- árvores e vegetação (tileset de natureza)
for name, (tx, ty, tw, th) in {
    "arvore_redonda": (0, 0, 2, 2), "arvore_pinheiro": (2, 0, 2, 2), "arvore_seca": (4, 0, 2, 2),
    "arvore_raiz": (6, 0, 2, 2), "arvore_redonda2": (16, 0, 2, 2), "arvore_redonda3": (18, 0, 2, 2),
    "pinheiros_trio": (0, 2, 4, 3), "arvores_trio": (4, 2, 4, 3), "arvores_trio_b": (16, 2, 4, 3),
    "arbusto1": (0, 10, 1, 1), "arbusto2": (1, 10, 1, 1), "arbusto3": (2, 10, 1, 1), "arbusto4": (6, 10, 1, 1),
    "arbusto5": (10, 10, 1, 1), "mato1": (3, 10, 1, 1), "mato2": (4, 10, 1, 1), "mato3": (5, 10, 1, 1),
    "mato4": (7, 10, 1, 1), "mato5": (8, 10, 1, 1), "mato6": (9, 10, 1, 1),
    "flor_girassol": (0, 11, 1, 1), "flor_girassol2": (1, 11, 1, 1), "flor_trevo": (2, 11, 1, 1),
    "flor_vermelha": (3, 11, 1, 1), "flor_margarida": (6, 11, 1, 1),
    "pedra_marrom": (15, 10, 2, 2), "pedra_marrom_g": (17, 10, 4, 3), "pedra_marrom_alta": (21, 10, 2, 3),
    "pedra_marrom_p1": (17, 13, 1, 1), "pedra_marrom_p2": (18, 13, 1, 1), "pedra_marrom_p3": (19, 13, 1, 1),
    "pedra_cinza": (15, 14, 2, 2), "pedra_cinza_g": (17, 14, 4, 3), "pedra_cinza_alta": (21, 14, 2, 3),
    "pedra_cinza_p1": (17, 17, 1, 1), "pedra_cinza_p2": (18, 17, 1, 1), "pedra_cinza_p3": (19, 17, 1, 1),
    "frutas_bush1": (4, 14, 1, 1), "frutas_bush2": (5, 14, 1, 1), "frutas_bush3": (4, 15, 1, 1),
    "frutas_bush4": (5, 15, 1, 1), "frutas_bush5": (4, 16, 1, 1), "frutas_bush6": (5, 16, 1, 1),
    "frutas_bush_g1": (7, 14, 2, 2), "frutas_bush_g2": (9, 14, 2, 2), "frutas_bush_g3": (7, 16, 2, 2),
    "toco1": (12, 13, 1, 1), "toco2": (13, 13, 1, 1),
    "cristal1": (0, 14, 1, 1), "cristal2": (1, 14, 1, 1), "cristal3": (2, 14, 1, 1), "cristal4": (3, 14, 1, 1),
}.items():
    PROPS["n_" + name] = tiles(nature, tx, ty, tw, th)
# --- árvores grandes (parte de baixo do tileset de natureza): separadas por colunas vazias
def segments(img, y0, y1):
    a = np.array(img)[y0:y1, :, 3] > 0
    cols = a.any(axis=0)
    segs = []; start = None
    for x, v in enumerate(cols):
        if v and start is None:
            start = x
        if not v and start is not None:
            segs.append((start, x)); start = None
    if start is not None:
        segs.append((start, len(cols)))
    return segs


for i, name in enumerate(["arvore_rosa", "arvore_grande", "arvore_branca", "arvore_outono"]):
    PROPS["n_" + name] = trim(nature.crop((i * 48, 288, i * 48 + 48, 336)))

# --- objetos soltos do tileset de casas (índices da extração sem dilatação)
HOUSE_BOXES = {"torii": (7, 82, 34, 29), "estatua_grande": (0, 241, 80, 63), "estatua_pequena": (49, 242, 30, 30),
               "totem": (81, 242, 31, 62), "cerca_ferro": (150, 162, 68, 46), "salao_madeira": (385, 226, 78, 78),
               "estatua_grande_verde": (0, 305, 80, 63), "estatua_pequena_verde": (49, 306, 30, 30)}
for name, (x, y, w, h) in HOUSE_BOXES.items():
    PROPS["h_" + name] = trim(house.crop((x, y, x + w, y + h)))

# ---------------------------------------------------------------------- áudio
MUSIC = {
    "town": "33 - Calm Village.ogg", "town_night": "9 - Quiet.ogg", "home": "5 - Peaceful.ogg",
    "title": "38 - Intro.ogg", "dungeon1": "21 - Dungeon.ogg", "dungeon2": "40 - Crypt.ogg",
    "dungeon3": "30 - Ruins.ogg", "dungeon4": "10 - Dark Castle.ogg", "boss": "17 - Fight.ogg",
    "boss2": "28 - Tension.ogg",
}
for k, f in MUSIC.items():
    shutil.copyfile(src("Audio", "Musics", f), dst("audio", "music", k + ".ogg"))
SFX = {
    "ui_click": ("Menu", "Accept.wav"), "ui_ok": ("Menu", "Accept2.wav"), "ui_back": ("Menu", "Cancel.wav"),
    "ui_move": ("Menu", "Move1.wav"), "ui_error": ("Menu", "Cancel2.wav"), "ui_open": ("Menu", "Menu5.wav"),
    "ui_close": ("Menu", "Menu6.wav"), "ui_tab": ("Menu", "Move3.wav"),
    "swing1": ("Whoosh & Slash", "Slash.wav"), "swing2": ("Whoosh & Slash", "Slash2.wav"),
    "swing3": ("Whoosh & Slash", "Slash3.wav"), "launch": ("Whoosh & Slash", "Launch.wav"),
    "magic1": ("Magic & Skill", "Magic1.wav"), "magic2": ("Magic & Skill", "Magic2.wav"),
    "magic3": ("Magic & Skill", "Magic3.wav"), "heal": ("Magic & Skill", "Heal.wav"), "spirit": ("Magic & Skill", "Spirit.wav"),
    "fireball": ("Elemental", "Fireball.wav"), "explosion": ("Elemental", "Explosion.wav"),
    "explosion2": ("Elemental", "Explosion3.wav"), "water": ("Elemental", "WaterDrop.wav"), "grass": ("Elemental", "Grass.wav"),
    "bubble": ("Elemental", "Bubble.wav"),
    "hit1": ("Hit & Impact", "Hit1.wav"), "hit2": ("Hit & Impact", "Hit2.wav"), "hit3": ("Hit & Impact", "Hit3.wav"),
    "hit_crit": ("Hit & Impact", "Impact3.wav"), "hurt": ("Hit & Impact", "Impact2.wav"), "die": ("Hit & Impact", "Impact4.wav"),
    "thud": ("Hit & Impact", "Impact.wav"),
    "coin": ("Bonus", "Coin.wav"), "coin2": ("Bonus", "Coin2.wav"), "gold": ("Bonus", "Gold1.wav"),
    "chest": ("Bonus", "Bonus2.wav"), "powerup": ("Bonus", "PowerUp1.wav"), "bonus": ("Bonus", "Bonus.wav"),
    "alert": ("Alert", "Alert.wav"), "alert2": ("Alert", "Alert3.wav"),
    "jump": ("Jump & Bounce", "Jump.wav"), "bounce": ("Jump & Bounce", "Bounce.wav"),
    "bird": ("Creature", "Bird.wav"), "dog": ("Creature", "Dog.wav"), "wings": ("Creature", "Wings.wav"),
    "voice1": ("Voice", "Voice1.wav"), "voice2": ("Voice", "Voice4.wav"), "voice3": ("Voice", "Voice7.wav"),
}
for k, (sub, f) in SFX.items():
    shutil.copyfile(src("Audio", "Sounds", sub, f), dst("audio", "sfx", k + ".wav"))
JINGLES = {"levelup": "LevelUp1.wav", "gameover": "GameOver.wav", "success": "Success1.wav", "success2": "Success3.wav",
           "secret": "Secret1.wav", "boss_clear": "Success2.wav"}
for k, f in JINGLES.items():
    shutil.copyfile(src("Audio", "Jingles", f), dst("audio", "jingle", k + ".wav"))
for k, f in {"wind": "Wind.wav", "river": "River.wav", "rain": "Rain.wav"}.items():
    shutil.copyfile(src("Audio", "Sounds", "Ambient", f), dst("audio", "ambient", k + ".wav"))

# --- mobília e escadas (tileset de elementos)
FURN = {"furn_cama": (1, 5, 1, 2), "furn_mesa": (2, 10, 3, 1), "furn_estante": (3, 7, 1, 2), "furn_planta": (0, 7, 1, 2),
        "furn_tapete": (13, 5, 3, 2), "furn_lareira": (8, 1, 1, 1), "furn_trofeu": (8, 7, 2, 2), "furn_relogio": (7, 10, 1, 1)}
for name, (tx, ty, tw, th) in FURN.items():
    PROPS[name] = tiles(element_t, tx, ty, tw, th)
for i, (dx, ux) in enumerate([(6, 6), (9, 9), (9, 9), (8, 8)]):
    PROPS["stairs_down_%d" % i] = tiles(element_t, dx, 11, 1, 1, False)
    PROPS["stairs_up_%d" % i] = tiles(element_t, ux, 12, 1, 1, False)

for k, im in PROPS.items():
    im.save(dst("props", k + ".png"))

# recortes do tileset de elementos (mobília, barris, placas...)
ELEMENTS = {}
meta = {"props": {k: [v.width, v.height] for k, v in PROPS.items()}}
json.dump(meta, open(dst("props", "_sizes.json"), "w"), indent=1)

if PREVIEW:
    # folha de conferência dos props recortados
    names = sorted(PROPS.keys())
    W = 1200; x = y = 6; rowh = 0
    pos = []
    for n in names:
        im = PROPS[n]; s = 2
        w, h = im.width * s, im.height * s
        if x + w + 6 > W:
            x = 6; y += rowh + 18; rowh = 0
        pos.append((n, x, y, im)); x += max(w, 60) + 8; rowh = max(rowh, h)
    from PIL import ImageDraw
    sheet = Image.new("RGBA", (W, y + rowh + 24), (70, 70, 82, 255)); d = ImageDraw.Draw(sheet)
    for n, px, py, im in pos:
        sheet.alpha_composite(im.resize((im.width * 2, im.height * 2), Image.NEAREST), (px, py + 10))
        d.text((px, py - 2), n[2:16], fill=(255, 255, 0, 255))
    sheet.save(os.path.join(SP, "props_sheet.png")); print("preview", sheet.size)

print("ok:", DST)
