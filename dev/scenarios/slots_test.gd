extends Node

## Menu inicial e espaços de save, em arquivos de teste (user://slot_test_N.json, nunca os reais).
## Rodar: tools/run_godot.sh 120 --resolution 1280x720 -- --scenario=slots_test --save=dev_save.json
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(cond: bool, what: String) -> void:
	print("[slots] ", "ok    " if cond else "FALHA ", what)
	if not cond:
		fails += 1


func run(dev: Node) -> void:
	await dev.wait(0.5)
	# espaço 1 de teste: jogo novo e gravação
	GameState.slot = 1
	GameState.save_path = "user://slot_test_1.json"
	GameState.debug_reset()
	GameState.save_now()
	check(not FileAccess.file_exists("user://slot_test_1.json"), "espaço novo sem personagem não é gravado")
	Story.start_new_game("Ana", "Rui", "Lia", "f")
	GameState.gold = 777
	GameState.save_now()
	check(FileAccess.file_exists("user://slot_test_1.json"), "grava depois de criar o personagem")
	# troca de espaço e volta
	GameState.gold = 1
	GameState.save_path = "user://slot_test_1.json"
	GameState.debug_reset()
	GameState.load_game()
	check(GameState.gold == 777 and Story.hero_name() == "Ana", "carrega ouro e nome do espaço")
	# menu inicial
	GameState.slot = 0
	GameState.save_path = ""
	Game.go_to_title()
	await dev.wait(1.5)
	check(get_tree().current_scene.name == "Title", "menu inicial abriu")
	await dev.shot(OUT + "slots_1_menu.png")
	get_tree().current_scene._open_slots("carregar")
	await dev.wait(0.5)
	await dev.shot(OUT + "slots_2_carregar.png")
	get_tree().current_scene._close_slots()
	get_tree().current_scene._open_slots("novo")
	await dev.wait(0.3)
	await dev.shot(OUT + "slots_3_novo.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://slot_test_1.json"))
	print("[slots] RESULTADO: %d falhas" % fails)
