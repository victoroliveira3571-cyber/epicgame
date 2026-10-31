class_name LpcPortrait
extends Control

## Retrato LPC (o mesmo rosto do personagem no mundo): recorte do quadro de frente, com
## expressão, piscar e balanço enquanto fala. Para quem não é humano, `fallback` (rosto antigo).

var look: Dictionary = {}
var expr: String = "neutral"
var crop: Rect2 = Rect2(14, 6, 36, 36)
var px_scale: float = 2.0
var talking: bool = false
var fallback: Texture2D = null
var fallback_tint: Color = Color.WHITE
var tint: Color = Color.WHITE

var _tex: Texture2D
var _blink: float = 0.0
var _next_blink: float = 2.5
var _t: float = 0.0
var _pop: float = 0.0
var _req: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_look(lk: Dictionary) -> void:
	fallback = null
	look = lk
	var key := LpcW.look_key(lk, "portrait")
	if key == _req and _tex != null:
		return
	_req = key
	_tex = LpcW.cached(lk, "portrait")
	if _tex == null:
		LpcW.request(lk, "portrait", func(t: Texture2D) -> void:
			if is_instance_valid(self) and key == _req:
				_tex = t
				queue_redraw())
	queue_redraw()


func set_fallback(tex: Texture2D, color: Color = Color.WHITE) -> void:
	fallback = tex
	fallback_tint = color
	_req = ""
	_tex = null
	queue_redraw()


## Troca a expressão com um "pulo" pequeno do retrato.
func set_expr(e: String) -> void:
	if e == "" or e == expr:
		return
	expr = e
	_pop = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.13
		_next_blink = randf_range(2.2, 4.5)
	_blink = maxf(_blink - delta, 0.0)
	_pop = maxf(_pop - delta * 5.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var size_px := crop.size * px_scale
	var bob := 0.0
	if talking:
		bob = -absf(sin(_t * 9.0)) * 1.0
	else:
		bob = sin(_t * 1.8) * 0.5
	bob -= _pop * 2.0
	if fallback != null:
		draw_texture_rect(fallback, Rect2(Vector2(0, bob), size_px), false, fallback_tint)
		return
	if _tex == null:
		return
	var e := expr
	if _blink > 0.0 and e not in ["closed", "happy", "shock", "eyeroll"]:
		e = "closed"
	var idx := LpcW.PORTRAIT_EXPR.find(e)
	if idx < 0:
		idx = 0
	var src := Rect2(idx * LpcW.CELL + crop.position.x, crop.position.y, crop.size.x, crop.size.y)
	draw_texture_rect_region(_tex, Rect2(Vector2(0, roundf(bob)), size_px), src, tint)
