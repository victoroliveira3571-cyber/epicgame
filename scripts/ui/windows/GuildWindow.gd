extends UIWindow

## Guilda dos Aventureiros: missões permanentes, missões diárias e acesso à masmorra.

var tab: int = 0


func _init() -> void:
	win_title = "Guilda dos Aventureiros"
	win_size = Vector2(560, 310)


func build() -> void:
	tab_bar(["Diárias", "Missões"], tab, func(i: int) -> void:
		tab = i
		rebuild(), Vector2(0, 0), 80)
	var enter := UI.button("Portão da masmorra (créditos: %d)" % Story.credits(), func() -> void:
		HUD.open_window("dungeon"), 0)
	enter.position = Vector2(300, 0)
	body.add_child(enter)
	var col := scroll_column(Vector2(0, 22), Vector2(540, 252))
	if tab == 0:
		_daily(col)
	else:
		_missions(col)


func _reward_text(r: Dictionary) -> String:
	var parts: Array[String] = []
	if r.has("gold"):
		parts.append("%d ouro" % r["gold"])
	if r.has("xp"):
		parts.append("%d XP" % r["xp"])
	if r.has("item"):
		parts.append(Data.item_name(r["item"]))
	return ", ".join(parts)


func _daily(col: VBoxContainer) -> void:
	col.add_child(UI.label("Novas missões todo dia. Complete e resgate aqui.", UI.C_DIM))
	var quests: Array = GameState.daily.get("quests", [])
	for i in quests.size():
		var tpl := GameState.daily_template(quests[i]["id"])
		if tpl.is_empty():
			continue
		var prog := GameState.daily_progress(tpl)
		var goal := int(tpl["goal"])
		var done := prog >= goal
		var claimed: bool = quests[i]["claimed"]
		col.add_child(_row(tpl["title"], "%s  (%d/%d)" % [tpl["desc"], prog, goal], _reward_text(tpl["reward"]), done, claimed,
			func() -> void: _claim_daily(i)))


func _missions(col: VBoxContainer) -> void:
	var list: Array = []
	for m in Data.MISSIONS:
		list.append(m)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca := GameState.is_mission_claimed(a["id"])
		var cb := GameState.is_mission_claimed(b["id"])
		if ca != cb:
			return not ca
		var da := GameState.is_mission_complete(a["id"])
		var db := GameState.is_mission_complete(b["id"])
		if da != db:
			return da
		return false)
	for m in list:
		var claimed := GameState.is_mission_claimed(m["id"])
		var done := GameState.is_mission_complete(m["id"])
		col.add_child(_row(m["title"], "%s  (%d/%d)" % [m["desc"], GameState.mission_progress(m), m["goal"]],
			_reward_text(m["reward"]), done, claimed, func() -> void: _claim(m["id"])))


func _row(title: String, sub: String, reward: String, done: bool, claimed: bool, cb: Callable) -> Control:
	var color := UI.C_DIM if claimed else (UI.C_GOOD if done else UI.C_TEXT)
	var icon := Pix.skill_icon("items/Scroll") if not claimed else Pix.skill_icon("items/Ring")
	var btn := "Resgatar" if not claimed else "Feito"
	var row := list_row(icon, title, color, sub, reward, UI.C_GOLD, btn, cb, claimed or not done, 524)
	return row


func _claim(id: String) -> void:
	if GameState.claim_mission(id):
		Audio.jingle("success")


func _claim_daily(i: int) -> void:
	if GameState.claim_daily(i):
		Audio.jingle("success")
