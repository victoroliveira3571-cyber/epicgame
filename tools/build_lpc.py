"""Monta o guarda-roupa LPC do herói (cenas do Pomodoro + loja de visuais).

Lê as peças baixadas em EPICGAME/raw_assets/lpc/ (Universal LPC Spritesheet Character Generator)
e grava em game/assets/lpc/:
  <caminho_da_peca>.png   tira 704x64 = 11 quadros de 64x64:
                          0 = sentado na cadeira (de lado, virado à direita)
                          1 = sentado no chão (de lado, virado à direita)
                          2..10 = andando para a direita (9 quadros; o 2 é parado)
  catalog.json            categorias, peças (nome, preço, camadas com zPos, tingível), cores e créditos.

Peças de pano e cabelo viram tons de cinza (o jogo multiplica pela cor escolhida).
Uso (da pasta game/):  python3 tools/build_lpc.py
"""
import csv, json, os, glob, shutil
from PIL import Image

RAW = "../raw_assets/lpc/"
SHEETS = RAW + "spritesheets/"
OUT = "assets/lpc/"
F = 64
BODIES = ["male", "female"]

# cores para tingir (nome, hex)
DYES = [
    ["Branco", "f2efe6"], ["Cinza", "8e8c96"], ["Preto", "3a3640"], ["Vermelho", "c8463c"], ["Vinho", "7e2f3e"],
    ["Laranja", "e0813a"], ["Amarelo", "e8c84a"], ["Verde", "5f9e4a"], ["Musgo", "56663a"], ["Azul", "3f6fc0"],
    ["Marinho", "2e3f6e"], ["Céu", "7fb5e0"], ["Roxo", "7a52a8"], ["Rosa", "e08fb0"], ["Marrom", "8a5a36"], ["Bege", "d8c49a"],
]
HAIR = [
    ["Preto", "3b3138"], ["Castanho", "6b4430"], ["Castanho claro", "9a6a42"], ["Ruivo", "c0592c"], ["Loiro", "e0c070"],
    ["Platinado", "eae2cf"], ["Grisalho", "a8a4a8"], ["Azul", "5a7ad8"], ["Rosa", "e07fb0"], ["Verde", "5aa86a"], ["Roxo", "8a5ac0"],
]

# categoria -> [nome, slot]. Slots: uma peça por slot. "base" = escolhas grátis de aparência.
CATEGORIES = [
    ["cabelo", "Cabelo", "cabelo"], ["barba", "Barba", "barba"],
    ["chapeu", "Chapéus", "cabeca"], ["touca", "Toucas", "cabeca"], ["oculos", "Óculos", "oculos"],
    ["mascara", "Máscaras", "mascara"], ["camisa", "Camisas", "torso"], ["blusa", "Blusas", "torso"],
    ["blusa_frio", "Blusas de frio", "torso"], ["calca", "Calças", "pernas"], ["short", "Shorts e saias", "pernas"],
    ["sapato", "Sapatos", "pes"], ["fantasia", "Fantasias", "fantasia"],
]

# id, categoria, nome, preço (créditos de estudo), definições LPC, extras
# extras: color = cor padrão (hex), hides = slots escondidos (fantasia), head = troca a cabeça
ITEMS = [
    # cabelo (grátis)
    ["cab_liso", "cabelo", "Liso", 0, ["hair_plain"]], ["cab_baguncado", "cabelo", "Bagunçado", 0, ["hair_messy1"]],
    ["cab_acordei", "cabelo", "Recém-acordado", 0, ["hair_bedhead"]], ["cab_raspado", "cabelo", "Raspado", 0, ["hair_buzzcut"]],
    ["cab_cacheado", "cabelo", "Cacheado curto", 0, ["hair_curly_short"]], ["cab_afro", "cabelo", "Afro", 0, ["hair_afro"]],
    ["cab_espetado", "cabelo", "Espetado", 0, ["hair_spiked"]], ["cab_topete", "cabelo", "Topete", 0, ["hair_swoop"]],
    ["cab_repartido", "cabelo", "Repartido", 0, ["hair_parted"]], ["cab_pixie", "cabelo", "Pixie", 0, ["hair_pixie"]],
    ["cab_chanel", "cabelo", "Chanel", 0, ["hair_bob"]], ["cab_longo", "cabelo", "Longo", 0, ["hair_long"]],
    ["cab_longo_liso", "cabelo", "Longo liso", 0, ["hair_long_straight"]], ["cab_ondulado", "cabelo", "Ondulado", 0, ["hair_wavy"]],
    ["cab_rabo", "cabelo", "Rabo de cavalo", 0, ["hair_ponytail"]], ["cab_rabo_alto", "cabelo", "Rabo alto", 0, ["hair_high_ponytail"]],
    ["cab_tranca", "cabelo", "Trança", 0, ["hair_braid"]], ["cab_coque", "cabelo", "Coque", 0, ["hair_bangs_bun"]],
    ["cab_dread", "cabelo", "Dreads", 0, ["hair_dreadlocks_short"]], ["cab_moicano", "cabelo", "Moicano", 0, ["hair_shorthawk"]],
    ["cab_careca", "cabelo", "Calvície", 0, ["hair_balding"]],
    # barba (grátis)
    ["bar_por_fazer", "barba", "Por fazer", 0, ["beards_5oclock_shadow"]], ["bar_aparada", "barba", "Aparada", 0, ["beards_trimmed"]],
    ["bar_media", "barba", "Média", 0, ["beards_medium"]], ["bar_cheia", "barba", "Cheia", 0, ["beards_beard"]],
    ["bar_bigode", "barba", "Bigode", 0, ["beards_mustache"]], ["bar_bigodao", "barba", "Bigodão", 0, ["beards_walrus"]],
    ["bar_guidao", "barba", "Bigode guidão", 0, ["beards_handlebar"]],
    # chapéus
    ["cartola", "chapeu", "Cartola", 80, ["hat_formal_tophat"]], ["coco", "chapeu", "Chapéu-coco", 60, ["hat_formal_bowler"]],
    ["boina_couro", "chapeu", "Boné de couro", 40, ["hat_cap_leather"], {"color": "8a5a36"}],
    ["chapeu_pena", "chapeu", "Chapéu com pena", 90, ["hat_cap_cavalier", "hat_cap_cavalier_feather"]],
    ["bonnie", "chapeu", "Chapéu de aba", 70, ["hat_cap_bonnie", "hat_cap_bonnie_feather"]],
    ["tricornio", "chapeu", "Tricórnio", 70, ["hat_tricorne"]], ["bicorne", "chapeu", "Bicorne", 70, ["hat_bicorne_athwart_basic"]],
    ["chapeu_mago", "chapeu", "Chapéu de mago", 120, ["hat_magic_wizard", "hat_magic_wizard_belt", "hat_magic_wizard_buckle"]],
    ["chapeu_lua", "chapeu", "Chapéu celestial", 140, ["hat_magic_celestial_moon"]],
    ["tiara", "chapeu", "Tiara", 150, ["hat_formal_tiara"]], ["coroa", "chapeu", "Coroa", 250, ["hat_formal_crown"]],
    # toucas
    ["capuz", "touca", "Capuz", 40, ["hat_hood_cloth"], {"color": "56663a"}],
    ["capuz_saco", "touca", "Capuz de saco", 30, ["hat_hood_sack_cloth"], {"color": "d8c49a"}],
    ["bandana", "touca", "Bandana", 25, ["hat_bandana"], {"color": "c8463c"}],
    ["bandana2", "touca", "Bandana com borda", 30, ["hat_bandana2"], {"color": "3f6fc0"}],
    ["hijab", "touca", "Hijab", 40, ["hat_hood_hijab"], {"color": "7a52a8"}],
    ["gorro_natal", "touca", "Gorro de Natal", 80, ["hat_holiday_christmas", "hat_holiday_santa"]],
    # óculos
    ["oc_simples", "oculos", "Óculos simples", 30, ["facial_glasses"]], ["oc_redondo", "oculos", "Óculos redondos", 30, ["facial_glasses_round"]],
    ["oc_nerd", "oculos", "Óculos de nerd", 35, ["facial_glasses_nerd"]], ["oc_meia_lua", "oculos", "Meia-lua", 35, ["facial_glasses_halfmoon"]],
    ["oc_gatinho", "oculos", "Gatinho", 35, ["facial_glasses_secretary"]], ["oc_escuro", "oculos", "Óculos escuros", 50, ["facial_glasses_shades"]],
    ["oc_sol", "oculos", "Óculos de sol", 50, ["facial_glasses_sunglasses"]], ["monoculo", "oculos", "Monóculo", 60, ["facial_monocle_right"]],
    # máscaras
    ["mascara_lisa", "mascara", "Máscara", 40, ["facial_mask_plain"]],
    ["tapa_olho", "mascara", "Tapa-olho", 30, ["facial_eyepatch_left"]],
    ["tapa_olho2", "mascara", "Tapa-olho pequeno", 25, ["facial_eyepatch_small_left"]],
    # camisas
    ["camiseta", "camisa", "Camiseta", 0, ["torso_clothes_tshirt"], {"color": "3f6fc0"}],
    ["camiseta_v", "camisa", "Camiseta gola V", 30, ["torso_clothes_tshirt_vneck"], {"color": "f2efe6"}],
    ["camiseta_botao", "camisa", "Camiseta com botões", 35, ["torso_clothes_tshirt_buttoned"], {"color": "5f9e4a"}],
    ["polo", "camisa", "Polo", 40, ["torso_clothes_shortsleeve_polo"], {"color": "c8463c"}],
    ["polo_longa", "camisa", "Polo manga longa", 45, ["torso_clothes_longsleeve2_polo"], {"color": "2e3f6e"}],
    ["camisa_social", "camisa", "Camisa social", 50, ["torso_clothes_longsleeve2_buttoned"], {"color": "f2efe6"}],
    # blusas
    ["regata", "blusa", "Regata", 25, ["torso_clothes_sleeveless1"], {"color": "f2efe6"}],
    ["regata_decote", "blusa", "Regata decotada", 30, ["torso_clothes_sleeveless2_scoop"], {"color": "e08fb0"}],
    ["regata_v", "blusa", "Regata gola V", 30, ["torso_clothes_sleeveless2_vneck"], {"color": "e8c84a"}],
    ["blusa_decote", "blusa", "Blusa decotada", 30, ["torso_clothes_tshirt_scoop"], {"color": "7fb5e0"}],
    ["blusa_ombro", "blusa", "Blusa manga longa", 35, ["torso_clothes_longsleeve_scoop"], {"color": "7e2f3e"}],
    # blusas de frio
    ["manga_longa", "blusa_frio", "Blusa de manga longa", 40, ["torso_clothes_longsleeve"], {"color": "8e8c96"}],
    ["moletom", "blusa_frio", "Moletom", 40, ["torso_clothes_longsleeve2"], {"color": "56663a"}],
    ["cardigan", "blusa_frio", "Cardigã", 55, ["torso_clothes_longsleeve2_cardigan"], {"color": "8a5a36"}],
    ["sueter_v", "blusa_frio", "Suéter gola V", 45, ["torso_clothes_longsleeve2_vneck"], {"color": "7e2f3e"}],
    ["colete_trico", "blusa_frio", "Cardigã curto", 45, ["torso_clothes_shortsleeve_cardigan"], {"color": "d8c49a"}],
    # calças
    ["calca", "calca", "Calça", 0, ["legs_pants"], {"color": "2e3f6e"}],
    ["calca_larga", "calca", "Calça comprida", 30, ["legs_pants2"], {"color": "8a5a36"}],
    ["calca_social", "calca", "Calça social", 45, ["legs_formal"], {"color": "3a3640"}],
    ["calca_listrada", "calca", "Calça listrada", 50, ["legs_formal_striped"], {"color": "8e8c96"}],
    ["calca_dobra", "calca", "Calça dobrada", 35, ["legs_cuffed"], {"color": "3f6fc0"}],
    ["bombacha", "calca", "Bombacha", 40, ["legs_pantaloons"], {"color": "d8c49a"}],
    ["legging", "calca", "Legging", 30, ["legs_leggings"], {"color": "3a3640"}],
    # shorts e saias
    ["bermuda", "short", "Bermuda", 25, ["legs_shorts"], {"color": "d8c49a"}],
    ["short", "short", "Short", 25, ["legs_shorts_short"], {"color": "3f6fc0"}],
    ["saia", "short", "Saia", 30, ["legs_skirts_plain"], {"color": "7a52a8"}],
    # sapatos
    ["sapato", "sapato", "Sapato", 0, ["feet_shoes_basic"], {"color": "3a3640"}],
    ["sapatilha", "sapato", "Sapatilha", 30, ["feet_shoes_sara"], {"color": "c8463c"}],
    ["sapato_amarrar", "sapato", "Sapato de amarrar", 35, ["feet_shoes_ghillies"], {"color": "8a5a36"}],
    ["bota", "sapato", "Bota", 45, ["feet_boots_basic"], {"color": "8a5a36"}],
    ["bota_dobra", "sapato", "Bota dobrada", 50, ["feet_boots_fold"], {"color": "3a3640"}],
    ["sandalia", "sapato", "Sandália", 20, ["feet_sandals"], {"color": "8a5a36"}],
    ["pantufa", "sapato", "Pantufa", 20, ["feet_slippers"], {"color": "e08fb0"}],
    # fantasias (cobrem outros slots)
    ["fan_esqueleto", "fantasia", "Esqueleto", 150, ["heads_skeleton"], {"head": True, "hides": ["cabelo", "barba"]}],
    ["fan_vampiro", "fantasia", "Vampiro", 150, ["heads_vampire"], {"head": True, "hides": ["barba"]}],
    ["fan_zumbi", "fantasia", "Zumbi", 150, ["heads_zombie"], {"head": True, "hides": ["barba"]}],
    ["fan_lobo", "fantasia", "Lobisomem", 180, ["heads_wolf_male"], {"head": True, "hides": ["cabelo", "barba"], "female": ["heads_wolf_female"]}],
    ["fan_orc", "fantasia", "Orc", 120, ["heads_orc_male"], {"head": True, "hides": ["barba"], "female": ["heads_orc_female"]}],
    ["fan_goblin", "fantasia", "Goblin", 120, ["heads_goblin"], {"head": True, "hides": ["barba"]}],
    ["fan_abobora", "fantasia", "Cabeça de abóbora", 120, ["heads_jack"], {"head": True, "hides": ["cabelo", "barba", "oculos", "mascara"]}],
    ["fan_frank", "fantasia", "Frankenstein", 150, ["heads_frankenstein"], {"head": True, "hides": ["cabelo", "barba"]}],
    ["fan_cavaleiro", "fantasia", "Armadura de cavaleiro", 300,
        ["torso_armour_plate", "legs_armour", "feet_armour", "arms_armour", "hat_helmet_mail"],
        {"hides": ["torso", "pernas", "pes", "cabeca", "cabelo"]}],
    ["fan_legiao", "fantasia", "Legionário", 250, ["torso_armour_legion", "legs_skirts_legion", "feet_sandals"],
        {"hides": ["torso", "pernas", "pes"], "color": "8a5a36"}],
    ["fan_pirata", "fantasia", "Capitão pirata", 250, ["hat_tricorne_captain", "hat_tricorne_captain_skull", "facial_eyepatch_left"],
        {"hides": ["cabeca", "mascara", "oculos"]}],
    ["fan_noel", "fantasia", "Papai Noel", 200, ["hat_holiday_christmas", "hat_holiday_santa", "beards_winter"],
        {"hides": ["cabeca", "barba"], "color": "f2efe6"}],
]

BASE_LAYERS = {
    "male": [["body/bodies/male/", 10, False], ["head/heads/human/male/", 100, False]],
    "female": [["body/bodies/female/", 10, False], ["head/heads/human/female/", 100, False]],
}
EYES = ["eyes/human/adult/default/", 105]
EYES_BLINK = "eyes/human/adult/closing/"


def load_defs():
    defs = {}
    for f in glob.glob(RAW + "sheet_definitions/**/*.json", recursive=True):
        try:
            d = json.load(open(f))
        except Exception:
            continue
        defs[os.path.basename(f)[:-5]] = d
    return defs


def strip_for(path, tint):
    """Tira de 11 quadros de uma pasta LPC (sit.png + walk.png)."""
    out = Image.new("RGBA", (F * 11, F), (0, 0, 0, 0))
    sit_p, walk_p = SHEETS + path + "sit.png", SHEETS + path + "walk.png"
    if not os.path.exists(sit_p):
        return None
    sit = Image.open(sit_p).convert("RGBA")
    out.paste(sit.crop((2 * F, 3 * F, 3 * F, 4 * F)), (0, 0))
    out.paste(sit.crop((1 * F, 3 * F, 2 * F, 4 * F)), (F, 0))
    if os.path.exists(walk_p):
        walk = Image.open(walk_p).convert("RGBA")
        for i in range(9):
            out.paste(walk.crop((i * F, 3 * F, i * F + F, 4 * F)), (F * (2 + i), 0))
    if tint:
        out = to_gray(out)
    return out


def to_gray(im):
    """Tons de cinza normalizados (o tom mais claro vira quase branco) para multiplicar pela cor."""
    px = im.load()
    lums = [0.299 * r + 0.587 * g + 0.114 * b for (r, g, b, a) in im.getdata() if a > 0]
    if not lums:
        return im
    hi = max(lums)
    k = 245.0 / max(hi, 1.0)
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            v = int(min(255, (0.299 * r + 0.587 * g + 0.114 * b) * k))
            px[x, y] = (v, v, v, a)
    return im


def load_credits():
    """CREDITS.csv do LPC: arquivo -> (autores, licenças, links)."""
    out = {}
    with open(RAW + "CREDITS.csv", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f, skipinitialspace=True):
            fn = (row.get("filename") or "").strip()
            split = lambda k: [x.strip() for x in (row.get(k) or "").split(",") if x.strip()]
            out[fn] = (split("authors"), split("licenses"), split("urls"))
    return out


def fname(path):
    return path.strip("/").replace("/", "_") + ".png"


def main():
    defs = load_defs()
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    written = {}
    src = {}
    csv_credits = load_credits()

    def credit_of(files):
        authors, lic, urls = set(), set(), set()
        for n in files:
            for anim in ("sit.png", "walk.png"):
                c = csv_credits.get(src.get(n, "") + anim)
                if c:
                    authors.update(c[0]); lic.update(c[1]); urls.update(c[2])
        return {"authors": sorted(authors), "licenses": sorted(lic), "urls": sorted(urls)}

    def emit(path, tint):
        key = (path, tint)
        if key not in written:
            im = strip_for(path, tint)
            if im is None:
                written[key] = None
            else:
                n = ("g_" if tint else "") + fname(path)
                im.save(OUT + n)
                written[key] = n
                src[n] = path
        return written[key]

    credits = {}
    items = {}
    missing = []
    for row in ITEMS:
        iid, cat, name, price, def_ids = row[:5]
        ex = row[5] if len(row) > 5 else {}
        layers = {"male": [], "female": []}
        tintable = False
        for bt in BODIES:
            ids = ex.get("female", def_ids) if bt == "female" else def_ids
            for did in ids:
                d = defs.get(did)
                if d is None:
                    missing.append(did)
                    continue
                rec = d.get("recolors")
                mat = rec.get("material") if isinstance(rec, dict) else ""
                tint = mat in ("cloth", "hair")
                for lk in sorted(k for k in d if k.startswith("layer_")):
                    lay = d[lk]
                    p = lay.get(bt) or lay.get("male")
                    if not p or "${" in p:
                        continue
                    n = emit(p, tint)
                    if n is None:
                        continue
                    tintable = tintable or tint
                    layers[bt].append({"file": n, "z": int(lay.get("zPos", 50)), "tint": tint})
        if not layers["male"]:
            missing.append(iid)
            continue
        if not layers["female"]:
            layers["female"] = layers["male"]
        item = {"cat": cat, "name": name, "price": price, "layers": layers, "tint": tintable}
        if "color" in ex:
            item["color"] = ex["color"]
        if "hides" in ex:
            item["hides"] = ex["hides"]
        if ex.get("head"):
            item["head"] = True
        items[iid] = item
        credits[iid] = credit_of({l["file"] for bt in BODIES for l in layers[bt]})

    base = {}
    for bt, lst in BASE_LAYERS.items():
        base[bt] = [{"file": emit(p, t), "z": z, "tint": t} for p, z, t in lst]
    base["eyes"] = {"file": emit(EYES[0], False), "blink": emit(EYES_BLINK, False), "z": EYES[1]}
    credits["_base"] = credit_of([l["file"] for bt in BODIES for l in base[bt]] + [base["eyes"]["file"], base["eyes"]["blink"]])
    no_credit = [k for k, v in credits.items() if not v["authors"]]
    if no_credit:
        print("sem créditos no CSV:", no_credit)

    cat = {
        "frame": F, "frames": {"chair": 0, "ground": 1, "walk": 2, "walk_count": 9},
        "anchor": {"chair": [29, 48], "ground": [24, 56]},
        "categories": CATEGORIES, "dyes": DYES, "hair_colors": HAIR,
        "base": base, "items": items, "credits": credits,
        "source": "Universal LPC Spritesheet Character Generator - github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator",
    }
    json.dump(cat, open(OUT + "catalog.json", "w"), ensure_ascii=False, indent=1)
    n_png = len([v for v in written.values() if v])
    print(f"{len(items)} peças, {n_png} imagens, faltando: {sorted(set(missing))}")


if __name__ == "__main__":
    main()
