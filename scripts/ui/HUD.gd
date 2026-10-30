extends CanvasLayer

## (provisório) HUD completo vem depois.

var _prompt: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	add_to_group("hud")
	_prompt = Label.new()
	_prompt.add_theme_font_override("font", Pix.font())
	_prompt.add_theme_font_size_override("font_size", 16)
	_prompt.position = Vector2(500, 620)
	add_child(_prompt)


func set_prompt(text: String) -> void:
	_prompt.text = text


func open_window(id: String) -> void:
	print("[HUD] abrir janela: ", id)


func on_scene_ready(_which: String) -> void:
	pass
