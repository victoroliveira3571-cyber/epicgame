extends UIWindow

## Quadro de resultado do duelo da Arena: ouro, XP e prestígio ganhos e barras mostrando quanto falta
## para o próximo rank e para o próximo nível (as barras andam do valor de antes para o de agora).

var _anim: Array = []   # [Bar, ratio_depois]


func _init() -> void:
	win_size = Vector2(430, 300)
	win_title = "Resultado do duelo"


func refresh() -> void:
	pass


func build() -> void:
	var r: Dictionary = Arena.last_result
	if r.is_empty():
		HUD.close_window()
		return
	var won: bool = r.get("won", false)
	var v := UI.vbox(4)
	add_to_body(v, Vector2(0, 0))
	v.add_child(UI.label(("VITÓRIA contra %s" if won else "DERROTA para %s") % r.get("opp", ""), UI.C_GOOD if won else UI.C_BAD, 2))
	v.add_child(UI.hline())
	if won:
		v.add_child(UI.label("Ouro:  +%d" % int(r.get("gold", 0)), UI.C_GOLD))
		v.add_child(UI.label("XP:  +%d" % int(r.get("xp", 0)), UI.C_XP))
		v.add_child(UI.label("Prestígio:  +%d   (sequência de %d vitória%s)" % [int(r.get("prestige", 0)), int(r.get("streak", 0)), "s" if int(r.get("streak", 0)) != 1 else ""], UI.C_ORANGE_L))
	else:
		v.add_child(UI.label("Prestígio:  %d" % int(r.get("prestige", 0)), UI.C_BAD))
		v.add_child(UI.label("Sem ouro nem XP desta vez. Treine e volte!", UI.C_DIM))
	v.add_child(UI.hline(Color(UI.C_ORANGE, 0.3)))
	# barra do rank
	var after: int = int(r.get("prestige_after", 0))
	var before: int = int(r.get("prestige_before", 0))
	var ri := Arena.rank_index(after)
	var ri_before := Arena.rank_index(before)
	var lower := int(Arena.RANKS[ri][1])
	var has_next := ri < Arena.RANKS.size() - 1
	var upper := int(Arena.RANKS[ri + 1][1]) if has_next else lower
	var ratio_after := 1.0 if not has_next else float(after - lower) / float(maxi(upper - lower, 1))
	var ratio_before := 0.0 if ri_before != ri else (1.0 if not has_next else float(before - lower) / float(maxi(upper - lower, 1)))
	v.add_child(UI.label("Rank %s" % Arena.RANKS[ri][0], Arena.RANKS[ri][2]))
	var bar := UI.Bar.new(Vector2(400, 12), Arena.RANKS[ri][2])
	bar.shown_ratio = clampf(ratio_before, 0.0, 1.0)
	v.add_child(bar)
	_anim.append([bar, ratio_after, ("%d / %d" % [after, upper]) if has_next else "%d (rank máximo)" % after])
	if bool(r.get("rank_up", false)):
		v.add_child(UI.label("NOVO RANK: %s!" % Arena.RANKS[ri][0], UI.C_GOLD))
	elif has_next:
		v.add_child(UI.label("Faltam %d de prestígio para %s" % [upper - after, Arena.RANKS[ri + 1][0]], UI.C_DIM))
	# barra de XP
	var lvl_before: int = int(r.get("level_before", GameState.level))
	var xr_before := float(int(r.get("xp_before", 0))) / float(maxi(int(r.get("xp_need_before", 1)), 1))
	var xr_after := float(GameState.xp) / float(maxi(GameState.xp_to_next, 1))
	if GameState.level != lvl_before:
		xr_before = 0.0
	v.add_child(UI.label("Nível %d" % GameState.level, UI.C_XP))
	var xbar := UI.Bar.new(Vector2(400, 12), UI.C_XP)
	xbar.shown_ratio = clampf(xr_before, 0.0, 1.0)
	v.add_child(xbar)
	_anim.append([xbar, xr_after, "%d / %d XP" % [GameState.xp, GameState.xp_to_next]])
	if GameState.level != lvl_before:
		v.add_child(UI.label("Subiu para o nível %d!" % GameState.level, UI.C_GOLD))
	else:
		v.add_child(UI.label("Faltam %d XP para o nível %d" % [GameState.xp_to_next - GameState.xp, GameState.level + 1], UI.C_DIM))
	v.add_child(UI.button("Continuar", func() -> void: HUD.close_window(), 110))
	call_deferred("_start_anim")


func _start_anim() -> void:
	await get_tree().create_timer(0.35).timeout
	for a in _anim:
		if is_instance_valid(a[0]):
			(a[0] as UI.Bar).set_ratio(float(a[1]), str(a[2]))
