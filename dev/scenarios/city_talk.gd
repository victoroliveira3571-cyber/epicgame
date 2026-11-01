extends Node

## v3.2: abre o diálogo do fragmento de Pedralta (com horas suficientes) e tira um print no meio.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	Story.st()["focus_min"] = 60 * 20
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	Game.go_to_city("pedralta")
	await dev.wait(4.0)
	var sc := get_tree().current_scene
	var npc := get_tree().get_nodes_in_group("speaker_granito")[0] as Node2D
	sc.player.global_position = npc.global_position + Vector2(0, 26)
	CityStory.talk("granito")
	for i in 40:
		await get_tree().create_timer(0.15).timeout
		if HUD.is_dialogue_open() and HUD._dialog.index >= 2 and not HUD._dialog.typing:
			break
		Input.parse_input_event(_e())
	await dev.shot(OUT + "city_dialogo.png")
	for i in 80:
		await get_tree().create_timer(0.1).timeout
		if not HUD.is_dialogue_open() and CityStory.fragments() >= 1:
			break
		Input.parse_input_event(_e())
	print("[talk] fragmentos ", CityStory.fragments())


func _e() -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = KEY_E
	ev.pressed = true
	return ev
