"""Baixa do repositório do LPC (Universal LPC Spritesheet Character Generator) as animações que o
herói e os NPCs usam no mundo: andar, parado, golpe, estocada, magia, arco, dano, gesto e sentar.

Grava em EPICGAME/raw_assets/lpc/spritesheets/ (mesma estrutura do repositório). Arquivos que já
existem não são baixados de novo. Uso (da pasta game/):  python3 tools/fetch_lpc_anims.py
"""
import json, os, glob, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

RAW = "../raw_assets/lpc/"
SHEETS = RAW + "spritesheets/"
BASE_URL = "https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/master/spritesheets/"
ANIMS = ["walk", "sit", "idle", "slash", "thrust", "spellcast", "shoot", "hurt", "emote", "combat_idle"]
BODIES = ["male", "female"]

sys.path.insert(0, os.path.dirname(__file__))
from lpc_parts import all_def_ids, EXTRA_DIRS, EXTRA_FILES  # noqa: E402


def load_defs():
    defs = {}
    for f in glob.glob(RAW + "sheet_definitions/**/*.json", recursive=True):
        try:
            defs[os.path.basename(f)[:-5]] = json.load(open(f))
        except Exception:
            pass
    return defs


VARIANT_PREF = ["white", "gray", "light gray", "steel", "silver", "brown", "leather", "medium", "simple"]


def variant_of(d):
    v = d.get("variants") or []
    for p in VARIANT_PREF:
        if p in v:
            return p
    return v[0] if v else ""


def dirs_for(d):
    out = set()
    for lk in (k for k in d if k.startswith("layer_")):
        lay = d[lk]
        if lay.get("custom_animation"):
            continue
        for bt in BODIES:
            p = lay.get(bt) or lay.get("male")
            if p and "${" not in p:
                out.add(p)
    return out


def fetch(rel):
    dst = SHEETS + rel
    if os.path.exists(dst):
        return "ok"
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    r = subprocess.run(["curl", "-s", "-f", "-o", dst, BASE_URL + rel])
    if r.returncode != 0:
        if os.path.exists(dst):
            os.remove(dst)
        return "404"
    return "new"


def main():
    defs = load_defs()
    dirs = set(EXTRA_DIRS)
    missing = []
    variants = {}
    for did in all_def_ids():
        if did not in defs:
            missing.append(did)
            continue
        ds = dirs_for(defs[did])
        dirs |= ds
        v = variant_of(defs[did])
        if v:
            for dd in ds:
                variants[dd] = v
    jobs = [d + a + ".png" for d in sorted(dirs) for a in ANIMS] + list(EXTRA_FILES)
    # peças com variantes de cor ficam em <pasta><anim>/<variante>.png
    jobs += [d + a + "/" + variants[d] + ".png" for d in sorted(variants) for a in ANIMS]
    json.dump(variants, open(RAW + "variants_chosen.json", "w"), indent=1)
    with ThreadPoolExecutor(24) as ex:
        res = list(ex.map(fetch, jobs))
    print(f"{len(dirs)} pastas, {len(jobs)} arquivos: {res.count('new')} novos, {res.count('ok')} já havia, "
          f"{res.count('404')} sem a animação. Definições não achadas: {missing}")


if __name__ == "__main__":
    main()
