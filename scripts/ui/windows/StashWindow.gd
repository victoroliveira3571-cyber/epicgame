extends UIWindow

## Baú da casa (v2.7): guarda itens fora da mochila. Esquerda: mochila; direita: baú.
## "1" move uma unidade, "Tudo" move a pilha inteira (a peça equipada não sai do herói).


func _init() -> void:
	win_title = "Baú da Casa"
	win_size = Vector2(540, 310)


func build() -> void:
	add_to_body(UI.label("Mochila", UI.C_ORANGE_L), Vector2(0, 0))
	add_to_body(UI.label("Baú", UI.C_ORANGE_L), Vector2(272, 0))
	_column(Vector2(0, 18), GameState.inventory, true)
	_column(Vector2(272, 18), GameState.stash, false)


func _column(pos: Vector2, source: Dictionary, to_chest: bool) -> void:
	var col := scroll_column(pos, Vector2(262, 252))
	var ids: Array = source.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return Data.item_name(a) < Data.item_name(b))
	var shown := 0
	for id in ids:
		var n := GameState.stashable_count(id) if to_chest else int(source[id])
		if n <= 0:
			continue
		shown += 1
		var it := Data.get_item(id)
		var card := list_row(Pix.tex(str(it.get("icon", ""))), Data.item_name(id), UI.C_TEXT, "x%d" % n, "", UI.C_DIM,
			"Tudo", func() -> void: _move(id, n, to_chest), false, 238)
		var one := UI.button("1", func() -> void: _move(id, 1, to_chest), 16)
		(card.get_child(0) as Control).add_child(one)
		(card.get_child(0) as Control).move_child(one, (card.get_child(0) as Control).get_child_count() - 2)
		col.add_child(card)
	if shown == 0:
		col.add_child(UI.label("(vazio)", UI.C_DIM))


func _move(id: String, n: int, to_chest: bool) -> void:
	var ok := GameState.stash_put(id, n) if to_chest else GameState.stash_take(id, n)
	if ok:
		Audio.sfx2("gaveta", -10.0)
	else:
		Audio.sfx("ui_error")
