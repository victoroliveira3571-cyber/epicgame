class_name DungeonObjects
extends RefCounted

## Pequenas classes interativas da masmorra: escada, baú, santuário e tocha.


class Stairs extends Interactable:
	var kind: String = "down"      # down = próximo andar | up = sair para a cidade
	var style: int = 0
	var locked: bool = false
	var floor_n: int = 1
	var sprite: Sprite2D

	func _ready() -> void:
		super()
		sprite = Sprite2D.new()
		sprite.texture = Pix.tex("props/stairs_%s_%d.png" % [kind, style])
		sprite.position = Vector2(0, -8)
		sprite.z_index = -50
		add_child(sprite)
		interact_range = 14.0
		if kind == "down":
			Fx.make_light(self, Vector2(0, -6), Color(1.0, 0.85, 0.55), 0.5, 0.6)

	func get_prompt() -> String:
		if locked:
			return "Derrote o chefe para descer"
		if kind == "down":
			return "[E] Descer para o andar %d" % (floor_n + 1)
		return "[E] Voltar para a cidade"

	func can_interact(_player: Node) -> bool:
		return not locked

	func interact(_player: Node) -> void:
		Audio.sfx("jump", -2.0)
		if kind == "down":
			Game.descend()
		else:
			HUD.confirm("Sair da masmorra e voltar para a cidade?", func() -> void: Game.finish_run(false))


class Chest extends Interactable:
	var big: bool = false
	var opened: bool = false
	var floor_n: int = 1
	var sprite: Sprite2D
	var tex_closed: Texture2D
	var tex_open: Texture2D

	func _ready() -> void:
		super()
		var rel := "items/treasure/BigTreasureChest.png" if big else "items/treasure/LittleTreasureChest.png"
		var frame_w := 16
		tex_closed = Pix.atlas(rel, Rect2(0, 0, frame_w, Pix.tex(rel).get_height()))
		tex_open = Pix.atlas(rel, Rect2(frame_w, 0, frame_w, Pix.tex(rel).get_height()))
		sprite = Sprite2D.new()
		sprite.texture = tex_closed
		sprite.position = Vector2(0, -7)
		add_child(sprite)
		Fx.make_shadow(self, 12.0, 0.0)
		prompt_text = "Abrir baú"
		interact_range = 16.0
		if big:
			sprite.modulate = Color(0.8, 0.9, 1.2)

	func get_prompt() -> String:
		return "[E] Abrir baú" if not opened else ""

	func interact(player: Node) -> void:
		if opened:
			return
		opened = true
		enabled = false
		sprite.texture = tex_open
		Audio.sfx("chest")
		GameState.bump("chests")
		Game.run_add("chests")
		var world := get_parent()
		var lm := Data.floor_scale_reward(floor_n)
		Loot.spawn_gold(world, global_position, int(round(float(randi_range(14, 34)) * lm * (2.5 if big else 1.0))))
		var n_items := 2 if big else 1
		for i in n_items:
			var id := Loot.roll_equipment(floor_n, mini(5, (floor_n - 1) / 3)) if (big and i == 0) else Loot.roll_item(floor_n, true)
			if id != "":
				Pickup.spawn(world, global_position + Vector2(0, -2), "item", 1, id)
		if not big and randf() < 0.3:
			Pickup.spawn(world, global_position, "item", 1, Loot.roll_item(floor_n))
		Fx.burst(world, global_position + Vector2(0, -8), Color(1, 0.85, 0.4), 10, 50.0, 0.5, 2.0)
		Fx.fx(world, "spark", global_position + Vector2(0, -8), 1.0)


class Shrine extends Interactable:
	var used: bool = false
	var sprite: Sprite2D
	var light: PointLight2D

	func _ready() -> void:
		super()
		sprite = Sprite2D.new()
		sprite.texture = Pix.tex("props/h_estatua_pequena.png")
		sprite.position = Vector2(0, -sprite.texture.get_height() / 2.0)
		add_child(sprite)
		Fx.make_shadow(self, 16.0, 0.0)
		light = Fx.make_light(self, Vector2(0, -10), Color(0.5, 0.8, 1.0), 0.6, 0.9)
		interact_range = 18.0

	func get_prompt() -> String:
		return "[E] Rezar no santuário" if not used else ""

	func interact(_player: Node) -> void:
		if used:
			return
		used = true
		enabled = false
		var options := ["forca", "foco", "couraca", "regen", "sabedoria"]
		var pick: String = options[randi() % options.size()]
		GameState.add_buff(pick, 240.0)
		GameState.heal(int(GameState.get_max_hp() * 0.25))
		var b: Dictionary = Data.BUFFS[pick]
		Audio.sfx("magic2")
		Audio.sfx("heal", -4.0)
		var world := get_parent()
		Fx.fx(world, "aura", global_position + Vector2(0, -10), 1.8, 0.0, Color(0.6, 0.85, 1.0))
		Fx.ring(world, global_position + Vector2(0, -8), 40.0, Color(0.6, 0.85, 1.0), 0.5, 2.0)
		GameState.toast.emit("Bênção: %s (%s) por 4 min" % [b["name"], b["desc"]], Color("8fd4ff"))
		sprite.modulate = Color(0.6, 0.6, 0.7)
		light.energy = 0.2


class Torch extends Node2D:
	var light: PointLight2D
	var t: float = randf() * 6.0

	func _ready() -> void:
		var flame := AnimatedSprite2D.new()
		flame.sprite_frames = Pix.fx_frames("fx/Elemental_Flam_SpriteSheet.png", 40, 12.0, "flame")
		flame.sprite_frames.set_animation_loop("flame", true)
		flame.scale = Vector2(0.4, 0.4)
		flame.position = Vector2(0, -3)
		flame.speed_scale = randf_range(0.9, 1.2)
		add_child(flame)
		flame.play("flame")
		var bracket := ColorRect.new()
		bracket.color = Color("3a2a2a")
		bracket.size = Vector2(3, 5)
		bracket.position = Vector2(-1.5, 2)
		add_child(bracket)
		light = Fx.make_light(self, Vector2(0, 2), Color(1.0, 0.7, 0.35), 1.1, 1.0)

	func _process(delta: float) -> void:
		t += delta
		light.energy = 0.85 + sin(t * 9.0) * 0.08 + sin(t * 23.0) * 0.05
