extends Node

## Prints de todos os interiores (visão geral com a câmera afastada), para conferir a organização das salas.
## Uso: --scenario=interiores_shot [-- --only=biblioteca,loja]
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
const IDS := ["casa", "casa_familia", "casa_pai", "biblioteca", "loja", "forja", "restaurante", "guilda", "laboratorio",
	"delegacia", "casa_npc_0", "casa_npc_1", "casa_npc_2", "casa_npc_3",
	"acad_reitoria", "acad_aula", "acad_secretaria", "acad_bibliotecario", "acad_refeitorio", "acad_alojamento",
	"acad_quarto", "acad_dormitorio", "acad_comum", "acad_lab"]


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	Story.give_pet("corvin")
	Story.give_pet("brisa")
	for k in Looks.SPEAKER_LOOK:
		Story.set_flag("intro_" + str(k))
	var only: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7).split(",")
	for id in IDS:
		if not only.is_empty() and not only.has(id):
			continue
		Game.enter_interior(id, "town")
		await dev.wait(2.4)
		HUD.close_window()
		var scene := get_tree().current_scene
		if scene.has_method("room_px"):
			var sz: Vector2 = scene.room_px()
			var cam := Camera2D.new()
			cam.position = sz / 2.0
			cam.zoom = Vector2.ONE * minf(1280.0 / sz.x, 720.0 / sz.y) * 0.95
			scene.add_child(cam)
			cam.make_current()
		await dev.wait(0.5)
		await dev.shot(OUT + "int_%s.png" % id)
	print("[int] ok")
