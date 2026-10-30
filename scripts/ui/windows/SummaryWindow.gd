extends UIWindow

## Resumo da expedição, mostrado ao voltar para a cidade.


func _init() -> void:
	win_title = "Resumo da expedição"
	win_size = Vector2(380, 250)


func build() -> void:
	var r: Dictionary = Game.last_run_summary
	var v := UI.vbox(4)
	add_to_body(v, Vector2(0, 0))
	if r.get("died", false):
		v.add_child(UI.label("Você foi derrotado e voltou com metade da vida.", UI.C_BAD))
	else:
		v.add_child(UI.label("Expedição concluída!", UI.C_GOOD))
	v.add_child(UI.hline())
	var t := int(r.get("time", 0.0))
	var rows := [
		["Andares", "%d  >  %d" % [int(r.get("start_floor", 1)), int(r.get("deepest", 1))]],
		["Monstros derrotados", str(int(r.get("kills", 0)))],
		["Chefes", str(int(r.get("bosses", 0)))],
		["Baús abertos", str(int(r.get("chests", 0)))],
		["Ouro coletado", UI.fmt_int(int(r.get("gold", 0)))],
		["XP ganho", UI.fmt_int(int(r.get("xp", 0)))],
		["Tempo", "%d:%02d" % [t / 60, t % 60]],
	]
	for row in rows:
		var h := UI.hbox(0)
		var k := UI.label(row[0], UI.C_DIM)
		k.custom_minimum_size.x = 150
		h.add_child(k)
		h.add_child(UI.label(row[1], UI.C_TEXT))
		v.add_child(h)
	var items: Dictionary = r.get("items", {})
	if not items.is_empty():
		v.add_child(UI.hline())
		v.add_child(UI.label("Itens encontrados", UI.C_ORANGE_L))
		var flow := HFlowContainer.new()
		flow.custom_minimum_size.x = 350
		flow.add_theme_constant_override("h_separation", 3)
		flow.add_theme_constant_override("v_separation", 3)
		v.add_child(flow)
		for id in items:
			var s := UI.Slot.new(22)
			s.set_item(id, int(items[id]))
			s.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flow.add_child(s)
	v.add_child(UI.spacer(4))
	v.add_child(UI.button("Continuar", func() -> void: HUD.close_window(), 90))
