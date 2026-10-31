extends Node

## Controle de cenas, transições com fade, controles (InputMap) e estado da
## expedição na masmorra. Autoload: `Game`.

signal run_updated
signal run_finished(summary: Dictionary)

const TOWN_SCENE := "res://scenes/Main.tscn"
const TITLE_SCENE := "res://scenes/Title.tscn"
const DUNGEON_SCENE := "res://scenes/Dungeon.tscn"
const INTERIOR_SCENE := "res://scenes/Interior.tscn"
const FOREST_SCENE := "res://scenes/Forest.tscn"

var current_floor: int = 0
var run: Dictionary = {}
var town_spawn: String = "start"      # "start" | "gate" | "forest" | "door:<id do interior>"
var forest_spawn: String = "town"     # "town" | "door:<id do interior>"
var interior_id: String = ""
var interior_return: String = "town"  # para onde a porta do interior leva: "town" | "forest"
var transitioning: bool = false
var input_locked: bool = false    # janelas abertas / diálogo / transição
var last_run_summary: Dictionary = {}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _card_title: Label
var _card_sub: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.04, 0.03, 0.06, 1.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)
	# cartão do lugar durante a transição (Floresta, Masmorra, cidade)
	_card_title = UI.label("", UI.C_ORANGE_L, 3)
	_card_sub = UI.label("", UI.C_TEXT)
	for l in [_card_title, _card_sub]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(UI.SIZE.x, 30)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.modulate.a = 0.0
		_fade_layer.add_child(l)
	_card_title.position = Vector2(0, UI.SIZE.y / 2.0 - 28)
	_card_sub.position = Vector2(0, UI.SIZE.y / 2.0 + 6)


# ============================================================ Controles
func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("attack", [KEY_SPACE, KEY_J])
	_add_action("dodge", [KEY_SHIFT, KEY_K])
	_add_action("skill", [KEY_Q, KEY_L])
	_add_action("skill2", [KEY_R])      # habilidade do nível 10
	_add_action("skill3", [KEY_X])      # habilidade do nível 30
	_add_action("skill_book", [KEY_Z])  # magia do Livro de Magia (laboratório)
	_add_action("interact", [KEY_E])
	_add_action("eat", [KEY_F])
	_add_action("potion", [KEY_H])
	_add_action("inventory", [KEY_I, KEY_TAB])
	_add_action("character", [KEY_C])
	_add_action("habits", [KEY_T])
	_add_action("quests", [KEY_G])
	_add_action("pause", [KEY_ESCAPE])
	_add_action("map", [KEY_M])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


# ============================================================ Transições
func fade_out(duration: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await tw.finished


func fade_in(duration: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await tw.finished


## `title`/`subtitle`: cartão do lugar mostrado no escuro (fade mais longo, para a passagem não ser seca).
func change_scene(path: String, duration: float = 0.3, title: String = "", subtitle: String = "") -> void:
	if transitioning:
		return
	transitioning = true
	input_locked = true
	var carded := title != ""
	await fade_out(maxf(duration, 0.5) if carded else duration)
	get_tree().paused = false
	if carded:
		_card_title.text = title
		_card_sub.text = subtitle
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_card_title, "modulate:a", 1.0, 0.25)
		tw.tween_property(_card_sub, "modulate:a", 1.0, 0.25)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	if carded:
		await get_tree().create_timer(0.8).timeout
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(_card_title, "modulate:a", 0.0, 0.35)
		tw2.tween_property(_card_sub, "modulate:a", 0.0, 0.35)
	await fade_in(maxf(duration + 0.05, 0.7) if carded else duration + 0.05)
	input_locked = false
	transitioning = false


func go_to_title() -> void:
	GameState.in_dungeon = false
	Audio.pomo_update()
	change_scene(TITLE_SCENE)


func go_to_town(spawn: String = "start") -> void:
	if Law.is_jailed():
		go_to_jail(Law.jail_left(), "assault")
		return
	town_spawn = spawn
	GameState.in_dungeon = false
	if spawn == "forest":
		change_scene(TOWN_SCENE, 0.5, "Focus Town", "De volta à cidade")
	else:
		change_scene(TOWN_SCENE)


# ============================================================ Delegacia
## Preso: leva à cela da delegacia com o cartão "PRESO!". A pena vem de Law (minutos de foco).
func go_to_jail(fine_min: int, reason: String) -> void:
	interior_id = "delegacia"
	interior_return = "town"
	town_spawn = "start"
	GameState.in_dungeon = false
	run = {}
	var sub := "Multa: %d min de foco no Pomodoro" % fine_min
	change_scene(INTERIOR_SCENE, 0.6, "PRESO!" if reason != "murder" else "PRESO POR HOMICÍDIO!", sub)


# ============================================================ Interiores
func enter_interior(id: String, from: String = "town") -> void:
	interior_id = id
	interior_return = from
	if from == "town":
		town_spawn = "door:" + id
	GameState.in_dungeon = false
	change_scene(INTERIOR_SCENE, 0.25)


func leave_interior() -> void:
	if interior_return == "forest":
		go_to_forest("door:" + interior_id)
	else:
		go_to_town("door:" + interior_id)


# ============================================================ Floresta
func go_to_forest(spawn: String = "town") -> void:
	if Law.is_jailed():
		HUD.show_toast("Você está preso: cumpra a pena estudando.", UI.C_BAD)
		return
	forest_spawn = spawn
	GameState.in_dungeon = false
	if spawn.begins_with("door:"):
		change_scene(FOREST_SCENE)
	else:
		change_scene(FOREST_SCENE, 0.5, "Floresta de Focus Town", "A trilha das ervas")


# ============================================================ Masmorra
## Pode entrar no andar: liberado pela história e créditos para a entrada (o custo sobe a cada
## entrada no mesmo andar no mesmo dia, ver Data.travel_cost).
func can_enter_floor(floor_n: int) -> bool:
	if not Story.floor_unlocked(floor_n):
		return false
	return Story.credits() >= floor_entry_cost(floor_n)


func floor_entry_cost(floor_n: int) -> int:
	return Story.entry_cost("andar_%d" % floor_n, Data.floor_toll(floor_n))


func enter_dungeon(start_floor: int = 1) -> bool:
	if Law.is_jailed():
		GameState.toast.emit("Você está preso: cumpra a pena estudando.", Color("ff7a6a"))
		return false
	if not Story.floor_unlocked(start_floor):
		GameState.toast.emit("Este andar ainda não está liberado pela história.", Color("ff7a6a"))
		Audio.sfx("ui_error")
		return false
	if not Story.pay_entry("andar_%d" % start_floor, Data.floor_toll(start_floor)):
		GameState.toast.emit("Faltam créditos de estudo: o andar %d custa %d agora." % [start_floor, floor_entry_cost(start_floor)], Color("ff7a6a"))
		Audio.sfx("ui_error")
		return false
	current_floor = start_floor
	run = {
		"start_floor": start_floor, "kills": 0, "bosses": 0, "gold": 0, "xp": 0, "items": {},
		"time": 0.0, "chests": 0, "deepest": start_floor, "died": false,
	}
	GameState.in_dungeon = true
	GameState.register_floor_reached(start_floor)
	Audio.sfx2("porta_metal", -6.0, 0.0)
	run_updated.emit()
	change_scene(DUNGEON_SCENE, 0.5, "Masmorra", "Andar %d" % start_floor)
	return true


## Escada para baixo: confere se o próximo andar está liberado e cobra o pedágio dele.
func try_descend() -> void:
	var next := current_floor + 1
	if not Story.floor_unlocked(next):
		HUD.show_toast("O andar %d ainda não está liberado pela história." % next, UI.C_BAD)
		Audio.sfx("ui_error")
		return
	var cost := floor_entry_cost(next)
	if Story.credits() < cost:
		HUD.show_toast("O andar %d custa %d créditos de estudo agora (você tem %d)." % [next, cost, Story.credits()], UI.C_BAD)
		Audio.sfx("ui_error")
		return
	HUD.confirm("Pagar %s para descer ao andar %d?" % [Story.entry_text("andar_%d" % next, Data.floor_toll(next)), next], func() -> void:
		if Story.pay_entry("andar_%d" % next, Data.floor_toll(next)):
			descend())


func descend() -> void:
	current_floor += 1
	run["deepest"] = maxi(int(run.get("deepest", 1)), current_floor)
	GameState.bump("floors_descended")
	GameState.register_floor_reached(current_floor)
	run_updated.emit()
	change_scene(DUNGEON_SCENE, 0.25)


func restart_floor() -> void:
	change_scene(DUNGEON_SCENE, 0.25)


func run_add(key: String, amount: int = 1) -> void:
	if run.is_empty():
		return
	run[key] = int(run.get(key, 0)) + amount
	run_updated.emit()


func run_add_item(item_id: String, amount: int = 1) -> void:
	if run.is_empty():
		return
	var items: Dictionary = run["items"]
	items[item_id] = int(items.get(item_id, 0)) + amount


## Duelo da história (Torneio das Guildas): arena com o chefe dado, sem pedágio e sem castigo.
func start_duel(boss_id: String) -> void:
	current_floor = 9
	run = {
		"start_floor": 0, "kills": 0, "bosses": 0, "gold": 0, "xp": 0, "items": {},
		"time": 0.0, "chests": 0, "deepest": 0, "died": false, "duel": boss_id,
	}
	GameState.in_dungeon = true
	change_scene(DUNGEON_SCENE)


func is_duel() -> bool:
	return not run.is_empty() and String(run.get("duel", "")) != ""


func finish_run(died: bool) -> void:
	if run.is_empty():
		go_to_town("gate")
		return
	if is_duel():
		run = {}
		GameState.full_heal()
		if died:
			GameState.toast.emit("Você perdeu o duelo. Recupere o fôlego e fale com Helena para tentar de novo.", Color("ffb23e"))
		town_spawn = "door:guilda"
		go_to_town("door:guilda")
		return
	run["died"] = died
	last_run_summary = run.duplicate(true)
	run = {}
	if died:
		GameState.revive_after_defeat()
	run_finished.emit(last_run_summary)
	go_to_town("gate")


# ============================================================ Sensação de impacto
var _hit_stop_active: bool = false


## Congela o jogo por um instante (acertos fortes).
func hit_stop(duration: float = 0.05) -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false
