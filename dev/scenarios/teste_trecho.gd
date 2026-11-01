extends Node

## Teste do pack CC0 do ansimuz: troca só o chão da Cidade (academia) por grama + trecho da vila.
## Prints em _shots/teste_trecho_jogo.png (sem HUD). Não mexe no save real (usar --save=dev_save.json).
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
const DIR := "res://assets/teste_cc0/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	Game.go_to_city("academia")
	await dev.wait(4.0)
	var sc := get_tree().current_scene
	var ground: Sprite2D = null
	for c in sc.get_children():
		if c is Sprite2D and c.z_index == -100:
			ground = c
			break
	if ground == null:
		printerr("[teste] chão da cidade não encontrado")
		return
	var old := ground.texture.get_image()
	var img := Image.create(old.get_width(), old.get_height(), false, Image.FORMAT_RGBA8)
	var grass := Image.load_from_file(DIR + "grass-tile.png")
	grass.convert(Image.FORMAT_RGBA8)
	for y in range(0, img.get_height(), grass.get_height()):
		for x in range(0, img.get_width(), grass.get_width()):
			img.blit_rect(grass, Rect2i(Vector2i.ZERO, grass.get_size()), Vector2i(x, y))
	var trecho := Image.load_from_file(DIR + "trecho.png")
	trecho.convert(Image.FORMAT_RGBA8)
	var pos := Vector2i(old.get_width() / 2, old.get_height() / 2) - trecho.get_size() / 2
	img.blit_rect(trecho, Rect2i(Vector2i.ZERO, trecho.get_size()), pos)
	ground.texture = ImageTexture.create_from_image(img)
	var pl := sc.get("player") as Node2D
	if pl != null:
		pl.global_position = ground.global_position + Vector2(pos) + Vector2(trecho.get_size()) / 2.0
	HUD.set("visible", false)
	await dev.wait(1.0)
	await dev.shot(OUT + "teste_trecho_jogo.png")
	HUD.set("visible", true)
