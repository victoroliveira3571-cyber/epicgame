extends Node

## Música e efeitos sonoros. Autoload: `Audio`.
## Música com troca suave (fade); efeitos tocam em uma piscina de players,
## com variação leve de tom pra não soar repetitivo.

const SFX_DIR := "res://assets/ninja/audio/sfx/"
const MUSIC_DIR := "res://assets/ninja/audio/music/"
const JINGLE_DIR := "res://assets/ninja/audio/jingle/"
const POOL_SIZE := 14

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_music: String = ""
var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
var _streams: Dictionary = {}
var _fade_tween: Tween
var _last_played: Dictionary = {}  # evita o mesmo som disparar dezenas de vezes no mesmo frame

const MUSIC_DB := -9.0
const CLOCK_DB := -16.0

## Nomes lógicos que apontam para faixas medievais (escolhe uma ao acaso quando há várias).
const MUSIC_ALIASES := {
	"town": ["medieval_1", "medieval_2", "medieval_3"],
	"town_night": ["medieval_ambient"],
	"title": ["medieval_3"],
}

var _clock: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player()
	_music_b = _make_player()
	_active_music = _music_a
	for i in POOL_SIZE:
		_pool.append(_make_player())
	_apply_volume()
	GameState.stats_changed.connect(_apply_volume)


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Master"
	add_child(p)
	return p


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, GameState.audio_muted)
	var db: float = linear_to_db(GameState.audio_volume) if GameState.audio_volume > 0.001 else -80.0
	AudioServer.set_bus_volume_db(bus, db)
	if _active_music != null and _active_music.playing and (_fade_tween == null or not _fade_tween.is_running()):
		_active_music.volume_db = _music_db()


func _music_db() -> float:
	var v := GameState.music_volume
	return MUSIC_DB + (linear_to_db(v) if v > 0.001 else -80.0)


func _load_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
		if s is AudioStreamOggVorbis or s is AudioStreamMP3:
			s.loop = true
	else:
		push_warning("[Audio] não encontrado: " + path)
	_streams[path] = s
	return s


func play_music(name: String, fade: float = 1.0) -> void:
	if name == _current_music:
		return
	_current_music = name
	if name == "":
		stop_music(fade)
		return
	var track := name
	if MUSIC_ALIASES.has(name):
		var options: Array = MUSIC_ALIASES[name]
		track = options[randi() % options.size()]
	var path := MUSIC_DIR + track + ".mp3"
	if not ResourceLoader.exists(path):
		path = MUSIC_DIR + track + ".ogg"
	var stream := _load_stream(path)
	if stream == null:
		return
	var incoming := _music_b if _active_music == _music_a else _music_a
	var outgoing := _active_music
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()
	_active_music = incoming
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", _music_db(), fade)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", -60.0, fade)
		_fade_tween.chain().tween_callback(outgoing.stop)


func stop_music(fade: float = 0.8) -> void:
	_current_music = ""
	if _active_music != null and _active_music.playing:
		var p := _active_music
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -60.0, fade)
		tw.tween_callback(p.stop)


func sfx(name: String, volume_db: float = 0.0, pitch_var: float = 0.06) -> void:
	var now := Time.get_ticks_msec()
	if _last_played.has(name) and now - int(_last_played[name]) < 35:
		return
	_last_played[name] = now
	var stream := _load_stream(SFX_DIR + name + ".wav")
	if stream == null:
		return
	_play_on_pool(stream, volume_db, pitch_var)


## Tique-taque do relógio (sessão de foco do Pomodoro).
func set_clock(on: bool) -> void:
	if _clock == null:
		if not on:
			return
		_clock = _make_player()
		_clock.stream = _load_stream(SFX_DIR + "clock_tick.mp3")
		_clock.volume_db = CLOCK_DB
	if _clock.stream == null:
		return
	if on and not _clock.playing:
		_clock.play()
	elif not on and _clock.playing:
		_clock.stop()


func jingle(name: String, volume_db: float = -2.0) -> void:
	var stream := _load_stream(JINGLE_DIR + name + ".wav")
	if stream != null:
		_play_on_pool(stream, volume_db, 0.0)


func _play_on_pool(stream: AudioStream, volume_db: float, pitch_var: float) -> void:
	var p := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db - 3.0
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


## Sons de interface (cliques) usados pelos botões do tema.
func ui_click() -> void:
	sfx("ui_click", -6.0, 0.03)
