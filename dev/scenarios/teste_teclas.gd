extends Node

## Confere a troca de teclas: trocar, gravar, recarregar do arquivo e restaurar o padrão.
## Saída só no console. Ao final, deixa tudo como estava (arquivo de teclas apagado).


func run(_dev: Node) -> void:
	print("[teclas] padrão: skill=", Game.key_name("skill"), " caderno=", Game.key_name("caderno"),
		" pet=", Game.key_name("pet"), " decorar=", Game.key_name("decorar"))
	Game.rebind("skill", KEY_Q)
	print("[teclas] depois de trocar skill para Q: ", Game.key_name("skill"))
	print("[teclas] arquivo gravado: ", FileAccess.file_exists(Game.KEYBIND_FILE))
	Game._set_single_key("skill", KEY_1)
	print("[teclas] antes de recarregar (forçado para 1): ", Game.key_name("skill"))
	Game._load_keybinds()
	print("[teclas] depois de recarregar do arquivo: ", Game.key_name("skill"))
	Game.rebind("caderno", KEY_J)
	print("[teclas] caderno agora: ", Game.key_name("caderno"), " | pressionar J dispara a ação: ",
		InputMap.event_is_action(_key_event(KEY_J), "caderno"))
	Game.reset_keybinds()
	print("[teclas] após restaurar: skill=", Game.key_name("skill"), " caderno=", Game.key_name("caderno"),
		" arquivo existe=", FileAccess.file_exists(Game.KEYBIND_FILE))


func _key_event(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code as Key
	ev.pressed = true
	return ev
