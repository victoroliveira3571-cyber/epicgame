extends CanvasLayer

## Interface do jogo (autoload `HUD`): cartão do jogador, hotbar, Pomodoro, minimapa,
## barra de chefe, avisos, confirmações e o gerenciador de janelas.
## A camada tem escala 2: todo o layout é pensado em 640x360.

const WINDOWS := {
	"inventario": "res://scripts/ui/windows/InventoryWindow.gd",
	"personagem": "res://scripts/ui/windows/CharacterWindow.gd",
	"loja": "res://scripts/ui/windows/ShopWindow.gd",
	"forja": "res://scripts/ui/windows/ForgeWindow.gd",
	"guilda": "res://scripts/ui/windows/GuildWindow.gd",
	"dungeon": "res://scripts/ui/windows/DungeonWindow.gd",
	"habitos": "res://scripts/ui/windows/HabitsWindow.gd",
	"restaurante": "res://scripts/ui/windows/RestaurantWindow.gd",
	"casa": "res://scripts/ui/windows/HomeWindow.gd",
	"pausa": "res://scripts/ui/windows/PauseWindow.gd",
	"classe": "res://scripts/ui/windows/ClassWindow.gd",
	"resumo": "res://scripts/ui/windows/SummaryWindow.gd",
}
const POMODORO_PRESETS := [15, 25, 45]
const BREAK_MINUTES := 5

var root: Control
var scene_kind: String = ""       # "town" | "dungeon" | ""
var window: UIWindow = null
var window_id: String = ""

# Pomodoro (continua rodando entre cenas e com janelas abertas)
var pomo_state: String = "idle"   # idle | focus | break | paused
var pomo_minutes: int = 25
var pomo_total: float = 0.0
var pomo_left: float = 0.0
var _pomo_prev_state: String = "focus"

var _prompt: Label
var _card: Control
var _card_face: TextureRect
var _card_name: Label
var _hp_bar: UI.Bar
var _xp_bar: UI.Bar
var _food_bar: UI.Bar
var _gold_label: Label
var _energy_box: HBoxContainer
var _buff_box: HBoxContainer
var _hotbar: Control
var _hot_potion: UI.Slot
var _hot_food: UI.Slot
var _hot_skill: HotSkill
var _hot_dodge: HotSkill
var _pomo_panel: Control
var _pomo_time: Label
var _pomo_status: Label
var _pomo_bar: UI.Bar
var _pomo_btn: Button
var _pomo_mode: Button
var _pomo_reset: Button
var _minimap: Minimap
var _boss_box: Control
var _boss_name: Label
var _boss_bar: UI.Bar
var _banner: Control
var _toasts: VBoxContainer
var _confirm_box: Control
var _hint: Label
var _last_buffs_sig: String = ""
var _face_class: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	scale = Vector2(2, 2)
	add_to_group("hud")
	root = Control.new()
	root.theme = UI.theme()
	root.size = UI.SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_card()
	_build_pomodoro()
	_build_minimap()
	_build_hotbar()
	_build_boss_bar()
	_build_banner()
	_build_prompt()
	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(8, 74)
	_toasts.size = Vector2(200, 100)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_theme_constant_override("separation", 2)
	root.add_child(_toasts)
	GameState.stats_changed.connect(_refresh_card)
	GameState.energy_changed.connect(_refresh_card)
	GameState.buffs_changed.connect(_refresh_buffs)
	GameState.toast.connect(show_toast)
	GameState.leveled_up.connect(_on_level_up)
	GameState.item_gained.connect(_on_item_gained)
	Game.run_finished.connect(_on_run_finished)
	set_scene_kind("")
	_refresh_card()
	_refresh_pomodoro()


# ================================================================== Cena
func on_scene_ready(which: String) -> void:
	scene_kind = which
	set_scene_kind(which)
	hide_boss()
	_prompt.text = ""
	if window != null:
		close_window()
	if which == "town":
		if not GameState.has_chosen_class():
			Audio.play_music("title")
			open_window("classe")
		elif not Game.last_run_summary.is_empty() and not Game.last_run_summary.get("shown", false):
			Game.last_run_summary["shown"] = true
			open_window("resumo")


func set_scene_kind(which: String) -> void:
	var playing := which != ""
	_card.visible = playing
	_hotbar.visible = playing
	_pomo_panel.visible = playing
	_minimap.visible = which == "dungeon"
	_hint.visible = playing


# ================================================================== Cartão do jogador
func _build_card() -> void:
	_card = Control.new()
	_card.position = Vector2(6, 6)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_card)
	var bg := Panel.new()
	bg.size = Vector2(172, 62)
	bg.add_theme_stylebox_override("panel", UI.flat(Color(0.1, 0.08, 0.08, 0.82), UI.C_LINE, 1))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(bg)
	var frame := Panel.new()
	frame.size = bg.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.box_tex("nine_path_panel", 5, Vector4(0, 0, 0, 0), false))
	_card.add_child(frame)
	_card_face = UI.icon(null, 32)
	_card_face.position = Vector2(7, 7)
	_card.add_child(_card_face)
	var face_frame := Panel.new()
	face_frame.position = Vector2(6, 6)
	face_frame.size = Vector2(34, 34)
	face_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_frame.add_theme_stylebox_override("panel", UI.flat(Color.TRANSPARENT, UI.C_ORANGE, 1))
	_card.add_child(face_frame)
	_card_name = UI.label("")
	_card_name.position = Vector2(46, 5)
	_card.add_child(_card_name)
	_hp_bar = UI.Bar.new(Vector2(118, 10), UI.C_HP)
	_hp_bar.position = Vector2(46, 18)
	_card.add_child(_hp_bar)
	_xp_bar = UI.Bar.new(Vector2(118, 6), UI.C_XP)
	_xp_bar.position = Vector2(46, 30)
	_xp_bar.back = Color("121c2a")
	_card.add_child(_xp_bar)
	_food_bar = UI.Bar.new(Vector2(118, 4), UI.C_FOOD)
	_food_bar.position = Vector2(46, 38)
	_food_bar.back = Color("2a1c0c")
	_card.add_child(_food_bar)
	_gold_label = UI.label("", UI.C_GOLD)
	_gold_label.position = Vector2(8, 44)
	_card.add_child(_gold_label)
	_energy_box = UI.hbox(2)
	_energy_box.position = Vector2(46, 46)
	_energy_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_energy_box)
	_buff_box = UI.hbox(2)
	_buff_box.position = Vector2(6, 68)
	_buff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_buff_box)


func _refresh_card() -> void:
	if _card == null or not GameState.has_chosen_class():
		return
	var cls: Dictionary = Data.CLASSES[GameState.player_class]
	if _face_class != GameState.player_class:
		_face_class = GameState.player_class
		_card_face.texture = Pix.atlas("chars/%s.png" % cls["sheet"], Rect2(0, 0, 16, 16))
		_card_face.custom_minimum_size = Vector2(32, 32)
		_card_face.size = Vector2(32, 32)
	_card_name.text = "Nv %d %s" % [GameState.level, cls["name"]]
	var max_hp := GameState.get_max_hp()
	_hp_bar.set_ratio(float(GameState.hp) / float(max_hp), "%d/%d" % [GameState.hp, max_hp])
	_xp_bar.set_ratio(float(GameState.xp) / float(maxi(1, GameState.xp_to_next)))
	_food_bar.set_ratio(float(GameState.hunger) / 100.0)
	_food_bar.fill = UI.C_FOOD if GameState.hunger > 20 else UI.C_BAD
	_gold_label.text = "%s" % UI.fmt_int(GameState.gold)
	_gold_label.position.x = 8
	for c in _energy_box.get_children():
		_energy_box.remove_child(c)
		c.queue_free()
	for i in Data.ENERGY_MAX:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(6, 6)
		pip.color = UI.C_ENERGY if i < GameState.energy else Color("3a3426")
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_energy_box.add_child(pip)
	_refresh_buffs()
	_refresh_hotbar()


func _refresh_buffs() -> void:
	if _buff_box == null:
		return
	var sig := ",".join(GameState.buffs.keys())
	if sig == _last_buffs_sig and _buff_box.get_child_count() == GameState.buffs.size():
		return
	_last_buffs_sig = sig
	for c in _buff_box.get_children():
		_buff_box.remove_child(c)
		c.queue_free()
	for bid in GameState.buffs:
		var b: Dictionary = Data.BUFFS.get(bid, {})
		var box := UI.vbox(0)
		box.name = "buff_" + bid
		var ic := UI.icon(Pix.skill_icon(b.get("icon", "items/Kunai")), 14)
		box.add_child(ic)
		var t := UI.label("", UI.C_DIM)
		t.name = "t"
		box.add_child(t)
		_buff_box.add_child(box)


func _tick_buff_labels() -> void:
	for bid in GameState.buffs:
		var n := _buff_box.get_node_or_null("buff_" + bid)
		if n != null:
			var t := n.get_node_or_null("t") as Label
			if t != null:
				t.text = UI.fmt_time(float(GameState.buffs[bid]))


# ================================================================== Hotbar
class HotSkill extends Control:
	var icon_tex: Texture2D
	var key_text: String = ""
	var ratio: float = 0.0      # 0 = pronto, 1 = recarga cheia
	var seconds_left: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)
		size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_texture_rect(Pix.tex("ui/theme/inventory_cell.png"), Rect2(0, 0, 24, 24), false)
		if icon_tex != null:
			draw_texture_rect(icon_tex, Rect2(4, 4, 16, 16), false, Color.WHITE if ratio <= 0.0 else Color(1, 1, 1, 0.5))
		if ratio > 0.0:
			draw_rect(Rect2(1, 1 + 22.0 * (1.0 - ratio), 22, 22.0 * ratio), Color(0, 0, 0, 0.55))
			var f := Pix.font(1)
			var s := "%.1f" % seconds_left if seconds_left < 10.0 else str(int(seconds_left))
			var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, Vector2((24 - w) / 2.0, 16), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		var kf := Pix.font(1)
		draw_string(kf, Vector2(2, 34), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_DIM)


func _build_hotbar() -> void:
	_hotbar = Control.new()
	_hotbar.position = Vector2(UI.SIZE.x / 2.0 - 60, UI.SIZE.y - 46)
	_hotbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hotbar)
	_hot_potion = UI.Slot.new(24)
	_hot_potion.position = Vector2(0, 0)
	_hot_potion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hotbar.add_child(_hot_potion)
	_hot_food = UI.Slot.new(24)
	_hot_food.position = Vector2(32, 0)
	_hot_food.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hotbar.add_child(_hot_food)
	_hot_skill = HotSkill.new()
	_hot_skill.position = Vector2(68, 0)
	_hot_skill.key_text = "Q"
	_hotbar.add_child(_hot_skill)
	_hot_dodge = HotSkill.new()
	_hot_dodge.position = Vector2(96, 0)
	_hot_dodge.key_text = "Shift"
	_hot_dodge.icon_tex = Pix.skill_icon("items/Boot")
	_hotbar.add_child(_hot_dodge)
	for pair in [[_hot_potion, "H"], [_hot_food, "F"]]:
		var l := UI.label(pair[1], UI.C_DIM)
		l.position = pair[0].position + Vector2(2, 25)
		_hotbar.add_child(l)
	_hint = UI.label("I Inventário  C Personagem  T Hábitos  G Missões  P Pomodoro  Esc Pausa", Color(1, 1, 1, 0.55))
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("shadow_offset_x", 1)
	_hint.add_theme_constant_override("shadow_offset_y", 1)
	_hint.position = Vector2(8, UI.SIZE.y - 14)
	root.add_child(_hint)


func _refresh_hotbar() -> void:
	if _hot_potion == null:
		return
	var pid := GameState.quick_potion()
	_hot_potion.set_item(pid, GameState.count_item(pid) if pid != "" else 0)
	_hot_potion.dim = pid == ""
	var fid := GameState.quick_food()
	_hot_food.set_item(fid, GameState.count_item(fid) if fid != "" else 0)
	_hot_food.dim = fid == ""
	if GameState.has_chosen_class():
		var sk: Dictionary = Data.SKILLS[Data.CLASSES[GameState.player_class]["skill"]]
		_hot_skill.icon_tex = Pix.skill_icon(sk["icon"])
		_hot_skill.queue_redraw()
	_hot_dodge.queue_redraw()


func _tick_hotbar() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or not GameState.has_chosen_class():
		return
	var sk: Dictionary = Data.SKILLS[Data.CLASSES[GameState.player_class]["skill"]]
	var cd := float(sk["cd"])
	var r := clampf(p.skill_cd_left / cd, 0.0, 1.0)
	if r != _hot_skill.ratio or p.skill_cd_left > 0.0:
		_hot_skill.ratio = r
		_hot_skill.seconds_left = p.skill_cd_left
		_hot_skill.queue_redraw()
	var dr := clampf(p.dodge_cd_left / Player.DODGE_COOLDOWN, 0.0, 1.0)
	if dr != _hot_dodge.ratio or p.dodge_cd_left > 0.0:
		_hot_dodge.ratio = dr
		_hot_dodge.seconds_left = p.dodge_cd_left
		_hot_dodge.queue_redraw()


# ================================================================== Pomodoro
func _build_pomodoro() -> void:
	_pomo_panel = Control.new()
	_pomo_panel.position = Vector2(UI.SIZE.x - 164, 6)
	_pomo_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_pomo_panel)
	var bg := Panel.new()
	bg.size = Vector2(158, 50)
	bg.add_theme_stylebox_override("panel", UI.flat(Color(0.1, 0.08, 0.08, 0.82), UI.C_LINE, 1))
	_pomo_panel.add_child(bg)
	var frame := Panel.new()
	frame.size = bg.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.box_tex("nine_path_panel", 5, Vector4(0, 0, 0, 0), false))
	_pomo_panel.add_child(frame)
	_pomo_status = UI.label("POMODORO", UI.C_ORANGE_L)
	_pomo_status.position = Vector2(8, 5)
	_pomo_panel.add_child(_pomo_status)
	_pomo_time = UI.label("25:00", UI.C_TEXT, 2)
	_pomo_time.position = Vector2(8, 15)
	_pomo_panel.add_child(_pomo_time)
	_pomo_bar = UI.Bar.new(Vector2(142, 3), UI.C_GOOD)
	_pomo_bar.position = Vector2(8, 41)
	_pomo_panel.add_child(_pomo_bar)
	_pomo_mode = UI.button("25m", _cycle_preset, 34)
	_pomo_mode.position = Vector2(80, 7)
	_pomo_panel.add_child(_pomo_mode)
	_pomo_btn = UI.button("Iniciar", pomodoro_toggle, 62)
	_pomo_btn.position = Vector2(80, 23)
	_pomo_panel.add_child(_pomo_btn)
	_pomo_reset = UI.button("x", pomodoro_cancel, 22)
	_pomo_reset.position = Vector2(118, 7)
	_pomo_panel.add_child(_pomo_reset)


func _cycle_preset() -> void:
	if pomo_state != "idle":
		return
	var i := POMODORO_PRESETS.find(pomo_minutes)
	pomo_minutes = POMODORO_PRESETS[(i + 1) % POMODORO_PRESETS.size()]
	_refresh_pomodoro()


func pomodoro_toggle() -> void:
	match pomo_state:
		"idle":
			pomo_state = "focus"
			pomo_total = pomo_minutes * 60.0
			pomo_left = pomo_total
			Audio.sfx("ui_ok", -3.0)
			show_toast("Foco iniciado: %d minutos" % pomo_minutes, UI.C_GOOD)
		"focus", "break":
			_pomo_prev_state = pomo_state
			pomo_state = "paused"
		"paused":
			pomo_state = _pomo_prev_state
	_refresh_pomodoro()


func pomodoro_cancel() -> void:
	if pomo_state == "idle":
		return
	if pomo_state == "focus" or (pomo_state == "paused" and _pomo_prev_state == "focus"):
		show_toast("Foco cancelado: sem recompensa.", UI.C_DIM)
	pomo_state = "idle"
	pomo_left = 0.0
	_refresh_pomodoro()


func _tick_pomodoro(delta: float) -> void:
	if pomo_state == "focus" or pomo_state == "break":
		pomo_left -= delta
		if pomo_left <= 0.0:
			_pomodoro_done()
	_refresh_pomodoro()


func _pomodoro_done() -> void:
	if pomo_state == "focus":
		var xp := int(round(pomo_minutes * 2.4))
		var gold := int(round(pomo_minutes * 1.2))
		var r := GameState.complete_focus_session(xp, gold)
		Audio.jingle("success2")
		show_toast("Foco concluído! +%d XP  +%d ouro  +%d energia" % [r["xp"], r["gold"], r["energy"]], UI.C_GOLD)
		pomo_state = "break"
		pomo_total = BREAK_MINUTES * 60.0
		pomo_left = pomo_total
	else:
		Audio.sfx("ui_ok")
		show_toast("Pausa terminada. Hora de focar!", UI.C_XP)
		pomo_state = "idle"
		pomo_left = 0.0


func _refresh_pomodoro() -> void:
	if _pomo_time == null:
		return
	Audio.set_clock(pomo_state == "focus")
	var shown_left := pomo_left if pomo_state != "idle" else pomo_minutes * 60.0
	_pomo_time.text = UI.fmt_time(shown_left)
	_pomo_mode.text = "%dm" % pomo_minutes
	_pomo_mode.disabled = pomo_state != "idle"
	match pomo_state:
		"idle":
			_pomo_status.text = "POMODORO"
			_pomo_btn.text = "Iniciar"
			_pomo_bar.set_ratio(0.0)
		"focus":
			_pomo_status.text = "FOCO"
			_pomo_btn.text = "Pausar"
			_pomo_bar.fill = UI.C_ORANGE
			_pomo_bar.set_ratio(1.0 - pomo_left / maxf(pomo_total, 1.0))
		"break":
			_pomo_status.text = "PAUSA"
			_pomo_btn.text = "Pausar"
			_pomo_bar.fill = UI.C_GOOD
			_pomo_bar.set_ratio(1.0 - pomo_left / maxf(pomo_total, 1.0))
		"paused":
			_pomo_status.text = "PAUSADO"
			_pomo_btn.text = "Seguir"
	_pomo_reset.disabled = pomo_state == "idle"


# ================================================================== Minimapa
class Minimap extends Control:
	const CELL := 2
	var dungeon: Node = null

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func bind(d: Node) -> void:
		dungeon = d
		if d != null:
			var s: Vector2i = d.map_size()
			size = Vector2(s.x * CELL + 4, s.y * CELL + 4)
			custom_minimum_size = size
			if d.has_signal("explored_changed") and not d.explored_changed.is_connected(queue_redraw):
				d.explored_changed.connect(queue_redraw)
		queue_redraw()

	func _process(_delta: float) -> void:
		if visible and dungeon != null and is_instance_valid(dungeon):
			queue_redraw()

	func _draw() -> void:
		if dungeon == null or not is_instance_valid(dungeon):
			return
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.06, 0.78))
		draw_rect(Rect2(Vector2.ZERO, size), UI.C_LINE, false, 1.0)
		var s: Vector2i = dungeon.map_size()
		for y in s.y:
			for x in s.x:
				if dungeon.explored[y * s.x + x] == 0:
					continue
				if dungeon.is_floor_cell(x, y):
					draw_rect(Rect2(2 + x * CELL, 2 + y * CELL, CELL, CELL), Color(0.62, 0.56, 0.5, 0.9))
				elif dungeon.is_floor_cell(x, y + 1) or dungeon.is_floor_cell(x - 1, y) or dungeon.is_floor_cell(x + 1, y) or dungeon.is_floor_cell(x, y - 1):
					draw_rect(Rect2(2 + x * CELL, 2 + y * CELL, CELL, CELL), Color(0.25, 0.22, 0.26, 0.9))
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
		if dungeon.stairs_down != null:
			var sc: Vector2i = dungeon.cell_of(dungeon.stairs_down.global_position)
			if dungeon.explored[sc.y * s.x + sc.x] == 1:
				draw_rect(Rect2(2 + sc.x * CELL - 1, 2 + sc.y * CELL - 1, 4, 4), Color(UI.C_ORANGE_L, pulse))
		if dungeon.stairs_up != null:
			var uc: Vector2i = dungeon.cell_of(dungeon.stairs_up.global_position)
			draw_rect(Rect2(2 + uc.x * CELL, 2 + uc.y * CELL, 3, 3), UI.C_GOOD)
		if dungeon.boss != null and is_instance_valid(dungeon.boss) and dungeon.boss.state != Enemy.State.DEAD:
			var bc: Vector2i = dungeon.cell_of(dungeon.boss.global_position)
			if dungeon.explored[bc.y * s.x + bc.x] == 1:
				draw_rect(Rect2(2 + bc.x * CELL - 1, 2 + bc.y * CELL - 1, 5, 5), Color(UI.C_HP, pulse))
		var pc: Vector2i = dungeon.player_cell()
		draw_rect(Rect2(2 + pc.x * CELL - 1, 2 + pc.y * CELL - 1, 4, 4), UI.C_TEXT)


func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.position = Vector2(UI.SIZE.x - 130, 62)
	root.add_child(_minimap)


# ================================================================== Chefe
func _build_boss_bar() -> void:
	_boss_box = Control.new()
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.position = Vector2(UI.SIZE.x / 2.0 - 110, 14)
	root.add_child(_boss_box)
	_boss_name = UI.label("", UI.C_TEXT)
	_boss_name.size = Vector2(220, 12)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	_boss_bar = UI.Bar.new(Vector2(220, 9), Color("c93a3a"))
	_boss_bar.position = Vector2(0, 14)
	_boss_box.add_child(_boss_bar)


func show_boss(boss_name: String, ratio: float) -> void:
	_boss_name.text = boss_name
	_boss_bar.shown_ratio = ratio
	_boss_bar.set_ratio(ratio)
	_boss_box.visible = true


func update_boss(ratio: float) -> void:
	_boss_bar.set_ratio(ratio)


func hide_boss() -> void:
	if _boss_box != null:
		_boss_box.visible = false


# ================================================================== Banner e avisos
func _build_banner() -> void:
	_banner = Control.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	root.add_child(_banner)


func floor_banner(title: String, subtitle: String) -> void:
	for c in _banner.get_children():
		c.queue_free()
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.position = Vector2(0, 100)
	strip.size = Vector2(UI.SIZE.x, 44)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(strip)
	var t := UI.label(title, UI.C_ORANGE_L, 2)
	t.position = Vector2(0, 103)
	t.size = Vector2(UI.SIZE.x, 24)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(t)
	var s := UI.label(subtitle, UI.C_TEXT)
	s.position = Vector2(0, 129)
	s.size = Vector2(UI.SIZE.x, 12)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(s)
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.35)
	tw.tween_interval(1.8)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.6)


func show_toast(text: String, color: Color = Color.WHITE) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UI.flat(Color(0.08, 0.06, 0.07, 0.85), Color(color, 0.7), 1, Vector4(5, 2, 5, 3)))
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, color)
	pc.add_child(l)
	_toasts.add_child(pc)
	while _toasts.get_child_count() > 5:
		_toasts.get_child(0).queue_free()
		_toasts.remove_child(_toasts.get_child(0))
	var tw := pc.create_tween()
	tw.tween_interval(3.2)
	tw.tween_property(pc, "modulate:a", 0.0, 0.5)
	tw.tween_callback(pc.queue_free)


func _on_level_up(new_level: int) -> void:
	Audio.jingle("levelup")
	show_toast("Nível %d! Você ganhou pontos de talento (C)." % new_level, UI.C_GOLD)


func _on_item_gained(item_id: String, amount: int) -> void:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return
	show_toast("+%d %s" % [amount, it["name"]], UI.item_color(item_id))


func _on_run_finished(_summary: Dictionary) -> void:
	pass


# ================================================================== Prompt
func _build_prompt() -> void:
	_prompt = UI.label("", UI.C_TEXT)
	_prompt.position = Vector2(0, UI.SIZE.y - 66)
	_prompt.size = Vector2(UI.SIZE.x, 12)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_prompt.add_theme_constant_override("shadow_offset_x", 1)
	_prompt.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(_prompt)


func set_prompt(text: String) -> void:
	if _prompt != null:
		_prompt.text = text


# ================================================================== Janelas
func is_window_open() -> bool:
	return window != null and is_instance_valid(window)


func open_window(id: String) -> void:
	if is_window_open():
		if window_id == id:
			return
		close_window()
	if not WINDOWS.has(id):
		push_warning("[HUD] janela desconhecida: " + id)
		return
	var script: Script = load(WINDOWS[id])
	if script == null:
		push_warning("[HUD] janela sem script: " + id)
		return
	var w: UIWindow = script.new()
	w.win_id = id
	window = w
	window_id = id
	root.add_child(w)
	get_tree().paused = true
	Game.input_locked = true
	set_prompt("")
	Audio.sfx("ui_open", -3.0)


func close_window() -> void:
	if not is_window_open():
		return
	var closing_id := window_id
	window.queue_free()
	window = null
	window_id = ""
	get_tree().paused = false
	Game.input_locked = false
	if closing_id == "classe" and not GameState.has_chosen_class():
		open_window("classe")


func toggle_window(id: String) -> void:
	if is_window_open() and window_id == id:
		close_window()
	else:
		open_window(id)


## Pergunta sim/não. Em jogo pausa o mundo até responder.
func confirm(text: String, on_yes: Callable) -> void:
	if _confirm_box != null and is_instance_valid(_confirm_box):
		_confirm_box.queue_free()
	_confirm_box = Control.new()
	_confirm_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_box.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(_confirm_box)
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.5)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_box.add_child(veil)
	var panel := UI.window_panel(Vector2(240, 80))
	panel.position = ((UI.SIZE - Vector2(240, 80)) / 2.0).round()
	_confirm_box.add_child(panel)
	var l := UI.wrap_label(text, UI.C_TEXT, 216)
	l.position = Vector2(12, 12)
	panel.add_child(l)
	var close_box := func() -> void:
		if _confirm_box != null and is_instance_valid(_confirm_box):
			_confirm_box.queue_free()
		_confirm_box = null
		if not is_window_open():
			get_tree().paused = false
			Game.input_locked = false
	var yes := UI.button("Sim", func() -> void:
		close_box.call()
		on_yes.call(), 50)
	yes.position = Vector2(50, 54)
	panel.add_child(yes)
	var no := UI.button("Não", func() -> void: close_box.call(), 50)
	no.position = Vector2(140, 54)
	panel.add_child(no)
	get_tree().paused = true
	Game.input_locked = true
	Audio.sfx("ui_open", -3.0)


# ================================================================== Loop e atalhos
func _process(delta: float) -> void:
	_tick_pomodoro(delta)
	if _card.visible:
		_tick_hotbar()
		_tick_buff_labels()
	if scene_kind == "dungeon":
		if _minimap.dungeon == null or not is_instance_valid(_minimap.dungeon):
			_minimap.bind(get_tree().get_first_node_in_group("dungeon"))


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if scene_kind == "" or Game.transitioning:
		return
	if _confirm_box != null and is_instance_valid(_confirm_box):
		return
	var shortcuts := {
		"inventory": "inventario", "character": "personagem", "habits": "habitos", "quests": "guilda", "pause": "pausa",
	}
	for action in shortcuts:
		if ev.is_action(action):
			if action == "quests" and scene_kind != "town":
				return
			if action == "pause" and is_window_open():
				return  # a própria janela fecha com Esc
			get_viewport().set_input_as_handled()
			toggle_window(shortcuts[action])
			return
	if ev.keycode == KEY_P and not is_window_open():
		pomodoro_toggle()
