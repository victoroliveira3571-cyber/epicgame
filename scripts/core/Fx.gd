class_name Fx
extends RefCounted

## Efeitos visuais reutilizáveis: sombras, textos flutuantes, brilhos, anéis,
## partículas simples e animações de FX (cortes, explosões...).

static var _shadow_tex: Texture2D = null
static var _glow_tex: Texture2D = null
static var _circle_tex: Texture2D = null


## Elipse escura suave usada sob personagens, monstros e objetos.
static func shadow_tex() -> Texture2D:
	if _shadow_tex == null:
		var img := Image.create(16, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in 8:
			for x in 16:
				var dx := (x + 0.5 - 8.0) / 8.0
				var dy := (y + 0.5 - 4.0) / 4.0
				var d := dx * dx + dy * dy
				if d < 1.0:
					img.set_pixel(x, y, Color(0, 0, 0, 0.32 if d < 0.6 else 0.2))
		_shadow_tex = ImageTexture.create_from_image(img)
	return _shadow_tex


static func make_shadow(parent: Node, width_px: float = 12.0, y_off: float = 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = shadow_tex()
	s.scale = Vector2(width_px / 16.0, width_px / 16.0)
	s.position = Vector2(0, y_off)
	s.z_index = -1
	s.z_as_relative = true
	s.show_behind_parent = true
	parent.add_child(s)
	return s


## Luz suave radial (para PointLight2D e brilhos).
static func glow_tex() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_glow_tex = t
	return _glow_tex


static func make_light(parent: Node, pos: Vector2, color: Color, scale: float, energy: float = 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = glow_tex()
	l.texture_scale = scale
	l.color = color
	l.energy = energy
	l.position = pos
	parent.add_child(l)
	return l


## Toca uma animação de FX uma única vez e some.
static func play_once(parent: Node, frames: SpriteFrames, anim: String, pos: Vector2, fx_scale: Vector2 = Vector2.ONE,
		rot: float = 0.0, tint: Color = Color.WHITE, z: int = 50) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = frames
	a.position = pos
	a.scale = fx_scale
	a.rotation = rot
	a.modulate = tint
	a.z_index = z
	parent.add_child(a)
	a.play(anim)
	a.animation_finished.connect(a.queue_free)
	return a


static func fx(parent: Node, name: String, pos: Vector2, fx_scale: float = 1.0, rot: float = 0.0, tint: Color = Color.WHITE) -> AnimatedSprite2D:
	var spec: Array = FX_TABLE.get(name, [])
	if spec.is_empty():
		return null
	var frames := Pix.fx_frames("fx/" + spec[0], int(spec[1]), float(spec[2]))
	return play_once(parent, frames, "fx", pos, Vector2(fx_scale, fx_scale), rot, tint)


# nome -> [arquivo, largura do quadro, fps]
const FX_TABLE := {
	"slash": ["Attack_SlashCurved_SpriteSheet.png", 32, 22.0],
	"slash2": ["Attack_SlashDoubleCurved_SpriteSheet.png", 32, 22.0],
	"cut": ["Attack_Cut_SpriteSheet.png", 32, 22.0],
	"cutx": ["Attack_CutX_SpriteSheet.png", 32, 22.0],
	"claw": ["Attack_Claw_SpriteSheet.png", 32, 22.0],
	"circular": ["Attack_CircularSlash_SpriteSheet.png", 32, 20.0],
	"explosion": ["Elemental_Explosion_SpriteSheet.png", 40, 18.0],
	"flame": ["Elemental_Flam_SpriteSheet.png", 40, 14.0],
	"thunder": ["Elemental_Thunder_SpriteSheet.png", 32, 16.0],
	"smoke": ["Smoke_Smoke_SpriteSheet.png", 32, 14.0],
	"circle": ["Magic_Circle_SpriteSheetWhite.png", 32, 16.0],
	"circle_o": ["Magic_Circle_SpriteSheetOrange.png", 32, 16.0],
	"spark": ["Magic_Spark_SpriteSheet.png", 30, 18.0],
	"boost": ["Magic_Boost_SpriteSheet.png", 53, 14.0],
	"aura": ["Magic_Aura_SpriteSheet.png", 25, 12.0],
	"shield": ["Magic_Shield_SpriteSheetBlue.png", 24, 12.0],
	"rock": ["Elemental_RockSpike_SpriteSheet.png", 45, 18.0],
}


## Texto que sobe e some, em coordenadas de mundo (parent = nó do mundo).
static func float_text(parent: Node, text: String, pos: Vector2, color: Color, size: int = 1, rise: float = 14.0, life: float = 0.7) -> Label:
	var l := Label.new()
	l.text = text
	var level := 1 if size > 3 else size
	l.add_theme_font_override("font", Pix.font(level))
	l.add_theme_font_size_override("font_size", Pix.font_px(level))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1, 1))
	l.add_theme_constant_override("outline_size", 2)
	l.z_index = 200
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos + Vector2(-float(text.length()) * 3.0, -6.0)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - rise, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, life * 0.5).set_delay(life * 0.5)
	tw.chain().tween_callback(l.queue_free)
	return l


## Pisca o sprite com uma cor (acerto).
static func flash(item: CanvasItem, color: Color = Color(2.2, 2.2, 2.2), time: float = 0.09) -> void:
	if item == null or not is_instance_valid(item):
		return
	item.modulate = color
	var tw := item.create_tween()
	tw.tween_property(item, "modulate", Color.WHITE, time)


static func shake_camera(camera: Camera2D, strength: float = 2.0, duration: float = 0.2) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var tw := camera.create_tween()
	var steps := 6
	for i in steps:
		var f := 1.0 - float(i) / steps
		tw.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * f, duration / steps)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.03)


## Faíscas pequenas saindo de um ponto.
static func burst(parent: Node, pos: Vector2, color: Color, count: int = 6, speed: float = 40.0, life: float = 0.35, size: float = 1.5) -> void:
	for i in count:
		var p := ColorRect.new()
		p.color = color
		p.size = Vector2(size, size)
		p.position = pos
		p.z_index = 150
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(p)
		var a := randf() * TAU
		var d := Vector2(cos(a), sin(a)) * randf_range(speed * 0.4, speed)
		var tw := p.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", pos + d * life, life).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, life)
		tw.chain().tween_callback(p.queue_free)


## Anel que se expande (ondas de choque, curas).
static func ring(parent: Node, pos: Vector2, radius: float, color: Color, life: float = 0.35, width: float = 1.5) -> void:
	var r := Node2D.new()
	r.position = pos
	r.z_index = 40
	r.set_script(RING_SCRIPT)
	r.set("color", color)
	r.set("width", width)
	parent.add_child(r)
	var tw := r.create_tween()
	tw.set_parallel(true)
	tw.tween_property(r, "radius", radius, life).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, life)
	tw.chain().tween_callback(r.queue_free)


const RING_SCRIPT := preload("res://scripts/core/FxRing.gd")
