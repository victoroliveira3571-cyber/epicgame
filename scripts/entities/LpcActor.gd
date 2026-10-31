class_name LpcActor
extends Node2D

## Personagem LPC no mundo: uma textura montada pelo LpcW e o quadro da animação atual.
## Origem do nó = pés. Nomes de animação no estilo "walk_down", "idle_left", "slash_right".
## Animações sem repetição emitem `anim_finished` e voltam para `idle`.

signal anim_finished(anim: String)
signal ready_to_draw

var look: Dictionary = {}
var full: bool = false            # true = todas as animações (herói, oponentes); false = NPC
var animation: String = "idle_down"
var frame: int = 0
var speed_scale: float = 1.0
var hold_last: bool = false       # animação sem repetição fica no último quadro
var sprite: Sprite2D
var texture: Texture2D

var _base: String = "idle"
var _dir: String = "down"
var _t: float = 0.0
var _idle_breath: float = 0.0
var _want_key: String = ""


static func make(parent: Node, look_in: Dictionary, all_anims: bool = false) -> LpcActor:
	var a := LpcActor.new()
	a.look = look_in
	a.full = all_anims
	parent.add_child(a)
	return a


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.region_enabled = true
	sprite.visible = false
	add_child(sprite)
	var s := float(look.get("scale", 1.0)) * LpcW.WORLD_SCALE
	sprite.scale = Vector2(s, s)
	_idle_breath = randf() * 3.0
	refresh()


## Remonta a textura (depois de trocar roupa, equipamento ou aparência).
func refresh(new_look: Variant = null) -> void:
	if new_look != null:
		look = new_look
	var s := float(look.get("scale", 1.0)) * LpcW.WORLD_SCALE
	if sprite != null:
		sprite.scale = Vector2(s, s)
	var mode := "full" if full else "npc"
	var key := LpcW.look_key(look, mode)
	_want_key = key
	var tex := LpcW.cached(look, mode)
	if tex != null:
		_set_texture(tex)
	else:
		# só aplica a montagem do look atual: uma montagem antiga que termine depois não sobrescreve
		# (método ligado, não lambda: o Godot invalida a chamada se o ator sair da cena)
		LpcW.request(look, mode, _on_composed.bind(key))


func _on_composed(tex: Texture2D, key: String) -> void:
	if key == _want_key:
		_set_texture(tex)


func _set_texture(tex: Texture2D) -> void:
	if not is_instance_valid(self) or sprite == null:
		return
	texture = tex
	sprite.texture = tex
	sprite.visible = tex != null
	_apply_frame()
	ready_to_draw.emit()


func play(name: String, restart: bool = false) -> void:
	var base := name.get_slice("_", 0)
	var dir := name.get_slice("_", 1) if name.contains("_") else _dir
	if base == "attack":
		base = "slash"
	if not LpcW.ANIMS.has(base):
		base = "idle"
	if not full and base in ["slash", "thrust", "spellcast", "shoot"]:
		base = "emote"
	var new_name := base + "_" + dir
	if new_name == animation and not restart:
		return
	var changed_base := base != _base
	animation = new_name
	_base = base
	_dir = dir if LpcW.DIRS.has(dir) else "down"
	if changed_base or restart:
		_t = 0.0
		frame = 0
	_apply_frame()


func base_anim() -> String:
	return _base


func dir_name() -> String:
	return _dir


func anim_length(base: String) -> float:
	var a: Array = LpcW.ANIMS.get(base, LpcW.ANIMS["idle"])
	return float(a[2]) / maxf(float(a[5]), 0.01)


func _process(delta: float) -> void:
	if sprite == null or texture == null:
		return
	var a: Array = LpcW.ANIMS[_base]
	var n: int = a[2]
	var fps: float = a[5]
	if fps <= 0.0:
		return
	_t += delta * fps * speed_scale
	var f := int(_t)
	if _base == "walk":
		f = 1 + f % 8            # quadro 0 do andar é o parado
	elif a[6]:
		f = f % n
	elif f >= n:
		f = n - 1
		if not hold_last:
			var done := _base
			play("idle_" + _dir, true)
			anim_finished.emit(done)
			return
	if f != frame:
		frame = f
		_apply_frame()


func _apply_frame() -> void:
	if sprite == null or texture == null:
		return
	var a: Array = LpcW.ANIMS[_base]
	var cell: int = a[4]
	var row := 0 if int(a[3]) == 1 else int(LpcW.DIRS.get(_dir, 2))
	var col := clampi(frame, 0, int(a[2]) - 1)
	if _base == "sit":
		col = 2            # sentado numa cadeira/banco
	sprite.region_rect = Rect2(int(a[0]) + col * cell, int(a[1]) + row * cell, cell, cell)
	# pés do LPC ficam na linha ~62 da célula de 64 (centro da célula de 128 = célula de 64 no meio)
	var off := (cell - 64) / 2
	sprite.offset = Vector2(-32 - off, -61 - off)


## Quadro atual como textura solta (rastro do rolamento, retrato rápido).
func snapshot() -> AtlasTexture:
	if texture == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = texture
	at.region = sprite.region_rect
	return at


## Um gesto curto (mão no queixo/aceno do LPC "emote") e volta ao parado.
func gesture() -> void:
	play("emote_" + _dir, true)


## Pulinho (surpresa/alegria) e balanço (riso).
func hop(height: float = 3.0) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "position:y", -height, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func shake(amount: float = 1.0, time: float = 0.3) -> void:
	var tw := create_tween()
	var steps := int(time / 0.05)
	for i in steps:
		tw.tween_property(sprite, "position:x", amount * (1.0 if i % 2 == 0 else -1.0), 0.05)
	tw.tween_property(sprite, "position:x", 0.0, 0.05)


func nod() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "position:y", 1.0, 0.08)
	tw.tween_property(sprite, "position:y", 0.0, 0.1)
	tw.tween_property(sprite, "position:y", 1.0, 0.08)
	tw.tween_property(sprite, "position:y", 0.0, 0.1)
