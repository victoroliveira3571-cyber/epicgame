extends Node

## v3.7: Academia como castelo. Pátio com muralha e jardim; portão do castelo -> corredores com portas; Reitoria
## (matrícula com a Reitora), Sala de Aula (Mestre Lin), volta para a porta certa e saída para o pátio.
## Anda pelo corredor central de verdade (move_up) e confere a seta de objetivo. Prints em _shots/v37_cam_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node
var _auto := true


func check(cond: bool, what: String) -> void:
	if cond:
		print("[cam] ok    ", what)
	else:
		fails += 1
		printerr("[cam] FALHA ", what)


func run(d: Node) -> void:
	dev = d
	_autoplay()
	GameState.debug_reset()
	Story.start_new_game("Teo", "Rui", "Miriam", "m")
	GameState.choose_class("arqueiro")
	Story.set_flag("saiu_casa")
	Story.set_flag("bussola")
	Story.set_step("a_matricula")
	Game.go_to_city("academia")
	await dev.wait(4.0)
	var c := get_tree().current_scene
	check(c.get("city_id") == "academia", "pátio da Academia")
	check(c.buildings.has("castelo") and c.door_spawns.has("castelo"), "castelo com portão de entrada")
	var arrow: Variant = Story.objective_world_pos(c)
	check(arrow != null and (arrow as Vector2).distance_to(c.door_spawns["castelo"]) < 4.0, "seta no pátio aponta para o portão do castelo")
	await dev.shot(OUT + "v37_cam_patio.png")
	# anda até o portão do castelo
	var pl: Node2D = c.player
	pl.global_position = c.door_spawns["castelo"] + Vector2(0, 40)
	await dev.wait(0.3)
	Input.action_press("move_up")
	await dev.wait(0.8)
	Input.action_release("move_up")
	check(pl.global_position.y < c.door_spawns["castelo"].y + 6, "chega no portão (castelo não bloqueia a frente)")
	Game.go_to_castle("start")
	await dev.wait(3.0)
	var k := get_tree().current_scene
	check(k.is_in_group("castle"), "entrou no castelo")
	check(k.DOORS.size() >= 10, "castelo com %d portas" % k.DOORS.size())
	await dev.shot(OUT + "v37_cam_saguao.png")
	var arrow2: Variant = Story.objective_world_pos(k)
	check(arrow2 != null and (arrow2 as Vector2).distance_to(k.door_spawns["acad_reitoria"]) < 4.0, "seta dentro do castelo aponta para a Reitoria")
	# anda pelo corredor central até a Reitoria
	var p2: Node2D = k.player
	Input.action_press("move_up")
	await dev.wait(5.5)
	Input.action_release("move_up")
	await dev.wait(0.2)
	check(p2.global_position.y < 8 * 16, "andou pelo corredor central até o fundo (y=%d)" % int(p2.global_position.y))
	await dev.shot(OUT + "v37_cam_corredor.png")
	# Reitoria: matrícula
	Game.enter_interior("acad_reitoria", "castle")
	await dev.wait(2.5)
	var r := get_tree().current_scene
	var reitora_ok := false
	for n in r.get_tree().get_nodes_in_group("speaker_reitora"):
		reitora_ok = true
	check(reitora_ok, "Reitora Aurora na Reitoria")
	await dev.shot(OUT + "v37_cam_reitoria.png")
	await Story.talk("reitora")
	await dev.wait(1.0)
	check(Story.step() == "a_aula", "matrícula feita (passo %s)" % Story.step())
	Game.leave_interior()
	await dev.wait(2.5)
	var k2 := get_tree().current_scene
	check(k2.is_in_group("castle") and k2.player.global_position.distance_to(k2.door_spawns["acad_reitoria"]) < 30.0, "voltou para a porta da Reitoria")
	var arrow3: Variant = Story.objective_world_pos(k2)
	check(arrow3 != null and (arrow3 as Vector2).distance_to(k2.door_spawns["acad_aula"]) < 4.0, "seta agora aponta para a Sala de Aula")
	# Sala de Aula: Mestre Lin
	Game.enter_interior("acad_aula", "castle")
	await dev.wait(2.5)
	var lin_ok := not get_tree().get_nodes_in_group("speaker_lin").is_empty()
	check(lin_ok, "Mestre Lin na Sala de Aula")
	await dev.shot(OUT + "v37_cam_aula.png")
	await Story.talk("lin_a")
	await dev.wait(1.0)
	check(Story.step() == "a_jardim", "primeira aula feita (passo %s)" % Story.step())
	Game.leave_interior()
	await dev.wait(2.5)
	var k3 := get_tree().current_scene
	var arrow4: Variant = Story.objective_world_pos(k3)
	check(arrow4 != null, "seta para o jardim aponta para a saída do castelo")
	# sai do castelo andando pelo saguão
	k3.player.global_position = Vector2(25 * 16, 32 * 16)
	Input.action_press("move_down")
	await dev.wait(1.5)
	Input.action_release("move_down")
	await dev.wait(3.0)
	var c2 := get_tree().current_scene
	check(c2.get("city_id") == "academia" and c2.player.global_position.distance_to(c2.door_spawns["castelo"]) < 30.0, "saiu do castelo na frente do portão")
	_auto = false
	print("[cam] falhas: ", fails)


func _autoplay() -> void:
	while true:
		await get_tree().create_timer(0.12, true, false, true).timeout
		if not _auto:
			continue
		var box: DialogueBox = HUD._dialog
		if box == null or not is_instance_valid(box):
			continue
		if box.choosing:
			var kids := box._choices.get_children()
			if not kids.is_empty():
				kids[0].emit_signal("pressed")
			continue
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_E
		ev2.pressed = false
		Input.parse_input_event(ev2)
