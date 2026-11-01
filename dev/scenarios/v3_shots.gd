extends Node

## Corpos, armas por item, loja com provador, interiores novos e duelo na Arena.
## Prints em _shots/v3_*.png. Rodar: tools/run_godot.sh 200 --resolution 1280x720 -- --scenario=v3_shots --save=dev_save.json
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var dev: Node


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	await dev.wait(0.3)
	Story.start_new_game("Ana", "Rui", "Lia", "m")
	GameState.set_appearance(LpcW.default_look("muscular"))
	GameState.choose_class("cavaleiro")
	GameState.level = 40
	GameState.gold = 99999
	# galeria: corpos e armas de cada item
	var looks: Array = [LpcW.default_look("muscular"), LpcW.default_look("male"), LpcW.default_look("female")]
	for wid in Looks.WEAPON_VISUALS:
		var lk := LpcW.default_look(["muscular", "female"][looks.size() % 2])
		var v: Array = Looks.WEAPON_VISUALS[wid]
		lk["weapon"] = v[0]
		lk["weapon_pal"] = v[1]
		lk["gear"] = {"armor": looks.size() % 6, "helmet": (looks.size() + 2) % 6, "shield": looks.size() % 6 if v[0] in ["arming", "saber", "longsword", "mace", "waraxe"] else -1, "boots": looks.size() % 6}
		looks.append(lk)
	var texs: Array = []
	for lk in looks:
		texs.append(null)
	for i in looks.size():
		var idx := i
		LpcW.request(looks[i], "full", func(t: Texture2D) -> void: texs[idx] = t)
	await dev.wait(1.5)
	var img := Image.create(64 * 9, 128 * ((looks.size() + 8) / 9), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.33, 0.3))
	for i in looks.size():
		if texs[i] == null:
			continue
		var at: Image = texs[i].get_image()
		var x := (i % 9) * 64
		var y := (i / 9) * 128
		img.blend_rect(at, Rect2i(576, 128, 64, 64), Vector2i(x, y))
		var base := LpcW.weapon_anim(str(looks[i].get("weapon", "")))
		var a: Array = LpcW.ANIMS[base]
		var cell: int = a[4]
		var src := Rect2i(int(a[0]) + 3 * cell + (cell - 64) / 2, int(a[1]) + 3 * cell + (cell - 64) / 2, 64, 64)
		img.blend_rect(at, src, Vector2i(x, y + 64))
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(OUT + "v3_galeria.png")
	# loja com provador
	Game.enter_interior("loja")
	await dev.wait(2.0)
	await _skip()
	await dev.shot(OUT + "v3_loja.png")
	HUD.open_window("loja")
	await dev.wait(0.5)
	var w := HUD.window
	w._try_on("couraca_runica")
	await dev.wait(0.6)
	await dev.shot(OUT + "v3_provador.png")
	HUD.close_window()
	for room in ["forja", "casa_npc_0", "biblioteca", "restaurante", "casa_npc_3"]:
		Game.enter_interior(room)
		await dev.wait(2.2)
		await dev.shot(OUT + "v3_%s.png" % room)
		await _skip()
	# arena
	Game.enter_interior("arena")
	await dev.wait(2.0)
	await _skip()
	await dev.shot(OUT + "v3_arena.png")
	HUD.open_window("arena")
	await dev.wait(0.8)
	await dev.shot(OUT + "v3_arena_janela.png")
	var opp: Dictionary = Arena.opponents()[1]
	HUD.close_window()
	get_tree().get_first_node_in_group("interior").start_duel(opp)
	await dev.wait(3.2)
	var p := get_tree().get_first_node_in_group("player") as Player
	for i in 20:
		var f := get_tree().get_first_node_in_group("enemy") as Node2D
		if f == null:
			break
		p.facing = (f.global_position - p.global_position).normalized()
		p.global_position = f.global_position - p.facing * 18.0
		Input.action_press("attack")
		await dev.wait(0.2)
		Input.action_release("attack")
		if i == 3:
			await dev.shot(OUT + "v3_duelo.png")
	await dev.wait(0.6)
	await dev.shot(OUT + "v3_duelo_fim.png")
	print("[v3] arena: ", GameState.arena)


func _skip() -> void:
	for i in 60:
		if not HUD.is_dialogue_open():
			return
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await dev.wait(0.06)
		var box: DialogueBox = HUD._dialog
		if box != null and box.choosing:
			box._choices.get_child(0).emit_signal("pressed")
		await dev.wait(0.04)
