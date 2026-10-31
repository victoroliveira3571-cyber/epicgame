class_name Cutscene
extends Node2D

## Cenas curtas de lado (não é a visão de cima do mapa): barras de cinema, fundo desenhado por código,
## o herói e o outro personagem ampliados com as animações LPC. Usadas nos momentos pontuais:
##  "sit"  : o herói chega à mesa, senta e abre o livro para começar a estudar;
##  "toll" : o herói entrega o crédito ao guarda do pedágio (moeda no ar) e passa.
## Uso: await Cutscene.play("sit", {"place": "biblioteca"}).

const W := 640.0
const H := 360.0
const SCALE := 4.2

var kind: String = "sit"
var info: Dictionary = {}
var t: float = 0.0
var hero: LpcActor
var other: LpcActor
var bars: float = 0.0
var caption: String = ""
var caption_a: float = 0.0
var coin_t: float = -1.0
var book_open: float = 0.0
var candle: float = 0.0
var skip: bool = false


static func play(cut_kind: String, data: Dictionary = {}) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root.has_node("CutsceneLayer"):
		return
	var layer := CanvasLayer.new()
	layer.name = "CutsceneLayer"
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)
	var c := Cutscene.new()
	c.kind = cut_kind
	c.info = data
	layer.add_child(c)
	c.scale = Vector2(2.0, 2.0)          # HUD é 640x360 em tela 1280x720
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	await c.run()
	layer.queue_free()


func run() -> void:
	Game.input_locked = true
	hero = LpcActor.make(self, Looks.hero(), true)
	hero.scale = Vector2(SCALE, SCALE)
	var tw := create_tween()
	tw.tween_property(self, "bars", 1.0, 0.35)
	await tw.finished
	match kind:
		"toll":
			await _toll()
		_:
			await _sit()
	var tw2 := create_tween()
	tw2.tween_property(self, "bars", 0.0, 0.3)
	await tw2.finished
	Game.input_locked = false


func _process(delta: float) -> void:
	t += delta
	candle += delta
	queue_redraw()


func _say(text: String, secs: float) -> void:
	caption = text
	var tw := create_tween()
	tw.tween_property(self, "caption_a", 1.0, 0.25)
	tw.tween_interval(secs)
	tw.tween_property(self, "caption_a", 0.0, 0.25)
	await tw.finished


# ------------------------------------------------------------------ Sentar para estudar
func _sit() -> void:
	hero.position = Vector2(-60, 262)
	hero.play("walk_right")
	var tw := create_tween()
	tw.tween_property(hero, "position:x", 232.0, 1.5)
	await tw.finished
	hero.play("idle_right")
	await get_tree().create_timer(0.25).timeout
	hero.hold_last = true
	hero.play("sit_right", true)
	hero.position = Vector2(232, 292)
	Audio.sfx2("gaveta", -10.0, 0.0)
	await get_tree().create_timer(0.7).timeout
	var tb := create_tween()
	tb.tween_property(self, "book_open", 1.0, 0.6)
	Audio.sfx("ui_open", -6.0)
	await tb.finished
	await _say(str(info.get("line", "Respire fundo. Um bloco de cada vez.")), 1.4)


# ------------------------------------------------------------------ Pagar o pedágio
func _toll() -> void:
	other = LpcActor.make(self, Looks.of(str(info.get("guard", "osvaldo"))), true)
	other.scale = Vector2(SCALE, SCALE)
	other.position = Vector2(470, 262)
	other.play("idle_left")
	hero.position = Vector2(-60, 262)
	hero.play("walk_right")
	var tw := create_tween()
	tw.tween_property(hero, "position:x", 330.0, 1.3)
	await tw.finished
	hero.play("idle_right")
	await get_tree().create_timer(0.2).timeout
	hero.gesture()
	coin_t = 0.0
	Audio.sfx("coin_big", -4.0)
	var tc := create_tween()
	tc.tween_property(self, "coin_t", 1.0, 0.7)
	await tc.finished
	other.nod()
	other.play("emote_left", true)
	await _say(str(info.get("line", "-1 crédito de estudo. Pode passar.")), 1.0)
	other.play("idle_left")
	hero.play("walk_right")
	var tw2 := create_tween()
	tw2.tween_property(hero, "position:x", 700.0, 1.0)
	await tw2.finished


# ------------------------------------------------------------------ Desenho
func _setting() -> String:
	if info.has("setting"):
		return str(info["setting"])
	return "gate_forest" if kind == "toll" else "inn"


func _draw() -> void:
	StageArt.paint(self, _setting(), t)
	if kind == "toll":
		pass
	else:
		# mesa, cadeira, vela e livro por cima do fundo
		draw_rect(Rect2(300, 214, 190, 12), Color("8a5a30"))
		draw_rect(Rect2(300, 214, 190, 3), Color("b9814e"))
		draw_rect(Rect2(310, 226, 10, 80), Color("5a361f"))
		draw_rect(Rect2(470, 226, 10, 80), Color("5a361f"))
		draw_rect(Rect2(186, 270, 84, 9), Color("7a4a2a"))
		draw_rect(Rect2(186, 214, 9, 65), Color("5a361f"))
		draw_rect(Rect2(190, 279, 8, 40), Color("5a361f"))
		draw_rect(Rect2(258, 279, 8, 40), Color("5a361f"))
		draw_rect(Rect2(446, 150, 12, 64), Color("e8d7a6"))
		StageArt.glow(self, Vector2(452, 140), 70.0, Color(1.0, 0.78, 0.4, 0.8), 7)
		draw_circle(Vector2(452, 142), 6.0 + sin(candle * 13.0) * 1.2, Color("ffb03b"))
		draw_circle(Vector2(452, 142), 3.0, Color("fff1a8"))
		var bw := 38.0 + 30.0 * book_open
		draw_rect(Rect2(380 - bw / 2.0, 202, bw, 12), Color("c4453d") if book_open < 0.5 else Color("f1e5c6"))
		draw_rect(Rect2(380 - bw / 2.0, 202, bw, 12), Color("2a1810"), false, 2.0)
		if book_open > 0.5:
			draw_rect(Rect2(379, 202, 2, 12), Color("2a1810"))
	if coin_t >= 0.0 and coin_t < 1.0:
		var a := Vector2(380, 190)
		var b := Vector2(446, 190)
		var p := a.lerp(b, coin_t) + Vector2(0, -sin(coin_t * PI) * 38.0)
		draw_circle(p, 5.0, Color("ffd35a"))
		draw_circle(p, 5.0, Color("8a5a10"), false, 1.5)
	var bh := 30.0 * bars
	draw_rect(Rect2(0, 0, W, bh), Color.BLACK)
	draw_rect(Rect2(0, H - bh, W, bh), Color.BLACK)
	if caption != "" and caption_a > 0.0:
		var f := Pix.font(1)
		var w := f.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string_outline(f, Vector2((W - w) / 2.0, H - bh - 14), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, caption_a))
		draw_string(f, Vector2((W - w) / 2.0, H - bh - 14), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.95, 0.8, caption_a))
