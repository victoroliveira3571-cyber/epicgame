"""Personagens LPC do mundo (herói, NPCs, oponentes da Arena): um atlas por peça com todas as
animações, no mesmo layout, e as cores trocáveis marcadas para o shader do jogo.

Lê raw_assets/lpc/ (baixe antes com tools/fetch_lpc_anims.py) e grava em game/assets/lpcw/:
  <peça>.png        atlas 1024x1536 (layout em LAYOUT; células de 64 px, golpe em células de 128 px)
  catalog.json      paletas, corpos, cabeças, rostos (expressões), peças, equipamentos e armas

Cores trocáveis: o pixel que bate com a paleta-base do material vira (R = índice*32+16, G = canal,
B = 254). Canais: 1 pele, 2 olhos, 3 cabelo, 4 cor da peça (tecido ou metal). O shader
assets/lpcw/lpc_ramp.gdshader troca pelo tom da paleta escolhida.
Uso (da pasta game/):  python3 tools/build_lpc_world.py
"""
import csv, glob, json, os, shutil, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from lpc_parts import (HEADS, EXPRESSIONS, GLOBAL_FACES, EYE_EXPR, EXTRA_HAIR, NPC_DEFS, EQUIP_VISUALS,
                       WEAPON_VISUALS, WEAPON_DEFAULT, WARDROBE_ITEMS)  # noqa: E402
from build_lpc import CATEGORIES  # noqa: E402

RAW = "../raw_assets/lpc/"
SHEETS = RAW + "spritesheets/"
PAL = RAW + "palette_definitions/"
OUT = "assets/lpcw/"
F = 64
W, H = 1024, 1792
VARIANTS = json.load(open(RAW + "variants_chosen.json")) if os.path.exists(RAW + "variants_chosen.json") else {}

# animação -> (x da coluna 0, y da linha "cima", quadros, linhas na folha, tamanho da célula)
# A metade de cima (y < 512) é a dos NPCs: andar, parado, gesto, combate, sentar, dano e magia.
LAYOUT = {
    "walk": (0, 0, 9, 4, 64), "idle": (9 * F, 0, 2, 4, 64), "emote": (11 * F, 0, 3, 4, 64),
    "combat_idle": (14 * F, 0, 2, 4, 64),
    "sit": (0, 4 * F, 3, 4, 64), "hurt": (3 * F, 4 * F, 6, 1, 64), "spellcast": (9 * F, 4 * F, 7, 4, 64),
    "shoot": (0, 8 * F, 13, 4, 64),
    "slash": (0, 12 * F, 6, 4, 128),
    "thrust": (0, 20 * F, 8, 4, 128),
}
SLOT = {"skin": 1, "eye": 2, "hair": 3, "item": 4}


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def load_pal(name):
    return {k: [hexc(c) for c in v] for k, v in json.load(open(PAL + name)).items()}


PALS = {"body": load_pal("body/body_ulpc.json"), "eye": load_pal("eye/eye_ulpc.json"),
        "hair": load_pal("hair/hair_ulpc.json"), "cloth": load_pal("cloth/cloth_ulpc.json"),
        "metal": load_pal("metal/metal_ulpc.json")}
# olhos: o desenho-base usa tons um pouco diferentes da paleta "blue"
EYE_BASE = [(41, 61, 75), (81, 135, 179), (80, 212, 236)]


def load_defs():
    defs = {}
    for f in glob.glob(RAW + "sheet_definitions/**/*.json", recursive=True):
        try:
            defs[os.path.basename(f)[:-5]] = json.load(open(f))
        except Exception:
            pass
    return defs


def src_file(d, anim):
    """Arquivo de uma animação: pasta de peça (<pasta><anim>.png) ou arma ({anim: caminho})."""
    if isinstance(d, dict):
        p = d.get(anim)
        return SHEETS + p if p and os.path.exists(SHEETS + p) else None
    p = SHEETS + d + anim + ".png"
    if os.path.exists(p):
        return p
    if d in VARIANTS:
        p = SHEETS + d + anim + "/" + VARIANTS[d] + ".png"
        if os.path.exists(p):
            return p
    return None


def _paste_frame(out, fr, x, y, cell):
    """Cola o quadro centralizado na célula; quadro maior que a célula é recortado no centro."""
    fw = fr.width
    if fw > cell:
        o = (fw - cell) // 2
        fr = fr.crop((o, o, o + cell, o + cell))
        fw = cell
    off = (cell - fw) // 2
    out.alpha_composite(fr, (x + off, y + off))


def build_atlas(d):
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    walk_p = src_file(d, "walk")
    walk = Image.open(walk_p).convert("RGBA") if walk_p else None
    wf = walk.height // 4 if walk else F
    got = False
    for anim, (x0, y0, n, rows, cell) in LAYOUT.items():
        p = src_file(d, anim)
        if p is None:
            # sem a animação: repete o quadro parado do andar (a peça não some no meio do golpe)
            if walk is None:
                continue
            for r in range(rows):
                rr = r if rows == 4 else 2
                stand = walk.crop((0, rr * wf, wf, rr * wf + wf))
                for c in range(n):
                    _paste_frame(out, stand, x0 + c * cell, y0 + r * cell, cell)
            continue
        im = Image.open(p).convert("RGBA")
        got = True
        fw = im.height // rows
        for r in range(rows):
            for c in range(min(n, im.width // fw)):
                fr = im.crop((c * fw, r * fw, c * fw + fw, r * fw + fw))
                _paste_frame(out, fr, x0 + c * cell, y0 + r * cell, cell)
    return out if got or walk is not None else None


def best_palette(colors, pals):
    """Paleta da lista que mais casa com as cores (pixels ponderados)."""
    best, best_n = None, 0
    for name, pal in pals.items():
        s = set(pal)
        n = sum(cnt for col, cnt in colors.items() if col in s)
        if n > best_n:
            best, best_n = name, n
    return best


def encode(im, slots):
    """slots: lista de (canal, paleta-base). Marca os pixels que batem com cada paleta."""
    a = np.array(im)
    rgb = a[..., :3].astype(np.int32)
    alpha = a[..., 3]
    mask_done = np.zeros(alpha.shape, bool)
    for ch, pal in slots:
        for i, col in enumerate(pal):
            d = np.abs(rgb - np.array(col)).sum(-1)
            m = (d <= 9) & (alpha > 0) & ~mask_done
            a[m, 0] = i * 32 + 16
            a[m, 1] = ch
            a[m, 2] = 254
            mask_done |= m
    return Image.fromarray(a)


def color_counts(im):
    a = np.array(im)
    px = a[a[..., 3] > 0][:, :3]
    if len(px) == 0:
        return {}
    cols, cnt = np.unique(px, axis=0, return_counts=True)
    return {tuple(int(v) for v in c): int(n) for c, n in zip(cols, cnt)}


def slots_for(material, im):
    cc = color_counts(im)
    if material == "body":
        return [(SLOT["skin"], PALS["body"]["light"]), (SLOT["eye"], EYE_BASE)], "skin"
    if material == "eye":
        return [(SLOT["eye"], EYE_BASE)], "eye"
    if material == "hair":
        return [(SLOT["hair"], PALS["hair"]["orange"])], "hair"
    if material in ("cloth", "metal"):
        name = best_palette(cc, PALS[material])
        if name is None:
            other = "metal" if material == "cloth" else "cloth"
            name = best_palette(cc, PALS[other])
            material = other if name else material
        if name:
            return [(SLOT["item"], PALS[material][name])], material + ":" + name
    # sem material declarado: tenta tecido e metal pelas cores
    for m in ("cloth", "metal"):
        name = best_palette(cc, PALS[m])
        if name and sum(cnt for c, cnt in cc.items() if c in set(PALS[m][name])) > 0.5 * sum(cc.values()):
            return [(SLOT["item"], PALS[m][name])], m + ":" + name
    # peça em tons de cinza (ex.: túnica "white"): os cinzas viram os 6 tons da paleta de tecido
    grays = sorted(c for c in cc if c[0] == c[1] == c[2])
    if grays and sum(cc[c] for c in grays) > 0.8 * sum(cc.values()) and len(grays) <= 6:
        n = len(grays)
        pal = [None] * 6
        for i, g in enumerate(grays):
            pal[round(i * 5 / max(n - 1, 1))] = g
        return [(SLOT["item"], [c if c else (-99, -99, -99) for c in pal])], "cloth:gray"
    return [], ""


def fname(d):
    return d.replace("{anim}/", "").replace("/", "_").strip("_").replace(".png", "") + ".png"


def load_credits():
    out = {}
    with open(RAW + "CREDITS.csv", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f, skipinitialspace=True):
            fn = (row.get("filename") or "").strip()
            split = lambda k: [x.strip() for x in (row.get(k) or "").split(",") if x.strip()]
            out[fn] = (split("authors"), split("licenses"))
    return out


class Builder:
    def __init__(self):
        self.done = {}
        self.credits = load_credits()
        self.authors, self.licenses = set(), set()

    def layer(self, d, material, z, name=None):
        key = (name or str(d), material)
        if key not in self.done:
            im = build_atlas(d)
            if im is None:
                self.done[key] = None
            else:
                slots, ramp = slots_for(material, im)
                if slots:
                    im = encode(im, slots)
                n = name or fname(d)
                im.save(OUT + n, optimize=True)
                self.done[key] = {"file": n, "ramp": ramp}
                base_dir = d if isinstance(d, str) else os.path.dirname(os.path.dirname(next(iter(d.values()))) + "/")
                for anim in ("walk.png", "slash.png", "idle.png"):
                    c = self.credits.get(base_dir + anim) or self.credits.get(base_dir.rstrip("/"))
                    if c:
                        self.authors.update(c[0])
                        self.licenses.update(c[1])
        info = self.done[key]
        return None if info is None else {"file": info["file"], "z": z, "ramp": info["ramp"]}


def def_layers(b, defs, did, body):
    d = defs.get(did)
    if d is None:
        return []
    rec = d.get("recolors")
    mat = rec.get("material", "") if isinstance(rec, dict) else ""
    if isinstance(rec, dict) and "color_1" in rec:
        mat = rec["color_1"].get("material", "")
    out = []
    for lk in sorted(k for k in d if k.startswith("layer_")):
        lay = d[lk]
        if lay.get("custom_animation"):
            continue
        p = lay.get(body)
        if p is None and body == "female":
            p = lay.get("male")
        if not p or "${" in p:
            continue
        l = b.layer(p, mat, int(lay.get("zPos", 50)))
        if l:
            out.append(l)
    return out


def main():
    defs = load_defs()
    if os.path.isdir(OUT):
        for f in glob.glob(OUT + "*.png"):
            os.remove(f)
    os.makedirs(OUT, exist_ok=True)
    b = Builder()
    cat = {"frame": F, "size": [W, H], "layout": LAYOUT,
           "palettes": {k: {n: ["%02x%02x%02x" % c for c in pal] for n, pal in v.items()} for k, v in PALS.items()}}
    # corpos, cabeças, rostos e olhos
    cat["bodies"] = {bt: def_layers(b, defs, "body", bt) for bt in ("male", "female", "muscular")}
    heads = {}
    for hid, did in HEADS.items():
        face_set = "elderly" if "elderly" in hid else ("female" if "female" in hid else "male")
        heads[hid] = {"male": def_layers(b, defs, did, "male"), "female": def_layers(b, defs, did, "female"),
                      "faces": face_set, "eyes": "elderly" if "elderly" in hid else "adult"}
    cat["heads"] = heads
    faces = {}
    for fs in ("male", "female", "elderly"):
        faces[fs] = {}
        for e in EXPRESSIONS:
            l = b.layer(f"head/faces/{fs}/{e}/", "body", 101)
            if l:
                faces[fs][e] = l
    faces["global"] = {}
    for e in GLOBAL_FACES:
        l = b.layer(f"head/faces/global/{e}/", "body", 102)
        if l:
            faces["global"][e] = l
    cat["faces"] = faces
    eyes = {}
    for age in ("adult", "elderly"):
        eyes[age] = {}
        for e in EYE_EXPR:
            l = b.layer(f"eyes/human/{age}/{e}/", "eye", 105)
            if l:
                eyes[age][e] = l
    cat["eyes"] = eyes
    cat["brows"] = {k: b.layer(f"eyes/eyebrows/{k}/adult/", "hair", 106) for k in ("thick", "thin")}
    cat["wrinkles"] = b.layer("head/wrinkles/", "body", 102)

    # peças: guarda-roupa (mesmos ids do Lpc.gd), cabelos extras e roupas dos NPCs
    parts = {}

    def add_part(pid, name, cat_id, price, def_ids, ex):
        lay = {}
        for bt in ("male", "female"):
            ids = ex.get("female", def_ids) if bt == "female" else def_ids
            ls = []
            for did in ids:
                ls += def_layers(b, defs, did, bt)
            lay[bt] = ls
        if not lay["male"] and not lay["female"]:
            print("sem camadas:", pid, def_ids)
            return
        for bt in ("male", "female"):
            if not lay[bt]:
                lay[bt] = lay["female" if bt == "male" else "male"]
        p = {"name": name, "cat": cat_id, "price": price, "layers": lay}
        for k in ("color", "hides", "head"):
            if k in ex:
                p[k] = ex[k]
        parts[pid] = p

    for row in WARDROBE_ITEMS:
        add_part(row[0], row[2], row[1], row[3], row[4], row[5] if len(row) > 5 else {})
    for pid, name, did in EXTRA_HAIR:
        add_part(pid, name, "cabelo", 0, [did], {})
    for did in NPC_DEFS:
        add_part("npc_" + did, did, "npc", 0, [did], {})
    cat["parts"] = parts

    equip = {}
    for slot, tiers in EQUIP_VISUALS.items():
        if isinstance(tiers, tuple):
            tiers = [tiers]
        equip[slot] = []
        for ids, mat, palname in tiers:
            lay = {}
            for bt in ("male", "female"):
                ls = []
                for did in ids:
                    ls += def_layers(b, defs, did, bt)
                lay[bt] = ls
            equip[slot].append({"layers": lay, "material": mat, "palette": palname})
    cat["equip"] = equip

    weapons = {}
    for wid, w in WEAPON_VISUALS.items():
        ls = []
        for side, z in (("bg", 9), ("fg", 140)):
            files = {}
            for anim, path in w[side].items():
                for v in w["v"]:
                    if os.path.exists(SHEETS + path.format(v=v)):
                        files[anim] = path.format(v=v)
                        break
            if not files:
                continue
            l = b.layer(files, "metal" if w.get("metal") else "", z, "weapon_%s_%s.png" % (wid, side))
            if l:
                ls.append(l)
        weapons[wid] = ls
    cat["weapon_default"] = WEAPON_DEFAULT
    cat["weapons"] = weapons
    cat["categories"] = CATEGORIES
    cat["credits"] = {"authors": sorted(b.authors, key=str.lower), "licenses": sorted(b.licenses)}
    cat["source"] = "Universal LPC Spritesheet Character Generator - github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator"
    json.dump(cat, open(OUT + "catalog.json", "w"), ensure_ascii=False, indent=1)
    n = len([v for v in b.done.values() if v])
    size = sum(os.path.getsize(f) for f in glob.glob(OUT + "*.png")) / 1e6
    print(f"{len(parts)} peças, {n} atlas ({size:.1f} MB)")


if __name__ == "__main__":
    main()
