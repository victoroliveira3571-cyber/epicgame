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
	"town": ["medieval_1", "medieval_2", "medieval_3", "happy_whistler"],
	"pausa": ["happy_whistler"],
	"town_night": ["medieval_ambient"],
	"title": ["medieval_3"],
}

var _clock: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ambience_name: String = ""

# Pomodoro: playlist do foco e camadas de ambiente (PomoSound)
const AMB_DB := -12.0
var _scene_music: String = ""         # música pedida pelo lugar atual
var _pomo_genre: String = ""          # playlist tocando ("" = nenhuma)
var _pomo_scene: String = ""
var _pomo_quiet: bool = false         # Pomodoro ativo: sem música nem ambiente, só o relógio
var _playlist: Array = []
var _pl_index: int = 0
var _amb_players: Dictionary = {}     # id -> AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player()
	_music_b = _make_player()
	_active_music = _music_a
	for i in POOL_SIZE:
		_pool.append(_make_player())
	_apply_volume()
	GameState.stats_changed.connect(_apply_volume)
	_music_a.finished.connect(_on_music_finished.bind(_music_a))
	_music_b.finished.connect(_on_music_finished.bind(_music_b))


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
	if not GameState.music_on:
		return -80.0
	return MUSIC_DB + (linear_to_db(v) if v > 0.001 else -80.0)


func _load_stream(path: String, looping: bool = false) -> AudioStream:
	var key := path + ("#loop" if looping else "")
	if _streams.has(key):
		return _streams[key]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
		# a mesma faixa pode tocar em loop (cidade) e sem loop (playlist): cópias separadas
		var other := path + ("" if looping else "#loop")
		if _streams.has(other) and _streams[other] == s:
			s = s.duplicate()
		if s is AudioStreamOggVorbis or s is AudioStreamMP3:
			s.loop = looping
		elif s is AudioStreamWAV:
			if looping:
				s.loop_mode = AudioStreamWAV.LOOP_FORWARD
				s.loop_begin = 0
				s.loop_end = int(s.get_length() * s.mix_rate)
			else:
				s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	else:
		push_warning("[Audio] não encontrado: " + path)
	_streams[key] = s
	return s


## Música do lugar (cidade, casa, masmorra...). Durante o Pomodoro a playlist do foco tem
## prioridade; quando o foco acaba, volta a música pedida aqui.
func play_music(name: String, fade: float = 1.0) -> void:
	_scene_music = name
	if _pomo_genre != "" or _pomo_quiet:
		return
	_play_named(name, fade)


func _play_named(name: String, fade: float = 1.0) -> void:
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
	var stream := _load_stream(path, true)
	if stream == null:
		return
	_crossfade_to(stream, fade)


func _crossfade_to(stream: AudioStream, fade: float) -> void:
	var incoming := _music_b if _active_music == _music_a else _music_a
	var outgoing := _active_music
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.stream_paused = false
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
	var stream := _load_stream(_find(SFX_DIR, name))
	if stream == null:
		return
	_play_on_pool(stream, volume_db, pitch_var)


## Sons enviados pelo Victor (assets/audio/sfx2/): ações e ambiente. Ver ASSETS.md.
const SFX2_DIR := "res://assets/audio/sfx2/"
## Sons enviados pelo Victor depois (assets/audio/novos/), nomeados pelo uso no jogo. Ver ASSETS.md.
const NOVOS_DIR := "res://assets/audio/novos/"
var _places: Dictionary = {}          # id -> AudioStreamPlayer (som de lugar em loop)
var forest_step: String = "passos_grama"  # passos na floresta: grama ou árvores (zona)
var _world_ducked: bool = false          # som do mundo pausado enquanto o Pomodoro toca o seu


func sfx2(name: String, volume_db: float = 0.0, pitch_var: float = 0.05) -> void:
	var now := Time.get_ticks_msec()
	if _last_played.has("2:" + name) and now - int(_last_played["2:" + name]) < 60:
		return
	_last_played["2:" + name] = now
	var stream := _load_stream(SFX2_DIR + name + ".wav")
	if stream != null:
		_play_on_pool(stream, volume_db, pitch_var)


## Efeito de "assets/audio/novos/<id>.mp3" (one-shot).
func novo(id: String, volume_db: float = 0.0, pitch_var: float = 0.04, gap: float = 0.0) -> void:
	var now := Time.get_ticks_msec()
	if _last_played.has("n:" + id) and now - int(_last_played["n:" + id]) < maxi(60, int(gap * 1000.0)):
		return
	_last_played["n:" + id] = now
	var stream := _load_stream(NOVOS_DIR + id + ".mp3")
	if stream != null:
		_play_on_pool(stream, volume_db, pitch_var)


## Som de fundo em loop de um lugar (floresta, masmorra, biblioteca, casa com lareira, forja).
## Troca com fade; "" tira o som do lugar. Com o regulador de efeitos no menu de pausa.
func set_place_loop(id: String, volume_db: float = -10.0) -> void:
	for old in _places.keys():
		if old != id:
			var p: AudioStreamPlayer = _places[old]
			_places.erase(old)
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -60.0, 0.8)
			tw.tween_callback(p.queue_free)
	if id == "" or _places.has(id):
		return
	var stream := _load_stream(NOVOS_DIR + id + ".mp3", true)
	if stream == null:
		return
	var p := _make_player()
	p.stream = stream
	p.volume_db = -60.0
	p.play(randf() * maxf(stream.get_length() - 1.0, 0.0))
	_places[id] = p
	p.stream_paused = _world_ducked
	create_tween().tween_property(p, "volume_db", volume_db + sfx_gain_db(), 1.2)


## Descansar: som de sono e, ao acordar, a voz do herói (só existe a masculina).
func wake_up() -> void:
	sfx("sleep", -4.0)
	if String(Story.st().get("gender", "m")) != "f":
		get_tree().create_timer(1.2).timeout.connect(func() -> void: novo("heroi_acorda", -4.0))


## Volume dos efeitos (regulador do menu de pausa), em dB.
func sfx_gain_db() -> float:
	var v := GameState.sfx_volume
	return linear_to_db(v) if v > 0.001 else -80.0


## Som de ambiente preso a um ponto do mundo (rio, bigorna, relógio, goteira). `loop` = contínuo;
## senão toca de vez em quando (a cada `every` segundos, com variação). Some com a distância.
func emitter(parent: Node, pos: Vector2, name: String, volume_db: float = -8.0, loop: bool = true,
		every: float = 8.0, max_dist: float = 220.0) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	p.position = pos
	p.stream = _load_stream(SFX2_DIR + name + ".wav", loop)
	p.volume_db = volume_db + sfx_gain_db()
	p.max_distance = max_dist
	p.attenuation = 1.6
	p.bus = "Master"
	p.add_to_group("world_amb")
	parent.add_child(p)
	p.stream_paused = _world_ducked
	if p.stream == null:
		return p
	if loop:
		p.play(randf() * maxf(p.stream.get_length() - 0.5, 0.0))
	else:
		var t := Timer.new()
		t.one_shot = false
		t.wait_time = every * randf_range(0.4, 1.0)
		p.add_child(t)
		t.timeout.connect(func() -> void:
			t.wait_time = every * randf_range(0.6, 1.4)
			p.pitch_scale = randf_range(0.92, 1.08)
			p.play())
		t.start()
	return p


## Tique-taque do relógio (sessão de foco do Pomodoro).
func set_clock(on: bool) -> void:
	on = on and GameState.clock_on
	if _clock == null:
		if not on:
			return
		_clock = _make_player()
		_clock.stream = _load_stream(SFX_DIR + "clock_tick.mp3", true)
		_clock.volume_db = CLOCK_DB
	if _clock.stream == null:
		return
	if on and not _clock.playing:
		_clock.play()
	elif not on and _clock.playing:
		_clock.stop()


func jingle(name: String, volume_db: float = -2.0) -> void:
	var stream := _load_stream(_find(JINGLE_DIR, name))
	if stream != null:
		_play_on_pool(stream, volume_db, 0.0)


## Som de fundo contínuo (ex.: natureza na cena do Pomodoro). "" para.
func set_ambience(name: String, volume_db: float = -14.0) -> void:
	if name == _ambience_name:
		return
	_ambience_name = name
	if _ambience == null:
		_ambience = _make_player()
	if name == "":
		_ambience.stop()
		return
	_ambience.stream = _load_stream(MUSIC_DIR + name + ".mp3", true)
	_ambience.volume_db = volume_db
	_ambience.play()


## Prefere o .mp3 (sons que o Victor adicionou) e cai no .wav original.
func _find(dir: String, name: String) -> String:
	var mp3 := dir + name + ".mp3"
	return mp3 if ResourceLoader.exists(mp3) else dir + name + ".wav"


func _play_on_pool(stream: AudioStream, volume_db: float, pitch_var: float) -> void:
	var p := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db - 3.0 + sfx_gain_db()
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


## Sons de interface (cliques) usados pelos botões do tema.
func ui_click() -> void:
	sfx("ui_click", -6.0, 0.03)


# ================================================================== Pomodoro
## Reavalia playlist e ambiente (chame quando o estado do Pomodoro, o cenário, o lugar ou as
## escolhas de som mudarem). Fora da masmorra, foco e pausa tocam a playlist do cenário.
func pomo_update(fade: float = 1.5) -> void:
	var active := HUD.pomo_state != "idle" and HUD.scene_kind != "dungeon"
	var scene := str(GameState.pomo_cfg.get("scene", "cafeteria"))
	_duck_world(active)
	# v2.4: durante o Pomodoro não há música nem ambiente, só o tique-taque do relógio.
	var was_quiet := _pomo_quiet
	_pomo_quiet = active
	_pomo_genre = ""
	if active:
		if not was_quiet:
			_current_music = ""
			stop_music(fade)
	elif was_quiet:
		_current_music = ""
		_play_named(_scene_music, fade)
	_update_ambience("")
	# timer pausado = música e ambiente pausados no mesmo ponto (voltam juntos com o tempo)
	var hold := HUD.pomo_state == "paused" and _pomo_genre != ""
	if _active_music != null:
		_active_music.stream_paused = hold
	for id in _amb_players:
		(_amb_players[id] as AudioStreamPlayer).stream_paused = HUD.pomo_state == "paused"


## Durante o Pomodoro (fora da masmorra) só tocam a música e o ambiente do foco: o som do mundo
## (loops de lugar, rio, grilos) pausa junto, para não misturar com o do Pomodoro.
func _duck_world(on: bool) -> void:
	_world_ducked = on
	for p in _places.values():
		(p as AudioStreamPlayer).stream_paused = on
	for n in get_tree().get_nodes_in_group("world_amb"):
		if n is AudioStreamPlayer2D:
			(n as AudioStreamPlayer2D).stream_paused = on
		elif n is AudioStreamPlayer:
			(n as AudioStreamPlayer).stream_paused = on


func _play_track(fade: float) -> void:
	if _playlist.is_empty():
		return
	var path: String = _playlist[_pl_index % _playlist.size()]
	var stream := _load_stream(path, false)
	if stream == null:
		return
	_current_music = "pl:" + path
	_crossfade_to(stream, fade)


func _on_music_finished(p: AudioStreamPlayer) -> void:
	if p == _active_music and _pomo_genre != "":
		pomo_next(0.3)


## Próxima faixa da playlist do foco.
func pomo_next(fade: float = 1.0) -> void:
	if _pomo_genre == "" or _playlist.is_empty():
		return
	_pl_index = (_pl_index + 1) % _playlist.size()
	_play_track(fade)


func pomo_track_title() -> String:
	if _pomo_genre == "" or _playlist.is_empty():
		return ""
	return PomoSound.track_title(_playlist[_pl_index % _playlist.size()])


func pomo_genre_playing() -> String:
	return _pomo_genre


func _update_ambience(scene: String) -> void:
	var want := {}
	if scene != "":
		for l in PomoSound.scene_layers(scene):
			if l["on"] and l["id"] != "acoes" and float(l["v"]) > 0.001:
				want[l["id"]] = AMB_DB + linear_to_db(float(l["v"]))
	_pomo_scene = scene
	for id in _amb_players.keys():
		if not want.has(id):
			var old: AudioStreamPlayer = _amb_players[id]
			_amb_players.erase(id)
			var tw := create_tween()
			tw.tween_property(old, "volume_db", -60.0, 0.8)
			tw.tween_callback(old.queue_free)
	for id in want:
		if _amb_players.has(id):
			var cur: AudioStreamPlayer = _amb_players[id]
			cur.volume_db = want[id]
			continue
		var stream := _load_stream(PomoSound.ambient_path(id), true)
		if stream == null:
			continue
		var p := _make_player()
		p.stream = stream
		p.volume_db = -60.0
		p.play(randf() * maxf(stream.get_length() - 1.0, 0.0))
		_amb_players[id] = p
		create_tween().tween_property(p, "volume_db", want[id], 1.2)


## Som curto de uma ação do herói na cena (xícara, gole, página), no volume de "Ações do herói".
func pomo_event(name: String) -> void:
	if _pomo_scene == "":
		return
	var l := PomoSound.layer(_pomo_scene, "acoes")
	if l.is_empty() or not l["on"] or float(l["v"]) <= 0.001:
		return
	var path := PomoSound.event_path(name)
	var stream := _load_stream(path) if path != "" else null
	if stream != null:
		_play_on_pool(stream, -4.0 + linear_to_db(float(l["v"])), 0.05)
