class_name Pickup
extends Node2D

## Moedas, itens e corações que caem dos monstros e dos baús. Saltam, ficam no chão
## brilhando e voam até o jogador quando ele chega perto.

var kind: String = "gold"      # gold | item | heart
var amount: int = 1
var item_id: String = ""
var vel: Vector2 = Vector2.ZERO
var height: float = 0.0
var vz: float = 0.0
var age: float = 0.0
var magnet: bool = false
var sprite: Node2D
var light: PointLight2D
var rarity: int = 0
var _bounces: int = 0

const MAGNET_RANGE := 52.0
const COLLECT_RANGE := 6.5


static func spawn(parent: Node, pos: Vector2, pickup_kind: String, value: int, id: String = "") -> Pickup:
	var p := Pickup.new()
	p.kind = pickup_kind
	p.amount = value
	p.item_id = id
	p.position = pos
	parent.add_child(p)
	return p


func _ready() -> void:
	z_index = 2
	var angle := randf() * TAU
	var speed := randf_range(30.0, 60.0)
	vel = Vector2(cos(angle), sin(angle)) * speed
	vz = randf_range(70.0, 110.0)
	Fx.make_shadow(self, 7.0, 0.0)
	match kind:
		"gold":
			var a := AnimatedSprite2D.new()
			a.sprite_frames = Pix.strip_frames("items/treasure/Coin2.png", 10, 4, 9.0, true, "spin")
			a.play("spin")
			a.frame = randi() % 4
			sprite = a
		"heart":
			var s := Sprite2D.new()
			s.texture = Pix.tex("items/potion/Heart.png")
			sprite = s
		_:
			var s2 := Sprite2D.new()
			s2.texture = Pix.item_icon(item_id)
			var it: Dictionary = Data.get_item(item_id)
			s2.modulate = it.get("tint", Color.WHITE) if it.get("kind", "") == "equip" else Color.WHITE
			rarity = int(it.get("rarity", 0))
			sprite = s2
	add_child(sprite)
	if kind == "item" and rarity >= 1:
		light = Fx.make_light(self, Vector2(0, -6), Data.RARITY_COLORS[rarity], 0.35 + 0.06 * rarity, 0.7)


func _physics_process(delta: float) -> void:
	age += delta
	if height > 0.0 or vz > 0.0:
		vz -= 280.0 * delta
		height += vz * delta
		position += vel * delta
		vel = vel.move_toward(Vector2.ZERO, 70.0 * delta)
		if height <= 0.0:
			height = 0.0
			if _bounces < 2:
				vz = -vz * 0.4
				_bounces += 1
			else:
				vz = 0.0
	sprite.position = Vector2(0, -6.0 - height)
	if kind != "gold" and height == 0.0:
		sprite.position.y += sin(age * 4.0) * 1.2
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.is_dead() or age < 0.45:
		return
	var d := global_position.distance_to(player.global_position)
	if d < MAGNET_RANGE:
		magnet = true
	if magnet:
		var dir := (player.global_position + Vector2(0, -2) - global_position).normalized()
		global_position += dir * (95.0 + (MAGNET_RANGE - minf(d, MAGNET_RANGE)) * 4.0) * delta
		if d < COLLECT_RANGE:
			_collect(player)


func _collect(player: Player) -> void:
	var world := get_parent()
	match kind:
		"gold":
			var gained := GameState.add_gold(amount, true)
			Game.run_add("gold", gained)
			Audio.sfx("coin_big" if amount >= 25 else "coin", -8.0, 0.12)
			Fx.float_text(world, "+%d" % gained, global_position + Vector2(0, -10), Color("ffd84a"))
		"heart":
			var heal_amount := maxi(8, int(GameState.get_max_hp() * 0.15))
			GameState.heal(heal_amount)
			Audio.sfx("heal", -8.0)
			Fx.float_text(world, "+%d" % heal_amount, global_position + Vector2(0, -10), Color("7ef08a"))
		_:
			GameState.add_item(item_id, amount)
			Game.run_add_item(item_id, amount)
			var it: Dictionary = Data.get_item(item_id)
			Audio.sfx("gold" if rarity < 3 else "powerup", -6.0)
			Fx.float_text(world, it.get("name", item_id), global_position + Vector2(0, -12), Data.RARITY_COLORS[rarity])
			Fx.burst(world, global_position + Vector2(0, -6), Data.RARITY_COLORS[rarity], 6, 36.0, 0.35)
	queue_free()
