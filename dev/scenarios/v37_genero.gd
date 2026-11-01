extends Node

## v3.7: tokens de gênero ({o}, {masc|fem}), patentes no feminino e as falas do capítulo 2 reescritas para a
## história v4 (Ivo e Lin já conhecem o herói da Academia).
var fails := 0


func check(cond: bool, what: String) -> void:
	if cond:
		print("[gen] ok    ", what)
	else:
		fails += 1
		printerr("[gen] FALHA ", what)


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.start_new_game("Ana", "Rui", "Lia", "f")
	Story.st()["gender"] = "f"
	check(Story.fmt("{Capitão|Capitã}, sua primeira cruzada") == "Capitã, sua primeira cruzada", "masc|fem no feminino")
	check(Story.fmt("Obrigad{o}. {o filho|a filha}") == "Obrigada. a filha", "{o} e frase inteira")
	check(StoryV4.patente_name(9) == "Marquesa" and StoryV4.patente_name(5) == "Capitã", "patentes femininas")
	Story.st()["gender"] = "m"
	check(Story.fmt("{Capitão|Capitã} | x") == "Capitão | x", "masc e barra solta preservada")
	check(StoryV4.patente_name(9) == "Marquês", "patente masculina")
	var ex := StoryV4.dialog("c2_exame")
	check(str(ex[1][1]).contains("colega da Academia"), "Ivo já conhece o herói (c2_exame)")
	var li := StoryV4.dialog("c2_lin")
	check(str(li[3][1]).contains("Estudei com"), "Lin revela que estudou com o pai (c2_lin)")
	check(str(li[li.size() - 1][1]).contains("ruínas"), "c2_lin mantém o fim (ruínas)")
	Story.st()["flags"].erase("v4")
	check(str(StoryV4.dialog("c2_exame")[1][1]).contains("Um rapaz"), "save antigo usa a fala original")
	print("[gen] falhas: ", fails)
