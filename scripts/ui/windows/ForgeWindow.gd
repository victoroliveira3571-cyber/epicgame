extends UIWindow

## Ferreiro: aprimora equipamentos (até +5) com ouro e barras.

var selected: String = ""


func _init() -> void:
	win_title = "Ferreiro"
	win_size = Vector2(560, 310)


func build() -> void:
	add_to_body(UI.label("Escolha o equipamento", UI.C_DIM), Vector2(0, 0))
	var col := scroll_column(Vector2(0, 16), Vector2(290, 256))
	var ids: Array = []
	for id in GameState.inventory:
		if Data.is_equipment(id):
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return GameState.is_equipped(a) and not GameState.is_equipped(b))
	for id in ids:
		var it: Dictionary = Data.get_item(id)
		var lvl := GameState.upgrade_level(id)
		var title: String = "%s%s" % [it["name"], " +%d" % lvl if lvl > 0 else ""]
		var row := list_row(Pix.item_icon(id), title, UI.item_color(id),
			"Equipado" if GameState.is_equipped(id) else Data.SLOT_NAMES.get(it["slot"], ""), "", UI.C_DIM,
			"Ver", func() -> void:
				selected = id
				rebuild(), false, 280)
		col.add_child(row)
	if ids.is_empty():
		col.add_child(UI.label("Você não tem equipamentos.", UI.C_DIM))
	# --- painel de aprimoramento
	var det := UI.card(UI.C_PANEL, UI.C_LINE)
	det.position = Vector2(300, 0)
	det.custom_minimum_size = Vector2(240, 272)
	det.size = det.custom_minimum_size
	body.add_child(det)
	var v := UI.vbox(4)
	det.add_child(v)
	v.add_child(UI.label("Ouro: %s" % UI.fmt_int(GameState.gold), UI.C_GOLD))
	if selected == "" or GameState.count_item(selected) <= 0:
		v.add_child(UI.wrap_label("O ferreiro aumenta em 12%% os atributos do item a cada nível (máx. +%d)." % Data.UPGRADE_MAX, UI.C_DIM, 220))
		return
	var it2: Dictionary = Data.get_item(selected)
	var lvl2 := GameState.upgrade_level(selected)
	var head := UI.hbox(5)
	v.add_child(head)
	head.add_child(UI.icon(Pix.item_icon(selected), 24))
	head.add_child(UI.wrap_label("%s +%d" % [it2["name"], lvl2], UI.item_color(selected), 180))
	v.add_child(UI.hline())
	var cost := GameState.upgrade_cost(selected)
	if cost.is_empty():
		v.add_child(UI.label("Nível máximo!", UI.C_GOOD))
		return
	var mult := Data.UPGRADE_STAT_BONUS
	for pair in [["atk", "Ataque"], ["def", "Defesa"], ["hp", "Vida"], ["speed", "Velocidade"], ["crit", "Crítico %"], ["luck", "Sorte %"]]:
		var base := float(it2.get(pair[0], 0.0))
		if base > 0.0:
			var now := base * (1.0 + mult * lvl2)
			var nxt := base * (1.0 + mult * (lvl2 + 1))
			v.add_child(UI.label("%s: %s  >  %s" % [pair[1], _n(now), _n(nxt)], UI.C_TEXT))
	v.add_child(UI.hline())
	var mat: String = cost["material"]
	var have := GameState.count_item(mat)
	var need := int(cost["qty"])
	var mh := UI.hbox(4)
	v.add_child(mh)
	mh.add_child(UI.icon(Pix.item_icon(mat), 16))
	mh.add_child(UI.label("%s: %d / %d" % [Data.item_name(mat), have, need], UI.C_GOOD if have >= need else UI.C_BAD))
	v.add_child(UI.label("Ouro: %s" % UI.fmt_int(int(cost["gold"])), UI.C_GOOD if GameState.gold >= int(cost["gold"]) else UI.C_BAD))
	var up := UI.button("Aprimorar", func() -> void:
		if GameState.upgrade_item(selected):
			Audio.sfx("powerup")
			Audio.sfx("hit3", -4.0)
		else:
			Audio.sfx("ui_error"), 80)
	up.disabled = not GameState.can_upgrade(selected)
	v.add_child(up)
	v.add_child(UI.wrap_label("Barras de metal caem de monstros e baús, ou são vendidas por aventureiros.", UI.C_DIM, 220))


func _n(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")
