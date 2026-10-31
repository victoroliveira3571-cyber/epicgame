class_name Arena
extends RefCounted

## Arena de Combate (PvP contra aventureiros controlados pelo jogo): ranks por prestígio,
## oponentes do dia (3 por vez: fácil, justo e difícil), recompensas e registro no save
## (GameState.arena = {prestige, wins, losses, streak, best, seed}).

const RANKS := [
	["Bronze", 0, Color("c8834a")], ["Prata", 100, Color("c8d0d8")], ["Ouro", 260, Color("ffd35a")],
	["Platina", 520, Color("8ae0e0")], ["Lenda", 900, Color("e08aff")],
]
const NAMES := ["Kael", "Mira", "Tobias", "Yara", "Dante", "Lúcia", "Oren", "Sasha", "Rurik", "Nádia", "Ícaro",
	"Bianca", "Fausto", "Hana", "Gael", "Iris", "Zeca", "Maya", "Bóris", "Clara", "Theo", "Vera", "Nico", "Lara"]
const EPITHETS := ["o Veloz", "a Tempestade", "de Ferro", "o Paciente", "a Raposa", "o Teimoso", "a Sombra",
	"do Norte", "o Calmo", "a Implacável", "o Aprendiz", "a Sábia", "o Barulhento", "a Certeira"]
const CLASSES := [
	["sword", "Espadachim", false], ["dagger", "Duelista", false], ["spear", "Lanceiro", false],
	["bow", "Arqueiro", true], ["staff", "Mago", true],
]
const DIFFS := [["Fácil", 0.75, Color("8ee28e")], ["Justo", 1.0, Color("ffd35a")], ["Difícil", 1.3, Color("ff7a6a")]]


static func data() -> Dictionary:
	if GameState.arena.is_empty():
		GameState.arena = {"prestige": 0, "wins": 0, "losses": 0, "streak": 0, "best": 0, "seed": 1}
	return GameState.arena


static func prestige() -> int:
	return int(data().get("prestige", 0))


static func rank_index(p: int = -1) -> int:
	var pr := prestige() if p < 0 else p
	var r := 0
	for i in RANKS.size():
		if pr >= int(RANKS[i][1]):
			r = i
	return r


static func rank_name() -> String:
	return str(RANKS[rank_index()][0])


static func rank_color() -> Color:
	return RANKS[rank_index()][2]


## Prestígio que falta para o próximo rank (0 = já é Lenda).
static func to_next() -> int:
	var r := rank_index()
	return 0 if r >= RANKS.size() - 1 else int(RANKS[r + 1][1]) - prestige()


## Os 3 oponentes atuais. Mudam a cada luta (seed) e a cada dia.
static func opponents() -> Array:
	var rng := RandomNumberGenerator.new()
	var day := int(Time.get_unix_time_from_system() / 86400.0)
	rng.seed = hash(str(day) + ":" + str(data().get("seed", 1)))
	var out: Array = []
	var used := {}
	for d in DIFFS.size():
		var n: String = NAMES[rng.randi() % NAMES.size()]
		while used.has(n):
			n = NAMES[rng.randi() % NAMES.size()]
		used[n] = true
		out.append(_make(rng, n, d))
	return out


static func _make(rng: RandomNumberGenerator, name: String, diff: int) -> Dictionary:
	var cls: Array = CLASSES[rng.randi() % CLASSES.size()]
	var rank := rank_index()
	var mult: float = float(DIFFS[diff][1]) * (1.0 + rank * 0.12)
	var st := GameState.get_stats()
	var p_hp := float(GameState.get_max_hp())
	var p_atk := float(st["atk"])
	var p_def := float(st["def"])
	var reduction := p_def / (p_def + 40.0)
	# o golpe dele tira ~8% da sua vida (justo); a sua espada precisa de ~11 golpes nele
	var dmg := (p_hp * 0.08 * mult) / maxf(1.0 - reduction, 0.2)
	var hp := p_atk * 11.0 * mult
	var female := rng.randf() < 0.5
	return {
		"name": "%s %s" % [name, EPITHETS[rng.randi() % EPITHETS.size()]],
		"weapon": cls[0], "class_name": cls[1], "ranged": cls[2], "diff": diff,
		"hp": hp, "dmg": dmg, "speed": 58.0 + rng.randf() * 14.0 + diff * 4.0,
		"aggro": 0.55 + diff * 0.2, "dodge": 0.15 + diff * 0.15 + rank * 0.03,
		"gold": int((40 + GameState.level * 6) * (0.7 + diff * 0.35) * (1.0 + rank * 0.25)),
		"xp": int((30 + GameState.level * 8) * (0.7 + diff * 0.35)),
		"prestige": [12, 22, 36][diff] + rank * 3, "loss": [10, 7, 4][diff] + rank * 2,
		"look": _random_look(rng, female, cls[0], rank + diff),
	}


static func _random_look(rng: RandomNumberGenerator, female: bool, weapon: String, power: int) -> Dictionary:
	var skins := ["light", "amber", "olive", "taupe", "bronze", "brown", "black"]
	var hairs_m := ["cab_espetado", "cab_baguncado", "cab_raspado", "cab_topete", "cab_moicano", "cab_dread", "cab_cacheado", "cab_rabo", "cab_flat_top"]
	var hairs_f := ["cab_rabo_alto", "cab_tranca", "cab_longo", "cab_pixie", "cab_cachos_longos", "cab_coque_alto", "cab_marias", "cab_lob"]
	var hair_pals := ["black", "dark_brown", "chestnut", "redhead", "blonde", "platinum", "white", "blue", "pink", "green"]
	var cloths := ["red", "navy", "forest", "black", "maroon", "teal", "purple", "orange", "slate", "leather"]
	var torso := ["manga_longa", "camiseta", "regata", "moletom", "camiseta_v"]
	var legs := ["calca", "bombacha", "legging", "calca_larga"]
	var c1: String = cloths[rng.randi() % cloths.size()]
	var c2: String = cloths[rng.randi() % cloths.size()]
	var t: String = torso[rng.randi() % torso.size()]
	var l: String = legs[rng.randi() % legs.size()]
	var lk := {
		"body": "female" if female else "male", "head": "human_female" if female else "human_male",
		"skin": skins[rng.randi() % skins.size()], "eyes": LpcW.EYES[rng.randi() % LpcW.EYES.size()][0],
		"hair_pal": hair_pals[rng.randi() % hair_pals.size()], "brows": "thin" if female else "thick",
		"equip": {"cabelo": (hairs_f if female else hairs_m)[rng.randi() % (hairs_f if female else hairs_m).size()],
			"torso": t, "pernas": l, "pes": "bota"},
		"colors": {t: c1, l: c2, "bota": "black"}, "weapon": weapon, "extras": [],
		"gear": {"armor": clampi(power - 1 + rng.randi_range(-1, 1), -1, 5), "boots": clampi(power - 2, -1, 5)},
	}
	if weapon in ["sword", "spear"] and rng.randf() < 0.6:
		lk["gear"]["shield"] = clampi(power - 1, 0, 5)
	if power >= 3 and rng.randf() < 0.5:
		lk["gear"]["helmet"] = clampi(power - 2, 0, 5)
	if rng.randf() < 0.4:
		lk["extras"].append(["npc_cape_solid", cloths[rng.randi() % cloths.size()]])
	if weapon == "bow":
		lk["extras"].append(["npc_quiver", ""])
	if not female and rng.randf() < 0.3:
		lk["equip"]["barba"] = ["bar_por_fazer", "bar_aparada", "bar_cheia", "bar_bigode"][rng.randi() % 4]
	return lk


## Registra o resultado e devolve um resumo para a tela.
static func record(opp: Dictionary, won: bool) -> Dictionary:
	var d := data()
	var before := rank_index()
	var res := {"won": won, "gold": 0, "xp": 0, "prestige": 0, "rank_up": false}
	if won:
		d["wins"] = int(d.get("wins", 0)) + 1
		d["streak"] = int(d.get("streak", 0)) + 1
		d["best"] = maxi(int(d.get("best", 0)), int(d["streak"]))
		var bonus := mini(int(d["streak"]) - 1, 4) * 2
		res["prestige"] = int(opp["prestige"]) + bonus
		res["gold"] = int(opp["gold"])
		res["xp"] = int(opp["xp"])
		d["prestige"] = prestige() + int(res["prestige"])
		GameState.add_gold(res["gold"])
		GameState.add_xp(res["xp"], false)
	else:
		d["losses"] = int(d.get("losses", 0)) + 1
		d["streak"] = 0
		res["prestige"] = -int(opp["loss"])
		d["prestige"] = maxi(prestige() - int(opp["loss"]), 0)
	d["seed"] = int(d.get("seed", 1)) + 1
	res["rank_up"] = rank_index() > before
	GameState.arena = d
	GameState.save_game()
	return res
