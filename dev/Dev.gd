extends Node

## Ferramenta de desenvolvimento (inerte no jogo normal): só age se o jogo for
## aberto com argumentos de usuário, por exemplo:
##   Godot --path game -- --scenario=smoke_font --save=dev_save.json
## Cenários ficam em res://dev/scenarios/<nome>.gd e podem tirar prints,
## simular ações e imprimir resultados.

var scenario_name: String = ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			scenario_name = arg.substr(11)
	if scenario_name == "":
		return
	await get_tree().process_frame
	# o menu inicial pula direto para a cidade nos testes: espera a troca de cena terminar
	for i in 120:
		var cs := get_tree().current_scene
		if cs != null and cs.name != "Title":
			break
		await get_tree().process_frame
	var path := "res://dev/scenarios/%s.gd" % scenario_name
	var script: Script = load(path)
	if script == null:
		printerr("[Dev] cenário não encontrado: ", path)
		get_tree().quit(1)
		return
	var runner: Node = script.new()
	add_child(runner)
	print("[Dev] rodando cenário: ", scenario_name)
	await runner.run(self)
	print("[Dev] fim do cenário")
	get_tree().quit()


func shot(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[Dev] print salvo: ", path, " ", img.get_size())


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
