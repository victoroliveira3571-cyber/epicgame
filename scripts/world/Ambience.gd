class_name Ambience
extends Node2D

## Sons de ambiente do mundo aberto (cidade e floresta), com os áudios do Victor:
## de dia pássaros cantam perto do jogador; à noite grilos contínuos e uma coruja de vez em
## quando. Água (lago, rio) e outros pontos usam Audio.emitter() posicionais.

var forced_hour: float = -1.0
var bird_every: float = 9.0
var _crickets: AudioStreamPlayer
var _night: bool = false
var _check: float = 0.0
var _bird_t: float = 4.0
var _owl_t: float = 12.0
var _last_hour: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_crickets = AudioStreamPlayer.new()
	_crickets.stream = load(Audio.SFX2_DIR + "amb_grilos.wav")
	if _crickets.stream is AudioStreamWAV:
		var st := (_crickets.stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
		_crickets.stream = st
	_crickets.volume_db = -60.0
	_crickets.add_to_group("world_amb")
	add_child(_crickets)
	_update(true)


func is_night() -> bool:
	var hour := forced_hour
	if hour < 0.0:
		var t := Time.get_time_dict_from_system()
		hour = float(t["hour"]) + float(t["minute"]) / 60.0
	return hour >= 19.5 or hour < 5.5


func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = 5.0
		_update(false)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or Audio._world_ducked:
		return
	if _night:
		_owl_t -= delta
		if _owl_t <= 0.0:
			_owl_t = randf_range(18.0, 40.0)
			_one_shot("coruja", player.global_position + Vector2(randf_range(-160, 160), randf_range(-120, -40)), -10.0)
	else:
		_bird_t -= delta
		if _bird_t <= 0.0:
			_bird_t = bird_every * randf_range(0.5, 1.5)
			_one_shot("passaro", player.global_position + Vector2(randf_range(-150, 150), randf_range(-110, 60)), -12.0)


func _update(instant: bool) -> void:
	var n := is_night()
	var hour := int(forced_hour if forced_hour >= 0.0 else float(Time.get_time_dict_from_system()["hour"]))
	# sino da cidade às 6h, 12h e 18h (só quando a hora vira, não ao entrar na cena)
	if hour != _last_hour:
		if _last_hour >= 0 and hour in [6, 12, 18] and HUD.pomo_state == "idle":
			Audio.novo("sino_6_12_18", -6.0)
		_last_hour = hour
	if n == _night and not instant:
		return
	_night = n
	if n and not _crickets.playing:
		_crickets.play(randf() * 5.0)
	var tw := create_tween()
	tw.tween_property(_crickets, "volume_db", -14.0 if n else -60.0, 0.1 if instant else 3.0)
	if not n:
		tw.tween_callback(_crickets.stop)


func _one_shot(name: String, pos: Vector2, db: float) -> void:
	var p := AudioStreamPlayer2D.new()
	p.stream = load(Audio.SFX2_DIR + name + ".wav")
	p.position = pos
	p.volume_db = db + Audio.sfx_gain_db()
	p.pitch_scale = randf_range(0.9, 1.1)
	p.max_distance = 300.0
	get_parent().add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
