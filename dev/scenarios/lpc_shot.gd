extends Node

## Personagens LPC no mundo e nos diálogos: casa da família (diálogo com a mãe, páginas,
## narração), cidade com NPCs e o herói com armadura. Prints em _shots/lpc_*.png.
## Rodar: tools/run_godot.sh 120 --resolution 1280x720 -- --scenario=lpc_shot --save=dev_save.json

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var dev: Node


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	await dev.wait(0.3)
	Story.start_new_game("Ana", "Rui", "Lia", "f")
	HUD.close_window()
	Game.enter_interior("casa_familia")
	await dev.wait(1.6)
	await dev.shot(OUT + "lpc_01_narracao.png")
	for i in 2:
		await _advance()
	await dev.wait(0.5)
	await dev.shot(OUT + "lpc_02_mae.png")
	await _advance()
	await dev.wait(0.6)
	await dev.shot(OUT + "lpc_03_heroi.png")
	# pula até a última fala (a longa) e mostra a página 1
	for i in 30:
		if not HUD.is_dialogue_open():
			break
		var box: DialogueBox = HUD._dialog
		if box.index >= box.lines.size() - 1:
			break
		if box.choosing:
			box._choices.get_child(0).emit_signal("pressed")
			await dev.wait(0.1)
			continue
		await _advance()
	await dev.wait(3.0)
	await dev.shot(OUT + "lpc_04_longa_p1.png")
	await _advance()
	await dev.wait(3.0)
	await dev.shot(OUT + "lpc_05_longa_p2.png")
	while HUD.is_dialogue_open():
		await _advance()
	await dev.wait(0.5)
	# cidade
	Game.go_to_town("start")
	await dev.wait(2.5)
	while HUD.is_dialogue_open():
		await _advance()
	await dev.wait(1.0)
	await dev.shot(OUT + "lpc_06_cidade.png")
	# herói com classe e armadura
	GameState.choose_class("cavaleiro")
	for id in Data.ITEMS:
		var it: Dictionary = Data.ITEMS[id]
		if it.get("kind", "") == "equip" and int(it.get("tier", 0)) == 4 and Data.class_can_use("cavaleiro", id):
			GameState.add_item(id, 1)
			GameState.equip_item(id)
	var p := get_tree().get_first_node_in_group("player") as Player
	p.refresh_sheet()
	await dev.wait(1.0)
	await dev.shot(OUT + "lpc_07_armadura.png")
	Input.action_press("attack")
	await dev.wait(0.12)
	await dev.shot(OUT + "lpc_08_golpe.png")
	Input.action_release("attack")
	await dev.wait(0.5)


func _advance() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_E
	ev.pressed = true
	Input.parse_input_event(ev)
	await dev.wait(0.08)
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_E
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await dev.wait(0.12)
