extends UIWindow

## Caderno do herói (tecla N): só uma folha em branco para escrever livremente e desabafar.
## Nada vai para o save nem fica histórico: o texto vive só enquanto o jogo está aberto, e
## "Soltar a página" apaga na hora (a folha voa). Sugestões de escrita ajudam a começar.

const PROMPTS := [
	"O que está pesando na sua cabeça agora?",
	"Do que você tem medo nesta semana? Escreva sem filtro.",
	"O que te irritou hoje? Pode reclamar à vontade.",
	"Escreva tudo o que você precisa lembrar e tire da cabeça.",
	"Uma coisa pequena que deu certo hoje.",
	"Se você pudesse dizer algo para alguém agora, o que seria?",
	"Como está o seu corpo neste momento? Cansado, tenso, tranquilo?",
	"O que você faria se não tivesse medo de errar?",
]

static var _text: String = ""      # só durante esta sessão do jogo (não vai para o save)

var _edit: TextEdit
var _count: Label
var _prompt: Label
var _paper: Panel


func _init() -> void:
	win_title = "Caderno  -  escrita livre"
	win_size = Vector2(520, 300)


func refresh() -> void:
	pass  # o texto não pode ser recriado enquanto o jogador digita


func build() -> void:
	_prompt = UI.label(PROMPTS[randi() % PROMPTS.size()], UI.C_ORANGE_L)
	add_to_body(_prompt, Vector2(2, 0))
	add_to_body(UI.button("Outra ideia", func() -> void:
		_prompt.text = PROMPTS[randi() % PROMPTS.size()]
		Audio.sfx2("ui_pack5", -10.0), 80), Vector2(410, -2))
	_paper = Panel.new()
	var ps := UI.flat(Color("f3ead2"), Color("8a6a4a"), 1)
	ps.set_corner_radius_all(2)
	_paper.add_theme_stylebox_override("panel", ps)
	_paper.position = Vector2(0, 18)
	_paper.size = Vector2(500, 196)
	body.add_child(_paper)
	var lines := Lines.new()
	lines.size = _paper.size
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(lines)
	_edit = TextEdit.new()
	_edit.position = Vector2(24, 4)
	_edit.size = Vector2(470, 188)
	_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_edit.placeholder_text = "Escreva aqui. Ninguém vai ler, e nada fica salvo."
	_edit.add_theme_color_override("font_color", Color("2a1d2e"))
	_edit.add_theme_color_override("font_placeholder_color", Color(0.35, 0.28, 0.25, 0.55))
	_edit.add_theme_color_override("caret_color", Color("8f5545"))
	_edit.add_theme_constant_override("line_spacing", 3)
	var empty := StyleBoxEmpty.new()
	_edit.add_theme_stylebox_override("normal", empty)
	_edit.add_theme_stylebox_override("focus", empty)
	_edit.text = _text
	_edit.text_changed.connect(_on_changed)
	_paper.add_child(_edit)
	_count = UI.label("", UI.C_DIM)
	add_to_body(_count, Vector2(2, 220))
	add_to_body(UI.wrap_label("Só fica aqui enquanto o jogo está aberto.", UI.C_DIM, 220), Vector2(2, 236))
	add_to_body(UI.button("Soltar a página", func() -> void: _release(), 120), Vector2(380, 222))
	_on_changed()
	_edit.call_deferred("grab_focus")


## Linhas de caderno e margem vermelha.
class Lines extends Control:
	func _draw() -> void:
		for y in range(20, int(size.y), 15):
			draw_line(Vector2(4, y), Vector2(size.x - 4, y), Color(0.55, 0.65, 0.8, 0.35), 1.0)
		draw_line(Vector2(18, 2), Vector2(18, size.y - 2), Color(0.85, 0.35, 0.35, 0.5), 1.0)


func _on_changed() -> void:
	_text = _edit.text
	var words := _edit.text.split(" ", false).size() if _edit.text.strip_edges() != "" else 0
	_count.text = "%d palavras" % words
	if words >= 3:
		Story.on_notebook_written()


## Apaga a folha: ela sobe e some (o texto não é guardado em lugar nenhum).
func _release() -> void:
	if _edit.text.strip_edges() == "":
		return
	Audio.sfx2("gota", -6.0)
	Audio.sfx2("whoosh", -8.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_paper, "position:y", _paper.position.y - 40.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_paper, "modulate:a", 0.0, 0.45)
	tw.tween_property(_paper, "rotation", -0.06, 0.45)
	await tw.finished
	_text = ""
	_edit.text = ""
	_on_changed()
	_paper.position.y = 18.0
	_paper.rotation = 0.0
	create_tween().tween_property(_paper, "modulate:a", 1.0, 0.25)
	HUD.show_toast("Página solta. Respire e siga em frente.", UI.C_GOOD)
