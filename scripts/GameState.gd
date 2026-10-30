extends Node

## Estado global do personagem: nível, XP, ouro, fome.
## É um Autoload (singleton) — qualquer script do jogo pode acessar
## os valores daqui escrevendo "GameState.nome_da_variavel".
## Salva automaticamente em disco (user://savegame.json) a cada mudança.

signal stats_changed
signal damage_taken(amount: int)
signal leveled_up(new_level: int)

var level: int = 1
var xp: int = 0
var xp_to_next: int = 100
var gold: int = 0
var hunger: int = 100  # 0 a 100. 100 = sem fome, 0 = faminto.
var inventory: Dictionary = {}  # item_id (String) -> quantidade (int)
var total_focus_sessions: int = 0  # nunca reseta, usado pelas missões da Guilda
var claimed_missions: Array = []  # ids de missão já resgatadas
var player_class: String = ""  # vazio = ainda não escolheu (ver CLASSES)
var hp: int = 100
var casa_decorada: bool = false  # mobília comprada — reduz o gasto de fome
var total_monsters_defeated: int = 0  # nunca reseta, usado pelas missões
var habits: Array = []  # cada item: {name, streak, best_streak, last_completed_date, total_completions}
var audio_muted: bool = false
var audio_volume: float = 1.0  # 0.0 a 1.0
var equipped: Dictionary = {"weapon": "", "shield": "", "armor": ""}  # slot -> item_id

const SAVE_PATH := "user://savegame.json"
const HABIT_SLOTS := 5

const ITEM_BREAD := "pao"
const ITEM_POTION := "pocao_vida"
const ITEM_NAMES := {
	"pao": "Pão",
	"espada_madeira": "Espada de Madeira",
	"escudo_couro": "Escudo de Couro",
	"armadura_couro": "Armadura de Couro",
	"pocao_vida": "Poção de Vida",
}

# Classes jogáveis — escolhida uma vez, no primeiro boot (ClassSelectPanel).
# "melee" decide se o ataque ([Espaço]) é corpo a corpo ou um projétil.
const CLASSES := {
	"cavaleiro": {"name": "Cavaleiro", "melee": true, "attack": 12, "max_hp": 120},
	"paladino": {"name": "Paladino", "melee": true, "attack": 10, "max_hp": 140},
	"assassino": {"name": "Assassino", "melee": true, "attack": 16, "max_hp": 80},
	"escudeiro": {"name": "Escudeiro", "melee": true, "attack": 8, "max_hp": 100},
	"mago": {"name": "Mago", "melee": false, "attack": 14, "max_hp": 70},
	"arqueiro": {"name": "Arqueiro", "melee": false, "attack": 11, "max_hp": 90},
}

# Itens da Loja de Armas — compra/venda (v0.3) + efeito real quando equipado
# (v1.2). Cada item pertence a um "slot" (weapon/shield/armor) — só um item
# por slot equipado ao mesmo tempo.
const SHOP_ITEMS := [
	{"id": "espada_madeira", "name": "Espada de Madeira", "price": 15, "slot": "weapon", "attack_bonus": 5, "hp_bonus": 0},
	{"id": "escudo_couro", "name": "Escudo de Couro", "price": 20, "slot": "shield", "attack_bonus": 0, "hp_bonus": 15},
	{"id": "armadura_couro", "name": "Armadura de Couro", "price": 25, "slot": "armor", "attack_bonus": 0, "hp_bonus": 20},
]

# Missões da Guilda dos Aventureiros (lista fixa da v0.3).
const MISSIONS := [
	{"id": "m1", "title": "Primeiros Passos", "desc": "Complete 1 sessão de foco", "gold": 10, "xp": 0},
	{"id": "m2", "title": "Disciplina", "desc": "Complete 5 sessões de foco", "gold": 30, "xp": 0},
	{"id": "m3", "title": "Ganhando Fama", "desc": "Alcance o Nível 3", "gold": 25, "xp": 0},
	{"id": "m4", "title": "Pé-de-Meia", "desc": "Acumule 50 de ouro", "gold": 0, "xp": 15},
	{"id": "m5", "title": "Maratonista", "desc": "Complete 10 sessões de foco", "gold": 60, "xp": 0},
	{"id": "m6", "title": "Caçador", "desc": "Derrote 1 monstro na masmorra", "gold": 15, "xp": 0},
	{"id": "m7", "title": "Exterminador", "desc": "Derrote 5 monstros na masmorra", "gold": 40, "xp": 0},
	{"id": "m8", "title": "Veterano", "desc": "Alcance o Nível 5", "gold": 0, "xp": 30},
]

const FURNITURE_COST := 50


func _ready() -> void:
	load_game()
	_ensure_habits_initialized()


## Chamado quando uma sessão de foco (Pomodoro) é concluída com sucesso.
## Se a fome está zerada, a recompensa vem pela metade — comer de vez em
## quando (no Restaurante, nível 2) compensa.
func add_pomodoro_reward(xp_reward: int, gold_reward: int) -> void:
	var multiplier := 0.5 if hunger <= 0 else 1.0
	xp += int(xp_reward * multiplier)
	gold += int(gold_reward * multiplier)
	var hunger_cost := 2 if casa_decorada else 5
	hunger = max(hunger - hunger_cost, 0)
	_check_level_up()
	save_game()
	stats_changed.emit()


func add_gold(amount: int) -> void:
	gold += amount
	save_game()
	stats_changed.emit()


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	save_game()
	stats_changed.emit()
	return true


func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount
	save_game()
	stats_changed.emit()


func remove_item(item_id: String, amount: int = 1) -> bool:
	if inventory.get(item_id, 0) < amount:
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
		# Se o último desse item foi embora e ele estava equipado, desequipa
		# sozinho (não dá pra manter equipado o que você não tem mais).
		var slot := _slot_for_item(item_id)
		if slot != "" and equipped.get(slot, "") == item_id:
			unequip_slot(slot)
	save_game()
	stats_changed.emit()
	return true


func eat_hunger(amount: int) -> void:
	hunger = clamp(hunger + amount, 0, 100)
	save_game()
	stats_changed.emit()


## Chamado toda vez que uma sessão de FOCO termina (independente da recompensa
## de XP/ouro) — alimenta as missões da Guilda, que nunca resetam.
func register_focus_session_completed() -> void:
	total_focus_sessions += 1
	save_game()
	stats_changed.emit()


func buy_shop_item(item_id: String) -> bool:
	for shop_item in SHOP_ITEMS:
		if shop_item["id"] == item_id:
			if spend_gold(shop_item["price"]):
				add_item(item_id, 1)
				return true
			return false
	return false


func get_item_sell_price(item_id: String) -> int:
	if item_id == ITEM_BREAD:
		return 4
	for shop_item in SHOP_ITEMS:
		if shop_item["id"] == item_id:
			return int(shop_item["price"] / 2.0)
	return 0


func sell_item(item_id: String) -> bool:
	var price := get_item_sell_price(item_id)
	if not remove_item(item_id, 1):
		return false
	gold += price
	save_game()
	stats_changed.emit()
	return true


func is_mission_complete(mission_id: String) -> bool:
	match mission_id:
		"m1":
			return total_focus_sessions >= 1
		"m2":
			return total_focus_sessions >= 5
		"m3":
			return level >= 3
		"m4":
			return gold >= 50
		"m5":
			return total_focus_sessions >= 10
		"m6":
			return total_monsters_defeated >= 1
		"m7":
			return total_monsters_defeated >= 5
		"m8":
			return level >= 5
		_:
			return false


func is_mission_claimed(mission_id: String) -> bool:
	return claimed_missions.has(mission_id)


func claim_mission(mission_id: String) -> bool:
	if is_mission_claimed(mission_id) or not is_mission_complete(mission_id):
		return false
	for m in MISSIONS:
		if m["id"] == mission_id:
			xp += int(m["xp"])
			gold += int(m["gold"])
			break
	claimed_missions.append(mission_id)
	_check_level_up()
	save_game()
	stats_changed.emit()
	return true


## --- Classe e combate (v0.5/v0.6) ---

func has_chosen_class() -> bool:
	return player_class != "" and CLASSES.has(player_class)


func set_class(class_id: String) -> void:
	if has_chosen_class():
		return  # a classe é escolhida uma única vez
	if not CLASSES.has(class_id):
		return
	player_class = class_id
	hp = int(CLASSES[class_id]["max_hp"])
	save_game()
	stats_changed.emit()


func get_max_hp() -> int:
	var base := int(CLASSES[player_class]["max_hp"]) if has_chosen_class() else 100
	return base + get_equipment_hp_bonus()


func get_attack_power() -> int:
	var base := int(CLASSES[player_class]["attack"]) if has_chosen_class() else 10
	return base + get_equipment_attack_bonus()


## --- Equipamento (v1.2) ---

func equip_item(item_id: String) -> bool:
	if inventory.get(item_id, 0) <= 0:
		return false
	var slot := _slot_for_item(item_id)
	if slot == "":
		return false  # não é um item equipável
	var old_bonus := _hp_bonus_for_item(equipped.get(slot, ""))
	equipped[slot] = item_id
	var new_bonus := _hp_bonus_for_item(item_id)
	hp = clamp(hp + (new_bonus - old_bonus), 1, get_max_hp())
	save_game()
	stats_changed.emit()
	return true


func unequip_slot(slot: String) -> void:
	if equipped.get(slot, "") == "":
		return
	var old_bonus := _hp_bonus_for_item(equipped[slot])
	equipped[slot] = ""
	hp = clamp(hp - old_bonus, 1, get_max_hp())
	save_game()
	stats_changed.emit()


func is_item_equipped(item_id: String) -> bool:
	var slot := _slot_for_item(item_id)
	return slot != "" and equipped.get(slot, "") == item_id


func get_equipment_attack_bonus() -> int:
	return _attack_bonus_for_item(equipped.get("weapon", ""))


func get_equipment_hp_bonus() -> int:
	return _hp_bonus_for_item(equipped.get("shield", "")) + _hp_bonus_for_item(equipped.get("armor", ""))


func _slot_for_item(item_id: String) -> String:
	for shop_item in SHOP_ITEMS:
		if shop_item["id"] == item_id:
			return shop_item.get("slot", "")
	return ""


func _hp_bonus_for_item(item_id: String) -> int:
	if item_id == "":
		return 0
	for shop_item in SHOP_ITEMS:
		if shop_item["id"] == item_id:
			return int(shop_item.get("hp_bonus", 0))
	return 0


func _attack_bonus_for_item(item_id: String) -> int:
	if item_id == "":
		return 0
	for shop_item in SHOP_ITEMS:
		if shop_item["id"] == item_id:
			return int(shop_item.get("attack_bonus", 0))
	return 0


func is_ranged_class() -> bool:
	if has_chosen_class():
		return not bool(CLASSES[player_class]["melee"])
	return false


func is_alive() -> bool:
	return hp > 0


func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	damage_taken.emit(amount)
	save_game()
	stats_changed.emit()


func heal(amount: int) -> void:
	hp = clamp(hp + amount, 0, get_max_hp())
	save_game()
	stats_changed.emit()


## Chamado quando o jogador morre numa masmorra: volta com metade do HP
## máximo. Sem perda de item/ouro — é um jogo de foco, não de punição.
func revive_after_defeat() -> void:
	hp = int(get_max_hp() / 2.0)
	save_game()
	stats_changed.emit()


func register_monster_defeated() -> void:
	total_monsters_defeated += 1
	save_game()
	stats_changed.emit()


## Mobília da Casa (v0.7): efeito real — reduz o gasto de fome por sessão
## de foco de 5 para 2. Comprada uma única vez.
func buy_furniture() -> bool:
	if casa_decorada:
		return false
	if not spend_gold(FURNITURE_COST):
		return false
	casa_decorada = true
	save_game()
	stats_changed.emit()
	return true


## --- Hábitos (v1.1) ---
## 5 hábitos de texto livre (você escolhe o nome, ex.: "Beber água",
## "Alongar"). Marcar como feito uma vez por dia de verdade (calendário do
## sistema) dá XP/ouro e mantém uma sequência de dias — quebrar um dia
## reseta a sequência, mas nunca tira o que você já ganhou.

func _ensure_habits_initialized() -> void:
	while habits.size() < HABIT_SLOTS:
		habits.append({
			"name": "Hábito %d" % (habits.size() + 1),
			"streak": 0,
			"best_streak": 0,
			"last_completed_date": "",
			"total_completions": 0,
		})


func _today_string() -> String:
	return Time.get_date_string_from_system()


func _unix_for_date(date_str: String) -> int:
	return Time.get_unix_time_from_datetime_string(date_str + " 00:00:00")


func rename_habit(index: int, new_name: String) -> void:
	if index < 0 or index >= habits.size():
		return
	var trimmed := new_name.strip_edges()
	habits[index]["name"] = trimmed if trimmed != "" else "Hábito %d" % (index + 1)
	save_game()
	stats_changed.emit()


func is_habit_completed_today(index: int) -> bool:
	if index < 0 or index >= habits.size():
		return false
	return habits[index].get("last_completed_date", "") == _today_string()


## Retorna true se marcou com sucesso (false se já tinha marcado hoje).
func complete_habit(index: int) -> bool:
	if index < 0 or index >= habits.size():
		return false
	if is_habit_completed_today(index):
		return false

	var habit: Dictionary = habits[index]
	var today := _today_string()
	var last_date: String = habit.get("last_completed_date", "")
	var new_streak := 1
	if last_date != "":
		var gap_days := int(round((_unix_for_date(today) - _unix_for_date(last_date)) / 86400.0))
		new_streak = int(habit.get("streak", 0)) + 1 if gap_days == 1 else 1

	habit["streak"] = new_streak
	habit["best_streak"] = max(int(habit.get("best_streak", 0)), new_streak)
	habit["last_completed_date"] = today
	habit["total_completions"] = int(habit.get("total_completions", 0)) + 1
	habits[index] = habit

	# Recompensa base + bônus a cada 5 dias seguidos de sequência.
	var streak_bonus := int(new_streak / 5.0)
	xp += 5 + streak_bonus * 2
	gold += 5 + streak_bonus * 3
	_check_level_up()
	save_game()
	stats_changed.emit()
	return true


## --- Áudio (v1.1) ---

func set_audio_muted(muted: bool) -> void:
	audio_muted = muted
	save_game()
	stats_changed.emit()


func set_audio_volume(volume: float) -> void:
	audio_volume = clamp(volume, 0.0, 1.0)
	save_game()
	stats_changed.emit()


## TEMPORÁRIO (teste): F9 sobe um nível sem salvar. Remover antes da v2.0.
func debug_level_up() -> void:
	xp += xp_to_next - xp
	_check_level_up()
	stats_changed.emit()


func _check_level_up() -> void:
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 100 * level
		leveled_up.emit(level)


func save_game() -> void:
	var data := {
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next,
		"gold": gold,
		"hunger": hunger,
		"inventory": inventory,
		"total_focus_sessions": total_focus_sessions,
		"claimed_missions": claimed_missions,
		"player_class": player_class,
		"hp": hp,
		"casa_decorada": casa_decorada,
		"total_monsters_defeated": total_monsters_defeated,
		"habits": habits,
		"audio_muted": audio_muted,
		"audio_volume": audio_volume,
		"equipped": equipped,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	level = parsed.get("level", 1)
	xp = parsed.get("xp", 0)
	xp_to_next = parsed.get("xp_to_next", 100)
	gold = parsed.get("gold", 0)
	hunger = parsed.get("hunger", 100)
	var loaded_inventory: Variant = parsed.get("inventory", {})
	inventory = loaded_inventory if typeof(loaded_inventory) == TYPE_DICTIONARY else {}
	total_focus_sessions = parsed.get("total_focus_sessions", 0)
	var loaded_claimed: Variant = parsed.get("claimed_missions", [])
	claimed_missions = loaded_claimed if typeof(loaded_claimed) == TYPE_ARRAY else []
	player_class = parsed.get("player_class", "")
	hp = parsed.get("hp", get_max_hp())
	casa_decorada = parsed.get("casa_decorada", false)
	total_monsters_defeated = parsed.get("total_monsters_defeated", 0)
	var loaded_habits: Variant = parsed.get("habits", [])
	habits = loaded_habits if typeof(loaded_habits) == TYPE_ARRAY else []
	audio_muted = parsed.get("audio_muted", false)
	audio_volume = parsed.get("audio_volume", 1.0)
	var loaded_equipped: Variant = parsed.get("equipped", {})
	equipped = loaded_equipped if typeof(loaded_equipped) == TYPE_DICTIONARY else {"weapon": "", "shield": "", "armor": ""}
	for slot_key in ["weapon", "shield", "armor"]:
		if not equipped.has(slot_key):
			equipped[slot_key] = ""
	stats_changed.emit()
