class_name ObjectiveCompass
extends Control

## v2.9: Bússola da mãe. Seta de objetivo na borda da tela apontando para o ponto da missão principal
## (dourada), que substitui a orientação do Corvo, e a animação de "item recebido" (a bússola abre um mapa
## no meio da tela e voa para o canto). Missões secundárias entram em `extra_markers` quando tiverem ponto no mapa.

const MARGIN := 18.0
const GAIN_TIME := 3.4

var extra_markers: Array = []      # [{"pos": Vector2 (mundo), "color": Color, "label": String}]
var _gain_t: float = -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func play_gain() -> void:
	_gain_t = 0.0


func has_compass() -> bool:
	return Story.started() and (bool(Story.flag("bussola", false)) or Story.step() != "c1_casa")


func _process(delta: float) -> void:
	if _gain_t >= 0.0:
		_gain_t += delta
		if _gain_t > GAIN_TIME:
			_gain_t = -1.0
	queue_redraw()


func _draw() -> void:
	if _gain_t >= 0.0:
		_draw_gain()
	if not has_compass() or HUD.is_window_open() or HUD.is_dialogue_open():
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.is_in_group("town"):
		return
	var markers: Array = []
	var obj: Variant = Story.objective_world_pos(scene)
	if obj != null:
		markers.append({"pos": obj, "color": UI.C_GOLD, "label": "Missão"})
	markers.append_array(extra_markers)
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	for m in markers:
		_draw_marker(pl, m)


func _draw_marker(pl: Node2D, m: Dictionary) -> void:
	var xf := get_viewport().get_canvas_transform()
	# o mundo desenha na resolução da janela; o HUD, em UI.SIZE
	var sp: Vector2 = (xf * (m["pos"] as Vector2)) * (UI.SIZE / get_viewport().get_visible_rect().size)
	var rect := Rect2(Vector2.ZERO, UI.SIZE).grow(-MARGIN)
	var col: Color = m["color"]
	var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	var dist := int(pl.global_position.distance_to(m["pos"]) / 16.0)
	var f := Pix.font(1)
	if rect.has_point(sp):
		# no alvo à vista: seta que pula sobre ele
		var tip := sp + Vector2(0, -22.0 - 3.0 * beat)
		_arrow(tip, Vector2.DOWN, col, 7.0)
		return
	var center := UI.SIZE / 2.0
	var dir := (sp - center).normalized()
	var edge := center + dir * 1000.0
	# prende no retângulo: escala o vetor até tocar a borda
	var t := minf(absf((rect.size.x / 2.0) / maxf(absf(dir.x), 0.0001)), absf((rect.size.y / 2.0) / maxf(absf(dir.y), 0.0001)))
	edge = center + dir * t
	_arrow(edge, dir, Color(col, 0.75 + 0.25 * beat), 8.0)
	var txt := "%s %d" % [m["label"], dist]
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var tp := edge - dir * Vector2(16.0 + w / 2.0, 14.0) - Vector2(w / 2.0, -4.0)
	tp.x = clampf(tp.x, 2.0, UI.SIZE.x - w - 2.0)
	tp.y = clampf(tp.y, 14.0, UI.SIZE.y - 4.0)
	draw_string_outline(f, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.1, 0.06, 0.04))
	draw_string(f, tp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)


## Triângulo apontando para `dir` com a ponta em `tip`.
func _arrow(tip: Vector2, dir: Vector2, col: Color, size: float) -> void:
	var side := dir.orthogonal()
	var back := tip - dir * size * 1.6
	var pts := PackedVector2Array([tip, back + side * size, back - side * size])
	draw_colored_polygon(pts, col)
	var outline := PackedVector2Array([tip, back + side * size, back - side * size, tip])
	draw_polyline(outline, UI.C_LINE, 1.0)


func _draw_gain() -> void:
	var k := _gain_t / GAIN_TIME
	var center := UI.SIZE / 2.0
	var corner := Vector2(34, 82)
	var open := clampf(k / 0.35, 0.0, 1.0)                 # 0..0.35: o mapa se abre
	var fly := clampf((k - 0.65) / 0.35, 0.0, 1.0)         # 0.65..1: voa para o canto
	var e := fly * fly * (3.0 - 2.0 * fly)
	var pos := center.lerp(corner, e)
	var sc := lerpf(1.0, 0.32, e)
	var alpha := 1.0 - clampf((k - 0.9) / 0.1, 0.0, 1.0)
	# mapa de pergaminho que se desdobra (largura cresce de dentro para fora)
	var w := 150.0 * open * sc
	var h := 96.0 * sc
	if w > 2.0:
		var r := Rect2(pos + Vector2(-w / 2.0, -h / 2.0 + 34.0 * sc), Vector2(w, h))
		draw_rect(r, Color(0.86, 0.74, 0.5, 0.95 * alpha))
		draw_rect(r, Color(0.35, 0.22, 0.1, alpha), false, 2.0)
		for i in 4:
			var y := r.position.y + r.size.y * (0.2 + 0.2 * i)
			draw_line(Vector2(r.position.x + 8.0, y), Vector2(r.end.x - 8.0 - 20.0 * (i % 2), y), Color(0.5, 0.35, 0.2, 0.6 * alpha), 1.0)
		draw_circle(r.position + r.size * Vector2(0.7, 0.55), 3.0 * sc + 1.0, Color(0.8, 0.15, 0.1, alpha))
	_draw_compass(pos, 26.0 * sc, alpha)
	if k < 0.65:
		var f := Pix.font(1)
		var msg := "Bússola recebida!"
		var mw := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var tp := Vector2(center.x - mw / 2.0, center.y - 52.0)
		draw_string_outline(f, tp, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.1, 0.06, 0.04))
		draw_string(f, tp, msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_GOLD)


func _draw_compass(c: Vector2, r: float, alpha: float) -> void:
	draw_circle(c, r, Color(0.2, 0.14, 0.08, alpha))
	draw_arc(c, r, 0.0, TAU, 28, Color(0.95, 0.78, 0.35, alpha), 2.0)
	draw_circle(c, r * 0.82, Color(0.95, 0.9, 0.75, alpha))
	var spin := sin(Time.get_ticks_msec() * 0.004) * 0.5
	var dir := Vector2.UP.rotated(spin)
	var side := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([c + dir * r * 0.7, c + side * r * 0.16, c - side * r * 0.16]), Color(0.85, 0.2, 0.15, alpha))
	draw_colored_polygon(PackedVector2Array([c - dir * r * 0.7, c + side * r * 0.16, c - side * r * 0.16]), Color(0.25, 0.25, 0.3, alpha))
	draw_circle(c, r * 0.1, Color(0.95, 0.78, 0.35, alpha))
