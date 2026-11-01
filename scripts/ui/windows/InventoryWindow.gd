extends UIWindow

## Inventário e equipamento (I). Esquerda: equipamento; centro: mochila com filtros; direita: detalhes.

const FILTERS := [["Tudo", ""], ["Equip.", "equip"], ["Consumo", "use"], ["Material", "material"]]
const COLS := 9

var filter: String = ""
var selected: String = ""
var compare_open: bool = false     # painel flutuante de comparação (abre ao clicar num equipamento)
var _sel_slot: Control = null
var _compare: Control = null


func _init() -> void:
	win_title = "Inventário"
	win_size = Vector2(580, 310)


func build() -> void:
	_sel_slot = null
	# --- equipamento
	var eq := UI.vbox(3)
	add_to_body(eq, Vector2(0, 0))
	eq.add_child(UI.label("Equipado", UI.C_DIM))
	for slot in Data.EQUIP_SLOTS:
		var row := UI.hbox(4)
		eq.add_child(row)
		var s := UI.Slot.new(24)
		var id: String = GameState.equipped.get(slot, "")
		s.empty_icon = Pix.tex(Data.SLOT_ICONS.get(slot, ""))
		s.set_item(id, 1)
		s.selected = id != "" and id == selected
		s.pressed.connect(func() -> void:
			if id != "":
				selected = id
				rebuild())
		row.add_child(s)
		s.tooltip_text = Data.SLOT_NAMES.get(slot, slot)
	# --- prévia do herói com o que está equipado (v2.7); gira sozinho, arraste para virar
	var pv := AppearanceEditor.Preview.new(true)
	pv.custom_minimum_size = Vector2(86, 170)
	pv.size = Vector2(86, 170)
	pv.px = 1.4
	add_to_body(pv, Vector2(32, 18))
	pv.set_look(Looks.hero())
	# --- mochila
	var tabs := UI.hbox(2)
	add_to_body(tabs, Vector2(120, 0))
	for f in FILTERS:
		var b := UI.button(f[0], func() -> void:
			filter = f[1]
			rebuild(), 48)
		b.disabled = filter == f[1]
		tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(120, 20)
	scroll.size = Vector2(COLS * 27 + 8, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = COLS
	scroll.add_child(grid)
	var ids := _filtered_ids()
	var shown := maxi(ids.size(), 45)
	shown = int(ceil(shown / float(COLS))) * COLS
	for i in shown:
		var s2 := UI.Slot.new(24)
		if i < ids.size():
			var id2: String = ids[i]
			s2.set_item(id2, GameState.count_item(id2))
			s2.selected = id2 == selected
			s2.equipped = GameState.is_equipped(id2)
			s2.pressed.connect(func() -> void:
				compare_open = selected != id2 or not compare_open
				selected = id2
				rebuild())
			if id2 == selected:
				_sel_slot = s2
		grid.add_child(s2)
	# --- detalhes
	var det := UI.card(UI.C_PANEL, UI.C_LINE)
	det.position = Vector2(120 + COLS * 27 + 14, 0)
	det.custom_minimum_size = Vector2(176, 262)
	det.size = det.custom_minimum_size
	body.add_child(det)
	var dv := UI.vbox(4)
	det.add_child(dv)
	_build_details(dv)
	var gold := UI.label("Ouro: %s" % UI.fmt_int(GameState.gold), UI.C_GOLD)
	add_to_body(gold, Vector2(0, 250))
	_build_compare()


# ------------------------------------------------------------------ Comparação
## Equipamento clicado na mochila: painel flutuante ao lado do item, com os atributos lado a lado
## (item escolhido x o que está equipado no mesmo espaço) e a diferença de cada um.
func _build_compare() -> void:
	_compare = null
	if not compare_open or _sel_slot == null or not Data.is_equipment(selected) or GameState.is_equipped(selected):
		return
	var cur: String = GameState.equipped.get(Data.slot_of(selected), "")
	_compare = UIWindow.compare_card(selected, cur)
	_compare.z_index = 20
	var row := UI.hbox(4)
	(_compare.get_child(0) as Control).add_child(row)
	var sel := selected
	var eqb := UI.button("Equipar", func() -> void:
		compare_open = false
		GameState.equip_item(sel), 56)
	eqb.disabled = not Data.class_can_use(GameState.player_class, sel)
	row.add_child(eqb)
	row.add_child(UI.button("Fechar", func() -> void:
		compare_open = false
		rebuild(), 50))
	body.add_child(_compare)
	_place_compare.call_deferred()


func _place_compare() -> void:
	if _compare == null or not is_instance_valid(_compare) or not is_instance_valid(_sel_slot):
		return
	_compare.reset_size()
	var r := _sel_slot.get_global_rect()
	var origin := body.get_global_rect().position
	var sz := _compare.size
	var pos := Vector2(r.end.x + 4.0, r.position.y - 6.0) - origin
	if pos.x + sz.x > body.size.x:
		pos.x = r.position.x - origin.x - sz.x - 4.0
	pos.y = clampf(pos.y, -4.0, body.size.y - sz.y + 4.0)
	_compare.position = pos.round()


func _gui_input(ev: InputEvent) -> void:
	# clicar fora do painel fecha a comparação
	if compare_open and ev is InputEventMouseButton and ev.pressed:
		compare_open = false
		rebuild()


func _filtered_ids() -> Array:
	var out: Array = []
	for id in GameState.inventory:
		var it: Dictionary = Data.get_item(id)
		if it.is_empty():
			continue
		var kind: String = it["kind"]
		if filter == "equip" and kind != "equip":
			continue
		if filter == "use" and kind not in ["potion", "food", "tonic", "book"]:
			continue
		if filter == "material" and kind != "material":
			continue
		out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		var ia: Dictionary = Data.get_item(a)
		var ib: Dictionary = Data.get_item(b)
		if ia["kind"] != ib["kind"]:
			return str(ia["kind"]) < str(ib["kind"])
		if int(ia.get("tier", 0)) != int(ib.get("tier", 0)):
			return int(ia.get("tier", 0)) > int(ib.get("tier", 0))
		return str(ia["name"]) < str(ib["name"]))
	return out


func _build_details(dv: VBoxContainer) -> void:
	if selected == "" or Data.get_item(selected).is_empty() or (GameState.count_item(selected) <= 0):
		dv.add_child(UI.wrap_label("Escolha um item para ver os detalhes.", UI.C_DIM, 176))
		return
	var it: Dictionary = Data.get_item(selected)
	var lvl := GameState.upgrade_level(selected)
	var head := UI.hbox(5)
	dv.add_child(head)
	head.add_child(UI.icon(Pix.item_icon(selected), 24))
	var hv := UI.vbox(0)
	head.add_child(hv)
	hv.add_child(UI.wrap_label(it["name"] + (" +%d" % lvl if lvl > 0 else ""), UI.item_color(selected), 140))
	if it["kind"] == "equip":
		hv.add_child(UI.label("%s - %s" % [Data.SLOT_NAMES.get(it["slot"], ""), Data.RARITY_NAMES[int(it["rarity"])]], UI.C_DIM))
	else:
		hv.add_child(UI.label("x%d" % GameState.count_item(selected), UI.C_DIM))
	dv.add_child(UI.hline())
	if it["kind"] == "equip":
		var mult := 1.0 + Data.UPGRADE_STAT_BONUS * float(lvl)
		for pair in [["atk", "Ataque"], ["def", "Defesa"], ["hp", "Vida"], ["speed", "Velocidade"], ["crit", "Crítico %"], ["luck", "Sorte %"]]:
			var v := float(it.get(pair[0], 0.0))
			if v > 0.0:
				var line := "%s: +%s" % [pair[1], _num(v * mult)]
				var cur_id: String = GameState.equipped.get(it["slot"], "")
				if cur_id != "" and cur_id != selected:
					var cur: Dictionary = Data.get_item(cur_id)
					var cv := float(cur.get(pair[0], 0.0)) * (1.0 + Data.UPGRADE_STAT_BONUS * float(GameState.upgrade_level(cur_id)))
					var diff := v * mult - cv
					line += "  (%s%s)" % ["+" if diff >= 0 else "", _num(diff)]
					dv.add_child(UI.label(line, UI.C_GOOD if diff > 0 else UI.C_BAD if diff < 0 else UI.C_TEXT))
				else:
					dv.add_child(UI.label(line, UI.C_TEXT))
		if not Data.class_can_use(GameState.player_class, selected):
			dv.add_child(UI.wrap_label("Sua classe não pode usar este item.", UI.C_BAD, 176))
	else:
		dv.add_child(UI.wrap_label(str(it.get("desc", "")), UI.C_TEXT, 176))
	dv.add_child(UI.label("Vale %s de ouro" % UI.fmt_int(GameState.sell_price(selected)), UI.C_GOLD))
	var btns := UI.hbox(4)
	dv.add_child(btns)
	if it["kind"] == "equip":
		if GameState.is_equipped(selected):
			btns.add_child(UI.button("Tirar", func() -> void: GameState.unequip_slot(it["slot"]), 50))
		else:
			var eqb := UI.button("Equipar", func() -> void: GameState.equip_item(selected), 50)
			eqb.disabled = not Data.class_can_use(GameState.player_class, selected)
			btns.add_child(eqb)
	elif it["kind"] in ["potion", "food", "tonic", "book"]:
		btns.add_child(UI.button("Usar", func() -> void:
			if GameState.use_item(selected):
				Audio.sfx("heal", -4.0)
			else:
				Audio.sfx("ui_error"), 50))


func _num(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")
