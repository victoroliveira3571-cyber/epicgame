class_name Voice
extends Node

## Vozes dos personagens nos diálogos (estilo MMORPG clássico: Ragnarok/MU, sem palavras reais).
## Cada fala toca uma reação curta no começo (saudação, risada, "hm?", raiva, tristeza) e, enquanto o texto
## aparece, pedacinhos de clipes do pack escolhido para o personagem, com o tom dele. Os clipes vêm dos packs
## do Victor (tools/build_voices.py -> assets/audio/voice, catálogo em VoiceCatalog).

const PROFILES := {
	# who: [voz, tom]  (tom < 1 grave/velho, > 1 agudo/pequeno)
	"heroi_m": ["male", 1.0], "heroi_f": ["fem_bright", 1.0],
	"mae": ["fem_mid", 1.0], "pai": ["male", 0.82],
	"marta": ["fem_mid", 0.88], "helena": ["fem_bright", 1.0], "osvaldo": ["male", 0.78],
	"pietro": ["male", 1.12], "ivo": ["male", 1.05], "lin": ["mage", 0.9], "aldric": ["orc", 0.85],
	"vizinho": ["male", 0.92], "espirito": ["mage", 0.6], "sentinela": ["orc", 0.55],
	"bibliotecario": ["mage", 0.7], "cavaleiro": ["orc", 0.8], "rei": ["orc", 0.62],
	"corvin": ["fem_bright", 1.75], "brisa": ["fem_mid", 1.45], "lumen": ["fem_bright", 1.55], "airevis": ["mage", 1.35],
	"espelho": ["fem_mid", 1.12], "ferreiro": ["orc", 0.95], "armeiro": ["male", 0.95],
	"costureira": ["fem_mid", 1.06], "estalajadeiro": ["male", 0.9], "mestre_cla": ["mage", 0.8],
	"bibliotecaria": ["fem_mid", 0.92], "arena": ["fem_bright", 0.92],
	"cientista": ["mage", 1.25], "pipeta": ["fem_bright", 1.15], "tonico": ["orc", 1.1],
}
const FALLBACK := [["male", 1.0], ["fem_mid", 1.0], ["mage", 1.0], ["fem_bright", 1.0], ["male", 0.85], ["orc", 1.0]]
const BLIP_LEN := 0.085
const BLIP_PLAYERS := 3

var _reaction: AudioStreamPlayer
var _blips: Array[AudioStreamPlayer] = []
var _blip_stop: Array[int] = []
var _blip_i: int = 0
var _streams: Dictionary = {}
var _last_who: String = ""
var enabled: bool:
	get:
		return not bool(GameState.pomo_cfg.get("voice_off", false))
	set(v):
		GameState.pomo_cfg["voice_off"] = not v


func set_enabled(on: bool) -> void:
	enabled = on


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reaction = AudioStreamPlayer.new()
	_reaction.bus = "Master"
	add_child(_reaction)
	for i in BLIP_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_blips.append(p)
		_blip_stop.append(0)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for i in _blips.size():
		if _blips[i].playing and now >= _blip_stop[i]:
			_blips[i].stop()


## [voz, tom] do personagem. Desconhecidos recebem uma voz fixa pelo nome.
func profile(who: String) -> Array:
	if who == "heroi":
		who = "heroi_f" if String(Story.st().get("gender", "m")) == "f" else "heroi_m"
	if PROFILES.has(who):
		return PROFILES[who]
	return FALLBACK[absi(who.hash()) % FALLBACK.size()]


func _clips(voice: String, cat: String) -> Array:
	var v: Dictionary = VoiceCatalog.CLIPS.get(voice, {})
	return v.get(cat, [])


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


## Começo de uma fala: reação curta pela expressão e pelo texto.
func line_start(who: String, expr: String, text: String) -> void:
	if not enabled or who == "narr" or who == "":
		return
	var prof := profile(who)
	var t := text.to_lower()
	var cat := ""
	match expr:
		"happy":
			cat = "laugh" if (t.contains("haha") or t.contains("hehe")) else "happy"
		"anger", "angry":
			cat = "angry"
		"sad":
			cat = "sad"
		"shock":
			cat = "ask"
		_:
			if who != _last_who and _starts_greeting(t):
				cat = "greet"
			elif t.contains("?"):
				cat = "ask"
			elif t.contains("haha"):
				cat = "laugh"
	_last_who = who
	if cat == "":
		return
	var clips := _clips(prof[0], cat)
	if clips.is_empty():
		return
	var s := _stream(clips[randi() % clips.size()])
	if s == null:
		return
	_reaction.stream = s
	_reaction.pitch_scale = clampf(float(prof[1]), 0.5, 2.0)
	_reaction.volume_db = -7.0
	_reaction.play()


func _starts_greeting(t: String) -> bool:
	for g in ["olá", "oi", "bom dia", "boa tarde", "boa noite", "bem-vind", "e aí", "salve", "saudações"]:
		if t.begins_with(g):
			return true
	return false


## Um "bip" de sílaba enquanto o texto aparece: pedaço curto de um clipe do personagem.
func blip(who: String) -> void:
	if not enabled or who == "narr" or who == "":
		return
	var prof := profile(who)
	var cat: String = ["greet", "yes", "ask", "happy"][randi() % 4]
	var clips := _clips(prof[0], cat)
	if clips.is_empty():
		return
	var s := _stream(clips[randi() % clips.size()])
	if s == null:
		return
	var len_s := s.get_length()
	var p := _blips[_blip_i]
	p.stream = s
	p.pitch_scale = clampf(float(prof[1]) * randf_range(0.93, 1.1), 0.4, 2.2)
	p.volume_db = -15.0
	var from := randf_range(0.02, maxf(0.03, len_s - BLIP_LEN * 2.0))
	p.play(from)
	_blip_stop[_blip_i] = Time.get_ticks_msec() + int(BLIP_LEN * 1000.0 / p.pitch_scale)
	_blip_i = (_blip_i + 1) % _blips.size()


func reset_speaker() -> void:
	_last_who = ""
