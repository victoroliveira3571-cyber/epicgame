"""Monstros do Dungeon Tileset II (0x72, CC0) -> tiras horizontais em game/assets/custom/dt2/ e scripts/core/DT2Data.gd.
Uso (da pasta game/):  python3 tools/build_dt2.py
Cada monstro gera <id>_idle.png, <id>_run.png e as versões espelhadas <id>_idle_l.png e <id>_run_l.png.
"""
import glob, os, re
from PIL import Image, ImageOps

SRC = "../Recursos baixados por mim/baixados_pelo_claude/0x72_dungeon2/x_0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7/frames/"
OUT = "assets/custom/dt2/"
# id do jogo -> nome no pack
MONSTERS = {
    "duende": "goblin", "diabrete": "imp", "chort": "chort", "orc_mascarado": "masked_orc", "orc_guerreiro": "orc_warrior",
    "orc_xama": "orc_shaman", "abobora": "pumpkin_dude", "zumbi": "zombie", "zumbi_pequeno": "tiny_zombie", "zumbi_gelo": "ice_zombie",
    "lodoso": "muddy", "pantaneiro": "swampy", "necromante": "necromancer", "wogol": "wogol", "lesma": "slug", "lesminha": "tiny_slug",
    "ogro": "ogre", "demonio_grande": "big_demon", "zumbi_grande": "big_zombie", "anjo": "angel", "doutor": "doc",
}


def frames(prefix):
    files = sorted(glob.glob(SRC + prefix + "_f*.png"), key=lambda f: int(re.search(r"_f(\d+)\.png", f).group(1)))
    return [Image.open(f).convert("RGBA") for f in files]


def strip(ims, flip=False):
    w = max(i.width for i in ims)
    h = max(i.height for i in ims)
    out = Image.new("RGBA", (w * len(ims), h), (0, 0, 0, 0))
    for k, im in enumerate(ims):
        if flip:
            im = ImageOps.mirror(im)
        out.paste(im, (k * w + (w - im.width) // 2, h - im.height))
    return out, w, h


os.makedirs(OUT, exist_ok=True)
data = {}
for gid, name in MONSTERS.items():
    idle = frames(name + "_idle_anim") or frames(name + "_anim")
    run = frames(name + "_run_anim") or frames(name + "_anim") or idle
    if not idle:
        print("sem quadros:", name)
        continue
    for tag, ims in (("idle", idle), ("run", run)):
        s, w, h = strip(ims)
        s.save(OUT + "%s_%s.png" % (gid, tag))
        s2, _, _ = strip(ims, True)
        s2.save(OUT + "%s_%s_l.png" % (gid, tag))
        data.setdefault(gid, {})[tag] = len(ims)
        data[gid]["w"] = max(data[gid].get("w", 0), w)
        data[gid]["h"] = max(data[gid].get("h", 0), h)
    print(gid, data[gid])
lines = ["class_name DT2Data", "extends RefCounted", "", "## Gerado por tools/build_dt2.py (Dungeon Tileset II, 0x72, CC0). w/h = tamanho do quadro; idle/run = quantidade de quadros.", "const SIZES := {"]
for gid, d in data.items():
    lines.append('\t"%s": {"w": %d, "h": %d, "idle": %d, "run": %d},' % (gid, d["w"], d["h"], d["idle"], d["run"]))
lines.append("}")
open("scripts/core/DT2Data.gd", "w").write("\n".join(lines) + "\n")
