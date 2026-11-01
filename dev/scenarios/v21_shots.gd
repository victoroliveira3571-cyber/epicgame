extends Node

## v2.1: prints da escolha de classe, diálogo (retrato x mundo), inventário (ícones e comparação),
## créditos de viagem, editor da casa e progressão de habilidades. Prints em _shots/v21_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var dev: Node


func run(d: Node) -> void:
	dev = d
	await dev.wait(1.5)
	GameState.debug_reset()
	Story.start_new_game("Ana", "Rui", "Lia", "m")
	Story.set_flag("saiu_casa")
	Story.st()["step"] = "c1_marta"
	await dev.wait(0.5)
	Game.go_to_town("start")
	await dev.wait(2.0)
	HUD.open_window("classe")
	await dev.wait(1.2)
	await dev.shot(OUT + "v21_1_classe.png")
	HUD.close_window()
	await _icons_sheet()
	await inventory_compare()
	await osvaldo_dialogue()
	await travel_costs()
	await skills_and_promotion()


## Folha com o ícone de cada equipamento ao lado do herói vestindo o item (devem ser iguais).
func _icons_sheet() -> void:
	GameState.choose_class("cavaleiro")
	await dev.wait(1.5)
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("1d1a18")
	bg.size = Vector2(1280, 720)
	layer.add_child(bg)
	var x := 10.0
	var y := 10.0
	for id in Data.ITEMS:
		var it: Dictionary = Data.ITEMS[id]
		if it["kind"] != "equip" or it["slot"] == "amulet":
			continue
		var tr := TextureRect.new()
		tr.texture = Pix.item_icon(id)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(48, 48)
		tr.position = Vector2(x, y)
		layer.add_child(tr)
		var l := Label.new()
		l.text = id
		l.add_theme_font_size_override("font_size", 9)
		l.position = Vector2(x, y + 48)
		layer.add_child(l)
		x += 84
		if x > 1200:
			x = 10
			y += 66
	await dev.wait(0.5)
	await dev.shot(OUT + "v21_2_icones.png")
	layer.queue_free()


func inventory_compare() -> void:
	for id in ["espada_aco", "capacete_ferro", "elmo_runico", "botas_couro", "couraca_mithril", "escudo_runico"]:
		GameState.add_item(id, 1, true)
	GameState.equip_item("capacete_ferro")
	GameState.upgrades["capacete_ferro"] = 2
	GameState.mark_dirty()
	HUD.open_window("inventario")
	await dev.wait(0.6)
	var w = HUD.window
	w.selected = "elmo_runico"
	w.compare_open = true
	w.rebuild()
	await dev.wait(0.5)
	await dev.shot(OUT + "v21_3_comparar.png")
	w.selected = "espada_aco"
	w.rebuild()
	await dev.wait(0.5)
	await dev.shot(OUT + "v21_3b_comparar.png")
	HUD.close_window()


## Osvaldo: o mesmo visual no mapa e no retrato do diálogo.
func osvaldo_dialogue() -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	p.global_position = Vector2(4 * 16 + 40, 26 * 16 + 4)
	p.camera.reset_smoothing()
	Story.st()["credits"] = 0
	await dev.wait(0.8)
	Story.talk("osvaldo")
	await dev.wait(1.4)
	await dev.shot(OUT + "v21_4_osvaldo.png")
	await _skip_dialogue()


func _skip_dialogue() -> void:
	var idle := 0.0
	while idle < 0.6:
		if HUD.is_dialogue_open():
			idle = 0.0
			var box: DialogueBox = HUD._dialog
			box.typing = false
			box._next()
		else:
			idle += 0.1
		await dev.wait(0.1)


## v2.2: toda entrada custa 1 crédito; 45 min de foco = 1 crédito; morrer tira 1 e o saldo pode ficar negativo.
func travel_costs() -> void:
	Story.st()["credits"] = 20
	Story.st()["entries"] = {}
	var costs: Array = []
	for i in 4:
		costs.append(Story.entry_cost("floresta", 1))
		Story.pay_entry("floresta", 1)
	if costs != [1, 1, 1, 1] or Story.credits() != 16:
		printerr("[v21] FALHA custo fixo da floresta: ", costs, " saldo ", Story.credits())
	Story.pay_entry("andar_5", Data.floor_toll(5))
	if Story.credits() != 15:
		printerr("[v21] FALHA andar 5 deveria custar 1: ", Story.credits())
	# morte: 1 -> 0 -> -1 -> -2; entrar exige saldo >= 1
	Story.st()["credits"] = 1
	Story.lose_credit_on_death()
	Story.lose_credit_on_death()
	Story.lose_credit_on_death()
	if Story.credits() != -2 or Game.can_enter_floor(1):
		printerr("[v21] FALHA saldo negativo após mortes: ", Story.credits())
	# 45 min de foco pagam: -2 +1 = -1 (ainda sem entrar), 90 min -> 0, mais 45 -> 1
	Story.st()["credit_min"] = 0
	Story.add_focus_minutes(45)
	if Story.credits() != -1:
		printerr("[v21] FALHA 45 min = 1 crédito: ", Story.credits())
	Story.add_focus_minutes(90)
	if Story.credits() != 1:
		printerr("[v21] FALHA dívida paga: ", Story.credits())
	Story.st()["credits"] = 4
	Story.st()["chapter"] = 4
	Story.st()["entries"] = {"andar_1": {"d": Time.get_date_string_from_system(), "n": 2}}
	HUD.open_window("dungeon")
	await dev.wait(0.6)
	await dev.shot(OUT + "v21_5_portao.png")
	HUD.close_window()


## Nível 55: R e X liberadas, maestria do Q, passivas; promoção 1 feita e prova 2 aberta.
func skills_and_promotion() -> void:
	GameState.level = 24
	GameState.xp = 0
	GameState.xp_to_next = 10
	GameState.add_xp(10, false)          # sobe para 25: abre a prova 1
	var tr := GameState.promotion_trial()
	print("[v21] prova aberta: ", tr)
	if int(tr.get("tier", 0)) != 1:
		printerr("[v21] FALHA: prova 1 deveria abrir no nível 25")
	var atk_before := GameState.get_attack_power()
	GameState.counters["monsters"] = int(GameState.counters.get("monsters", 0)) + 40
	Story.st()["focus_min"] = Story.focus_minutes() + 120
	if not GameState.promote():
		printerr("[v21] FALHA: deveria promover com as metas cumpridas")
	print("[v21] título: ", GameState.class_title(), " ataque ", atk_before, " -> ", GameState.get_attack_power())
	GameState.level = 54
	GameState.xp_to_next = 10
	GameState.add_xp(10, false)
	print("[v21] nível ", GameState.level, " R=", GameState.slot_skill("skill2"), " X=", GameState.slot_skill("skill3"),
		" maestria Q=", GameState.skill_mastered("skill"), " recarga Q=", GameState.skill_cooldown("skill"))
	if GameState.slot_skill("skill2") == "" or GameState.slot_skill("skill3") == "" or not GameState.skill_mastered("skill"):
		printerr("[v21] FALHA progressão de habilidades no nível 55")
	if int(GameState.promotion_trial().get("tier", 0)) != 2:
		printerr("[v21] FALHA: prova 2 deveria abrir no nível 50")
	GameState.counters["monsters"] = int(GameState.counters.get("monsters", 0)) + 30
	await dev.wait(0.5)
	# usa as habilidades novas (sem inimigos: só confere que não quebra)
	var p := get_tree().get_first_node_in_group("player") as Player
	for cls in Data.CLASSES:
		GameState.player_class = cls
		GameState.mark_dirty()
		for slot in ["skill2", "skill3"]:
			p.slot_cd_left[slot] = 0.0
			p._cast_slot(slot)
			await dev.wait(0.5)
			p.state = Player.State.NORMAL
	GameState.player_class = "cavaleiro"
	GameState.mark_dirty()
	GameState.stats_changed.emit()
	await dev.wait(0.8)
	await dev.shot(OUT + "v21_6_hotbar.png")
	HUD.open_window("personagem")
	await dev.wait(0.3)
	HUD.window.mode = "habilidades"
	HUD.window.rebuild()
	await dev.wait(0.4)
	await dev.shot(OUT + "v21_7_habilidades.png")
	HUD.close_window()
	HUD.open_window("guilda")
	await dev.wait(0.3)
	HUD.window.tab = 2
	HUD.window.rebuild()
	await dev.wait(0.4)
	await dev.shot(OUT + "v21_8_promocao.png")
	HUD.close_window()
