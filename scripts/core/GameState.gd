extends Node

## Estado global do jogo: progressão, inventário, equipamento, energia, missões,
## hábitos e salvamento. Autoload: `GameState`.
## Tudo que muda aqui emite `stats_changed` e agenda um salvamento (a cada ~2 s).

signal stats_changed
signal damage_taken(amount: int)
signal leveled_up(new_level: int)
signal player_died
signal knocked_out                     # vida chegou a 0 com no_death (duelos da Arena)
signal toast(text: String, color: Color)
signal item_gained(item_id: String, amount: int)
signal buffs_changed
signal energy_changed
signal skill_unlocked(index: int)       # marco de habilidade (0 = nível 10 ... 9 = nível 100)
signal promoted(tier: int)

const SAVE_VERSION := 2

var save_path := ""                       # espaço ativo (user://slot_N.json); "" = no menu inicial
var slot: int = 0                         # 1..3 = espaço de save em uso; 0 = nenhum; -1 = teste (--save=)
const SLOT_COUNT := 3

# --- progressão
var level: int = 1
var xp: int = 0
var xp_to_next: int = 90
var gold: int = 0
var hunger: int = 100
var hp: int = 100
var player_class: String = ""
var talent_points: int = 0
var talents: Dictionary = {}          # id -> pontos
var energy: int = 3
var energy_day: String = ""
var best_floor: int = 0
var playtime: float = 0.0

# --- itens
var inventory: Dictionary = {}        # item_id -> quantidade
var stash: Dictionary = {}            # v2.7: baú da casa (item_id -> quantidade), fora da mochila
var equipped: Dictionary = {}         # slot -> item_id
var upgrades: Dictionary = {}         # item_id -> nível de aprimoramento
var furniture: Array = []             # ids de móveis comprados
var furniture_layout: Dictionary = {} # id do móvel -> [x, y, giro] na casa (px; giro 0..3)
var furniture_stored: Array = []      # comprados mas guardados (fora da casa)
# --- aparência do herói (LPC): moeda própria ganha estudando, peças compradas e o visual em uso
var study_credits: int = 0             # créditos de estudo: 1 por minuto de foco concluído
var looks_owned: Array = []            # ids de peças compradas (as de preço 0 são de graça)
var look: Dictionary = {}
var no_death: bool = false             # Arena: a vida para em 1 e emite knocked_out
var promotion: Dictionary = {}         # {tier: 0..4, trial: {tier, base: {monsters, focus, bosses}}}
var arena: Dictionary = {}             # {prestige, wins, losses, streak, best}              # ver Lpc.default_look()
var story: Dictionary = {}             # história (ver Story.gd): nomes, capítulo, passo, rank, pets, créditos, Caderno
var pomo_log: Array = []              # histórico de focos concluídos: {d: "AAAA-MM-DD", t: unix, m: minutos, s: cenário}

# --- contadores (nunca resetam; missões leem daqui)
var counters: Dictionary = {}
var claimed_missions: Array = []
var daily: Dictionary = {}            # {date, quests: [{id, claimed}], base: {stat: valor}}

# --- hábitos e áudio
var habits: Array = []
var audio_muted: bool = false
var audio_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0  # efeitos (golpes, magias, passos, sons de ação)
# v2.4: dificuldade (0 fácil, 1 médio, 2 difícil): dano recebido e recompensa de monstros (XP e ouro)
const DIFFICULTY_NAMES := ["Fácil", "Médio", "Difícil"]
const DIFFICULTY_DMG := [0.7, 1.0, 1.4]
const DIFFICULTY_REWARD := [0.8, 1.0, 1.3]
var difficulty: int = 1
var minigame_plays: Dictionary = {}   # v3.1: {"date": hoje, "<id>": partidas hoje}
var auto_aim: bool = true      # v2.6: mira automática (corpo e ataques viram para o inimigo próximo)
var safe_zone: bool = true     # v2.6: fora de floresta e masmorra os golpes não atingem moradores
var music_on: bool = true    # liga/desliga só a música (Pomodoro e pausa)
var clock_on: bool = true    # tique-taque do relógio durante o foco
var tutorial_done: Dictionary = {}
var pomo_cfg: Dictionary = {"focus": 25, "break": 5, "scene": "cafeteria"}   # escolhas da janela do Pomodoro

# --- temporários (não salvos)
var buffs: Dictionary = {}            # buff_id -> segundos restantes
var in_dungeon: bool = false
var _stats_cache: Dictionary = {}
var _stats_dirty: bool = true
var _save_queued: bool = false
var _save_timer: float = 0.0
var _regen_accum: float = 0.0
var _hunger_accum: float = 0.0
const STARVE_SECONDS := 60.0
var starve_left: float = -1.0           # v2.4: fome zerada = 1 min para comer, senão desmaia (-1 = sem contagem)
var _day_check_timer: float = 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save="):
			save_path = "user://" + arg.substr(7)   # testes: arquivo próprio, carregado já
			slot = -1
	get_tree().set_auto_accept_quit(false)
	if slot == -1:
		load_game()
	else:
		_reset_defaults()   # o menu inicial escolhe o espaço (novo jogo ou carregar)
	_ensure_habits()
	check_daily_reset()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()
		get_tree().quit()


func _process(delta: float) -> void:
	playtime += delta
	_tick_buffs(delta)
	_tick_regen_and_hunger(delta)
	if _save_queued:
		_save_timer -= delta
		if _save_timer <= 0.0:
			save_now()
	_day_check_timer += delta
	if _day_check_timer >= 30.0:
		_day_check_timer = 0.0
		check_daily_reset()


# ====================================================================== Stats
func mark_dirty() -> void:
	_stats_dirty = true


func get_stats() -> Dictionary:
	if _stats_dirty:
		_stats_cache = _compute_stats()
		_stats_dirty = false
	return _stats_cache


func _compute_stats() -> Dictionary:
	var s := {
		"atk": 0.0, "max_hp": 100.0, "def": 0.0, "speed": 66.0, "crit": 0.0, "luck": 0.0, "regen": 0.0,
		"xp_pct": 0.0, "gold_pct": 0.0, "crit_dmg": 1.5, "hunger_mult": 1.0, "focus_xp_pct": 0.0,
		"daily_energy": 0.0, "dmg_taken_mult": 1.0, "atk_pct": 0.0, "def_pct": 0.0, "speed_pct": 0.0,
		"hp_pct": 0.0, "cdr": 0.0,
	}
	if has_chosen_class():
		var c: Dictionary = Data.CLASSES[player_class]
		s["atk"] = Data.class_base_atk(player_class, level)
		s["max_hp"] = Data.class_base_hp(player_class, level)
		s["def"] = float(c["def"])
		s["speed"] = float(c["speed"])
		s["crit"] = float(c["crit"])
		match player_class:
			"cavaleiro":
				s["max_hp"] *= 1.10
			"paladino":
				s["regen"] += 0.6
			"assassino":
				s["crit_dmg"] = 2.0
			"escudeiro":
				s["def"] *= 1.25
	for tid in talents:
		var pts: int = int(talents[tid])
		var t: Dictionary = Data.TALENTS.get(tid, {})
		s["atk"] += float(t.get("atk", 0.0)) * pts
		s["max_hp"] += float(t.get("hp", 0.0)) * pts
		s["def"] += float(t.get("def", 0.0)) * pts
		s["speed"] += float(t.get("speed", 0.0)) * pts
		s["crit"] += float(t.get("crit", 0.0)) * pts
		s["luck"] += float(t.get("luck", 0.0)) * pts
	for slot in equipped:
		var iid: String = equipped[slot]
		if iid == "":
			continue
		var it: Dictionary = Data.get_item(iid)
		if it.is_empty():
			continue
		var mult := 1.0 + Data.UPGRADE_STAT_BONUS * float(upgrades.get(iid, 0))
		s["atk"] += float(it.get("atk", 0.0)) * mult
		s["max_hp"] += float(it.get("hp", 0.0)) * mult
		s["def"] += float(it.get("def", 0.0)) * mult
		s["speed"] += float(it.get("speed", 0.0)) * mult
		s["crit"] += float(it.get("crit", 0.0)) * mult
		s["luck"] += float(it.get("luck", 0.0)) * mult
	# passivas da progressão (a cada 10 níveis) e bônus das promoções de classe
	var ps := progression_stats()
	for k2 in ps:
		s[k2] = float(s.get(k2, 0.0)) + float(ps[k2])
	for fid in furniture:
		var f: Dictionary = Data.FURNITURE.get(fid, {})
		var fs: Dictionary = f.get("stat", {})
		s["max_hp"] += float(fs.get("hp", 0.0))
		s["regen"] += float(fs.get("regen", 0.0))
		s["xp_pct"] += float(fs.get("xp_pct", 0.0))
		s["gold_pct"] += float(fs.get("gold_pct", 0.0))
		s["crit"] += float(fs.get("crit", 0.0))
		s["focus_xp_pct"] += float(fs.get("focus_xp_pct", 0.0))
		s["daily_energy"] += float(fs.get("daily_energy", 0.0))
		s["hunger_mult"] -= float(fs.get("hunger_mult", 0.0))
	for k in Story.mother_bonus():
		var mk: String = "max_hp" if k == "hp" else k
		s[mk] = float(s.get(mk, 0.0)) + float(Story.mother_bonus()[k])
	var pet_id := String(story.get("pet", ""))
	if Data.PETS.has(pet_id) and (story.get("pets", []) as Array).has(pet_id):
		var pet: Dictionary = Data.PETS[pet_id]
		var growth := maxi(0, int(story.get("chapter", 1)) - 2)
		for k in pet["bonus"]:
			var pk: String = "max_hp" if k == "hp" else k   # v3.1: o bônus de vida dos pets nunca era somado
			s[pk] = float(s.get(pk, 0.0)) + float(pet["bonus"][k])
		for k in pet.get("grow", {}):
			s[k] = float(s.get(k, 0.0)) + float(pet["grow"][k]) * growth
	for bid in buffs:
		var b: Dictionary = Data.BUFFS.get(bid, {})
		s["atk_pct"] += float(b.get("atk_pct", 0.0))
		s["def_pct"] += float(b.get("def_pct", 0.0))
		s["speed_pct"] += float(b.get("speed_pct", 0.0))
		s["crit"] += float(b.get("crit", 0.0))
		s["regen"] += float(b.get("regen", 0.0))
		s["xp_pct"] += float(b.get("xp_pct", 0.0))
		if b.has("dmg_taken_mult"):
			s["dmg_taken_mult"] *= float(b["dmg_taken_mult"])
	s["atk"] *= 1.0 + s["atk_pct"]
	s["def"] *= 1.0 + s["def_pct"]
	s["speed"] *= 1.0 + s["speed_pct"]
	s["max_hp"] *= 1.0 + s["hp_pct"]
	s["cdr"] = clampf(s["cdr"], 0.0, 0.4)
	if hunger <= 0:
		s["atk"] *= 0.8
		s["regen"] = 0.0
	s["max_hp"] = float(int(round(s["max_hp"])))
	s["atk"] = snappedf(s["atk"], 0.1)
	s["crit"] = clampf(s["crit"], 0.0, 75.0)
	s["hunger_mult"] = maxf(s["hunger_mult"], 0.1)
	return s


func get_max_hp() -> int:
	return int(get_stats()["max_hp"])


func get_attack_power() -> float:
	return float(get_stats()["atk"])


func stat(stat_name: String) -> float:
	return float(get_stats().get(stat_name, 0.0))


# =============================================================== Classe e XP
func has_chosen_class() -> bool:
	return player_class != "" and Data.CLASSES.has(player_class)


func choose_class(class_id: String) -> void:
	if has_chosen_class() or not Data.CLASSES.has(class_id):
		return
	player_class = class_id
	mark_dirty()
	hp = get_max_hp()
	_give_starter_kit()
	_queue_save()
	stats_changed.emit()


func _give_starter_kit() -> void:
	var family: String = Data.CLASSES[player_class]["weapon"]
	var weapon_id: String = Data.WEAPON_TABLE[family][0][0]
	if inventory.get(weapon_id, 0) <= 0:
		inventory[weapon_id] = 1
	if equipped.get("weapon", "") == "":
		equipped["weapon"] = weapon_id
	if player_class in ["escudeiro", "paladino"]:
		inventory["escudo_couro"] = maxi(inventory.get("escudo_couro", 0), 1)
		if equipped.get("shield", "") == "":
			equipped["shield"] = "escudo_couro"
	inventory["pocao_vida"] = maxi(inventory.get("pocao_vida", 0), 2)
	inventory["pao"] = maxi(inventory.get("pao", 0), 2)
	mark_dirty()


func add_xp(amount: int, apply_bonus: bool = true) -> int:
	var gained := amount
	if apply_bonus:
		gained = int(round(float(amount) * (1.0 + stat("xp_pct"))))
	xp += gained
	_check_level_up()
	_queue_save()
	stats_changed.emit()
	return gained


func _check_level_up() -> void:
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = Data.xp_for_level(level)
		talent_points += Data.TALENT_POINTS_PER_LEVEL
		mark_dirty()
		hp = mini(get_max_hp(), hp + int(get_max_hp() * 0.5))
		leveled_up.emit(level)
		if level % 10 == 0 and level <= 100 and has_chosen_class():
			skill_unlocked.emit(level / 10 - 1)
		_maybe_open_trial()


# ======================================================= Habilidades por nível e promoção
## Quantos marcos de habilidade já foram alcançados (um a cada 10 níveis, até 10).
func skill_milestones() -> int:
	# toda classe nasce com a primeira magia (tecla R); as demais vêm a cada 10 níveis
	return clampi(maxi(level / 10, 1 if has_chosen_class() else 0), 0, Data.SKILL_LEVELS.size())


func class_progression() -> Array:
	return Data.CLASS_PROGRESSION.get(player_class, [])


## Habilidade ativa de uma tecla ("skill" = Q, "skill2" = R, "skill3" = X); "" se ainda não liberada.
func slot_skill(slot: String) -> String:
	if not has_chosen_class():
		return ""
	if slot == "skill":
		return str(Data.CLASSES[player_class]["skill"])
	if slot == "skill_book":
		return str(lab_data().get("book_spell", ""))
	var prog := class_progression()
	for i in mini(skill_milestones(), prog.size()):
		var e: Dictionary = prog[i]
		if e["type"] == "active" and e["slot"] == slot:
			return str(e["skill"])
	return ""


func skill_mastered(slot: String) -> bool:
	var prog := class_progression()
	for i in mini(skill_milestones(), prog.size()):
		var e: Dictionary = prog[i]
		if e["type"] == "mastery" and e["slot"] == slot:
			return true
	return false


## Multiplicador de dano da habilidade (maestria).
func skill_power(slot: String) -> float:
	return Data.MASTERY_DMG if skill_mastered(slot) else 1.0


## Recarga da habilidade em segundos (maestria e passivas de recarga).
func skill_cooldown(slot: String) -> float:
	var id := slot_skill(slot)
	if id == "":
		return 0.0
	var cd := float(Data.SKILLS[id]["cd"])
	if skill_mastered(slot):
		cd *= Data.MASTERY_CD
	return cd * (1.0 - stat("cdr"))


## Bônus das passivas liberadas e das promoções, somados por chave.
func progression_stats() -> Dictionary:
	var out := {}
	var prog := class_progression()
	for i in mini(skill_milestones(), prog.size()):
		var e: Dictionary = prog[i]
		if e["type"] == "passive":
			for k in e["stat"]:
				out[k] = float(out.get(k, 0.0)) + float(e["stat"][k])
	var tier := promotion_tier()
	if tier > 0:
		for k in Data.PROMOTION_BONUS:
			out[k] = float(out.get(k, 0.0)) + float(Data.PROMOTION_BONUS[k]) * tier
	return out


func promotion_tier() -> int:
	return int(promotion.get("tier", 0))


## Nome da classe com o título da promoção ("Guardião Real").
func class_title() -> String:
	if not has_chosen_class():
		return ""
	var t := promotion_tier()
	if t <= 0:
		return str(Data.CLASSES[player_class]["name"])
	return str(Data.PROMOTION_TITLES[player_class][t - 1])


## Prova aberta: {tier, base}. Vazio se não há prova agora.
func promotion_trial() -> Dictionary:
	return promotion.get("trial", {})


## Abre a próxima prova quando o nível chega no marco (25, 50, 75, 100) e a anterior já foi feita.
func _maybe_open_trial() -> void:
	if not has_chosen_class() or not promotion_trial().is_empty():
		return
	var tier := promotion_tier()
	if tier >= Data.PROMOTION_LEVELS.size() or level < int(Data.PROMOTION_LEVELS[tier]):
		return
	promotion["trial"] = {"tier": tier + 1, "base": {"monsters": get_stat("monsters"), "focus": Story.focus_minutes(), "bosses": get_stat("bosses")}}
	toast.emit("Prova de Promoção liberada! Veja na Guilda (G).", Color("ffd35a"))
	_queue_save()


## Progresso da prova: {monsters: [feito, meta], focus: [...], bosses: [...]}.
func trial_progress() -> Dictionary:
	var tr := promotion_trial()
	if tr.is_empty():
		return {}
	var goal: Dictionary = Data.PROMOTION_TRIALS[int(tr["tier"]) - 1]
	var base: Dictionary = tr["base"]
	return {
		"monsters": [get_stat("monsters") - int(base.get("monsters", 0)), int(goal["monsters"])],
		"focus": [Story.focus_minutes() - int(base.get("focus", 0)), int(goal["focus"])],
		"bosses": [get_stat("bosses") - int(base.get("bosses", 0)), int(goal["bosses"])],
	}


func can_promote() -> bool:
	var p := trial_progress()
	if p.is_empty():
		return false
	for k in p:
		if int(p[k][0]) < int(p[k][1]):
			return false
	return true


func promote() -> bool:
	if not can_promote():
		return false
	promotion["tier"] = promotion_tier() + 1
	promotion.erase("trial")
	mark_dirty()
	hp = get_max_hp()
	promoted.emit(promotion_tier())
	toast.emit("Promoção! Agora você é %s." % class_title(), Color("ffd35a"))
	_maybe_open_trial()
	_queue_save()
	stats_changed.emit()
	return true


func add_gold(amount: int, apply_bonus: bool = false) -> int:
	var gained := amount
	if apply_bonus:
		gained = int(round(float(amount) * (1.0 + stat("gold_pct") + stat("luck") * 0.01)))
	gold += gained
	_queue_save()
	stats_changed.emit()
	return gained


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	_queue_save()
	stats_changed.emit()
	return true


# ================================================================== Talentos
func spend_talent(talent_id: String) -> bool:
	if talent_points <= 0 or not Data.TALENTS.has(talent_id):
		return false
	talent_points -= 1
	talents[talent_id] = int(talents.get(talent_id, 0)) + 1
	mark_dirty()
	if talent_id == "vigor":
		hp = mini(get_max_hp(), hp + 14)
	_queue_save()
	stats_changed.emit()
	return true


func respec_cost() -> int:
	return 50 + level * 25


func respec_talents() -> bool:
	var total := 0
	for t in talents.values():
		total += int(t)
	if total <= 0 or not spend_gold(respec_cost()):
		return false
	talent_points += total
	talents.clear()
	mark_dirty()
	hp = mini(hp, get_max_hp())
	_queue_save()
	stats_changed.emit()
	return true


# =================================================================== Inventário
func count_item(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func add_item(item_id: String, amount: int = 1, silent: bool = false) -> void:
	if amount <= 0:
		return
	inventory[item_id] = count_item(item_id) + amount
	if not silent:
		item_gained.emit(item_id, amount)
	_queue_save()
	stats_changed.emit()


## Baú da casa: guarda tudo o que não está em uso (a peça equipada fica com o herói).
func stashable_count(item_id: String) -> int:
	return count_item(item_id) - (1 if is_equipped(item_id) else 0)


func stash_put(item_id: String, amount: int = 1) -> bool:
	amount = mini(amount, stashable_count(item_id))
	if amount <= 0 or not remove_item(item_id, amount):
		return false
	stash[item_id] = int(stash.get(item_id, 0)) + amount
	_queue_save()
	stats_changed.emit()
	return true


func stash_take(item_id: String, amount: int = 1) -> bool:
	amount = mini(amount, int(stash.get(item_id, 0)))
	if amount <= 0:
		return false
	stash[item_id] = int(stash[item_id]) - amount
	if int(stash[item_id]) <= 0:
		stash.erase(item_id)
	add_item(item_id, amount, true)
	return true


func remove_item(item_id: String, amount: int = 1) -> bool:
	if count_item(item_id) < amount:
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
		for slot in equipped.keys():
			if equipped[slot] == item_id:
				equipped[slot] = ""
				mark_dirty()
				hp = mini(hp, get_max_hp())
	_queue_save()
	stats_changed.emit()
	return true


func sell_price(item_id: String) -> int:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return 0
	var p := int(round(float(it.get("price", 0)) * 0.5))
	var lvl := int(upgrades.get(item_id, 0))
	return p + int(p * 0.4 * lvl)


func sell_item(item_id: String) -> bool:
	if is_equipped(item_id) and count_item(item_id) <= 1:
		return false
	var price := sell_price(item_id)
	if price <= 0 or not remove_item(item_id, 1):
		return false
	add_gold(price)
	return true


func buy_item(item_id: String, qty: int = 1) -> bool:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return false
	if not spend_gold(int(it["price"]) * qty):
		return false
	add_item(item_id, qty)
	return true


# ==================================================================== Equipar
func equip_item(item_id: String) -> bool:
	if count_item(item_id) <= 0 or not Data.is_equipment(item_id):
		return false
	if not Data.class_can_use(player_class, item_id):
		return false
	var slot: String = Data.slot_of(item_id)
	equipped[slot] = item_id
	if slot in ["armor", "helmet", "shield"]:
		Audio.novo("equipar_armadura", -8.0)
	else:
		Audio.sfx2("metal_tinir" if slot == "weapon" else "gaveta", -10.0)
	mark_dirty()
	hp = mini(hp, get_max_hp())
	_queue_save()
	stats_changed.emit()
	return true


func unequip_slot(slot: String) -> void:
	if equipped.get(slot, "") == "":
		return
	equipped[slot] = ""
	mark_dirty()
	hp = mini(hp, get_max_hp())
	_queue_save()
	stats_changed.emit()


func is_equipped(item_id: String) -> bool:
	var slot := Data.slot_of(item_id)
	return slot != "" and equipped.get(slot, "") == item_id


func equipped_weapon_hand() -> String:
	var wid: String = equipped.get("weapon", "")
	if wid == "":
		return ""
	return Data.get_item(wid).get("hand", "")


# ================================================================ Aprimoramento
func upgrade_level(item_id: String) -> int:
	return int(upgrades.get(item_id, 0))


func upgrade_cost(item_id: String) -> Dictionary:
	var lvl := upgrade_level(item_id)
	if lvl >= Data.UPGRADE_MAX:
		return {}
	var it: Dictionary = Data.get_item(item_id)
	var material: String = Data.UPGRADE_MATERIAL[lvl]
	var tier := int(it.get("tier", 0))
	if it.get("kind", "") == "equip" and tier >= 5:
		material = "barra_obsidiana" if tier == 5 else "barra_adamantium"   # v3.2: metal fino de Pedralta
	return {
		"gold": int(round(float(it.get("price", 20)) * 0.45 * float(lvl + 1))),
		"material": material,
		"qty": Data.UPGRADE_MATERIAL_QTY[lvl],
	}


func can_upgrade(item_id: String) -> bool:
	var c := upgrade_cost(item_id)
	if c.is_empty() or count_item(item_id) <= 0:
		return false
	return gold >= int(c["gold"]) and count_item(c["material"]) >= int(c["qty"])


func upgrade_item(item_id: String) -> bool:
	if not can_upgrade(item_id):
		return false
	var c := upgrade_cost(item_id)
	spend_gold(int(c["gold"]))
	remove_item(c["material"], int(c["qty"]))
	upgrades[item_id] = upgrade_level(item_id) + 1
	Audio.sfx2("bigorna1" if randf() < 0.5 else "bigorna2", -4.0)
	counters["upgrades"] = int(counters.get("upgrades", 0)) + 1
	mark_dirty()
	_queue_save()
	stats_changed.emit()
	return true


# ================================================================== Consumíveis
## Estado do laboratório (fica na história do save): magia do livro e bônus de foco do Tônico.
func lab_data() -> Dictionary:
	if not story.has("lab"):
		story["lab"] = {"book_spell": "", "boost_sessions": 0, "boost_pct": 0.0}
	return story["lab"]


func use_item(item_id: String) -> bool:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty() or count_item(item_id) <= 0:
		return false
	match it["kind"]:
		"potion":
			if hp >= get_max_hp():
				return false
			if not remove_item(item_id, 1):
				return false
			var amount := maxi(int(it.get("heal", 0)), int(get_max_hp() * float(it.get("heal_pct", 0.0))))
			heal(amount)
			return true
		"tonic":
			if not remove_item(item_id, 1):
				return false
			if it.has("buff"):
				add_buff(it["buff"], float(it.get("buff_time", 300.0)))
			else:
				var ld := lab_data()
				ld["boost_sessions"] = int(ld.get("boost_sessions", 0)) + int(it.get("sessions", 3))
				ld["boost_pct"] = float(it.get("pct", 0.25))
				toast.emit("Tônico bebido: +%d%% de XP nas próximas %d sessões de foco." % [int(float(ld["boost_pct"]) * 100.0), int(ld["boost_sessions"])], Color("8fd4ff"))
			mark_dirty()
			stats_changed.emit()
			return true
		"book":
			if not remove_item(item_id, 1):
				return false
			lab_data()["book_spell"] = str(it.get("spell", ""))
			var sk: Dictionary = Data.SKILLS.get(str(it.get("spell", "")), {})
			toast.emit("Magia aprendida: %s (tecla Z)." % sk.get("name", "?"), Color("c9a0ff"))
			mark_dirty()
			stats_changed.emit()
			return true
		"food":
			if hunger >= 100 and not it.has("buff"):
				return false
			if not remove_item(item_id, 1):
				return false
			hunger = clampi(hunger + int(it.get("hunger", 0)), 0, 100)
			if it.has("buff"):
				add_buff(it["buff"], float(it.get("buff_time", 300.0)))
			mark_dirty()
			stats_changed.emit()
			return true
	return false


func quick_potion() -> String:
	for pid in ["pocao_vida", "pocao_media", "pocao_grande"]:
		if count_item(pid) > 0:
			return pid
	return ""


func quick_food() -> String:
	for fid in Data.FOOD_PRIORITY:
		if count_item(fid) > 0:
			return fid
	return ""


func add_buff(buff_id: String, seconds: float) -> void:
	buffs[buff_id] = maxf(float(buffs.get(buff_id, 0.0)), seconds)
	mark_dirty()
	buffs_changed.emit()
	stats_changed.emit()


func clear_buff(buff_id: String) -> void:
	if buffs.erase(buff_id):
		mark_dirty()
		buffs_changed.emit()
		stats_changed.emit()


func _tick_buffs(delta: float) -> void:
	if buffs.is_empty():
		return
	var expired: Array = []
	for bid in buffs:
		buffs[bid] -= delta
		if buffs[bid] <= 0.0:
			expired.append(bid)
	if not expired.is_empty():
		for bid in expired:
			buffs.erase(bid)
		mark_dirty()
		buffs_changed.emit()
		stats_changed.emit()


# ======================================================================== Vida
func is_alive() -> bool:
	return hp > 0


func take_damage(raw: float) -> int:
	var st := get_stats()
	var reduction: float = float(st["def"]) / (float(st["def"]) + 40.0)
	var amount := maxi(1, int(round(raw * (1.0 - reduction) * float(st["dmg_taken_mult"]) * float(DIFFICULTY_DMG[difficulty]))))
	hp = maxi(hp - amount, 0)
	if no_death and hp <= 0:
		hp = 1
		knocked_out.emit()
	damage_taken.emit(amount)
	stats_changed.emit()
	_queue_save()
	if hp <= 0:
		player_died.emit()
	return amount


func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, get_max_hp())
	_queue_save()
	stats_changed.emit()


func full_heal() -> void:
	hp = get_max_hp()
	_queue_save()
	stats_changed.emit()


func revive_after_defeat() -> void:
	hp = maxi(1, int(get_max_hp() / 2.0))
	if hunger <= 0:
		hunger = 30   # senão a fome mataria de novo logo ao acordar
	starve_left = -1.0
	_queue_save()
	stats_changed.emit()


func _tick_regen_and_hunger(delta: float) -> void:
	if not has_chosen_class():
		return
	var max_hp := get_max_hp()
	if hp > 0 and hp < max_hp:
		var rate := stat("regen")
		if not in_dungeon and hunger > 0:
			rate += max_hp * 0.02  # v2.4: na cidade a vida volta mais devagar (era 6% por segundo)
		if rate > 0.0:
			_regen_accum += rate * delta
			if _regen_accum >= 1.0:
				var whole := int(_regen_accum)
				_regen_accum -= whole
				hp = mini(max_hp, hp + whole)
				stats_changed.emit()
	_tick_starvation(delta)
	if in_dungeon:
		_hunger_accum += delta * stat("hunger_mult")
		if _hunger_accum >= 45.0:
			_hunger_accum = 0.0
			if hunger > 0:
				hunger -= 1
				if hunger == 0:
					mark_dirty()
					toast.emit("Você está com fome! Coma algo (F).", Color("ffb23e"))
					Audio.sfx("cough", -4.0)
				stats_changed.emit()


## Fome zerada: contagem regressiva de 1 minuto. Comer cancela; se zerar, o herói desmaia
## (mesmo caminho da derrota: player_died, a cena leva de volta à cidade).
func _tick_starvation(delta: float) -> void:
	if hunger > 0 or hp <= 0:
		starve_left = -1.0
		return
	if starve_left < 0.0:
		starve_left = STARVE_SECONDS
		toast.emit("Fome! Você tem 1 minuto para comer (F).", Color("ff6a5a"))
		return
	var before := starve_left
	starve_left = maxf(starve_left - delta, 0.0)
	for mark in [30.0, 10.0]:
		if before > mark and starve_left <= mark:
			toast.emit("Faltam %d s para desmaiar de fome!" % int(mark), Color("ff6a5a"))
	if int(ceil(before)) != int(ceil(starve_left)):
		stats_changed.emit()
	if starve_left <= 0.0:
		starve_left = -1.0
		toast.emit("Você desmaiou de fome.", Color("ff6a5a"))
		if no_death:
			hp = 1
			hunger = 20
		else:
			hp = 0
			player_died.emit()
		stats_changed.emit()


# ======================================================================= Fome
func eat_hunger(amount: int) -> void:
	hunger = clampi(hunger + amount, 0, 100)
	mark_dirty()
	_queue_save()
	stats_changed.emit()


# ===================================================================== Energia
func spend_energy(amount: int = 1) -> bool:
	if energy < amount:
		return false
	energy -= amount
	_queue_save()
	energy_changed.emit()
	stats_changed.emit()
	return true


func add_energy(amount: int) -> void:
	var before := energy
	energy = clampi(energy + amount, 0, Data.ENERGY_MAX)
	if energy != before:
		energy_changed.emit()
		stats_changed.emit()
		_queue_save()


func _today() -> String:
	return Time.get_date_string_from_system()


func check_daily_reset() -> void:
	var today := _today()
	if energy_day == today:
		return
	energy_day = today
	energy = maxi(energy, Data.ENERGY_DAILY_MIN + int(stat("daily_energy")))
	_roll_daily_quests(today)
	energy_changed.emit()
	stats_changed.emit()
	_queue_save()


func _roll_daily_quests(today: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today)
	var pool: Array = []
	for i in Data.DAILY_TEMPLATES.size():
		pool.append(i)
	var picked: Array = []
	for _i in 3:
		var idx: int = rng.randi() % pool.size()
		picked.append({"id": Data.DAILY_TEMPLATES[pool[idx]]["id"], "claimed": false})
		pool.remove_at(idx)
	var base := {}
	for tpl in Data.DAILY_TEMPLATES:
		base[tpl["stat"]] = get_stat(tpl["stat"])
	daily = {"date": today, "quests": picked, "base": base}


# ===================================================================== Missões
func get_stat(stat_name: String) -> int:
	match stat_name:
		"level":
			return level
		"gold":
			return gold
		"best_floor":
			return best_floor
		_:
			return int(counters.get(stat_name, 0))


func bump(stat_name: String, amount: int = 1) -> void:
	counters[stat_name] = int(counters.get(stat_name, 0)) + amount
	_queue_save()
	stats_changed.emit()


func mission_progress(m: Dictionary) -> int:
	return mini(get_stat(m["stat"]), int(m["goal"]))


func is_mission_complete(mission_id: String) -> bool:
	for m in Data.MISSIONS:
		if m["id"] == mission_id:
			return get_stat(m["stat"]) >= int(m["goal"])
	return false


func is_mission_claimed(mission_id: String) -> bool:
	return claimed_missions.has(mission_id)


func claim_mission(mission_id: String) -> bool:
	if is_mission_claimed(mission_id) or not is_mission_complete(mission_id):
		return false
	for m in Data.MISSIONS:
		if m["id"] == mission_id:
			_grant_reward(m["reward"])
			break
	claimed_missions.append(mission_id)
	_queue_save()
	stats_changed.emit()
	return true


func daily_template(quest_id: String) -> Dictionary:
	for t in Data.DAILY_TEMPLATES:
		if t["id"] == quest_id:
			return t
	return {}


func daily_progress(tpl: Dictionary) -> int:
	var base: int = int(daily.get("base", {}).get(tpl["stat"], 0))
	return clampi(get_stat(tpl["stat"]) - base, 0, int(tpl["goal"]))


func claim_daily(index: int) -> bool:
	var quests: Array = daily.get("quests", [])
	if index < 0 or index >= quests.size() or quests[index]["claimed"]:
		return false
	var tpl := daily_template(quests[index]["id"])
	if tpl.is_empty() or daily_progress(tpl) < int(tpl["goal"]):
		return false
	quests[index]["claimed"] = true
	_grant_reward(tpl["reward"])
	_queue_save()
	stats_changed.emit()
	return true


func _grant_reward(reward: Dictionary) -> void:
	if reward.has("gold"):
		add_gold(int(reward["gold"]))
	if reward.has("xp"):
		add_xp(int(reward["xp"]), false)
	if reward.has("energy"):
		add_energy(int(reward["energy"]))
	if reward.has("item"):
		add_item(reward["item"], 1)


# ==================================================================== Pomodoro
## Registra um foco concluído no histórico (dias, semanas, meses e anos são calculados a partir daqui).
func log_pomodoro(minutes: int, scene: String = "", early: bool = false) -> void:
	var e := {"d": _today(), "t": int(Time.get_unix_time_from_system()), "m": minutes, "s": scene}
	if early:
		e["e"] = 1   # finalizado antes do fim (conta os minutos estudados)
	pomo_log.append(e)
	save_now()


## Chamado ao concluir uma sessão de foco. Fome zerada = recompensa pela metade.
## `energy` < 0 = energia padrão; `count` = conta como sessão para missões e diárias.
func complete_focus_session(xp_reward: int, gold_reward: int, minutes: int = 0, energy: int = -1, count: bool = true) -> Dictionary:
	var mult := 0.5 if hunger <= 0 else 1.0
	var boost := 0.0
	var ld := lab_data()
	if int(ld.get("boost_sessions", 0)) > 0 and minutes > 0:
		boost = float(ld.get("boost_pct", 0.0))
		ld["boost_sessions"] = int(ld["boost_sessions"]) - 1
	var xp_gain := int(round(float(xp_reward) * mult * (1.0 + stat("focus_xp_pct") + boost)))
	var gold_gain := int(round(float(gold_reward) * mult))
	var cost := maxi(1, int(round(5.0 * stat("hunger_mult"))))
	hunger = maxi(hunger - cost, 0)
	mark_dirty()
	if count:
		bump("focus_sessions")
	add_gold(gold_gain)
	var real_xp := add_xp(xp_gain)
	var en := Data.ENERGY_PER_FOCUS if energy < 0 else energy
	if en > 0:
		add_energy(en)
	var credits := add_study_credits(minutes)
	var story_credits := Story.add_focus_minutes(minutes)
	return {"xp": real_xp, "gold": gold_gain, "energy": en, "credits": credits, "story_credits": story_credits}


# ===================================================================== Aparência (guarda-roupa)
func add_study_credits(minutes: int) -> int:
	var n := maxi(minutes, 0) * Lpc.CREDITS_PER_MINUTE
	study_credits += n
	_queue_save()
	stats_changed.emit()
	return n


func owns_look(item_id: String) -> bool:
	return looks_owned.has(item_id) or int(Lpc.item(item_id).get("price", 1)) == 0


func buy_look(item_id: String) -> bool:
	var it := Lpc.item(item_id)
	if it.is_empty() or owns_look(item_id):
		return false
	var price := int(it["price"])
	if study_credits < price:
		return false
	study_credits -= price
	looks_owned.append(item_id)
	_queue_save()
	stats_changed.emit()
	return true


## Veste a peça (ou tira, se já estiver vestida e o slot puder ficar vazio).
func toggle_look(item_id: String) -> void:
	var it := Lpc.item(item_id)
	if it.is_empty() or not owns_look(item_id):
		return
	var slot := Lpc.slot_of(item_id)
	look = Lpc.resolve(look)
	var eq: Dictionary = look.get("equip", {})
	if eq.get(slot, "") == item_id:
		if slot != "cabelo":
			eq.erase(slot)
	else:
		eq[slot] = item_id
	look["equip"] = eq
	_queue_save()
	stats_changed.emit()


func set_look_color(item_id: String, hex: String) -> void:
	look = Lpc.resolve(look)
	var colors: Dictionary = look.get("colors", {})
	colors[item_id] = hex
	look["colors"] = colors
	_queue_save()
	stats_changed.emit()


## Aparência do herói (corpo, pele, olhos, cabelo, barba), mantendo as roupas do guarda-roupa.
func set_appearance(new_look: Dictionary) -> void:
	var base := Lpc.resolve(look)
	for k in ["body", "head", "skin", "eyes", "hair_pal", "brows"]:
		if new_look.has(k):
			base[k] = new_look[k]
	var eq: Dictionary = (base.get("equip", {}) as Dictionary).duplicate()
	var ne: Dictionary = new_look.get("equip", {})
	# jogo novo: leva também as roupas iniciais do corpo escolhido
	if look.is_empty():
		eq = ne.duplicate()
		base["colors"] = (new_look.get("colors", {}) as Dictionary).duplicate()
	for slot in ["cabelo", "barba"]:
		if ne.has(slot):
			eq[slot] = ne[slot]
		else:
			eq.erase(slot)
	base["equip"] = eq
	# o herói antigo das cenas do Pomodoro usa uma cor hex para o cabelo
	var hp: Array = LpcW.palettes("hair").get(str(base.get("hair_pal", "")), [])
	if hp.size() > 3:
		base["hair_color"] = str(hp[3])
	look = base
	_queue_save()
	stats_changed.emit()


func set_look_value(key: String, value: Variant) -> void:
	look = Lpc.resolve(look)
	look[key] = value
	_queue_save()
	stats_changed.emit()


# ===================================================================== Mobília
func owns_furniture(furniture_id: String) -> bool:
	return furniture.has(furniture_id)


## Móvel posto na casa (comprado e não guardado).
func is_furniture_placed(furniture_id: String) -> bool:
	return owns_furniture(furniture_id) and not furniture_stored.has(furniture_id)


func set_furniture_pos(furniture_id: String, pos: Vector2, rot: int = 0) -> void:
	furniture_layout[furniture_id] = [int(pos.x), int(pos.y), rot]
	furniture_stored.erase(furniture_id)
	_queue_save()


## Tira o móvel da casa e guarda (continua seu; volta pelo modo Decorar).
func store_furniture(furniture_id: String) -> void:
	if owns_furniture(furniture_id) and not furniture_stored.has(furniture_id):
		furniture_stored.append(furniture_id)
		_queue_save()


func furniture_pos(furniture_id: String) -> Variant:
	var v: Variant = furniture_layout.get(furniture_id)
	if typeof(v) == TYPE_ARRAY and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return null


func furniture_rot(furniture_id: String) -> int:
	var v: Variant = furniture_layout.get(furniture_id)
	if typeof(v) == TYPE_ARRAY and (v as Array).size() >= 3:
		return int(v[2]) % 4
	return 0


func buy_furniture(furniture_id: String) -> bool:
	if owns_furniture(furniture_id) or not Data.FURNITURE.has(furniture_id):
		return false
	if not spend_gold(int(Data.FURNITURE[furniture_id]["price"])):
		return false
	furniture.append(furniture_id)
	furniture_stored.append(furniture_id)   # vai para a caixa de móveis; coloca no modo Decorar
	mark_dirty()
	_queue_save()
	stats_changed.emit()
	return true


# ===================================================================== Hábitos
func _new_habit(n: int) -> Dictionary:
	return {"name": "Hábito %d" % n, "streak": 0, "best_streak": 0,
		"last_completed_date": "", "total_completions": 0, "difficulty": 1}


## Só preenche os 5 iniciais num jogo novo: a lista é do jogador (v2.5: adicionar, remover, dificuldade).
func _ensure_habits() -> void:
	if habits.is_empty():
		for i in Data.HABIT_SLOTS:
			habits.append(_new_habit(i + 1))


func add_habit() -> bool:
	if habits.size() >= Data.HABIT_MAX:
		return false
	habits.append(_new_habit(habits.size() + 1))
	_queue_save()
	stats_changed.emit()
	return true


func remove_habit(index: int) -> void:
	if index < 0 or index >= habits.size() or habits.size() <= 1:
		return
	habits.remove_at(index)
	_queue_save()
	stats_changed.emit()


func set_habit_difficulty(index: int, d: int) -> void:
	if index < 0 or index >= habits.size():
		return
	habits[index]["difficulty"] = clampi(d, 0, 2)
	_queue_save()
	stats_changed.emit()


func habit_mult(index: int) -> float:
	return float(Data.HABIT_DIFF_MULT[clampi(int(habits[index].get("difficulty", 1)), 0, 2)])


func rename_habit(index: int, new_name: String) -> void:
	if index < 0 or index >= habits.size():
		return
	var trimmed := new_name.strip_edges()
	habits[index]["name"] = trimmed if trimmed != "" else "Hábito %d" % (index + 1)
	_queue_save()
	stats_changed.emit()


func is_habit_completed_today(index: int) -> bool:
	if index < 0 or index >= habits.size():
		return false
	return habits[index].get("last_completed_date", "") == _today()


func _unix_for_date(date_str: String) -> int:
	return Time.get_unix_time_from_datetime_string(date_str + " 00:00:00")


## Retorna o resultado ({xp, gold, streak}) ou {} se já tinha marcado hoje.
func complete_habit(index: int) -> Dictionary:
	if index < 0 or index >= habits.size() or is_habit_completed_today(index):
		return {}
	var habit: Dictionary = habits[index]
	var today := _today()
	var last_date: String = habit.get("last_completed_date", "")
	var new_streak := 1
	if last_date != "":
		var gap_days := int(round((_unix_for_date(today) - _unix_for_date(last_date)) / 86400.0))
		new_streak = int(habit.get("streak", 0)) + 1 if gap_days == 1 else 1
	habit["streak"] = new_streak
	habit["best_streak"] = maxi(int(habit.get("best_streak", 0)), new_streak)
	habit["last_completed_date"] = today
	habit["total_completions"] = int(habit.get("total_completions", 0)) + 1
	habits[index] = habit
	var bonus := int(new_streak / 5.0)
	var m := habit_mult(index)
	var xp_gain := int(round(float(8 + bonus * 3) * m))
	var gold_gain := int(round(float(6 + bonus * 4) * m))
	bump("habit_marks")
	add_gold(gold_gain)
	add_xp(xp_gain, false)
	return {"xp": xp_gain, "gold": gold_gain, "streak": new_streak, "energy": 0}


# ===================================================================== Masmorra
func register_monster_defeated(is_boss: bool = false) -> void:
	bump("monsters")
	if is_boss:
		bump("bosses")


func register_floor_reached(floor_n: int) -> void:
	if floor_n > best_floor:
		best_floor = floor_n
	_queue_save()
	stats_changed.emit()


# ===================================================================== Áudio
func set_audio_muted(muted: bool) -> void:
	audio_muted = muted
	_queue_save()
	stats_changed.emit()


func set_audio_volume(volume: float) -> void:
	audio_volume = clampf(volume, 0.0, 1.0)
	_queue_save()
	stats_changed.emit()


func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	_queue_save()
	stats_changed.emit()


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_queue_save()
	stats_changed.emit()


## v3.1: recompensa dos mini-jogos (forja, cozinha, laboratório): XP e um pouco de ouro pelo desempenho
## (`score` de 0 a 1). Depois de MINIGAME_FULL partidas no mesmo dia o ganho cai para 25%.
const MINIGAME_FULL := 5


func minigame_reward(id: String, score: float) -> Dictionary:
	score = clampf(score, 0.0, 1.0)
	if str(minigame_plays.get("date", "")) != _today():
		minigame_plays = {"date": _today()}
	var played := int(minigame_plays.get(id, 0))
	minigame_plays[id] = played + 1
	var factor := 1.0 if played < MINIGAME_FULL else 0.25
	var xp_gain := int(round(float(Data.xp_for_level(level)) * 0.03 * score * factor))
	var gold_gain := int(round((10.0 + float(level) * 1.5) * score * factor))
	if score > 0.0:
		xp_gain = maxi(xp_gain, 1)
		gold_gain = maxi(gold_gain, 1)
	add_xp(xp_gain, false)
	add_gold(gold_gain)
	bump("minigames")
	return {"xp": xp_gain, "gold": gold_gain, "reduced": factor < 1.0, "played": played + 1}


func set_difficulty(d: int) -> void:
	difficulty = clampi(d, 0, 2)
	_queue_save()
	stats_changed.emit()


func set_auto_aim(on: bool) -> void:
	auto_aim = on
	_queue_save()


func set_safe_zone(on: bool) -> void:
	safe_zone = on
	_queue_save()


func reward_mult() -> float:
	return float(DIFFICULTY_REWARD[difficulty])


func set_music_on(on: bool) -> void:
	music_on = on
	_queue_save()
	stats_changed.emit()


func set_clock_on(on: bool) -> void:
	clock_on = on
	_queue_save()
	stats_changed.emit()


# ============================================================ Salvar e carregar
func _queue_save() -> void:
	if not _save_queued:
		_save_queued = true
		_save_timer = 1.5


func save_game() -> void:
	_queue_save()


func save_now() -> void:
	_save_queued = false
	if save_path == "":
		return   # menu inicial: ainda não há espaço escolhido
	if slot >= 1 and not bool(story.get("started", false)):
		return   # espaço novo só é gravado depois de criar o personagem
	var data := {
		"version": SAVE_VERSION,
		"level": level, "xp": xp, "xp_to_next": xp_to_next, "gold": gold, "hunger": hunger, "hp": hp,
		"player_class": player_class, "talent_points": talent_points, "talents": talents,
		"energy": energy, "energy_day": energy_day, "best_floor": best_floor, "playtime": playtime,
		"inventory": inventory, "stash": stash, "equipped": equipped, "upgrades": upgrades, "furniture": furniture, "furniture_layout": furniture_layout, "furniture_stored": furniture_stored, "pomo_log": pomo_log,
		"study_credits": study_credits, "looks_owned": looks_owned, "look": look, "story": story, "arena": arena, "promotion": promotion,
		"counters": counters, "claimed_missions": claimed_missions, "daily": daily,
		"habits": habits, "audio_muted": audio_muted, "audio_volume": audio_volume,
		"music_volume": music_volume, "sfx_volume": sfx_volume,
		"music_on": music_on, "difficulty": difficulty, "minigame_plays": minigame_plays, "auto_aim": auto_aim, "safe_zone": safe_zone, "clock_on": clock_on, "tutorial_done": tutorial_done, "pomo_cfg": pomo_cfg,
	}
	# grava num arquivo temporário e troca: uma queda de energia não corrompe o save
	var tmp_path := save_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		var dir := DirAccess.open(save_path.get_base_dir())
		if dir != null:
			dir.rename(tmp_path.get_file(), save_path.get_file())
		_daily_backup(data)


## Uma cópia por dia em user://backups (guarda as 30 mais recentes).
func _daily_backup(data: Dictionary) -> void:
	if slot < 1:
		return  # saves de teste não geram backup
	var dir_path := save_path.get_base_dir() + "/backups"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var target := "%s/slot%d_%s.json" % [dir_path, slot, _today()]
	var f := FileAccess.open(target, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	var names: Array = []
	for n in dir.get_files():
		if n.begins_with("slot%d_" % slot) and n.ends_with(".json"):
			names.append(n)
	names.sort()
	while names.size() > 30:
		dir.remove(names.pop_front())


func load_game() -> void:
	# se o jogo caiu bem no meio da troca de arquivos, o temporário completo vale
	if not FileAccess.file_exists(save_path) and FileAccess.file_exists(save_path + ".tmp"):
		DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if not FileAccess.file_exists(save_path):
		_reset_defaults()
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		_reset_defaults()
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_reset_defaults()
		return
	var d: Dictionary = parsed
	var version := int(d.get("version", 1))
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	gold = int(d.get("gold", 0))
	hunger = int(d.get("hunger", 100))
	player_class = String(d.get("player_class", ""))
	inventory = _dict_of(d.get("inventory", {}))
	stash = _dict_of(d.get("stash", {}))
	equipped = _dict_of(d.get("equipped", {}))
	habits = d.get("habits", []) if typeof(d.get("habits", [])) == TYPE_ARRAY else []
	claimed_missions = d.get("claimed_missions", []) if typeof(d.get("claimed_missions", [])) == TYPE_ARRAY else []
	audio_muted = bool(d.get("audio_muted", false))
	audio_volume = float(d.get("audio_volume", 1.0))
	sfx_volume = float(d.get("sfx_volume", 1.0))
	if version >= 2:
		xp_to_next = int(d.get("xp_to_next", Data.xp_for_level(level)))
		talent_points = int(d.get("talent_points", 0))
		talents = _dict_of(d.get("talents", {}))
		energy = int(d.get("energy", Data.ENERGY_DAILY_MIN))
		energy_day = String(d.get("energy_day", ""))
		best_floor = int(d.get("best_floor", 0))
		playtime = float(d.get("playtime", 0.0))
		upgrades = _dict_of(d.get("upgrades", {}))
		furniture = d.get("furniture", []) if typeof(d.get("furniture", [])) == TYPE_ARRAY else []
		furniture_layout = _dict_of(d.get("furniture_layout", {}))
		furniture_stored = d.get("furniture_stored", []) if typeof(d.get("furniture_stored", [])) == TYPE_ARRAY else []
		study_credits = int(d.get("study_credits", 0))
		looks_owned = d.get("looks_owned", []) if typeof(d.get("looks_owned", [])) == TYPE_ARRAY else []
		look = _dict_of(d.get("look", {}))
		arena = _dict_of(d.get("arena", {}))
		promotion = _dict_of(d.get("promotion", {}))
		story = _dict_of(d.get("story", {}))
		pomo_log = d.get("pomo_log", []) if typeof(d.get("pomo_log", [])) == TYPE_ARRAY else []
		counters = _dict_of(d.get("counters", {}))
		daily = _dict_of(d.get("daily", {}))
		music_volume = float(d.get("music_volume", 0.7))
		music_on = bool(d.get("music_on", true))
		difficulty = clampi(int(d.get("difficulty", 1)), 0, 2)
		minigame_plays = _dict_of(d.get("minigame_plays", {}))
		auto_aim = bool(d.get("auto_aim", true))
		safe_zone = bool(d.get("safe_zone", true))
		clock_on = bool(d.get("clock_on", true))
		tutorial_done = _dict_of(d.get("tutorial_done", {}))
		var pc := _dict_of(d.get("pomo_cfg", {}))
		for k in pc:
			pomo_cfg[k] = pc[k]
	else:
		_migrate_v1(d)
	for slot in Data.EQUIP_SLOTS:
		if not equipped.has(slot):
			equipped[slot] = ""
	# remove itens equipados que não existem mais no inventário
	for slot in equipped.keys():
		if equipped[slot] != "" and count_item(equipped[slot]) <= 0:
			equipped[slot] = ""
	mark_dirty()
	hp = int(d.get("hp", get_max_hp()))
	hp = clampi(hp, 1, get_max_hp()) if has_chosen_class() else hp
	_maybe_open_trial.call_deferred()   # saves que já passaram do nível 25 ganham a prova
	stats_changed.emit()


func _migrate_v1(d: Dictionary) -> void:
	# O save antigo (v1.x) usava XP = 100*nível e nível alto só de testes (F9). Se não houve nenhuma
	# sessão de foco de verdade e o nível passa de 10, recomeça do nível 1 (o save original fica
	# guardado em _backup_save/).
	var focus_old := int(d.get("total_focus_sessions", 0))
	var level_old := int(d.get("level", 1))
	if focus_old == 0 and level_old > 10:
		level = 1
		xp = 0
	xp_to_next = Data.xp_for_level(level)
	counters = {"focus_sessions": focus_old, "monsters": int(d.get("total_monsters_defeated", 0))}
	talent_points = (level - 1) * Data.TALENT_POINTS_PER_LEVEL
	talents = {}
	energy = Data.ENERGY_DAILY_MIN
	energy_day = ""
	furniture = ["mesa"] if bool(d.get("casa_decorada", false)) else []
	upgrades = {}
	# itens de arma que a classe nova não consegue usar continuam no inventário (podem ser vendidos)
	if player_class != "" and equipped.get("weapon", "") != "" and not Data.class_can_use(player_class, equipped["weapon"]):
		equipped["weapon"] = ""


func _dict_of(v: Variant) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else {}


# ============================================================ Espaços de save (menu inicial)
static func slot_path(n: int) -> String:
	return "user://slot_%d.json" % n


## Resumo de um espaço para o menu: {} se vazio.
func slot_info(n: int) -> Dictionary:
	var path := slot_path(n)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"broken": true}
	var d: Dictionary = parsed
	var st: Dictionary = d.get("story", {}) if typeof(d.get("story", {})) == TYPE_DICTIONARY else {}
	return {
		"hero": str(st.get("hero", "Aventureiro")), "level": int(d.get("level", 1)), "gold": int(d.get("gold", 0)),
		"class": str(d.get("player_class", "")), "chapter": int(st.get("chapter", 1)), "rank": int(st.get("rank", 0)),
		"playtime": float(d.get("playtime", 0.0)), "look": d.get("look", {}), "gender": str(st.get("gender", "m")),
		"saved": FileAccess.get_modified_time(path),
	}


## Começa um jogo novo no espaço `n` (o arquivo só é gravado ao criar o personagem).
func use_new_slot(n: int) -> void:
	slot = n
	save_path = slot_path(n)
	debug_reset()
	playtime = 0.0
	gold = 25


## Carrega o espaço `n`. Devolve false se estiver vazio ou estragado.
func use_slot(n: int) -> bool:
	if not FileAccess.file_exists(slot_path(n)):
		return false
	slot = n
	save_path = slot_path(n)
	debug_reset()
	load_game()
	_ensure_habits()
	check_daily_reset()
	stats_changed.emit()
	return true


func delete_slot(n: int) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(n)))
	if slot == n:
		slot = 0
		save_path = ""


## Volta para o menu inicial: grava e solta o espaço.
func leave_slot() -> void:
	save_now()
	_save_queued = false
	slot = 0
	save_path = ""


func _reset_defaults() -> void:
	level = 1
	xp = 0
	xp_to_next = Data.xp_for_level(1)
	gold = 25
	hunger = 100
	starve_left = -1.0
	difficulty = 1
	minigame_plays = {}
	talent_points = 0
	energy = Data.ENERGY_DAILY_MIN
	for slot in Data.EQUIP_SLOTS:
		equipped[slot] = ""
	mark_dirty()
	hp = get_max_hp()


## Usado em testes: volta ao estado de jogo novo.
func debug_reset() -> void:
	promotion = {}
	inventory = {}
	stash = {}
	equipped = {}
	upgrades = {}
	furniture = []
	furniture_layout = {}
	furniture_stored = []
	study_credits = 0
	looks_owned = []
	look = {}
	arena = {}
	no_death = false
	story = {}
	pomo_log = []
	counters = {}
	claimed_missions = []
	daily = {}
	talents = {}
	buffs = {}
	player_class = ""
	best_floor = 0
	energy_day = ""
	_reset_defaults()
	check_daily_reset()
	stats_changed.emit()
