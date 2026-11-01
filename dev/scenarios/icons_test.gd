extends Node

## v3.5: ícones de amuleto por tier e das barras novas.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(c: bool, what: String) -> void:
	if not c:
		print("[icones] FALHA ", what)
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	for id in ["amuleto_madeira", "amuleto_cobre", "amuleto_prata", "amuleto_ouro", "amuleto_runico", "amuleto_draconico", "amuleto_adamantium", "amuleto_supremo", "barra_obsidiana", "barra_adamantium", "barra_mithril"]:
		var t := Pix.item_icon(id)
		check(t != null and t.get_width() >= 16, "ícone de %s" % id)
		GameState.add_item(id, 3, true)
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	HUD.open_window("inventario")
	await dev.wait(0.8)
	await dev.shot(OUT + "icones_k.png")
	print("[icones] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
