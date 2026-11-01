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
	"pomodoro": "res://scripts/ui/windows/PomodoroWindow.gd",
	"historico": "res://scripts/ui/windows/PomodoroHistoryWindow.gd",
	"guarda_roupa": "res://scripts/ui/windows/WardrobeWindow.gd",
	"creditos": "res://scripts/ui/windows/CreditsWindow.gd",
	"criacao": "res://scripts/ui/windows/CreationWindow.gd",
	"caderno": "res://scripts/ui/windows/NotebookWindow.gd",
	"preocupacoes": "res://scripts/ui/windows/WorryWindow.gd",
	"recall": "res://scripts/ui/windows/RecallWindow.gd",
	"mapa": "res://scripts/ui/windows/MapWindow.gd",
	"laboratorio": "res://scripts/ui/windows/LabWindow.gd",
	"aparencia": "res://scripts/ui/windows/AppearanceWindow.gd",
	"arena": "res://scripts/ui/windows/ArenaWindow.gd",
	"arena_resultado": "res://scripts/ui/windows/ArenaResultWindow.gd",
}

var root: Control
var scene_kind: String = ""       # "town" | "dungeon" | ""
var window: UIWindow = null
var window_id: String = ""

# Pomodoro (continua rodando entre cenas e com janelas abertas)
var pomo_state: String = "idle"   # idle | focus | break | paused
var pomo_minutes: int = 25     # duração do foco em uso (ou escolhida na janela)
var pomo_total: float = 0.0
var pomo_left: float = 0.0
var _pomo_prev_state: String = "focus"

var _prompt: Label
var _card: Control
var _card_face: LpcPortrait
var _card_name: Label
var _hp_bar: UI.Bar
var _xp_bar: UI.Bar
var _food_bar: UI.Bar
var _gold_label: Label
var _credit_label: Label
var _objective: Control
var _obj_title: Label
var _obj_text: Label
var _dialog: DialogueBox = null
var _buff_box: HBoxContainer
var _hotbar: Control
var _hot_potion: UI.Slot
var _hot_food: UI.Slot
var _hot_skill: HotSkill
var _hot_slots: Dictionary = {}    # "skill2"/"skill3" -> HotSkill (habilidades R e X da progressão)
var _hot_dodge: HotSkill
var _pomo_panel: Control
var _pomo_time: Label
var _pomo_status: Label
var _pomo_bar: UI.Bar
var _pomo_btn: Button
var _pomo_mode: Button
var _pomo_reset: Button
var _pomo_bg: Panel
var _pomo_frame: Panel
var _pomo_mini: Label
var _pomo_min_btn: Button
var _obj_min_btn: Button
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
	_build_objective()
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
	Story.changed.connect(_refresh_objective)
	GameState.buffs_changed.connect(_refresh_buffs)
	GameState.toast.connect(show_toast)
	GameState.leveled_up.connect(_on_level_up)
	GameState.skill_unlocked.connect(_on_skill_unlocked)
	GameState.item_gained.connect(_on_item_gained)
	Game.run_finished.connect(_on_run_finished)
	set_scene_kind("")
	_refresh_card()
	_refresh_pomodoro()


# ================================================================== Cena
func on_scene_ready(which: String) -> void:
	scene_kind = which
	set_scene_kind(which)
	if pomo_state == "idle":
		pomo_place = ""
	Audio.pomo_update()
	set_hint("")
	hide_boss()
	_prompt.text = ""
	if window != null:
		close_window()
	_refresh_card()
	_refresh_objective()
	if which == "town":
		if not Story.started():
			Audio.play_music("title")
			open_window("criacao")
		elif not Game.last_run_summary.is_empty() and not Game.last_run_summary.get("shown", false):
			Game.last_run_summary["shown"] = true
			open_window("resumo")


const DEFAULT_HINT := "I Inventário  C Personagem  N Caderno  T Hábitos  G Missões  P Pomodoro  Esc Pausa"


## Texto pequeno no canto de baixo; vazio volta ao padrão.
func set_hint(text: String) -> void:
	if _hint != null:
		_hint.text = text


func set_scene_kind(which: String) -> void:
	var playing := which != ""
	_card.visible = playing
	_hotbar.visible = playing
	_pomo_panel.visible = playing
	_minimap.visible = which == "dungeon" or which == "town" or which == "forest"
	_hint.visible = playing
	_keys.visible = playing
	_objective.visible = playing and Story.started()


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
	_card_face = LpcPortrait.new()
	_card_face.crop = Rect2(16, 8, 32, 32)
	_card_face.px_scale = 1.0
	_card_face.position = Vector2(7, 7)
	_card_face.size = Vector2(32, 32)
	_card_face.clip_contents = true
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
	_credit_label = UI.label("", UI.C_ENERGY)
	_credit_label.position = Vector2(46, 44)
	_credit_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_card.add_child(_credit_label)
	_buff_box = UI.hbox(2)
	_buff_box.position = Vector2(6, 68)
	_buff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_buff_box)


func _refresh_card() -> void:
	if _card == null or not Story.started():
		return
	var lk := Looks.hero()
	var key := LpcW.look_key(lk, "portrait")
	if _face_class != key:
		_face_class = key
		_card_face.set_look(lk)
	_card_face.set_expr("sad" if GameState.hp < GameState.get_max_hp() * 0.3 else "neutral")
	_card_name.text = "%s  Nv %d" % [Story.hero_name(), GameState.level]
	_credit_label.text = "Créd. %d   %s" % [Story.credits(), Story.rank_name()]
	var max_hp := GameState.get_max_hp()
	_hp_bar.set_ratio(float(GameState.hp) / float(max_hp), "%d/%d" % [GameState.hp, max_hp])
	_xp_bar.set_ratio(float(GameState.xp) / float(maxi(1, GameState.xp_to_next)))
	if GameState.starve_left >= 0.0:
		_food_bar.set_ratio(0.0, "%d s" % int(ceil(GameState.starve_left)))
	else:
		_food_bar.set_ratio(float(GameState.hunger) / 100.0)
	_food_bar.fill = UI.C_FOOD if GameState.hunger > 20 else UI.C_BAD
	_gold_label.text = "%s" % UI.fmt_int(GameState.gold)
	_gold_label.position.x = 8
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


## Teclas de atalho desenhadas como teclinhas (canto inferior esquerdo, acima da hotbar).
class KeyHints extends Control:
	const ROWS := [[["I", "Inventário"], ["C", "Personagem"], ["N", "Caderno"], ["T", "Hábitos"]],
		[["G", "Missões"], ["P", "Pomodoro"], ["Esc", "Pausa"]]]

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(250, 32)

	func _draw() -> void:
		var f := Pix.font(1)
		for r in ROWS.size():
			var x := 0.0
			var y := r * 15.0
			for pair in ROWS[r]:
				var kw := f.get_string_size(pair[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 6.0
				draw_rect(Rect2(x, y + 1, kw, 12), Color(0.12, 0.1, 0.1, 0.78))
				draw_rect(Rect2(x, y + 1, kw, 12), Color(1, 1, 1, 0.35), false, 1.0)
				draw_rect(Rect2(x + 1, y + 11, kw - 2, 1), Color(0, 0, 0, 0.5))
				draw_string(f, Vector2(x + 3, y + 11), pair[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_ORANGE_L)
				x += kw + 3.0
				draw_string(f, Vector2(x + 1, y + 12), pair[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.8))
				draw_string(f, Vector2(x, y + 11), pair[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.78))
				x += f.get_string_size(pair[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 9.0


var _keys: KeyHints
var _keys_idle: float = 0.0


## As teclas somem devagar enquanto o jogador anda (não cobrem o mapa) e voltam quando ele para.
func _tick_keys(delta: float) -> void:
	if _keys == null or not _keys.visible:
		return
	var p := get_tree().get_first_node_in_group("player") as Player
	var moving := p != null and p.velocity.length() > 5.0
	_keys_idle = 0.0 if moving else _keys_idle + delta
	var want := 0.9 if _keys_idle > 1.5 else 0.22
	_keys.modulate.a = move_toward(_keys.modulate.a, want, delta * 1.5)


func _build_hotbar() -> void:
	_hotbar = Control.new()
	_hotbar.position = Vector2(8, UI.SIZE.y - 40)
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
	for slot in ["skill2", "skill3", "skill_book"]:
		var hs := HotSkill.new()
		hs.key_text = Data.SKILL_KEYS[slot]
		hs.visible = false
		_hotbar.add_child(hs)
		_hot_slots[slot] = hs
	_hot_dodge = HotSkill.new()
	_hot_dodge.position = Vector2(96, 0)
	_hot_dodge.key_text = "Shift"
	_hot_dodge.icon_tex = Pix.skill_icon("items/Boot")
	_hotbar.add_child(_hot_dodge)
	for pair in [[_hot_potion, "H"], [_hot_food, "F"]]:
		var l := UI.label(pair[1], UI.C_DIM)
		l.position = pair[0].position + Vector2(2, 25)
		_hotbar.add_child(l)
	_keys = KeyHints.new()
	_keys.position = Vector2(8, UI.SIZE.y - 76)
	root.add_child(_keys)
	# dica de contexto (ex.: "V Organizar móveis"), acima das teclas
	_hint = UI.label("", Color(1, 1, 1, 0.8))
	_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hint.add_theme_constant_override("shadow_offset_x", 1)
	_hint.add_theme_constant_override("shadow_offset_y", 1)
	_hint.position = Vector2(8, UI.SIZE.y - 92)
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
	var x := 96.0
	if GameState.has_chosen_class():
		var sk: Dictionary = Data.SKILLS[Data.CLASSES[GameState.player_class]["skill"]]
		_hot_skill.icon_tex = Pix.skill_icon(sk["icon"])
		_hot_skill.queue_redraw()
	for slot in _hot_slots:
		var hs: HotSkill = _hot_slots[slot]
		var id := GameState.slot_skill(slot)
		hs.visible = id != ""
		if id != "":
			hs.icon_tex = Pix.skill_icon(Data.SKILLS[id]["icon"])
			hs.position = Vector2(x, 0)
			x += 28.0
			hs.queue_redraw()
	_hot_dodge.position = Vector2(x, 0)
	_hot_dodge.queue_redraw()


func _tick_hotbar() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null or not GameState.has_chosen_class():
		return
	var cd := maxf(GameState.skill_cooldown("skill"), 0.1)
	var r := clampf(p.skill_cd_left / cd, 0.0, 1.0)
	if r != _hot_skill.ratio or p.skill_cd_left > 0.0:
		_hot_skill.ratio = r
		_hot_skill.seconds_left = p.skill_cd_left
		_hot_skill.queue_redraw()
	for slot in _hot_slots:
		var hs: HotSkill = _hot_slots[slot]
		if not hs.visible:
			continue
		var left := float(p.slot_cd_left.get(slot, 0.0))
		var r2 := clampf(left / maxf(GameState.skill_cooldown(slot), 0.1), 0.0, 1.0)
		if r2 != hs.ratio or left > 0.0:
			hs.ratio = r2
			hs.seconds_left = left
			hs.queue_redraw()
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
	_pomo_bg = bg
	var frame := Panel.new()
	_pomo_frame = frame
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
	_pomo_mode = UI.button("Cena", func() -> void: open_window("pomodoro"), 34)
	_pomo_mode.position = Vector2(80, 7)
	_pomo_panel.add_child(_pomo_mode)
	_pomo_btn = UI.button("Iniciar", pomodoro_toggle, 62)
	_pomo_btn.position = Vector2(80, 23)
	_pomo_panel.add_child(_pomo_btn)
	_pomo_reset = UI.button("x", pomodoro_stop_prompt, 22)
	_pomo_reset.tooltip_text = "Parar: finalizar contando o tempo estudado"
	_pomo_reset.position = Vector2(118, 7)
	_pomo_panel.add_child(_pomo_reset)
	_pomo_mini = UI.label("25:00", UI.C_TEXT)
	_pomo_mini.position = Vector2(6, 4)
	_pomo_panel.add_child(_pomo_mini)
	_pomo_min_btn = UI.button("-", func() -> void: _set_pomo_min(not _pomo_minimized()), 14)
	_pomo_min_btn.tooltip_text = "Minimizar / abrir o Pomodoro"
	_pomo_panel.add_child(_pomo_min_btn)
	_apply_pomo_min()


func _pomo_minimized() -> bool:
	return bool(GameState.pomo_cfg.get("hud_min", false))


func _set_pomo_min(v: bool) -> void:
	GameState.pomo_cfg["hud_min"] = v
	_apply_pomo_min()


## Minimizado: só o tempo numa tira pequena no canto (não atrapalha o cenário).
func _apply_pomo_min() -> void:
	var m := _pomo_minimized()
	for n in [_pomo_status, _pomo_time, _pomo_bar, _pomo_mode, _pomo_btn, _pomo_reset]:
		(n as CanvasItem).visible = not m
	_pomo_mini.visible = m
	var size_v := Vector2(62, 18) if m else Vector2(158, 50)
	_pomo_bg.size = size_v
	_pomo_frame.size = size_v
	_pomo_panel.position = Vector2(UI.SIZE.x - 6 - size_v.x, 6)
	_pomo_min_btn.text = "+" if m else "-"
	_pomo_min_btn.position = Vector2(size_v.x - 18, 2) if m else Vector2(140, 7)
	if _objective != null:
		_objective.position.y = 28.0 if m else 60.0


## Cenário preso pelo lugar onde o Victor sentou para estudar ("" = livre para trocar).
var pomo_place: String = ""


## Abre o Pomodoro com o cenário fixo do lugar (mesa da casa, taverna, biblioteca).
func open_pomodoro_at(scene: String) -> void:
	if pomo_state == "idle" or pomo_place == "" or pomo_place == scene:
		pomo_place = scene
		GameState.pomo_cfg["scene"] = scene
		Audio.pomo_update()
	open_window("pomodoro")


## Começa o foco com as durações escolhidas (minutos) e guarda a escolha.
func pomodoro_start(focus_min: int, break_min: int) -> void:
	pomo_minutes = clampi(focus_min, 1, 180)
	GameState.pomo_cfg["focus"] = pomo_minutes
	GameState.pomo_cfg["break"] = clampi(break_min, 1, 60)
	GameState.save_game()
	pomo_state = "focus"
	pomo_total = pomo_minutes * 60.0
	pomo_left = pomo_total
	Audio.novo("pomodoro_inicio", -6.0)
	show_toast("Foco iniciado: %d minutos" % pomo_minutes, UI.C_GOOD)
	Audio.pomo_update()
	_refresh_pomodoro()


func pomodoro_toggle() -> void:
	match pomo_state:
		"idle":
			open_window("pomodoro")
		"focus", "break":
			_pomo_prev_state = pomo_state
			pomo_state = "paused"
		"paused":
			pomo_state = _pomo_prev_state
	Audio.pomo_update()
	_refresh_pomodoro()


func pomodoro_cancel() -> void:
	if pomo_state == "idle":
		return
	if is_focus_running():
		show_toast("Foco descartado: sem recompensa.", UI.C_DIM)
	pomo_state = "idle"
	pomo_left = 0.0
	Audio.pomo_update()
	_refresh_pomodoro()


## Foco rodando ou pausado no meio de um foco (não na pausa).
func is_focus_running() -> bool:
	return pomo_state == "focus" or (pomo_state == "paused" and _pomo_prev_state == "focus")


## Minutos de foco já estudados nesta sessão (o tempo pausado não conta).
func pomo_studied_minutes() -> int:
	if not is_focus_running():
		return 0
	return int(floor(maxf(pomo_total - pomo_left, 0.0) / 60.0))


## Termina o foco antes da hora e conta o tempo já estudado. Na pausa, encerra a pausa.
func pomodoro_finish() -> void:
	if pomo_state == "idle":
		return
	if not is_focus_running():
		_end_break("Pausa encerrada.")
		return
	var minutes := pomo_studied_minutes()
	if minutes < 1:
		pomo_state = "idle"
		pomo_left = 0.0
		show_toast("Menos de 1 minuto estudado: nada para contar.", UI.C_DIM)
		Audio.pomo_update()
		_refresh_pomodoro()
		return
	_reward_focus(minutes, true)


## Pergunta se finaliza contando o tempo ou descarta (botão "x" do HUD e janela do Pomodoro).
func pomodoro_stop_prompt() -> void:
	if pomo_state == "idle":
		return
	if not is_focus_running():
		pomodoro_finish()
		return
	var m := pomo_studied_minutes()
	if m < 1:
		confirm("Parar o foco? Ainda não passou 1 minuto, então nada será contado.", func() -> void: pomodoro_cancel())
		return
	confirm("Finalizar agora e contar os %d min estudados? (XP, ouro, créditos de estudo e histórico proporcionais)" % m,
		func() -> void: pomodoro_finish())


var _recall_t: float = 0.0


func _tick_pomodoro(delta: float) -> void:
	_recall_t -= delta
	if _recall_t <= 0.0:
		_recall_t = 1.5
		_check_recall()
	if pomo_state == "focus" or pomo_state == "break":
		pomo_left -= delta
		if pomo_left <= 0.0:
			_pomodoro_done()
	_refresh_pomodoro()


func _pomodoro_done() -> void:
	if pomo_state == "focus":
		_reward_focus(pomo_minutes, false)
	else:
		_end_break("Pausa terminada. Hora de focar!")


## Dá a recompensa de `minutes` de foco (XP 4/min, ouro 2/min, fichas de estilo 1/min e minutos para os
## créditos de estudo da história) e começa a pausa. `early` = o Victor finalizou antes do fim.
func _reward_focus(minutes: int, early: bool) -> void:
	var xp := int(round(minutes * 4.0))
	var gold := int(round(minutes * 2.0))
	var r := GameState.complete_focus_session(xp, gold, minutes, 0, (not early) or minutes >= Data.FOCUS_MIN_SESSION)
	GameState.log_pomodoro(minutes, str(GameState.pomo_cfg.get("scene", "")), early)
	GameState.pomo_cfg["recall_pending"] = {"idx": GameState.pomo_log.size() - 1, "minutes": minutes}
	GameState.save_game()
	Audio.jingle("pomo_done", -3.0)
	var head := "Foco finalizado (%d min)!" % minutes if early else "Foco concluído!"
	show_toast("%s +%d XP  +%d ouro  +%d fichas de estilo" % [head, r["xp"], r["gold"], r["credits"]], UI.C_GOLD)
	if Story.started() and int(r.get("story_credits", 0)) == 0:
		show_toast("Próximo crédito de estudo em %d min de foco." % Story.minutes_to_next_credit(), UI.C_ENERGY)
	pomo_state = "break"
	pomo_total = float(int(GameState.pomo_cfg.get("break", 5))) * 60.0
	pomo_left = pomo_total
	Audio.pomo_update()
	_refresh_pomodoro()
	_check_recall.call_deferred()


# ------------------------------------------------------------------ Recall do fim do foco
func recall_pending() -> Dictionary:
	var p: Variant = GameState.pomo_cfg.get("recall_pending", {})
	return p if typeof(p) == TYPE_DICTIONARY else {}


## Abre o recall se ele estiver pendente e nada mais ocupar a tela (também depois de reabrir o jogo).
func _check_recall() -> void:
	if recall_pending().is_empty() or not Story.started() or window_id == "recall":
		return
	if Game.input_locked and not is_window_open():
		return   # diálogo ou cena em andamento
	if _confirm_box != null and is_instance_valid(_confirm_box):
		return
	open_window("recall")


func recall_submit(text: String) -> void:
	var p := recall_pending()
	var idx := int(p.get("idx", -1))
	if idx >= 0 and idx < GameState.pomo_log.size():
		GameState.pomo_log[idx]["r"] = text
	GameState.pomo_cfg.erase("recall_pending")
	GameState.save_game()
	Audio.sfx("ui_ok")
	show_toast("Recall guardado. Boa pausa!", UI.C_GOOD)
	close_window()


func _end_break(msg: String) -> void:
	Audio.sfx("ui_ok")
	show_toast(msg, UI.C_XP)
	pomo_state = "idle"
	pomo_left = 0.0
	Audio.pomo_update()
	_refresh_pomodoro()


func _refresh_pomodoro() -> void:
	if _pomo_time == null:
		return
	Audio.set_clock(pomo_state == "focus")
	if pomo_state == "idle":
		pomo_minutes = int(GameState.pomo_cfg.get("focus", 25))
	var shown_left := pomo_left if pomo_state != "idle" else pomo_minutes * 60.0
	_pomo_time.text = UI.fmt_time(shown_left)
	_pomo_mini.text = UI.fmt_time(shown_left)
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
	const TOWN_PX := 2.0          # pixels do minimapa por tile da cidade
	var px: float = 2.0           # escala em uso (mapas grandes ficam menores)
	var dungeon: Node = null
	var town: Node = null

	## Cidade: chão em miniatura, prédios e o jogador.
	func bind_town(t: Node) -> void:
		town = t
		dungeon = null
		if t != null:
			px = minf(TOWN_PX, 132.0 / float(t.W))
			size = (Vector2(t.W, t.H) * px).round() + Vector2(4, 4)
			custom_minimum_size = size
		_anchor()
		queue_redraw()

	func _anchor() -> void:
		position = (UI.SIZE - size - Vector2(6, 6)).round()

	func _draw_town() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.06, 0.82))
		if town.minimap_tex != null:
			draw_texture_rect(town.minimap_tex, Rect2(Vector2(2, 2), size - Vector2(4, 4)), false, Color(1, 1, 1, 0.92))
		draw_rect(Rect2(Vector2.ZERO, size), UI.C_ORANGE, false, 1.0)
		var k := px / float(town.T)
		for id in town.buildings:
			var b: Node2D = town.buildings[id]
			draw_rect(Rect2(Vector2(2, 2) + b.position * k - Vector2(3, 5), Vector2(6, 5)), Color("c8743a"))
			draw_rect(Rect2(Vector2(2, 2) + b.position * k - Vector2(3, 5), Vector2(6, 5)), UI.C_LINE, false, 1.0)
		var obj: Variant = Story.objective_world_pos(town)
		if obj != null:
			var op: Vector2 = Vector2(2, 2) + (obj as Vector2) * k
			var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
			draw_circle(op, 4.0 + 2.0 * beat, Color(UI.C_GOLD, 0.35 + 0.35 * beat))
			draw_circle(op, 2.0, UI.C_GOLD)
		if town.player != null and is_instance_valid(town.player):
			var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
			var p: Vector2 = Vector2(2, 2) + town.player.global_position * k
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(UI.C_TEXT, pulse))
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), UI.C_LINE, false, 1.0)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func bind(d: Node) -> void:
		dungeon = d
		town = null
		if d != null:
			var s: Vector2i = d.map_size()
			size = Vector2(s.x * CELL + 4, s.y * CELL + 4)
			custom_minimum_size = size
			if d.has_signal("explored_changed") and not d.explored_changed.is_connected(queue_redraw):
				d.explored_changed.connect(queue_redraw)
		_anchor()
		queue_redraw()

	func _process(_delta: float) -> void:
		if visible and ((dungeon != null and is_instance_valid(dungeon)) or (town != null and is_instance_valid(town))):
			queue_redraw()

	func _draw() -> void:
		if town != null and is_instance_valid(town):
			_draw_town()
			return
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


var _banner_tween: Tween


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
	# v2.4: um aviso novo cancela o anterior (ao andar na divisa das zonas os tweens brigavam)
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.35)
	_banner_tween.tween_interval(1.8)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


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
	Audio.novo("lvl_up", -2.0)
	Audio.sfx("star", -6.0)
	show_toast("Nível %d! Você ganhou pontos de talento (C)." % new_level, UI.C_GOLD)
	_refresh_hotbar()


## A cada 10 níveis: avisa a habilidade nova (ativa, passiva ou maestria).
func _on_skill_unlocked(index: int) -> void:
	if index == 0:
		return   # a primeira magia já nasce com a classe
	var prog := GameState.class_progression()
	if index < 0 or index >= prog.size():
		return
	var e: Dictionary = prog[index]
	var title := ""
	match str(e["type"]):
		"active":
			title = "%s  [%s]" % [Data.SKILLS[e["skill"]]["name"], Data.SKILL_KEYS[e["slot"]]]
		"passive":
			title = str(e["name"]) + " (passiva)"
		_:
			title = "Maestria [%s]" % Data.SKILL_KEYS[e["slot"]]
	floor_banner("Habilidade nova!", title)
	show_toast("Nível %d: %s. Detalhes em Personagem (C) > Habilidades." % [Data.SKILL_LEVELS[index], title], UI.C_XP)
	_refresh_hotbar()


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
	if window_id == "recall" and id != "recall":
		return   # o recall do foco não se pula
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
	match id:
		"inventario", "guarda_roupa":
			Audio.sfx2("gaveta", -8.0)
		"caderno":
			Audio.sfx2("ui_pack3", -6.0)
		_:
			Audio.sfx2("ui_pack1", -8.0)


func close_window() -> void:
	if not is_window_open():
		return
	var closing_id := window_id
	if closing_id == "recall" and not recall_pending().is_empty():
		return
	window.queue_free()
	window = null
	window_id = ""
	get_tree().paused = false
	Game.input_locked = false
	if closing_id == "criacao" and not Story.started():
		open_window("criacao")


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
	_confirm_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_box.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(_confirm_box)
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.5)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_tick_keys(delta)
	_tick_pomodoro(delta)
	if _card.visible:
		_tick_hotbar()
		_tick_buff_labels()
		_credit_label.tooltip_text = "Créditos de estudo: 1 a cada %d min de foco.\nFloresta e masmorra custam 1 por entrada. Morrer tira 1 (pode ficar negativo)." % Data.MINUTES_PER_CREDIT
	if scene_kind == "dungeon":
		if _minimap.dungeon == null or not is_instance_valid(_minimap.dungeon):
			_minimap.bind(get_tree().get_first_node_in_group("dungeon"))
	elif scene_kind == "town" or scene_kind == "forest":
		if _minimap.town == null or not is_instance_valid(_minimap.town):
			_minimap.bind_town(get_tree().get_first_node_in_group("town"))


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if scene_kind == "" or Game.transitioning:
		return
	if _confirm_box != null and is_instance_valid(_confirm_box):
		return
	if is_dialogue_open() or not Story.started():
		return
	var shortcuts := {
		"inventory": "inventario", "character": "personagem", "habits": "habitos", "quests": "guilda", "pause": "pausa",
		"map": "mapa",
	}
	if ev.keycode == KEY_N and not (is_window_open() and window_id != "caderno"):
		get_viewport().set_input_as_handled()
		toggle_window("caderno")
		return
	for action in shortcuts:
		if ev.is_action(action):
			if action == "quests" and scene_kind == "dungeon":
				return
			if action == "pause" and is_window_open():
				return  # a própria janela fecha com Esc
			if action == "map" and scene_kind in ["", "interior"]:
				# v2.4: dentro de prédios não há mapa. Antes só o menu inicial era barrado: no interior a janela
				# abria, não achava cena, se fechava dentro do build e deixava o jogo pausado (engasgo ao apertar M)
				return
			get_viewport().set_input_as_handled()
			toggle_window(shortcuts[action])
			return
	if ev.keycode == KEY_P:
		toggle_window("pomodoro")


# ================================================================== Objetivo da história
func _build_objective() -> void:
	_objective = Control.new()
	_objective.position = Vector2(UI.SIZE.x - 164, 60)
	_objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_objective)
	var bg := Panel.new()
	bg.name = "bg"
	bg.size = Vector2(158, 40)
	bg.add_theme_stylebox_override("panel", UI.flat(Color(0.1, 0.08, 0.08, 0.72), UI.C_LINE, 1))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective.add_child(bg)
	_obj_title = UI.label("", UI.C_ORANGE_L)
	_obj_title.position = Vector2(6, 2)
	_objective.add_child(_obj_title)
	_obj_text = UI.wrap_label("", UI.C_TEXT, 146)
	_obj_text.position = Vector2(6, 14)
	_obj_text.size = Vector2(146, 12)
	_objective.add_child(_obj_text)
	_objective.visible = false
	_obj_min_btn = UI.button("-", func() -> void:
		GameState.pomo_cfg["obj_min"] = not bool(GameState.pomo_cfg.get("obj_min", false))
		_refresh_objective(), 14)
	_obj_min_btn.tooltip_text = "Minimizar / abrir o objetivo"
	_obj_min_btn.position = Vector2(140, 1)
	_objective.add_child(_obj_min_btn)


func _refresh_objective() -> void:
	if _objective == null:
		return
	if not Story.started() or scene_kind == "":
		_objective.visible = false
		return
	_objective.visible = true
	var ch: Dictionary = StoryData.CHAPTERS.get(Story.chapter(), {})
	_obj_title.text = String(ch.get("title", "")) + "  -  Objetivo"
	_obj_text.text = Story.objective_text()
	_obj_text.size = Vector2(146, 0)
	var lines := maxi(1, int(ceil(Pix.font(1).get_string_size(_obj_text.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x / 128.0)))
	_objective.position.y = 28.0 if _pomo_minimized() else 60.0
	var omin := bool(GameState.pomo_cfg.get("obj_min", false))
	_obj_text.visible = not omin
	_obj_min_btn.text = "+" if omin else "-"
	(_objective.get_node("bg") as Panel).size = Vector2(158, 18 if omin else 20 + 15 * lines)
	_refresh_card()


## Esconde o cartão do jogador (fase final do Rei Demônio "apaga" o nome e os atributos).
## Esconde a parte de baixo do HUD (teclas, dica, atalhos) enquanto algo usa a tela (modo Decorar).
func set_bottom_hidden(hidden: bool) -> void:
	for n in [_keys, _hotbar, _hint]:
		if n != null:
			(n as CanvasItem).visible = not hidden


func set_card_hidden(hidden: bool) -> void:
	if _card != null:
		_card.modulate.a = 0.0 if hidden else 1.0


# ================================================================== Diálogo e perguntas
func is_dialogue_open() -> bool:
	return _dialog != null and is_instance_valid(_dialog)


## Mostra um diálogo da história (id de StoryData.DIALOGS ou lista de falas) e espera o fim.
var _stage: Stage = null


## Primeiro falante que não é o herói (define o cenário do palco, p. ex. o trono do Rei Demônio).
func _first_npc_speaker(lines: Array) -> String:
	for e in lines:
		if e is Dictionary:
			continue
		var who := str((e as Array)[0])
		if who.contains("@"):
			who = who.get_slice("@", 0)
		if who.contains(":"):
			who = who.get_slice(":", 1)
		if who not in ["narr", "heroi", "", "espelho"] and not who.begins_with("rua_"):
			return who
	return ""


## Chamado pela DialogueBox a cada fala para o palco acompanhar quem fala.
func stage_focus(who: String, vis: Dictionary) -> void:
	if _stage != null and is_instance_valid(_stage):
		_stage.focus(who, vis)


func dialogue(entry: Variant) -> void:
	var lines: Array = entry if entry is Array else StoryData.DIALOGS.get(String(entry), [])
	if lines.is_empty():
		return
	while is_dialogue_open():
		await get_tree().process_frame
	set_prompt("")
	var was_paused := get_tree().paused
	get_tree().paused = true
	Game.input_locked = true
	if Stage.wanted(lines) and scene_kind != "":
		_stage = Stage.new()
		root.add_child(_stage)
		_stage.open_stage(Stage.pick_setting(get_tree(), _first_npc_speaker(lines)))
	_dialog = DialogueBox.new()
	root.add_child(_dialog)
	_keys.visible = false
	_hotbar.visible = false
	_dialog.start(lines)
	await _dialog.finished
	if _stage != null and is_instance_valid(_stage):
		_stage.close_stage()
	_stage = null
	_dialog.queue_free()
	_keys.visible = scene_kind != ""
	_hotbar.visible = scene_kind != ""
	_dialog = null
	if not is_window_open() and not was_paused:
		get_tree().paused = false
		_unlock_soon()


## Pergunta de memória (QuizPanel). Devolve {"result": ..., "hints": n}.
func quiz(card: Dictionary, title: String) -> Dictionary:
	var was_paused := get_tree().paused
	get_tree().paused = true
	Game.input_locked = true
	var q := QuizPanel.new()
	root.add_child(q)
	q.start(card, title)
	var res: Dictionary = await q.done
	q.queue_free()
	if not is_window_open() and not is_dialogue_open() and not was_paused:
		get_tree().paused = false
		_unlock_soon()
	return res


## Solta os controles um instante depois: a tecla que fechou a fala não pode reabrir a conversa.
func _unlock_soon() -> void:
	Game.input_locked = true
	await get_tree().create_timer(0.2).timeout
	if not is_window_open() and not is_dialogue_open() and not Game.transitioning:
		Game.input_locked = false
