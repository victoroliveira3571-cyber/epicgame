"""Peças LPC usadas no mundo (herói, NPCs, equipamentos). Compartilhado por fetch_lpc_anims.py e
build_lpc_world.py. Ids = nomes das definições em raw_assets/lpc/sheet_definitions/."""
import os, sys

sys.path.insert(0, os.path.dirname(__file__))
from build_lpc import ITEMS as WARDROBE_ITEMS  # noqa: E402

BODIES = ["male", "female"]

# Cabeças (aparência do herói e dos NPCs): id do jogo -> definição
HEADS = {
    "human_male": "heads_human_male", "human_female": "heads_human_female",
    "elderly_male": "heads_human_male_elderly", "elderly_female": "heads_human_female_elderly",
    "plump": "heads_human_male_plump", "gaunt": "heads_human_male_gaunt",
}
# Expressões: pasta do rosto (por tipo de cabeça) e dos olhos
EXPRESSIONS = ["neutral", "happy", "sad", "anger", "shock", "blush", "closed", "closing", "shame", "eyeroll", "look_l", "look_r"]
GLOBAL_FACES = ["happy2", "angry2", "tears", "sad2"]
EYE_EXPR = ["default", "neutral", "anger", "sad", "sad2", "shock", "closing", "shame", "eyeroll", "look_l", "look_r"]

EXTRA_HAIR = [
    ["cab_solto", "Solto", "hair_loose"], ["cab_meio_preso", "Meio preso", "hair_half_up"],
    ["cab_marias", "Maria-chiquinha", "hair_pigtails"], ["cab_chanel_lado", "Chanel de lado", "hair_bob_side_part"],
    ["cab_cachos_longos", "Cachos longos", "hair_curly_long"], ["cab_preso_baixo", "Preso baixo", "hair_long_tied"],
    ["cab_princesa", "Princesa", "hair_princess"], ["cab_coque_alto", "Coque alto", "hair_topknot_short"],
    ["cab_trancinhas", "Trancinhas", "hair_cornrows"], ["cab_flat_top", "Flat top", "hair_flat_top_fade"],
    ["cab_twists", "Twists", "hair_twists_fade"], ["cab_desalinhado", "Desalinhado", "hair_unkempt"],
    ["cab_franja", "Franja", "hair_bangs"], ["cab_xlongo", "Bem longo ondulado", "hair_xlong_wavy"],
    ["cab_franja_lado", "Franja de lado", "hair_parted_side_bangs"], ["cab_natural", "Natural", "hair_natural"],
    ["cab_lob", "Long bob", "hair_lob"], ["cab_bagunca2", "Bagunçado 2", "hair_messy2"],
    ["cab_liberdade", "Espetado longo", "hair_spiked_liberty"], ["cab_cacheado2", "Cacheado 2", "hair_curly_short2"],
]

# Roupas usadas pelos NPCs (além das do guarda-roupa)
NPC_DEFS = [
    "torso_clothes_robe", "torso_clothes_tunic", "torso_clothes_blouse", "torso_clothes_blouse_longsleeve",
    "torso_clothes_vest", "torso_clothes_vest_open", "torso_clothes_corset", "torso_aprons_apron", "torso_aprons_apron_full",
    "torso_aprons_apron_half", "torso_aprons_overalls", "torso_aprons_suspenders", "torso_jacket_tabard", "torso_jacket_frock",
    "torso_jacket_collared", "torso_jacket_trench", "dress_bodice", "dress_sash", "dress_slit", "cape_solid", "cape_trim",
    "cape_tattered", "belt_leather", "belt_robe", "belt_sash", "belt_formal", "legs_skirt_straight", "legs_skirt_belle",
    "legs_skirt_overskirt", "legs_widepants", "legs_hose", "neck_necklace_simple", "neck_scarf", "neck_amulet_star",
    "neck_amulet_cross", "neck_capeclip", "beards_winter", "beards_bigstache", "beards_french", "quiver",
    "hat_helmet_horned", "hat_helmet_barbarian", "arms_gloves",
    "head_horns_demon", "wings_bat", "tail_lizard",   # Rei Demônio
]

# Equipamento visível por slot e tier (0..5). Cada entrada: (definições, material, paleta de metal/cor)
EQUIP_VISUALS = {
    "armor": [
        (["torso_armour_leather"], "cloth", "leather"),                                   # Armadura de Couro
        (["torso_chainmail", "arms_bracers"], "metal", "steel"),                           # Cota de Malha
        (["torso_armour_plate", "arms_bracers"], "metal", "silver"),                       # Peitoral de Aço
        (["torso_armour_plate", "shoulders_pauldrons", "arms_armour"], "cloth", "bluegray"),  # Couraça de Mithril
        (["torso_armour_legion", "shoulders_legion", "arms_armour"], "cloth", "lavender"),     # Couraça Rúnica
        (["torso_armour_plate", "shoulders_pauldrons", "arms_armour", "bauldron"], "metal", "gold"),  # Dracônica
    ],
    "helmet": [
        (["hat_hood_cloth"], "cloth", "leather"),
        (["hat_helmet_nasal"], "metal", "steel"),
        (["hat_helmet_barbuta"], "metal", "silver"),
        (["hat_helmet_armet"], "cloth", "bluegray"),
        (["hat_helmet_spangenhelm"], "cloth", "lavender"),
        (["hat_formal_crown"], "metal", "gold"),
    ],
    "boots": [
        (["feet_boots_basic"], "cloth", "leather"),
        (["feet_boots_fold"], "cloth", "walnut"),
        (["feet_armour"], "metal", "silver"),
        (["feet_armour"], "cloth", "bluegray"),
        (["feet_armour"], "cloth", "lavender"),
        (["feet_armour"], "metal", "gold"),
    ],
    "shield": [
        (["shield_round"], "", ""),
        (["shield_round"], "metal", "steel"),
        (["shield_heater_wood"], "", ""),
        (["shield_spartan"], "cloth", "bluegray"),
        (["shield_crusader"], "", ""),
        (["shield_spartan"], "metal", "gold"),
    ],
    "legs_heavy": (["legs_armour"], "metal", ""),
}

# Armas: visual -> camadas {z, anim: arquivo} (variante em {v}, a primeira que existir em `v`).
# "slash" de 128 px vai direto nas células de golpe. `metal` = cor recolorível pela paleta de metal.
def _w(fg, bg, v, metal=False):
    return {"fg": fg, "bg": bg, "v": v, "metal": metal}


_STAFF = lambda name, v: _w(
    {"walk": f"weapon/magic/{name}/universal/foreground/walk/{{v}}.png", "hurt": f"weapon/magic/{name}/universal/foreground/hurt/{{v}}.png",
     "thrust": f"weapon/magic/{name}/thrust/foreground/{{v}}.png"},
    {"walk": f"weapon/magic/{name}/universal/background/walk/{{v}}.png", "hurt": f"weapon/magic/{name}/universal/background/hurt/{{v}}.png",
     "thrust": f"weapon/magic/{name}/thrust/background/{{v}}.png"}, v)
_BOW = lambda name, v: _w(
    {"walk": f"weapon/ranged/bow/{name}/walk/foreground/{{v}}.png", "hurt": f"weapon/ranged/bow/{name}/universal/foreground/hurt/{{v}}.png",
     "shoot": f"weapon/ranged/bow/{name}/universal/foreground/shoot/{{v}}.png"},
    {"walk": f"weapon/ranged/bow/{name}/walk/background/{{v}}.png", "hurt": f"weapon/ranged/bow/{name}/universal/background/hurt/{{v}}.png",
     "shoot": f"weapon/ranged/bow/{name}/universal/background/shoot/{{v}}.png"}, v)

WEAPON_VISUALS = {
    "arming": _w({"walk": "weapon/sword/arming/universal/fg/walk/{v}.png", "idle": "weapon/sword/arming/universal/fg/idle/{v}.png",
                  "hurt": "weapon/sword/arming/universal/fg/hurt/{v}.png", "combat_idle": "weapon/sword/arming/universal/fg/combat_idle/{v}.png",
                  "slash": "weapon/sword/arming/attack_slash/fg/{v}.png"},
                 {"walk": "weapon/sword/arming/universal/bg/walk/{v}.png", "idle": "weapon/sword/arming/universal/bg/idle/{v}.png",
                  "hurt": "weapon/sword/arming/universal/bg/hurt/{v}.png", "combat_idle": "weapon/sword/arming/universal/bg/combat_idle/{v}.png",
                  "slash": "weapon/sword/arming/attack_slash/bg/{v}.png"}, ["steel"], True),
    "saber": _w({"walk": "weapon/sword/saber/walk/{v}.png", "hurt": "weapon/sword/saber/hurt/{v}.png", "slash": "weapon/sword/saber/attack_slash/{v}.png"},
                {"walk": "weapon/sword/saber/universal_behind/walk/{v}.png", "hurt": "weapon/sword/saber/universal_behind/hurt/{v}.png",
                 "slash": "weapon/sword/saber/attack_slash/behind/{v}.png"}, ["saber"], True),
    "longsword": _w({"walk": "weapon/sword/longsword/walk/{v}.png", "hurt": "weapon/sword/longsword/hurt/{v}.png",
                     "slash": "weapon/sword/longsword/attack_slash/{v}.png", "thrust": "weapon/sword/longsword/attack_thrust/{v}.png"},
                    {"walk": "weapon/sword/longsword/universal_behind/walk/{v}.png", "hurt": "weapon/sword/longsword/universal_behind/hurt/{v}.png",
                     "slash": "weapon/sword/longsword/attack_slash/behind/{v}.png"}, ["longsword"], True),
    "waraxe": _w({"walk": "weapon/blunt/waraxe/walk/{v}.png", "hurt": "weapon/blunt/waraxe/hurt/{v}.png", "slash": "weapon/blunt/waraxe/attack_slash/{v}.png"},
                 {"walk": "weapon/blunt/waraxe/behind/walk/{v}.png", "slash": "weapon/blunt/waraxe/attack_slash/behind/{v}.png"}, ["waraxe"], True),
    "mace": _w({"walk": "weapon/blunt/mace/walk/{v}.png", "hurt": "weapon/blunt/mace/hurt/{v}.png", "slash": "weapon/blunt/mace/attack_slash/{v}.png",
                "thrust": "weapon/blunt/mace/thrust/{v}.png"},
               {"walk": "weapon/blunt/mace/universal_behind/walk/{v}.png", "hurt": "weapon/blunt/mace/universal_behind/hurt/{v}.png",
                "slash": "weapon/blunt/mace/attack_slash/behind/{v}.png"}, ["mace"], True),
    "dagger": _w({"walk": "weapon/sword/dagger/walk/{v}.png", "slash": "weapon/sword/dagger/slash/{v}.png",
                  "thrust": "weapon/sword/dagger/thrust/{v}.png", "hurt": "weapon/sword/dagger/hurt/{v}.png"},
                 {"walk": "weapon/sword/dagger/behind/walk/{v}.png", "slash": "weapon/sword/dagger/behind/slash/{v}.png"}, ["dagger"], True),
    "katana": _w({"walk": "weapon/sword/katana/walk/{v}.png", "slash": "weapon/sword/katana/slash/{v}.png"},
                 {"walk": "weapon/sword/katana/walk/behind/{v}.png", "slash": "weapon/sword/katana/slash/behind/{v}.png"}, ["katana"], True),
    "rapier": _w({"walk": "weapon/sword/rapier/walk/{v}.png", "hurt": "weapon/sword/rapier/hurt/{v}.png", "slash": "weapon/sword/rapier/attack_slash/{v}.png"},
                 {"walk": "weapon/sword/rapier/universal_behind/walk/{v}.png", "slash": "weapon/sword/rapier/attack_slash/behind/{v}.png"}, ["rapier"], True),
    "scimitar": _w({"walk": "weapon/sword/scimitar/walk/{v}.png", "slash": "weapon/sword/scimitar/slash/{v}.png"},
                   {"walk": "weapon/sword/scimitar/walk/behind/{v}.png", "slash": "weapon/sword/scimitar/slash/behind/{v}.png"}, ["scimitar"], True),
    "staff": _w({"walk": "weapon/magic/simple/foreground/walk/{v}.png", "spellcast": "weapon/magic/simple/foreground/spellcast/{v}.png",
                 "thrust": "weapon/magic/simple/foreground/thrust/{v}.png", "hurt": "weapon/magic/simple/foreground/hurt/{v}.png"},
                {"walk": "weapon/magic/simple/background/walk/{v}.png", "spellcast": "weapon/magic/simple/background/spellcast/{v}.png",
                 "thrust": "weapon/magic/simple/background/thrust/{v}.png", "hurt": "weapon/magic/simple/background/hurt/{v}.png"}, ["simple"]),
    "gnarled": _STAFF("gnarled", ["medium", "dark", "gnarled"]),
    "loop": _STAFF("loop", ["light", "medium", "loop"]),
    "s_staff": _STAFF("s", ["red", "dark", "medium"]),
    "diamond": _STAFF("diamond", ["diamond", "light", "silver", "medium"]),
    "crystal": _STAFF("crystal", ["purple", "blue", "crystal"]),
    "diamond_gold": _STAFF("diamond", ["gold", "brass"]),
    "bow": _w({"walk": "weapon/ranged/bow/normal/universal/foreground/walk/{v}.png", "shoot": "weapon/ranged/bow/normal/universal/foreground/shoot/{v}.png",
               "hurt": "weapon/ranged/bow/normal/universal/foreground/hurt/{v}.png"},
              {"walk": "weapon/ranged/bow/normal/universal/background/walk/{v}.png", "shoot": "weapon/ranged/bow/normal/universal/background/shoot/{v}.png",
               "hurt": "weapon/ranged/bow/normal/universal/background/hurt/{v}.png"}, ["medium"]),
    "bow_dark": _w({"walk": "weapon/ranged/bow/normal/universal/foreground/walk/{v}.png", "shoot": "weapon/ranged/bow/normal/universal/foreground/shoot/{v}.png"},
                   {"walk": "weapon/ranged/bow/normal/universal/background/walk/{v}.png", "shoot": "weapon/ranged/bow/normal/universal/background/shoot/{v}.png"}, ["dark"]),
    "recurve": _BOW("recurve", ["medium", "recurve"]),
    "recurve_light": _BOW("recurve", ["light", "silver"]),
    "recurve_dark": _BOW("recurve", ["dark", "iron"]),
    "great_light": _BOW("great", ["light", "silver"]),
    "great": _BOW("great", ["medium", "great"]),
    "great_gold": _BOW("great", ["gold", "brass"]),
    "spear": _w({"walk": "weapon/polearm/spear/foreground/walk/{v}.png", "thrust": "weapon/polearm/spear/foreground/thrust/{v}.png",
                 "hurt": "weapon/polearm/spear/foreground/hurt/{v}.png"},
                {"walk": "weapon/polearm/spear/background/walk/{v}.png", "thrust": "weapon/polearm/spear/background/thrust/{v}.png",
                 "hurt": "weapon/polearm/spear/background/hurt/{v}.png"}, ["steel", "iron"]),
}
# família da classe -> visual padrão (NPCs e oponentes)
WEAPON_DEFAULT = {"sword": "arming", "dagger": "dagger", "staff": "staff", "bow": "recurve", "spear": "spear"}


def wardrobe_def_ids():
    out = []
    for row in WARDROBE_ITEMS:
        out += row[4]
        ex = row[5] if len(row) > 5 else {}
        out += ex.get("female", [])
    return out


def equip_def_ids():
    out = []
    for slot, tiers in EQUIP_VISUALS.items():
        if isinstance(tiers, tuple):
            out += tiers[0]
        else:
            for t in tiers:
                out += t[0]
    return out


def all_def_ids():
    ids = ["body"] + list(HEADS.values()) + ["eyebrows_thick", "eyebrows_thin"]
    ids += [h[2] for h in EXTRA_HAIR] + NPC_DEFS + wardrobe_def_ids() + equip_def_ids()
    return sorted(set(ids))


EXTRA_DIRS = []
for _h in ["male", "female", "elderly"]:
    for _e in EXPRESSIONS:
        EXTRA_DIRS.append(f"head/faces/{_h}/{_e}/")
for _e in GLOBAL_FACES:
    EXTRA_DIRS.append(f"head/faces/global/{_e}/")
for _a in ["adult", "elderly"]:
    for _e in EYE_EXPR:
        EXTRA_DIRS.append(f"eyes/human/{_a}/{_e}/")
EXTRA_DIRS += ["head/wrinkles/", "head/nose/big/adult/", "head/nose/button/adult/"]

EXTRA_DIRS += ["body/bodies/muscular/"]

EXTRA_FILES = []
for _w2 in WEAPON_VISUALS.values():
    for _side in ("fg", "bg"):
        for _anim, _path in _w2[_side].items():
            for _v in _w2["v"]:
                EXTRA_FILES.append(_path.format(v=_v))
