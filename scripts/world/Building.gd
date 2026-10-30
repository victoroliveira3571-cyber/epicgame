class_name Building
extends Node2D

## Prédio da cidade: sprite, colisão, plaquinha com o nome, porta interativa e luz
## de janela à noite. Abre a janela correspondente (HUD.open_window) com [E].

var building_id: String = ""
var display_name: String = ""
var interior_id: String = ""      # se não vazio, a porta leva a este interior (senão abre a janela)
var prop_name: String = ""
var door_dx: float = 0.0
var return_scene: String = "town"   # cena para onde a porta do interior devolve ("town" | "forest")

var sprite: Sprite2D
var label: Label
var door: Interactable
var light: PointLight2D
var body: StaticBody2D
var size: Vector2 = Vector2.ZERO


class DoorTrigger extends Interactable:
	var building: Building

	func get_prompt() -> String:
		return "[E] " + building.display_name

	func interact(_player: Node) -> void:
		Audio.sfx("ui_open", -4.0)
		if building.interior_id != "":
			Game.enter_interior(building.interior_id, building.return_scene)
		else:
			HUD.open_window(building.building_id)


static func create(parent: Node, id: String, title: String, prop: String, pos: Vector2, door_offset: float, interior: String = "") -> Building:
	var b := Building.new()
	b.building_id = id
	b.display_name = title
	b.prop_name = prop
	b.position = pos
	b.door_dx = door_offset
	b.interior_id = interior
	parent.add_child(b)
	return b


func _ready() -> void:
	var tex := Pix.tex("props/%s.png" % prop_name)
	size = tex.get_size() if tex != null else Vector2(48, 48)
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-size.x / 2.0, -size.y)
	add_child(sprite)
	body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x - 4.0, size.y - 6.0)
	col.shape = rect
	col.position = Vector2(0, -size.y / 2.0 - 1.0)
	body.add_child(col)
	add_child(body)
	label = Label.new()
	label.add_theme_font_override("font", Pix.font(1))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("fff1c9"))
	label.add_theme_color_override("font_outline_color", Color("2a1810"))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(200, 14)
	label.position = Vector2(-100, -size.y - 15)
	label.z_index = 60
	add_child(label)
	door = DoorTrigger.new()
	(door as DoorTrigger).building = self
	door.position = Vector2(door_dx, 8)
	door.interact_range = 22.0
	add_child(door)
	light = Fx.make_light(self, Vector2(door_dx, -8), Color(1.0, 0.78, 0.45), 0.55, 0.0)
	label.text = display_name


func set_night(amount: float) -> void:
	light.energy = amount * 0.9
