extends Node

## v3.7: habilidades nas teclas 1 a 4 e esquiva na R.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0


func check(c: bool, what: String) -> void:
	print("[teclas] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func _has(action: String, code: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == code:
			return true
	return false


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	GameState.level = 30
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	check(_has("skill", KEY_1) and not _has("skill", KEY_Q), "habilidade da classe na 1 (Q saiu)")
	check(_has("skill2", KEY_2) and _has("skill3", KEY_3) and _has("skill_book", KEY_4), "2, 3 e 4")
	check(_has("dodge", KEY_R) and _has("dodge", KEY_K) and not _has("dodge", KEY_SHIFT), "esquiva na R e K (Shift saiu)")
	check(_has("attack", KEY_SPACE), "ataque básico continua no Espaço")
	var pl := get_tree().get_first_node_in_group("player") as Player
	var hp0 := pl.skill_cd_left
	print("[teclas] input_locked=", Game.input_locked, " classe=", GameState.has_chosen_class(), " dialogo=", HUD.is_dialogue_open(), " janela=", HUD.is_window_open())
	_key(KEY_1, true)
	await get_tree().create_timer(0.3).timeout
	_key(KEY_1, false)
	check(pl.skill_cd_left > 0.0, "apertar 1 dispara a habilidade da classe")
	var st0 := pl.state
	_key(KEY_R, true)
	await get_tree().create_timer(0.1).timeout
	_key(KEY_R, false)
	check(pl.state == Player.State.DODGE or pl.dodge_cd_left > 0.0, "apertar R rola")
	await dev.shot(OUT + "teclas_hotbar.png")
	print("[teclas] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)


func _key(code: int, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)
