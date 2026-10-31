extends Node

## Revisão visual: Arena na cidade, escolha de classe, janela de personagem, chefes humanos em LPC
## (Ivo, Cavaleiro, Bibliotecário), Ivo preso e casa do Lin. Prints em _shots/review_*.png.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var dev: Node


func run(d: Node) -> void:
	dev = d
	await dev.wait(1.5)   # o save de teste pode estar no prólogo: deixa a troca de cena terminar
	GameState.debug_reset()
	Story.start_new_game("Ana", "Rui", "Lia", "f")
	Story.set_flag("saiu_casa")
	Story.st()["step"] = "c1_marta"
	await dev.wait(0.5)
	Game.go_to_town("start")
	await dev.wait(2.0)
	var p := get_tree().get_first_node_in_group("player") as Player
	p.global_position = Vector2(44 * 16 + 8, 20 * 16)
	p.camera.reset_smoothing()
	await dev.wait(1.0)
	await dev.shot(OUT + "review_1_arena_fora.png")
	HUD.open_window("classe")
	await dev.wait(1.0)
	await dev.shot(OUT + "review_2_classe.png")
	HUD.close_window()
	GameState.choose_class("cavaleiro")
	p.refresh_sheet()
	HUD.open_window("personagem")
	await dev.wait(0.8)
	await dev.shot(OUT + "review_3_personagem.png")
	HUD.close_window()
	var world := p.get_parent()
	var x := 0
	for id in ["ivo_duelo", "cavaleiro_sem_nome", "bibliotecario"]:
		var b := Boss.spawn_boss(world, id, p.global_position + Vector2(-60 + x, -40), 3)
		b.set_physics_process(false)
		x += 60
	var trap := StoryProp.make_ivo_trap()
	trap.position = p.global_position + Vector2(0, 40)
	world.add_child(trap)
	await dev.wait(1.5)
	await dev.shot(OUT + "review_4_chefes.png")
	Game.enter_interior("casa_npc_2")
	await dev.wait(2.0)
	await dev.shot(OUT + "review_5_lin.png")
	Game.enter_interior("biblioteca")
	await dev.wait(2.0)
	for i in 40:
		if not HUD.is_dialogue_open():
			break
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await dev.wait(0.08)
	await dev.wait(0.5)
	await dev.shot(OUT + "review_6_biblioteca.png")
