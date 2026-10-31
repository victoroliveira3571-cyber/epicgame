extends UIWindow

## Inscrição na Arena: rank e prestígio, recorde e os 3 oponentes do momento (fácil, justo,
## difícil) com recompensa. "Lutar" fecha a janela e começa o duelo (Interior.start_duel).


func _init() -> void:
	win_title = "Arena de Combate  -  Duelos"
	win_size = Vector2(520, 270)


func build() -> void:
	var d := Arena.data()
	var top := UI.hbox(10)
	add_to_body(top, Vector2(4, 0))
	var rank := UI.label("Rank: " + Arena.rank_name(), Arena.rank_color())
	top.add_child(rank)
	top.add_child(UI.label("Prestígio: %d" % Arena.prestige(), UI.C_GOLD))
	var nxt := Arena.to_next()
	top.add_child(UI.label(("Próximo rank em %d" % nxt) if nxt > 0 else "Rank máximo!", UI.C_DIM))
	var rec := UI.label("Vitórias %d   Derrotas %d   Sequência %d (melhor %d)" % [int(d.get("wins", 0)), int(d.get("losses", 0)), int(d.get("streak", 0)), int(d.get("best", 0))], UI.C_DIM)
	add_to_body(rec, Vector2(4, 16))
	var line := UI.hline()
	line.position = Vector2(0, 34)
	line.size = Vector2(win_size.x - 20, 1)
	body.add_child(line)
	var row := UI.hbox(8)
	add_to_body(row, Vector2(2, 42))
	for o in Arena.opponents():
		row.add_child(_card(o))
	var hint := UI.wrap_label("Duelos não matam: quando sua vida acaba, a luta para e você volta curad%s. Vitória: ouro, XP e prestígio (sequências dão bônus). Derrota: perde um pouco de prestígio." % Story.fmt("{o}"), UI.C_DIM, 490)
	add_to_body(hint, Vector2(4, 196))


func _card(o: Dictionary) -> Control:
	var c := UI.card()
	c.custom_minimum_size = Vector2(160, 148)
	var v := UI.vbox(2)
	c.add_child(v)
	var diff: Array = Arena.DIFFS[int(o["diff"])]
	v.add_child(UI.label(str(diff[0]), diff[2]))
	var pv := AppearanceEditor.Preview.new()
	pv.custom_minimum_size = Vector2(150, 54)
	pv.px = 0.85
	v.add_child(pv)
	pv.set_look(o["look"])
	v.add_child(UI.label(str(o["name"]), UI.C_TEXT))
	v.add_child(UI.label("%s  -  vida %d" % [o["class_name"], int(o["hp"])], UI.C_DIM))
	v.add_child(UI.label("+%d ouro  +%d XP  +%d prest." % [int(o["gold"]), int(o["xp"]), int(o["prestige"])], UI.C_GOLD))
	v.add_child(UI.button("Lutar", func() -> void:
		HUD.close_window()
		var room := get_tree().get_first_node_in_group("interior")
		if room != null and room.has_method("start_duel"):
			room.start_duel(o), 140))
	return c


func refresh() -> void:
	pass
