extends Node

## Dados estáticos do jogo: classes, itens, monstros, biomas, missões, talentos,
## mobília... Tudo que é "tabela" mora aqui, para balancear sem mexer na lógica.
## Autoload: acessível em qualquer script como `Data`.

const TILE := 16

# ------------------------------------------------------------------ Raridades
const RARITY_NAMES := ["Comum", "Incomum", "Raro", "Épico", "Lendário", "Mítico"]
const RARITY_COLORS := [
	Color("c9c4b8"), Color("7ed957"), Color("5aa9ff"), Color("b57aff"), Color("ffb23e"), Color("ff5a4d"),
]
# Cor aplicada (modulate) sobre os ícones de equipamento conforme o nível do item.
const TIER_TINTS := [
	Color(0.80, 0.62, 0.42), Color(0.82, 0.84, 0.88), Color(0.55, 0.72, 1.0),
	Color(0.78, 0.58, 1.0), Color(1.0, 0.84, 0.40), Color(1.0, 0.48, 0.42),
]
const TIER_UNLOCK_LEVEL := [1, 5, 10, 18, 28, 40]

# --------------------------------------------------------------------- Classes
# weapon: família de arma que a classe usa. ranged: ataque à distância.
const CLASSES := {
	"cavaleiro": {
		"name": "Cavaleiro", "sheet": "Knight", "weapon": "sword", "ranged": false, "skill": "giro",
		"hp": 120, "atk": 12, "def": 3, "speed": 68.0, "crit": 5,
		"hp_lv": 10.0, "atk_lv": 1.6, "passive_text": "+10% de vida máxima",
		"desc": "Guerreiro equilibrado. Aguenta bastante dano e acerta em arco.",
	},
	"paladino": {
		"name": "Paladino", "sheet": "KnightGold", "weapon": "sword", "ranged": false, "skill": "luz",
		"hp": 140, "atk": 10, "def": 4, "speed": 64.0, "crit": 3,
		"hp_lv": 12.0, "atk_lv": 1.3, "passive_text": "Regenera vida aos poucos",
		"desc": "Resistente e abençoado. Cura a si mesmo e castiga os inimigos.",
	},
	"assassino": {
		"name": "Assassino", "sheet": "NinjaDark", "weapon": "dagger", "ranged": false, "skill": "sombra",
		"hp": 80, "atk": 16, "def": 1, "speed": 80.0, "crit": 14,
		"hp_lv": 6.0, "atk_lv": 2.2, "passive_text": "Golpes críticos causam mais dano",
		"desc": "Rápido e letal, mas frágil. Quem erra o rolamento, sente.",
	},
	"escudeiro": {
		"name": "Escudeiro", "sheet": "Boy", "weapon": "sword", "ranged": false, "skill": "muralha",
		"hp": 100, "atk": 8, "def": 6, "speed": 66.0, "crit": 3,
		"hp_lv": 9.0, "atk_lv": 1.1, "passive_text": "+25% de defesa",
		"desc": "Quase impossível de derrubar. Ataca devagar, mas nunca recua.",
	},
	"mago": {
		"name": "Mago", "sheet": "SorcererBlack", "weapon": "staff", "ranged": true, "skill": "meteoro",
		"hp": 70, "atk": 14, "def": 0, "speed": 66.0, "crit": 6,
		"hp_lv": 5.0, "atk_lv": 2.0, "passive_text": "Magias atravessam 1 inimigo",
		"desc": "Dano à distância devastador. Precisa manter distância.",
	},
	"arqueiro": {
		"name": "Arqueiro", "sheet": "Hunter", "weapon": "bow", "ranged": true, "skill": "chuva",
		"hp": 90, "atk": 11, "def": 1, "speed": 72.0, "crit": 10,
		"hp_lv": 7.0, "atk_lv": 1.7, "passive_text": "Flechas voam mais rápido e longe",
		"desc": "Mira precisa e mobilidade. Mata de longe sem se expor.",
	},
}

const WEAPON_FAMILY_NAMES := {"sword": "Armas pesadas", "dagger": "Lâminas leves", "staff": "Cajados", "bow": "Arcos"}

# ---------------------------------------------------------------------- Skills
# cd = recarga em segundos. icon = caminho em assets/ninja/skill_icons/
const SKILLS := {
	"giro": {"name": "Giro Cortante", "icon": "spell/Cut", "cd": 6.0,
		"desc": "Gira a lâmina e acerta todos ao redor (180% de dano) com empurrão."},
	"luz": {"name": "Luz Sagrada", "icon": "spell/Heal", "cd": 12.0,
		"desc": "Cura 30% da vida máxima e fere inimigos próximos (120%)."},
	"sombra": {"name": "Investida Sombria", "icon": "spell/Camouflage", "cd": 5.0,
		"desc": "Avança atravessando inimigos, imune, causando 220% de dano."},
	"muralha": {"name": "Muralha", "icon": "spell/DefenseUpgrade", "cd": 10.0,
		"desc": "Por 4s recebe 70% menos dano e empurra quem se aproxima."},
	"meteoro": {"name": "Explosão Arcana", "icon": "spell/Explosion", "cd": 6.0,
		"desc": "Detona uma explosão na direção da mira (260% de dano em área)."},
	"chuva": {"name": "Chuva de Flechas", "icon": "items/Arrow", "cd": 5.0,
		"desc": "Dispara 7 flechas em leque (100% de dano cada)."},
}

# --------------------------------------------------------------------- Talentos
# Cada ponto de talento dá o bônus abaixo.
const TALENTS := {
	"forca": {"name": "Força", "icon": "items/Kunai", "desc": "+2 de ataque", "atk": 2.0},
	"vigor": {"name": "Vigor", "icon": "items/Armor", "desc": "+14 de vida máxima", "hp": 14.0},
	"guarda": {"name": "Guarda", "icon": "items/Guard", "desc": "+1 de defesa", "def": 1.0},
	"destreza": {"name": "Destreza", "icon": "items/Boot", "desc": "+0,8 de velocidade e +0,5% de crítico", "speed": 0.8, "crit": 0.5},
	"sorte": {"name": "Sorte", "icon": "items/Ring", "desc": "+1% de ouro e +0,6% de chance de drop", "luck": 1.0},
}
const TALENT_ORDER := ["forca", "vigor", "guarda", "destreza", "sorte"]
const TALENT_POINTS_PER_LEVEL := 2

# ----------------------------------------------------------------------- Buffs
const BUFFS := {
	"forca": {"name": "Força", "icon": "items/Kunai", "desc": "+15% de ataque", "atk_pct": 0.15},
	"foco": {"name": "Foco", "icon": "items/Boot", "desc": "+12% de velocidade, +5% de crítico", "speed_pct": 0.12, "crit": 5.0},
	"couraca": {"name": "Couraça", "icon": "items/Guard", "desc": "+25% de defesa", "def_pct": 0.25},
	"regen": {"name": "Regeneração", "icon": "spell/Heal", "desc": "Recupera 1,5 de vida por segundo", "regen": 1.5},
	"sabedoria": {"name": "Sabedoria", "icon": "spell/Vision", "desc": "+20% de XP", "xp_pct": 0.20},
	"banquete": {"name": "Banquete", "icon": "job/Dish", "desc": "+20% de ataque e +10% de defesa", "atk_pct": 0.20, "def_pct": 0.10},
	"muralha": {"name": "Muralha", "icon": "spell/DefenseUpgrade", "desc": "Recebe 70% menos dano", "dmg_taken_mult": 0.30},
}

# ----------------------------------------------------------------- Itens (DB)
# id -> {name, kind, slot, tier, rarity, icon, tint, atk, hp, def, speed, crit, luck,
#        price, desc, family, heal, hunger, buff, buff_time, shop_level}
var ITEMS: Dictionary = {}
var SHOP_ORDER: Array = []  # ids do equipamento de loja, por nível

const EQUIP_SLOTS := ["weapon", "helmet", "armor", "shield", "boots", "amulet"]
const SLOT_NAMES := {"weapon": "Arma", "helmet": "Capacete", "armor": "Armadura", "shield": "Escudo",
	"boots": "Botas", "amulet": "Amuleto"}
const SLOT_ICONS := {"weapon": "weapons/Sword_icon", "helmet": "skill_icons/items/Helmet", "armor": "skill_icons/items/Armor",
	"shield": "skill_icons/items/Guard", "boots": "skill_icons/items/Boot", "amulet": "skill_icons/items/Amulet"}

const WEAPON_TABLE := {
	"sword": [
		["espada_madeira", "Espada de Madeira", "Club"], ["espada_ferro", "Espada de Ferro", "Sword"],
		["espada_aco", "Espada de Aço", "Sword2"], ["montante", "Montante", "BigSword"],
		["machado_runico", "Machado Rúnico", "Axe"], ["martelo_real", "Martelo Real", "Hammer"],
	],
	"dagger": [
		["osso_afiado", "Osso Afiado", "Bone"], ["ninjaku", "Ninjaku", "Ninjaku"],
		["sai_aco", "Sai de Aço", "Sai"], ["katana", "Katana", "Katana"],
		["florete", "Florete", "Rapier"], ["lamina_sombria", "Lâmina Sombria", "Sword2"],
	],
	"staff": [
		["graveto_magico", "Graveto Mágico", "Stick"], ["varinha", "Varinha", "MagicWand"],
		["livro_feitico", "Livro de Feitiços", "Book"], ["tridente_arcano", "Tridente Arcano", "Fork"],
		["cajado_ancestral", "Cajado Ancestral", "Lance2"], ["varinha_estelar", "Varinha Estelar", "MagicWand"],
	],
	"bow": [
		["arco_curto", "Arco Curto", "Bow"], ["arco_longo", "Arco Longo", "Bow2"],
		["arco_composto", "Arco Composto", "Bow"], ["arco_cacador", "Arco de Caça", "Bow2"],
		["arco_elfico", "Arco Élfico", "Bow"], ["arco_estelar", "Arco Estelar", "Bow2"],
	],
}
const WEAPON_ATK := [5, 10, 17, 27, 40, 58]
const WEAPON_CRIT := {"sword": 0, "dagger": 2, "staff": 1, "bow": 1}

const ARMOR_TABLE := {
	"helmet": [["capuz_couro", "Capuz de Couro"], ["capacete_ferro", "Capacete de Ferro"], ["elmo_aco", "Elmo de Aço"],
		["elmo_mithril", "Elmo de Mithril"], ["elmo_runico", "Elmo Rúnico"], ["coroa_draconica", "Coroa Dracônica"]],
	"armor": [["armadura_couro", "Armadura de Couro"], ["cota_malha", "Cota de Malha"], ["peitoral_aco", "Peitoral de Aço"],
		["couraca_mithril", "Couraça de Mithril"], ["couraca_runica", "Couraça Rúnica"], ["couraca_draconica", "Couraça Dracônica"]],
	"shield": [["escudo_couro", "Escudo de Couro"], ["escudo_ferro", "Escudo de Ferro"], ["escudo_aco", "Escudo de Aço"],
		["escudo_mithril", "Escudo de Mithril"], ["escudo_runico", "Escudo Rúnico"], ["escudo_draconico", "Escudo Dracônico"]],
	"boots": [["botas_couro", "Botas de Couro"], ["botas_ferro", "Botas de Ferro"], ["botas_aco", "Botas de Aço"],
		["botas_mithril", "Botas de Mithril"], ["botas_runicas", "Botas Rúnicas"], ["botas_draconicas", "Botas Dracônicas"]],
	"amulet": [["amuleto_madeira", "Amuleto de Madeira"], ["amuleto_cobre", "Amuleto de Cobre"], ["amuleto_prata", "Amuleto de Prata"],
		["amuleto_ouro", "Amuleto de Ouro"], ["amuleto_runico", "Amuleto Rúnico"], ["amuleto_draconico", "Amuleto Dracônico"]],
}
const ARMOR_DEF := {"helmet": [1, 2, 4, 6, 9, 13], "armor": [2, 4, 7, 11, 16, 23], "shield": [2, 3, 5, 8, 12, 17],
	"boots": [0, 1, 2, 3, 5, 7], "amulet": [0, 0, 0, 0, 0, 0]}
const ARMOR_HP := {"helmet": [4, 8, 14, 22, 34, 50], "armor": [8, 16, 28, 44, 66, 95], "shield": [6, 10, 18, 28, 42, 60],
	"boots": [0, 0, 0, 0, 0, 0], "amulet": [0, 0, 0, 0, 0, 0]}
const BOOT_SPEED := [2.0, 3.0, 4.0, 6.0, 8.0, 10.0]
const AMULET_CRIT := [2.0, 3.0, 4.5, 6.5, 9.0, 12.0]
const AMULET_LUCK := [1.0, 2.0, 3.5, 5.0, 7.0, 10.0]
const TIER_PRICE := [30, 90, 260, 700, 1800, 4500]
const SLOT_PRICE_MULT := {"weapon": 1.3, "helmet": 0.7, "armor": 1.2, "shield": 0.9, "boots": 0.6, "amulet": 1.0}

const UPGRADE_MAX := 5
const UPGRADE_STAT_BONUS := 0.12  # por nível de aprimoramento, sobre os atributos base
const MATERIALS := {
	"barra_cobre": {"name": "Barra de Cobre", "icon": "items/resource/BarCopper", "price": 12, "tier": 0},
	"barra_ferro": {"name": "Barra de Ferro", "icon": "items/resource/BarIron", "price": 30, "tier": 1},
	"barra_prata": {"name": "Barra de Prata", "icon": "items/resource/BarSilver", "price": 80, "tier": 2},
	"barra_ouro": {"name": "Barra de Ouro", "icon": "items/resource/BarGold", "price": 160, "tier": 3},
	"barra_mithril": {"name": "Barra de Mithril", "icon": "items/resource/BarMithril", "price": 320, "tier": 4},
	"gema_verde": {"name": "Gema Verde", "icon": "items/resource/GemGreen", "price": 60, "tier": 1},
	"gema_roxa": {"name": "Gema Roxa", "icon": "items/resource/GemPurple", "price": 120, "tier": 2},
	"gema_vermelha": {"name": "Gema Vermelha", "icon": "items/resource/GemRed", "price": 240, "tier": 3},
	"gema_amarela": {"name": "Gema Amarela", "icon": "items/resource/GemYellow", "price": 480, "tier": 4},
}
# Material exigido para aprimorar até o nível indicado (1..5) e quantidade.
const UPGRADE_MATERIAL := ["barra_cobre", "barra_cobre", "barra_ferro", "barra_prata", "barra_ouro"]
const UPGRADE_MATERIAL_QTY := [1, 2, 3, 3, 4]

# Poções e comidas. heal_pct = % da vida máxima; heal = valor fixo mínimo.
const CONSUMABLES := {
	"pocao_vida": {"name": "Poção de Vida Pequena", "icon": "items/potion/LifePot", "price": 20, "heal_pct": 0.30, "heal": 35,
		"desc": "Recupera 30% da vida máxima (mín. 35)."},
	"pocao_media": {"name": "Poção de Vida", "icon": "items/potion/Medipack", "price": 70, "heal_pct": 0.60, "heal": 90,
		"desc": "Recupera 60% da vida máxima (mín. 90).", "shop_level": 8},
	"pocao_grande": {"name": "Elixir Vital", "icon": "items/potion/Heart", "price": 180, "heal_pct": 1.0, "heal": 200,
		"desc": "Recupera toda a vida.", "shop_level": 20},
	"pao": {"name": "Pão", "icon": "items/food/Honey", "price": 8, "hunger": 35, "desc": "Mata a fome (+35)."},
	"onigiri": {"name": "Onigiri", "icon": "items/food/Onigiri", "price": 6, "hunger": 25, "desc": "Lanche simples (+25 de fome)."},
	"macarrao": {"name": "Macarrão Quente", "icon": "items/food/Noodle", "price": 40, "hunger": 45, "buff": "forca", "buff_time": 300.0,
		"desc": "+45 de fome. Buff Força por 5 min."},
	"sushi": {"name": "Sushi", "icon": "items/food/Sushi", "price": 45, "hunger": 30, "buff": "foco", "buff_time": 300.0,
		"desc": "+30 de fome. Buff Foco por 5 min."},
	"espeto": {"name": "Espeto Defumado", "icon": "items/food/Yakitori", "price": 45, "hunger": 35, "buff": "couraca", "buff_time": 300.0,
		"desc": "+35 de fome. Buff Couraça por 5 min."},
	"camarao": {"name": "Camarão Frito", "icon": "items/food/Shrimp", "price": 50, "hunger": 30, "buff": "regen", "buff_time": 300.0,
		"desc": "+30 de fome. Buff Regeneração por 5 min."},
	"peixe": {"name": "Peixe Grelhado", "icon": "items/food/Fish", "price": 80, "hunger": 40, "buff": "sabedoria", "buff_time": 600.0,
		"desc": "+40 de fome. Buff Sabedoria por 10 min.", "shop_level": 6},
	"banquete": {"name": "Banquete do Guerreiro", "icon": "items/food/Beaf", "price": 120, "hunger": 60, "buff": "banquete", "buff_time": 600.0,
		"desc": "+60 de fome. Buff Banquete por 10 min.", "shop_level": 12},
}
const RESTAURANT_MENU := ["pao", "onigiri", "macarrao", "sushi", "espeto", "camarao", "peixe", "banquete"]
const SHOP_POTIONS := ["pocao_vida", "pocao_media", "pocao_grande"]

# Prioridade de comida quando aperta [F]: usa a mais simples primeiro.
const FOOD_PRIORITY := ["pao", "onigiri", "macarrao", "sushi", "espeto", "camarao", "peixe", "banquete"]


func _init() -> void:
	_build_items()


func _build_items() -> void:
	ITEMS.clear()
	for family in WEAPON_TABLE:
		var rows: Array = WEAPON_TABLE[family]
		for t in rows.size():
			var row: Array = rows[t]
			var item := {
				"id": row[0], "name": row[1], "kind": "equip", "slot": "weapon", "tier": t, "family": family,
				"icon": "weapons/%s_icon" % row[2], "hand": ("weapons/%s" if family == "bow" else "weapons/%s_hand") % row[2],
				"tint": TIER_TINTS[t] if t >= 2 and row[2] in ["Bow", "Bow2", "MagicWand", "Sword2"] else Color.WHITE,
				"atk": float(WEAPON_ATK[t]), "crit": float(WEAPON_CRIT[family] * (t + 1)) * 0.6,
				"price": int(TIER_PRICE[t] * SLOT_PRICE_MULT["weapon"]),
			}
			if family == "dagger":
				item["atk"] = float(WEAPON_ATK[t]) * 0.9
				item["crit"] = float(2 + t * 2)
			ITEMS[item["id"]] = item
	for slot in ARMOR_TABLE:
		var rows2: Array = ARMOR_TABLE[slot]
		for t in rows2.size():
			var row2: Array = rows2[t]
			var it := {
				"id": row2[0], "name": row2[1], "kind": "equip", "slot": slot, "tier": t,
				"icon": SLOT_ICONS[slot], "tint": TIER_TINTS[t],
				"def": float(ARMOR_DEF[slot][t]), "hp": float(ARMOR_HP[slot][t]),
				"price": int(TIER_PRICE[t] * SLOT_PRICE_MULT[slot]),
			}
			if slot == "boots":
				it["speed"] = BOOT_SPEED[t]
			if slot == "amulet":
				it["crit"] = AMULET_CRIT[t]
				it["luck"] = AMULET_LUCK[t]
			ITEMS[it["id"]] = it
	for mid in MATERIALS:
		var m: Dictionary = MATERIALS[mid]
		ITEMS[mid] = {"id": mid, "name": m["name"], "kind": "material", "tier": m["tier"], "icon": m["icon"], "price": m["price"],
			"desc": "Material de aprimoramento (Ferreiro)."}
	for cid in CONSUMABLES:
		var c: Dictionary = CONSUMABLES[cid].duplicate()
		c["id"] = cid
		c["kind"] = "potion" if c.has("heal_pct") else "food"
		c["tier"] = 0
		ITEMS[cid] = c
	for it2 in ITEMS.values():
		if it2["kind"] == "equip":
			it2["rarity"] = int(it2["tier"])
			it2["desc"] = _equip_desc(it2)
		elif not it2.has("rarity"):
			it2["rarity"] = 0
	SHOP_ORDER.clear()
	for slot2 in EQUIP_SLOTS:
		pass


func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


func item_name(item_id: String) -> String:
	var it: Dictionary = ITEMS.get(item_id, {})
	return it.get("name", item_id)


func is_equipment(item_id: String) -> bool:
	return ITEMS.get(item_id, {}).get("kind", "") == "equip"


func slot_of(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("slot", "")


func _equip_desc(it: Dictionary) -> String:
	var parts: Array[String] = []
	if it.get("atk", 0.0) > 0.0:
		parts.append("+%d ataque" % int(round(it["atk"])))
	if it.get("hp", 0.0) > 0.0:
		parts.append("+%d vida" % int(round(it["hp"])))
	if it.get("def", 0.0) > 0.0:
		parts.append("+%d defesa" % int(round(it["def"])))
	if it.get("speed", 0.0) > 0.0:
		parts.append("+%d velocidade" % int(round(it["speed"])))
	if it.get("crit", 0.0) > 0.0:
		parts.append("+%s%% crítico" % _fmt(it["crit"]))
	if it.get("luck", 0.0) > 0.0:
		parts.append("+%s%% sorte" % _fmt(it["luck"]))
	return ", ".join(parts)


func _fmt(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")


## Equipamentos que a classe pode usar em um slot (arma depende da família).
func class_can_use(class_id: String, item_id: String) -> bool:
	var it: Dictionary = ITEMS.get(item_id, {})
	if it.get("kind", "") != "equip":
		return false
	if it["slot"] != "weapon":
		return true
	return CLASSES.get(class_id, {}).get("weapon", "") == it.get("family", "")


## Equipamentos de loja que a classe pode comprar, por tier.
func shop_equipment(class_id: String, tier: int) -> Array:
	var out: Array = []
	for slot in EQUIP_SLOTS:
		for it in ITEMS.values():
			if it["kind"] == "equip" and it["slot"] == slot and int(it["tier"]) == tier and class_can_use(class_id, it["id"]):
				out.append(it["id"])
	return out


func max_tier_for_level(level: int) -> int:
	var t := 0
	for i in TIER_UNLOCK_LEVEL.size():
		if level >= TIER_UNLOCK_LEVEL[i]:
			t = i
	return t


# ----------------------------------------------------------------- Progressão
func xp_for_level(level: int) -> int:
	return int(90.0 * pow(float(level), 1.25))


func class_base_hp(class_id: String, level: int) -> float:
	var c: Dictionary = CLASSES[class_id]
	return float(c["hp"]) + float(c["hp_lv"]) * float(level - 1)


func class_base_atk(class_id: String, level: int) -> float:
	var c: Dictionary = CLASSES[class_id]
	return float(c["atk"]) + float(c["atk_lv"]) * float(level - 1)


# -------------------------------------------------------------------- Monstros
# behavior: melee | charger | ranged | flyer | hopper
# hp/dmg/xp/gold são valores base do andar 1 (escalam com o andar).
const MONSTERS := {
	"slime": {"name": "Slime", "sheet": "Slime", "hp": 22, "dmg": 6, "speed": 26.0, "behavior": "hopper", "xp": 5, "gold": [2, 6], "radius": 5.0},
	"slime_verde": {"name": "Slime Verde", "sheet": "Slime3", "hp": 30, "dmg": 8, "speed": 28.0, "behavior": "hopper", "xp": 7, "gold": [3, 8], "radius": 5.0},
	"rato": {"name": "Rato", "sheet": "Mouse", "hp": 14, "dmg": 5, "speed": 52.0, "behavior": "melee", "xp": 4, "gold": [1, 4], "radius": 4.0},
	"morcego": {"name": "Morcego", "sheet": "BlueBat", "hp": 12, "dmg": 5, "speed": 56.0, "behavior": "flyer", "xp": 5, "gold": [1, 5], "radius": 4.0},
	"cogumelo": {"name": "Cogumelo", "sheet": "Mushroom", "hp": 28, "dmg": 7, "speed": 22.0, "behavior": "ranged", "xp": 7, "gold": [2, 7], "radius": 5.0, "proj": "spore", "range": 90.0, "cooldown": 2.4},
	"esqueleto": {"name": "Esqueleto", "sheet": "Skeleton", "kind": "char", "hp": 42, "dmg": 11, "speed": 36.0, "behavior": "melee", "xp": 11, "gold": [4, 11], "radius": 5.0},
	"cranio": {"name": "Crânio Flutuante", "sheet": "Skull", "hp": 30, "dmg": 12, "speed": 40.0, "behavior": "charger", "xp": 12, "gold": [4, 11], "radius": 5.0},
	"espirito": {"name": "Espírito", "sheet": "Spirit", "hp": 26, "dmg": 11, "speed": 30.0, "behavior": "ranged", "xp": 12, "gold": [5, 12], "radius": 5.0, "proj": "orb", "range": 100.0, "cooldown": 2.0},
	"aranha": {"name": "Aranha", "sheet": "SpiderRed", "hp": 34, "dmg": 11, "speed": 58.0, "behavior": "melee", "xp": 12, "gold": [4, 11], "radius": 5.0},
	"lagarto": {"name": "Lagarto", "sheet": "Lizard", "hp": 52, "dmg": 14, "speed": 38.0, "behavior": "charger", "xp": 15, "gold": [6, 14], "radius": 5.0},
	"kappa": {"name": "Kappa", "sheet": "KappaGreen", "hp": 58, "dmg": 15, "speed": 34.0, "behavior": "ranged", "xp": 19, "gold": [8, 18], "radius": 5.0, "proj": "water", "range": 96.0, "cooldown": 2.2},
	"cobra": {"name": "Cobra", "sheet": "Snake", "hp": 40, "dmg": 16, "speed": 54.0, "behavior": "melee", "xp": 18, "gold": [7, 16], "radius": 5.0},
	"polvo": {"name": "Polvo Verde", "sheet": "GreenOctopus", "hp": 66, "dmg": 16, "speed": 30.0, "behavior": "hopper", "xp": 20, "gold": [8, 18], "radius": 5.0},
	"reptil": {"name": "Réptil", "sheet": "Reptile", "hp": 70, "dmg": 18, "speed": 40.0, "behavior": "charger", "xp": 22, "gold": [9, 20], "radius": 5.0},
	"chama": {"name": "Chama Viva", "sheet": "Flam", "hp": 54, "dmg": 20, "speed": 36.0, "behavior": "ranged", "xp": 26, "gold": [10, 22], "radius": 5.0, "proj": "fire", "range": 104.0, "cooldown": 1.8},
	"ciclope": {"name": "Ciclope", "sheet": "Cyclope", "hp": 110, "dmg": 24, "speed": 30.0, "behavior": "charger", "xp": 34, "gold": [12, 28], "radius": 6.0},
	"fera": {"name": "Fera", "sheet": "Beast", "hp": 84, "dmg": 22, "speed": 50.0, "behavior": "melee", "xp": 30, "gold": [11, 25], "radius": 6.0},
	"polvo_vermelho": {"name": "Polvo Rubro", "sheet": "RedOctopus", "hp": 90, "dmg": 24, "speed": 32.0, "behavior": "hopper", "xp": 32, "gold": [12, 26], "radius": 5.0},
	"demonio": {"name": "Olho Maligno", "sheet": "Eye", "hp": 70, "dmg": 24, "speed": 34.0, "behavior": "ranged", "xp": 33, "gold": [12, 26], "radius": 5.0, "proj": "orb", "range": 110.0, "cooldown": 1.6},
}

# Chefes: sprites em tiras horizontais. frames = quantidade; w = largura de cada quadro.
# anims: nome -> [arquivo, largura do quadro, nº de quadros, fps, loop]
const BOSSES := {
	"slime_gigante": {"name": "Slime Gigante", "folder": "GiantSlime", "hp": 420, "dmg": 16, "speed": 22.0, "xp": 160, "gold": [60, 90], "radius": 15.0,
		"patterns": ["slam", "summon", "burst"], "anims": {"idle": ["Idle", 62, 5, 6], "walk": ["Idle", 62, 5, 8], "hit": ["Hit", 62, 5, 10]}, "summon": "slime"},
	"ciclope_demoniaco": {"name": "Ciclope Demoníaco", "folder": "DemonCyclop", "hp": 760, "dmg": 24, "speed": 28.0, "xp": 300, "gold": [110, 160], "radius": 14.0,
		"patterns": ["charge", "burst", "slam"], "anims": {"idle": ["Idle", 50, 5, 6], "walk": ["Walk", 50, 6, 9], "hit": ["Hit", 50, 3, 10]}, "summon": "cranio"},
	"sapo_gigante": {"name": "Sapo Gigante", "folder": "GiantFrog", "hp": 1150, "dmg": 30, "speed": 30.0, "xp": 480, "gold": [160, 230], "radius": 14.0,
		"patterns": ["slam", "burst", "summon"], "anims": {"idle": ["Idle", 40, 5, 6], "walk": ["Idle", 40, 5, 8], "hit": ["Hit", 40, 3, 10]}, "summon": "kappa"},
	"tengu_rubro": {"name": "Tengu Rubro", "folder": "TenguRed", "hp": 1700, "dmg": 38, "speed": 34.0, "xp": 720, "gold": [240, 340], "radius": 15.0,
		"patterns": ["charge", "burst", "summon", "slam"], "anims": {"idle": ["Idle", 82, 6, 6], "walk": ["Walk", 82, 10, 9], "hit": ["Hit", 82, 8, 10]}, "summon": "chama"},
	"samurai_azul": {"name": "Samurai Gigante", "folder": "GiantBlueSamurai", "hp": 2300, "dmg": 46, "speed": 34.0, "xp": 1000, "gold": [320, 450], "radius": 15.0,
		"patterns": ["charge", "slam", "burst"], "anims": {"idle": ["Idle", 48, 12, 7], "walk": ["Walk", 48, 12, 10], "hit": ["Hit", 48, 8, 10]}, "summon": "fera"},
	"guaxinim_gigante": {"name": "Guaxinim Gigante", "folder": "GiantRacoon", "hp": 2900, "dmg": 54, "speed": 32.0, "xp": 1300, "gold": [400, 560], "radius": 14.0,
		"patterns": ["slam", "burst", "summon", "charge"], "anims": {"idle": ["Idle", 60, 6, 6], "walk": ["Idle", 60, 6, 8], "hit": ["Idle", 60, 6, 10]}, "summon": "ciclope"},
}
const BOSS_ORDER := ["slime_gigante", "ciclope_demoniaco", "sapo_gigante", "tengu_rubro", "samurai_azul", "guaxinim_gigante"]

# Biomas: 4 camadas de 5 andares. floor_style escolhe a paleta do chão/parede.
const BIOMES := [
	{"name": "Caverna Úmida", "music": "dungeon1", "style": 0, "enemies": ["slime", "rato", "morcego", "cogumelo"], "boss_color": Color.WHITE},
	{"name": "Cripta Esquecida", "music": "dungeon2", "style": 1, "enemies": ["esqueleto", "cranio", "espirito", "aranha", "lagarto"], "boss_color": Color.WHITE},
	{"name": "Pântano Sombrio", "music": "dungeon3", "style": 2, "enemies": ["kappa", "cobra", "polvo", "reptil", "slime_verde"], "boss_color": Color.WHITE},
	{"name": "Forja Infernal", "music": "dungeon4", "style": 3, "enemies": ["chama", "ciclope", "fera", "polvo_vermelho", "demonio"], "boss_color": Color.WHITE},
]


func biome_for_floor(floor_n: int) -> Dictionary:
	return BIOMES[((floor_n - 1) / 5) % BIOMES.size()]


func is_boss_floor(floor_n: int) -> bool:
	return floor_n % 5 == 0


func boss_for_floor(floor_n: int) -> String:
	return BOSS_ORDER[((floor_n / 5) - 1) % BOSS_ORDER.size()]


# Equilíbrio: a força dos monstros depende do ANDAR, não do bioma. Cada monstro vale
# (valor dele / média do seu bioma) x base x curva do andar. Assim monstros diferentes
# continuam variados, mas não há saltos de dificuldade ao trocar de bioma.
# Valores calibrados com a simulação de progressão (nível ~ andar, ver PROGRESSO.md).
const ENEMY_BASE := {"hp": 36.0, "dmg": 5.0, "xp": 5.5, "gold": 4.0}
const BOSS_HP_MULT := 4.0
const BOSS_DMG_MULT := 0.85
const BOSS_XP_MULT := 3.0
const BOSS_GOLD_MULT := 0.4


func floor_scale_hp(floor_n: int) -> float:
	return 1.0 + 0.24 * float(floor_n - 1)


func floor_scale_dmg(floor_n: int) -> float:
	return 1.0 + 0.16 * float(floor_n - 1)


func floor_scale_reward(floor_n: int) -> float:
	return pow(float(maxi(floor_n, 1)), 1.05)


## Valor relativo de um monstro dentro do bioma dele (1.0 = média). stat: hp | dmg | xp | gold.
func monster_rel(monster_id: String, stat: String) -> float:
	var biome_list: Array = []
	for b in BIOMES:
		if monster_id in b["enemies"]:
			biome_list = b["enemies"]
			break
	if biome_list.is_empty():
		return 1.0
	var total := 0.0
	for id in biome_list:
		total += _monster_stat_value(id, stat)
	return _monster_stat_value(monster_id, stat) / (total / float(biome_list.size()))


func _monster_stat_value(monster_id: String, stat: String) -> float:
	var m: Dictionary = MONSTERS[monster_id]
	if stat == "gold":
		return (float(m["gold"][0]) + float(m["gold"][1])) / 2.0
	return float(m[stat])


# --------------------------------------------------------------------- Missões
# stat: contador do GameState. reward: gold/xp/energy/item.
const MISSIONS := [
	{"id": "m1", "title": "Primeiros Passos", "desc": "Complete 1 sessão de foco", "stat": "focus_sessions", "goal": 1, "reward": {"gold": 10, "energy": 1}},
	{"id": "m2", "title": "Disciplina", "desc": "Complete 5 sessões de foco", "stat": "focus_sessions", "goal": 5, "reward": {"gold": 30, "energy": 2}},
	{"id": "m3", "title": "Ganhando Fama", "desc": "Alcance o nível 3", "stat": "level", "goal": 3, "reward": {"gold": 25}},
	{"id": "m4", "title": "Pé-de-Meia", "desc": "Tenha 50 de ouro", "stat": "gold", "goal": 50, "reward": {"xp": 15}},
	{"id": "m5", "title": "Maratonista", "desc": "Complete 10 sessões de foco", "stat": "focus_sessions", "goal": 10, "reward": {"gold": 60, "energy": 3}},
	{"id": "m6", "title": "Caçador", "desc": "Derrote 1 monstro na masmorra", "stat": "monsters", "goal": 1, "reward": {"gold": 15}},
	{"id": "m7", "title": "Exterminador", "desc": "Derrote 5 monstros na masmorra", "stat": "monsters", "goal": 5, "reward": {"gold": 40}},
	{"id": "m8", "title": "Veterano", "desc": "Alcance o nível 5", "stat": "level", "goal": 5, "reward": {"xp": 30}},
	{"id": "m9", "title": "Descendo a Escada", "desc": "Chegue ao andar 3 da masmorra", "stat": "best_floor", "goal": 3, "reward": {"gold": 50, "item": "pocao_vida"}},
	{"id": "m10", "title": "Matador de Slimes", "desc": "Derrote 50 monstros", "stat": "monsters", "goal": 50, "reward": {"gold": 120, "xp": 80}},
	{"id": "m11", "title": "Abre-Baús", "desc": "Abra 5 baús", "stat": "chests", "goal": 5, "reward": {"gold": 60}},
	{"id": "m12", "title": "Fim da Caverna", "desc": "Derrote o Slime Gigante (andar 5)", "stat": "bosses", "goal": 1, "reward": {"gold": 150, "xp": 120, "item": "pocao_media"}},
	{"id": "m13", "title": "Hábito Forte", "desc": "Marque hábitos 10 vezes", "stat": "habit_marks", "goal": 10, "reward": {"gold": 80, "energy": 2}},
	{"id": "m14", "title": "Ferreiro Cliente", "desc": "Aprimore um equipamento", "stat": "upgrades", "goal": 1, "reward": {"gold": 70}},
	{"id": "m15", "title": "Mestre Cuca", "desc": "Coma 5 pratos do Restaurante", "stat": "meals", "goal": 5, "reward": {"gold": 60}},
	{"id": "m16", "title": "Profundezas", "desc": "Chegue ao andar 8", "stat": "best_floor", "goal": 8, "reward": {"gold": 160, "xp": 150}},
	{"id": "m17", "title": "Foco Inabalável", "desc": "Complete 25 sessões de foco", "stat": "focus_sessions", "goal": 25, "reward": {"gold": 250, "energy": 5}},
	{"id": "m18", "title": "Senhor da Cripta", "desc": "Derrote 2 chefes", "stat": "bosses", "goal": 2, "reward": {"gold": 300, "xp": 250}},
	{"id": "m19", "title": "Lenda Viva", "desc": "Alcance o nível 15", "stat": "level", "goal": 15, "reward": {"gold": 400}},
	{"id": "m20", "title": "Abismo", "desc": "Chegue ao andar 15", "stat": "best_floor", "goal": 15, "reward": {"gold": 600, "xp": 500}},
]

# Missões diárias: 3 sorteadas por dia. {stat, goal, titulo}
const DAILY_TEMPLATES := [
	{"id": "d_focus1", "title": "Foco do dia", "desc": "Complete 1 sessão de foco", "stat": "focus_sessions", "goal": 1, "reward": {"gold": 25, "xp": 30, "energy": 1}},
	{"id": "d_focus3", "title": "Dia produtivo", "desc": "Complete 3 sessões de foco", "stat": "focus_sessions", "goal": 3, "reward": {"gold": 80, "xp": 100, "energy": 2}},
	{"id": "d_kill15", "title": "Caçada", "desc": "Derrote 15 monstros", "stat": "monsters", "goal": 15, "reward": {"gold": 50, "xp": 60}},
	{"id": "d_kill30", "title": "Limpeza geral", "desc": "Derrote 30 monstros", "stat": "monsters", "goal": 30, "reward": {"gold": 100, "xp": 120}},
	{"id": "d_chest2", "title": "Caçador de tesouros", "desc": "Abra 2 baús", "stat": "chests", "goal": 2, "reward": {"gold": 45, "xp": 40}},
	{"id": "d_habit3", "title": "Rotina em dia", "desc": "Marque 3 hábitos", "stat": "habit_marks", "goal": 3, "reward": {"gold": 40, "xp": 50, "energy": 1}},
	{"id": "d_floor3", "title": "Mergulho", "desc": "Desça 3 andares na masmorra", "stat": "floors_descended", "goal": 3, "reward": {"gold": 60, "xp": 80}},
	{"id": "d_boss", "title": "Caça ao chefe", "desc": "Derrote 1 chefe", "stat": "bosses", "goal": 1, "reward": {"gold": 120, "xp": 150, "energy": 1}},
	{"id": "d_meal", "title": "Hora do rango", "desc": "Coma 1 prato do Restaurante", "stat": "meals", "goal": 1, "reward": {"gold": 30, "xp": 30}},
]

# --------------------------------------------------------------------- Mobília
# Cada móvel dá um bônus permanente. icon: recorte do tileset de elementos.
const FURNITURE := {
	"cama": {"name": "Cama Confortável", "price": 60, "desc": "+15 de vida máxima.", "stat": {"hp": 15.0}, "icon": "furn_cama"},
	"mesa": {"name": "Mesa de Jantar", "price": 100, "desc": "A fome diminui 60% mais devagar.", "stat": {"hunger_mult": 0.4}, "icon": "furn_mesa"},
	"estante": {"name": "Estante de Livros", "price": 120, "desc": "+5% de XP.", "stat": {"xp_pct": 0.05}, "icon": "furn_estante"},
	"planta": {"name": "Vaso de Planta", "price": 80, "desc": "Regenera 0,4 de vida por segundo.", "stat": {"regen": 0.4}, "icon": "furn_planta"},
	"tapete": {"name": "Tapete Dourado", "price": 150, "desc": "+5% de ouro.", "stat": {"gold_pct": 0.05}, "icon": "furn_tapete"},
	"lareira": {"name": "Lareira", "price": 200, "desc": "+1 de energia no reabastecimento diário.", "stat": {"daily_energy": 1.0}, "icon": "furn_lareira"},
	"trofeu": {"name": "Armário de Troféus", "price": 250, "desc": "+3% de crítico.", "stat": {"crit": 3.0}, "icon": "furn_trofeu"},
	"relogio": {"name": "Relógio Antigo", "price": 300, "desc": "+10% de XP nas sessões de foco.", "stat": {"focus_xp_pct": 0.10}, "icon": "furn_relogio"},
}
const FURNITURE_ORDER := ["cama", "mesa", "estante", "planta", "tapete", "lareira", "trofeu", "relogio"]

# ---------------------------------------------------------------------- Energia
const ENERGY_MAX := 10
const ENERGY_DAILY_MIN := 3
const ENERGY_PER_FOCUS := 2
const FOCUS_MIN_SESSION := 10   # foco finalizado antes da hora conta como sessão (missões) a partir daqui (min)
const ENERGY_PER_HABIT := 1
const ENERGY_PER_RUN := 1

# ------------------------------------------------------------------------ Hábitos
const HABIT_SLOTS := 5
