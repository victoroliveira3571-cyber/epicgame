extends Node

## Controle de cenas, transições com fade, controles (InputMap) e estado da
## expedição na masmorra. Autoload: `Game`.

signal run_updated
signal run_finished(summary: Dictionary)

const TOWN_SCENE := "res://scenes/Main.tscn"
const DUNGEON_SCENE := "res://scenes/Dungeon.tscn"

var current_floor: int = 0
var run: Dictionary = {}
var town_spawn: String = "start"
var transitioning: bool = false
var input_locked: bool = false    # janelas abertas / diálogo / transição
var last_run_summary: Dictionary = {}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.04, 0.03, 0.06, 1.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	_fade_layer.add_child(_fade_rect)


# ============================================================ Controles
func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("attack", [KEY_SPACE, KEY_J])
	_add_action("dodge", [KEY_SHIFT, KEY_K])
	_add_action("skill", [KEY_Q, KEY_L])
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


func change_scene(path: String, duration: float = 0.3) -> void:
	if transitioning:
		return
	transitioning = true
	input_locked = true
	await fade_out(duration)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in(duration + 0.05)
	input_locked = false
	transitioning = false


func go_to_town(spawn: String = "start") -> void:
	town_spawn = spawn
	GameState.in_dungeon = false
	change_scene(TOWN_SCENE)


# ============================================================ Masmorra
func can_enter_dungeon() -> bool:
	return GameState.energy >= Data.ENERGY_PER_RUN


func enter_dungeon(start_floor: int = 1) -> bool:
	if not can_enter_dungeon():
		GameState.toast.emit("Sem energia! Complete sessões de foco para recarregar.", Color("ff7a6a"))
		Audio.sfx("ui_error")
		return false
	GameState.spend_energy(Data.ENERGY_PER_RUN)
	current_floor = start_floor
	run = {
		"start_floor": start_floor, "kills": 0, "bosses": 0, "gold": 0, "xp": 0, "items": {},
		"time": 0.0, "chests": 0, "deepest": start_floor, "died": false,
	}
	GameState.in_dungeon = true
	GameState.register_floor_reached(start_floor)
	run_updated.emit()
	change_scene(DUNGEON_SCENE)
	return true


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


func finish_run(died: bool) -> void:
	if run.is_empty():
		go_to_town("gate")
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
