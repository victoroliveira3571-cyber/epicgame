extends UIWindow

## Histórico dos Pomodoros concluídos, por dia, semana, mês e ano.

const TABS := ["Dias", "Semanas", "Meses", "Anos"]
const MONTHS := ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]

var tab: int = 0


class Chart extends Control:
	var bars: Array = []        # [{label, value, current}]
	var unit: String = "min"

	func _init(size_px: Vector2) -> void:
		custom_minimum_size = size_px
		size = size_px
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UI.C_PANEL)
		draw_rect(Rect2(Vector2.ZERO, size), UI.C_LINE, false, 1.0)
		if bars.is_empty():
			return
		var maxv := 1.0
		for b in bars:
			maxv = maxf(maxv, float(b["value"]))
		var n := bars.size()
		var slot := (size.x - 16.0) / float(n)
		var bw := minf(slot - 4.0, 30.0)
		var base := size.y - 16.0
		var f := Pix.font(1)
		for i in n:
			var b: Dictionary = bars[i]
			var x := 8.0 + slot * float(i) + (slot - bw) / 2.0
			var h := (base - 18.0) * float(b["value"]) / maxv
			var col := UI.C_ORANGE_L if b.get("current", false) else UI.C_ORANGE.darkened(0.15)
			if float(b["value"]) <= 0.0:
				draw_rect(Rect2(x, base - 2, bw, 2), Color(UI.C_DIM, 0.4))
			else:
				draw_rect(Rect2(x, base - h, bw, h), col)
				draw_rect(Rect2(x, base - h, bw, 2), col.lightened(0.3))
				var txt := str(int(b["value"]))
				var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				draw_string(f, Vector2(x + (bw - tw) / 2.0, base - h - 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_TEXT)
			var lbl: String = b["label"]
			var lw := f.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, Vector2(x + (bw - lw) / 2.0, size.y - 3.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_TEXT if b.get("current", false) else UI.C_DIM)


func _init() -> void:
	win_title = "Histórico de Pomodoros"
	win_size = Vector2(600, 330)


func build() -> void:
	tab_bar(TABS, tab, func(i: int) -> void:
		tab = i
		rebuild(), Vector2(0, 0), 64)
	add_to_body(UI.button("Voltar ao Pomodoro", func() -> void: HUD.open_window("pomodoro"), 0), Vector2(400, 0))
	var data := _aggregate()
	# resumo
	var total_min := 0
	for e in GameState.pomo_log:
		total_min += int(e.get("m", 0))
	var days := {}
	for e in GameState.pomo_log:
		days[e.get("d", "")] = true
	var summary := UI.hbox(14)
	add_to_body(summary, Vector2(0, 22))
	summary.add_child(UI.label(("Total: %d foco" if GameState.pomo_log.size() == 1 else "Total: %d focos") % GameState.pomo_log.size(), UI.C_GOLD))
	summary.add_child(UI.label("%s de foco" % _hm(total_min), UI.C_TEXT))
	summary.add_child(UI.label("%d dias com foco" % days.size(), UI.C_TEXT))
	summary.add_child(UI.label(("Sequência: %d dia" if _streak(days) == 1 else "Sequência: %d dias") % _streak(days), UI.C_GOOD))
	# gráfico
	var chart := Chart.new(Vector2(580, 124))
	chart.bars = data["bars"]
	add_to_body(chart, Vector2(0, 42))
	add_to_body(UI.label("Minutos de foco por %s" % ["dia (últimos 14)", "semana (últimas 12)", "mês (últimos 12)", "ano"][tab], UI.C_DIM), Vector2(0, 168))
	# lista do período
	var col := scroll_column(Vector2(0, 184), Vector2(580, 108))
	if data["rows"].is_empty():
		col.add_child(UI.label("Nenhum foco registrado ainda. Conclua um Pomodoro para começar o histórico!", UI.C_DIM))
	for r in data["rows"]:
		var h := UI.hbox(0)
		var k := UI.label(r["label"], UI.C_ORANGE_L)
		k.custom_minimum_size.x = 150
		h.add_child(k)
		var c := UI.label(("%d foco" if r["count"] == 1 else "%d focos") % r["count"], UI.C_TEXT)
		c.custom_minimum_size.x = 80
		h.add_child(c)
		h.add_child(UI.label(_hm(r["minutes"]), UI.C_GOLD))
		col.add_child(h)


func _hm(minutes: int) -> String:
	return "%dh%02d" % [minutes / 60, minutes % 60] if minutes >= 60 else "%d min" % minutes


func _streak(days: Dictionary) -> int:
	var n := 0
	var t := Time.get_unix_time_from_system()
	var today := Time.get_date_string_from_unix_time(int(t))
	var d := int(t)
	if not days.has(today):
		d -= 86400      # ainda dá tempo de manter a sequência hoje
	while days.has(Time.get_date_string_from_unix_time(d)):
		n += 1
		d -= 86400
	return n


func _date_unix(d: String) -> int:
	return Time.get_unix_time_from_datetime_string(d + " 00:00:00")


## Segunda-feira da semana de uma data (AAAA-MM-DD).
func _week_start(d: String) -> String:
	var u := _date_unix(d)
	var wd := int(Time.get_datetime_dict_from_unix_time(u)["weekday"])   # 0 = domingo
	return Time.get_date_string_from_unix_time(u - ((wd + 6) % 7) * 86400)


func _key_for(d: String) -> String:
	match tab:
		0:
			return d
		1:
			return _week_start(d)
		2:
			return d.substr(0, 7)
	return d.substr(0, 4)


func _label_for(key: String, short: bool) -> String:
	match tab:
		0:
			var parts := key.split("-")
			return "%s/%s" % [parts[2], parts[1]] if short else "%s/%s/%s" % [parts[2], parts[1], parts[0]]
		1:
			var parts := key.split("-")
			if short:
				return "%s/%s" % [parts[2], parts[1]]
			var end := Time.get_date_string_from_unix_time(_date_unix(key) + 6 * 86400).split("-")
			return "%s/%s a %s/%s" % [parts[2], parts[1], end[2], end[1]]
		2:
			var parts := key.split("-")
			return MONTHS[int(parts[1]) - 1] if short else "%s de %s" % [MONTHS[int(parts[1]) - 1], parts[0]]
	return key


func _aggregate() -> Dictionary:
	var sums := {}
	var counts := {}
	for e in GameState.pomo_log:
		var d: String = e.get("d", "")
		if d.length() < 10:
			continue
		var k := _key_for(d)
		sums[k] = int(sums.get(k, 0)) + int(e.get("m", 0))
		counts[k] = int(counts.get(k, 0)) + 1
	var now := int(Time.get_unix_time_from_system())
	var today := Time.get_date_string_from_unix_time(now)
	# barras: períodos recentes mesmo sem foco (barra vazia)
	var keys: Array = []
	match tab:
		0:
			for i in range(13, -1, -1):
				keys.append(Time.get_date_string_from_unix_time(now - i * 86400))
		1:
			var ws := _week_start(today)
			for i in range(11, -1, -1):
				keys.append(Time.get_date_string_from_unix_time(_date_unix(ws) - i * 7 * 86400))
		2:
			var y := int(today.substr(0, 4))
			var m := int(today.substr(5, 2))
			for i in range(11, -1, -1):
				var mm := m - i
				var yy := y
				while mm <= 0:
					mm += 12
					yy -= 1
				keys.append("%04d-%02d" % [yy, mm])
		3:
			var y2 := int(today.substr(0, 4))
			var first := y2
			for k in sums:
				first = mini(first, int(k))
			for yy in range(first, y2 + 1):
				keys.append("%04d" % yy)
	var cur_key := _key_for(today)
	var bars: Array = []
	for k in keys:
		bars.append({"label": _label_for(k, true), "value": int(sums.get(k, 0)), "current": k == cur_key})
	var all_keys: Array = sums.keys()
	all_keys.sort()
	all_keys.reverse()
	var rows: Array = []
	for k in all_keys:
		rows.append({"label": _label_for(k, false), "count": int(counts[k]), "minutes": int(sums[k])})
	return {"bars": bars, "rows": rows}
