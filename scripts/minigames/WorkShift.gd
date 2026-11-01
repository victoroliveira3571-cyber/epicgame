class_name WorkShift
extends Node2D

## v3.7: base dos mini-jogos de ofício jogados DENTRO do mundo (pedido do Victor: mini-jogos com cara de jogo de
## verdade, não telas de barras). Cada ofício tem uma sala própria (Interior "turno_<id>"): o herói anda com WASD,
## pega e leva coisas entre as estações com [E] e cumpre pedidos contra o relógio. Arte só de packs: estações
## animadas do Pixel Crawler, móveis do Ninja Adventure, comida do 64 Food Icons, personagens LPC.
## Fluxo: introdução (janela "mg_turno") -> contagem 3, 2, 1 -> turno -> resultado (recompensa e patente do ofício).
## Subclasses: `_build_room()`, `_tick(delta)`, `_score()` (0..1) e `_summary()` (linhas do resultado).

const SHIFT_DATA := {
	"cozinha": {"title": "Turno na cozinha da taverna", "room": "turno_cozinha", "skill": "atenção dividida e prioridades",
		"how_to": "Clientes chegam ao balcão com um pedido no balão. Pegue o ingrediente no caixote, prepare na TÁBUA (aperte E várias vezes), "
			+ "leve ao FOGÃO e tire quando ficar pronto, antes de queimar. Hambúrguer = bife pronto + pão na MESA DE MONTAGEM. "
			+ "Entregue no balcão, na frente do cliente certo. Erro vai para o BARRIL. Clientes servidos seguidos aumentam o combo."},
	"forja": {"title": "Turno na forja", "room": "turno_forja", "skill": "ritmo, tempo de reação e paciência",
		"how_to": "Leia o pedido no quadro. Pegue uma barra no caixote e ponha na FORNALHA: tire quando o calor estiver na faixa laranja. "
			+ "Na BIGORNA, martele no ritmo: aperte ESPAÇO (ou E) quando cada nota chegar no círculo. O metal esfria se você demorar! "
			+ "Tempere na TINA (E quando o vapor estiver na faixa) e entregue ao Brás. Peça perfeita vale mais."},
}

static var _return: Dictionary = {}
static var current_id: String = ""

var room: Interior
var game_id: String = ""
var duration: float = 120.0
var time_left: float = 0.0
var points: float = 0.0
var combo: int = 0
var running: bool = false
var carry: String = ""
var _carry_spr: Sprite2D
var _ui: CanvasLayer
var _panel: Control
var _lbl_time: Label
var _lbl_pts: Label
var _lbl_msg: Label
var _msg_t: float = 0.0
var _ending: bool = false


## Sai do lugar atual para a sala do ofício (volta para o mesmo lugar no fim).
static func begin(id: String) -> void:
	if not SHIFT_DATA.has(id):
		return
	# de onde veio: sala (Interior), cidade nova (City) ou Focus Town; volta para lá no fim
	var scene := Game.get_tree().current_scene
	if scene != null and scene.is_in_group("interior"):
		_return = {"kind": "interior", "interior": Game.interior_id, "from": Game.interior_return}
	elif scene != null and scene.is_in_group("city"):
		_return = {"kind": "city", "city": Game.city_id}
	else:
		_return = {"kind": "town"}
	current_id = id
	HUD.close_window()
	Game.enter_interior(str(SHIFT_DATA[id]["room"]), "turno")


static func attach(r: Interior) -> void:
	var id := r.id.trim_prefix("turno_")
	var s: WorkShift
	match id:
		"cozinha":
			s = KitchenShift.new()
		"forja":
			s = ForgeShift.new()
		_:
			return
	s.room = r
	s.game_id = id
	r.add_child(s)


func _ready() -> void:
	_build_ui()
	_build_room()
	_carry_spr = Sprite2D.new()
	_carry_spr.z_index = 50
	_carry_spr.position = Vector2(0, -40)
	_run_intro.call_deferred()


# ================================================================== Fluxo
func _run_intro() -> void:
	ShiftWindow.data = SHIFT_DATA[game_id].duplicate()
	ShiftWindow.data["mode"] = "intro"
	ShiftWindow.data["prof"] = game_id
	ShiftWindow.choice = ""
	HUD.open_window("mg_turno")
	while HUD.is_window_open():
		await get_tree().process_frame
	if ShiftWindow.choice != "start":
		_leave()
		return
	await _countdown()
	time_left = duration
	running = true
	if room.player != null and not _carry_spr.is_inside_tree():
		room.player.add_child(_carry_spr)
	_on_start()


func _countdown() -> void:
	Game.input_locked = true
	for n in ["3", "2", "1", "Já!"]:
		_say(n, UI.C_GOLD, 0.8)
		Audio.sfx("ui_click" if n != "Já!" else "powerup", -4.0)
		await get_tree().create_timer(0.7).timeout
	Game.input_locked = false


func _process(delta: float) -> void:
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0:
			_lbl_msg.text = ""
	if not running:
		return
	if HUD.is_window_open() or HUD.is_dialogue_open():
		return
	time_left -= delta
	_tick(delta)
	_refresh_ui()
	if time_left <= 0.0:
		_end()


func _end() -> void:
	if _ending:
		return
	_ending = true
	running = false
	set_carry("")
	Audio.jingle("success", -4.0)
	var score := clampf(_score(), 0.0, 1.0)
	var r := GameState.minigame_reward(game_id, score)
	var prof := GameState.add_profession_xp(game_id, score)
	ShiftWindow.data = SHIFT_DATA[game_id].duplicate()
	ShiftWindow.data["mode"] = "result"
	ShiftWindow.data["score"] = score
	ShiftWindow.data["reward"] = r
	ShiftWindow.data["prof"] = game_id
	ShiftWindow.data["prof_gain"] = prof
	ShiftWindow.data["lines"] = _summary()
	ShiftWindow.choice = ""
	HUD.open_window("mg_turno")
	while HUD.is_window_open():
		await get_tree().process_frame
	if ShiftWindow.choice == "again":
		Game.enter_interior(room.id, "turno")
		return
	_leave()


## Jogador saiu pela porta no meio do turno.
func request_exit() -> void:
	if not running:
		_leave()
		return
	HUD.confirm("Largar o turno agora? O que você fez até aqui conta.", func() -> void: _end())


func _leave() -> void:
	running = false
	var back: Dictionary = _return
	current_id = ""
	match str(back.get("kind", "town")):
		"interior":
			if not str(back.get("interior", "")).begins_with("turno_"):
				Game.enter_interior(str(back["interior"]), str(back.get("from", "town")))
				return
		"city":
			Game.go_to_city(str(back.get("city", "porto")))
			return
	Game.go_to_town("start")


# ================================================================== Carregar
func set_carry(item: String, tex: Texture2D = null) -> void:
	carry = item
	_carry_spr.texture = tex
	_carry_spr.visible = item != "" and tex != null
	if item != "":
		Audio.sfx("ui_move", -8.0)


# ================================================================== Interface
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 45
	_ui.scale = Vector2(2, 2)
	add_child(_ui)
	_panel = UI.card(Color(0.1, 0.08, 0.07, 0.92), UI.C_ORANGE)
	_panel.position = Vector2(UI.SIZE.x / 2.0 - 120, 4)
	_panel.custom_minimum_size = Vector2(240, 30)
	_ui.add_child(_panel)
	var v := UI.vbox(0)
	_panel.add_child(v)
	var h := UI.hbox(10)
	v.add_child(h)
	var title := UI.label(str(SHIFT_DATA.get(game_id, {}).get("title", "Turno")), UI.C_ORANGE_L)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title)
	_lbl_time = UI.label("", UI.C_TEXT)
	h.add_child(_lbl_time)
	_lbl_pts = UI.label("", UI.C_GOLD)
	v.add_child(_lbl_pts)
	_lbl_msg = UI.label("", UI.C_TEXT, 2)
	_lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_msg.position = Vector2(0, 120)
	_lbl_msg.size = Vector2(UI.SIZE.x, 24)
	_ui.add_child(_lbl_msg)


func _refresh_ui() -> void:
	var s := int(ceil(maxf(time_left, 0.0)))
	_lbl_time.text = "%d:%02d" % [s / 60, s % 60]
	_lbl_time.add_theme_color_override("font_color", UI.C_BAD if s <= 10 else UI.C_TEXT)
	_lbl_pts.text = "%d pontos%s   %s" % [int(points), ("   combo x%d" % combo) if combo >= 2 else "", _status()]


func _say(text: String, col: Color = UI.C_TEXT, t: float = 1.6) -> void:
	_lbl_msg.text = text
	_lbl_msg.add_theme_color_override("font_color", col)
	_msg_t = t


func add_points(base: float) -> float:
	combo += 1
	var mult := 1.0 + 0.1 * float(mini(combo - 1, 5))
	var got := base * mult
	points += got
	return got


func break_combo() -> void:
	combo = 0


# ================================================================== Para as subclasses
func _build_room() -> void:
	pass


func _on_start() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _score() -> float:
	return 0.0


func _status() -> String:
	return ""


func _summary() -> Array:
	return []


# ================================================================== Estação
## Ponto de trabalho com [E]: texto pelo `label_fn`, ação pelo `use_fn`. Desenha uma barra de progresso e o item
## que está nele (ícone flutuando), com brilho quando pronto e fumaça quando queima.
class Station extends Interactable:
	var label_fn: Callable
	var use_fn: Callable
	var progress: float = -1.0      # 0..1 (negativo = sem barra)
	var bar_col: Color = Color(1.0, 0.8, 0.3)
	var item_tex: Texture2D = null
	var ready_glow: bool = false
	var smoking: bool = false
	var icon_y: float = -26.0
	var zone: Vector2 = Vector2(-1, -1)  # faixa boa na barra (início, fim), para fornalha/tina

	func _init(radius: float = 20.0) -> void:
		interact_range = radius

	func get_prompt() -> String:
		if not enabled:
			return ""
		var t := str(label_fn.call()) if label_fn.is_valid() else prompt_text
		return "[E] " + t if t != "" else ""

	func interact(_player: Node) -> void:
		if use_fn.is_valid():
			use_fn.call()

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		if item_tex != null:
			var bob := sin(t * 3.0) * 1.0
			var sz := item_tex.get_size()
			if ready_glow:
				draw_circle(Vector2(0, icon_y + bob), 11.0 + sin(t * 8.0) * 1.5, Color(1.0, 0.9, 0.4, 0.45))
			draw_circle(Vector2(0, icon_y + bob + 1), 9.0, Color(0, 0, 0, 0.35))
			draw_texture_rect(item_tex, Rect2(Vector2(-sz.x / 2.0, icon_y + bob - sz.y / 2.0), sz), false)
		if smoking:
			for i in 3:
				var k := fmod(t * 0.8 + i * 0.33, 1.0)
				draw_circle(Vector2(sin(t * 2.0 + i) * 4.0, icon_y - 8.0 - k * 16.0), 3.0 + k * 3.0, Color(0.25, 0.25, 0.25, 0.6 * (1.0 - k)))
		if progress >= 0.0:
			var r := Rect2(-12, icon_y + 12, 24, 4)
			draw_rect(r.grow(1.0), Color(0.08, 0.06, 0.05, 0.9))
			if zone.x >= 0.0:
				draw_rect(Rect2(r.position.x + r.size.x * zone.x, r.position.y, r.size.x * (zone.y - zone.x), r.size.y), Color(1.0, 0.55, 0.15, 0.55))
			draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(progress, 0.0, 1.0), r.size.y)), bar_col)
