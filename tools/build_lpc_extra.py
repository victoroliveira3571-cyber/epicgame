"""v3.7: peças LPC extras para as armaduras dos materiais altos (asas, elmos fechados, viseiras, plumas,
cristas, chifres e ombreiras). Monta cada peça no mesmo atlas do mundo (layout de build_lpc_world.py), marca as
cores trocáveis e soma os autores e licenças ao catalog.json. Não apaga nada do que já existe em assets/lpcw/.

Baixar as peças (uma vez), da pasta acima de game/:
  git clone --depth 1 --filter=blob:none --sparse \\
      https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator raw_assets/lpc
  cd raw_assets/lpc && git sparse-checkout set --no-cone /sheet_definitions/ /palette_definitions/ /CREDITS.csv \\
      $(python3 ../../game/tools/build_lpc_extra.py --dirs)
Montar (da pasta game/):  python3 tools/build_lpc_extra.py
Outra pasta do LPC:       LPC_RAW=/caminho/lpc/ python3 tools/build_lpc_extra.py
"""
import json, os, sys

RAW = os.environ.get("LPC_RAW", "../raw_assets/lpc/")
if not RAW.endswith("/"):
    RAW += "/"

# peça -> (definição em sheet_definitions/, variante de cor ou "", material para as cores trocáveis)
EXTRA = {
    "wings_feathered": ("body/wings/wings_feathered.json", "white", "cloth"),
    "wings_lunar": ("body/wings/wings_lunar.json", "white", "cloth"),
    "hat_helmet_greathelm": ("headwear/helmets/helmets/hat_helmet_greathelm.json", "", "metal"),
    "hat_helmet_close": ("headwear/helmets/helmets/hat_helmet_close.json", "", "metal"),
    "hat_helmet_maximus": ("headwear/helmets/helmets/hat_helmet_maximus.json", "", "metal"),
    "hat_helmet_legion": ("headwear/helmets/helmets/hat_helmet_legion.json", "", "metal"),
    "hat_helmet_bascinet": ("headwear/helmets/helmets/hat_helmet_bascinet.json", "", "metal"),
    "hat_helmet_bascinet_round": ("headwear/helmets/helmets/hat_helmet_bascinet_round.json", "", "metal"),
    "hat_helmet_sugarloaf": ("headwear/helmets/helmets/hat_helmet_sugarloaf.json", "", "metal"),
    "hat_visor_slit": ("headwear/helmets/visors/hat_visor_slit.json", "", "metal"),
    "hat_visor_grated": ("headwear/helmets/visors/hat_visor_grated.json", "", "metal"),
    "hat_accessory_plumage": ("headwear/helmets/accessories/hat_accessory_plumage.json", "", "cloth"),
    "hat_accessory_crest": ("headwear/helmets/accessories/hat_accessory_crest.json", "", "metal"),
    "hat_accessory_horns_upward": ("headwear/helmets/accessories/hat_accessory_horns_upward.json", "", "metal"),
    "hat_accessory_wings": ("headwear/helmets/accessories/hat_accessory_wings.json", "", "metal"),
    "shoulders_mantal": ("arms/shoulders/shoulders_mantal.json", "", "cloth"),
    "shoulders_epaulets": ("arms/shoulders/shoulders_epaulets.json", "", "cloth"),
}


def layer_dirs(d):
    out = []
    for k in sorted(k for k in d if k.startswith("layer_")):
        lay = d[k]
        if lay.get("custom_animation"):
            continue
        for bt in ("male", "female"):
            p = lay.get(bt) or lay.get("male")
            if p and "${" not in p:
                out.append((k, bt, p, int(lay.get("zPos", 50))))
    return out


def main():
    if "--dirs" in sys.argv:
        dirs = set()
        for pid, (rel, _v, _m) in EXTRA.items():
            d = json.load(open(RAW + "sheet_definitions/" + rel))
            for _k, _bt, p, _z in layer_dirs(d):
                dirs.add("/spritesheets/" + p)
        print(" ".join(sorted(dirs)))
        return
    import build_lpc_world as bw
    bw.RAW, bw.SHEETS = RAW, RAW + "spritesheets/"
    credits = bw.load_credits()
    cat_path = bw.OUT + "catalog.json"
    cat = json.load(open(cat_path))
    extra = cat.get("extra", {})
    own = {l["file"] for e in extra.values() for ls in e["layers"].values() for l in ls}
    authors, licenses = set(cat.get("credits", {}).get("authors", [])), set(cat.get("credits", {}).get("licenses", []))
    for pid, (rel, variant, material) in EXTRA.items():
        d = json.load(open(RAW + "sheet_definitions/" + rel))
        layers = {"male": [], "female": []}
        built = {}
        for _k, bt, p, z in layer_dirs(d):
            if variant:
                bw.VARIANTS[p] = variant
            if p not in built and os.path.exists(bw.OUT + bw.fname(p)) and bw.fname(p) not in own:
                # arquivo do build principal (build_lpc_world.py): não sobrescreve, só aponta para ele
                print("já existe (mantido):", bw.fname(p))
                built[p] = {"file": bw.fname(p), "ramp": ""}
            if p not in built:
                im = bw.build_atlas(p)
                if im is None:
                    print("sem quadros:", pid, p)
                    built[p] = None
                    continue
                slots, ramp = bw.slots_for(material, im)
                if slots:
                    im = bw.encode(im, slots)
                name = bw.fname(p)
                im.save(bw.OUT + name, optimize=True)
                built[p] = {"file": name, "ramp": ramp}
                for anim in ("walk.png", "slash.png", "idle.png", "walk/" + (variant or "x") + ".png"):
                    c = credits.get(p + anim)
                    if c:
                        authors.update(c[0])
                        licenses.update(c[1])
            if built[p]:
                layers[bt].append({"file": built[p]["file"], "z": z, "ramp": built[p]["ramp"]})
        extra[pid] = {"name": d.get("name", pid), "layers": layers}
        print("ok", pid, [l["file"] for l in layers["male"]], [l["ramp"] for l in layers["male"]])
    cat["extra"] = extra
    cat.setdefault("credits", {})["authors"] = sorted(authors, key=str.lower)
    cat["credits"]["licenses"] = sorted(licenses)
    json.dump(cat, open(cat_path, "w"), ensure_ascii=False, indent=1)
    print("catalog.json atualizado:", len(extra), "peças extras")


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    main()
