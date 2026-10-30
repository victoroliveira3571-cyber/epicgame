extends CanvasLayer

## Painel de status (nível/XP/ouro/fome) + timer Pomodoro.
##
## Para ajustar a duração das sessões, mude só estas 5 constantes:
const WORK_SECONDS := 25 * 60       # duração do foco
const BREAK_SECONDS := 5 * 60       # pausa curta
const LONG_BREAK_SECONDS := 15 * 60 # pausa longa
const SESSIONS_BEFORE_LONG_BREAK := 4
const XP_PER_FOCUS := 20
const GOLD_PER_FOCUS := 10

enum Mode { FOCUS, BREAK, LONG_BREAK }

@onready var lvl_label: Label = $StatsPanel/Margin/VBox/LevelLabel
@onready var hp_label: Label = $StatsPanel/Margin/VBox/HPLabel
@onready var xp_label: Label = $StatsPanel/Margin/VBox/XPLabel
@onready var gold_label: Label = $StatsPanel/Margin/VBox/GoldLabel
@onready var hunger_label: Label = $StatsPanel/Margin/VBox/HungerLabel
@onready var inventory_label: Label = $StatsPanel/Margin/VBox/InventoryLabel

@onready var mode_label: Label = $PomodoroPanel/Margin/VBox/ModeLabel
@onready var time_label: Label = $PomodoroPanel/Margin/VBox/TimeLabel
@onready var cycle_label: Label = $PomodoroPanel/Margin/VBox/CycleLabel
@onready var start_button: Button = $PomodoroPanel/Margin/VBox/Buttons/StartButton
@onready var pause_button: Button = $PomodoroPanel/Margin/VBox/Buttons/PauseButton
@onready var reset_button: Button = $PomodoroPanel/Margin/VBox/Buttons/ResetButton
@onready var countdown_timer: Timer = $CountdownTimer
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var guild_panel: PanelContainer = $GuildPanel
@onready var class_select_panel: PanelContainer = $ClassSelectPanel
@onready var habits_panel: PanelContainer = $HabitsPanel
@onready var habits_button: Button = $StatsPanel/Margin/VBox/HabitsButton
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var mute_button: Button = $AudioPanel/AudioMargin/AudioVBox/AudioRow/MuteButton
@onready var volume_slider: HSlider = $AudioPanel/AudioMargin/AudioVBox/AudioRow/VolumeSlider

const MUSIC_TOWN := preload("res://assets/audio/music_town.ogg")
const MUSIC_DUNGEON := preload("res://assets/audio/music_dungeon.ogg")
const SFX_HIT := preload("res://assets/audio/sfx_hit.wav")
const SFX_COIN := preload("res://assets/audio/sfx_coin.wav")
const SFX_LEVELUP := preload("res://assets/audio/sfx_levelup.wav")

var hp_bar: ProgressBar
var xp_bar: ProgressBar
var current_music: String = ""
var last_known_level: int = 1

var mode: int = Mode.FOCUS
var remaining_seconds: int = WORK_SECONDS
var is_running: bool = false
var completed_focus_sessions: int = 0
var escape_was_pressed: bool = false
var f9_was_pressed: bool = false


func _ready() -> void:
	add_to_group("hud")
	_build_stat_bars()
	GameState.stats_changed.connect(_update_stats_display)
	GameState.damage_taken.connect(_on_player_damaged)
	GameState.leveled_up.connect(_on_leveled_up)
	_update_stats_display()

	start_button.pressed.connect(_on_start_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	countdown_timer.timeout.connect(_on_tick)

	pause_button.disabled = true
	_update_time_display()
	_update_mode_display()
	_update_cycle_display()

	if not GameState.has_chosen_class():
		class_select_panel.visible = true

	last_known_level = GameState.level
	music_player.finished.connect(func() -> void: music_player.play())

	habits_button.pressed.connect(toggle_habits)

	mute_button.button_pressed = GameState.audio_muted
	mute_button.text = "🔇" if GameState.audio_muted else "🔊"
	volume_slider.set_value_no_signal(GameState.audio_volume)
	mute_button.toggled.connect(_on_mute_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	_apply_audio_settings()


func _update_stats_display() -> void:
	if GameState.level > last_known_level:
		play_named_sfx("levelup")
	last_known_level = GameState.level

	lvl_label.text = "Nível %d" % GameState.level
	hp_label.text = "Vida: %d / %d" % [GameState.hp, GameState.get_max_hp()]
	xp_label.text = "XP: %d / %d" % [GameState.xp, GameState.xp_to_next]
	gold_label.text = "Ouro: %d" % GameState.gold
	hunger_label.text = "Fome: %d / 100" % GameState.hunger
	inventory_label.text = "Inventário: %s" % _format_inventory()
	hp_bar.max_value = GameState.get_max_hp()
	hp_bar.value = GameState.hp
	xp_bar.max_value = GameState.xp_to_next
	xp_bar.value = GameState.xp


func _format_inventory() -> String:
	if GameState.inventory.is_empty():
		return "vazio"
	var parts: Array[String] = []
	for item_id in GameState.inventory:
		var item_name: String = GameState.ITEM_NAMES.get(item_id, item_id)
		parts.append("%s x%d" % [item_name, GameState.inventory[item_id]])
	return ", ".join(parts)


func _on_start_pressed() -> void:
	if is_running:
		return
	is_running = true
	countdown_timer.start(1.0)
	start_button.disabled = true
	pause_button.disabled = false


func _on_pause_pressed() -> void:
	is_running = false
	countdown_timer.stop()
	start_button.disabled = false
	pause_button.disabled = true


func _on_reset_pressed() -> void:
	is_running = false
	countdown_timer.stop()
	mode = Mode.FOCUS
	completed_focus_sessions = 0
	remaining_seconds = WORK_SECONDS
	start_button.disabled = false
	pause_button.disabled = true
	_update_time_display()
	_update_mode_display()
	_update_cycle_display()


func _on_tick() -> void:
	remaining_seconds -= 1
	if remaining_seconds <= 0:
		_on_session_complete()
	else:
		_update_time_display()


func _on_session_complete() -> void:
	countdown_timer.stop()
	is_running = false
	start_button.disabled = false
	pause_button.disabled = true

	if mode == Mode.FOCUS:
		completed_focus_sessions += 1
		GameState.add_pomodoro_reward(XP_PER_FOCUS, GOLD_PER_FOCUS)
		GameState.register_focus_session_completed()
		if completed_focus_sessions % SESSIONS_BEFORE_LONG_BREAK == 0:
			mode = Mode.LONG_BREAK
			remaining_seconds = LONG_BREAK_SECONDS
		else:
			mode = Mode.BREAK
			remaining_seconds = BREAK_SECONDS
	else:
		mode = Mode.FOCUS
		remaining_seconds = WORK_SECONDS

	_update_mode_display()
	_update_time_display()
	_update_cycle_display()


func _update_time_display() -> void:
	var m := remaining_seconds / 60
	var s := remaining_seconds % 60
	time_label.text = "%02d:%02d" % [m, s]


func _update_mode_display() -> void:
	match mode:
		Mode.FOCUS:
			mode_label.text = "Foco"
		Mode.BREAK:
			mode_label.text = "Pausa curta"
		Mode.LONG_BREAK:
			mode_label.text = "Pausa longa"


func _update_cycle_display() -> void:
	var current := completed_focus_sessions % SESSIONS_BEFORE_LONG_BREAK
	cycle_label.text = "Ciclo %d/%d" % [current, SESSIONS_BEFORE_LONG_BREAK]


func _process(_delta: float) -> void:
	var f9_pressed := Input.is_physical_key_pressed(KEY_F9)
	if f9_pressed and not f9_was_pressed:
		GameState.debug_level_up()
	f9_was_pressed = f9_pressed

	var escape_pressed := Input.is_physical_key_pressed(KEY_ESCAPE)
	if escape_pressed and not escape_was_pressed:
		shop_panel.visible = false
		guild_panel.visible = false
		habits_panel.visible = false
	escape_was_pressed = escape_pressed


func toggle_shop() -> void:
	guild_panel.visible = false
	habits_panel.visible = false
	shop_panel.visible = not shop_panel.visible


func toggle_guild() -> void:
	shop_panel.visible = false
	habits_panel.visible = false
	guild_panel.visible = not guild_panel.visible


func toggle_habits() -> void:
	shop_panel.visible = false
	guild_panel.visible = false
	habits_panel.visible = not habits_panel.visible


func _on_mute_toggled(pressed: bool) -> void:
	GameState.set_audio_muted(pressed)
	mute_button.text = "🔇" if pressed else "🔊"
	_apply_audio_settings()


func _on_volume_changed(value: float) -> void:
	GameState.set_audio_volume(value)
	_apply_audio_settings()


func _apply_audio_settings() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, GameState.audio_muted)
	var db: float = linear_to_db(GameState.audio_volume) if GameState.audio_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(master_bus, db)


func play_music(which: String) -> void:
	if current_music == which:
		return
	current_music = which
	music_player.stream = MUSIC_TOWN if which == "town" else MUSIC_DUNGEON
	music_player.play()


func play_named_sfx(which: String) -> void:
	match which:
		"hit":
			sfx_player.stream = SFX_HIT
		"coin":
			sfx_player.stream = SFX_COIN
		"levelup":
			sfx_player.stream = SFX_LEVELUP
		_:
			return
	sfx_player.play()


func _build_stat_bars() -> void:
	hp_bar = _make_bar(Color(0.3, 0.85, 0.35))
	xp_bar = _make_bar(Color(0.4, 0.7, 1.0))
	hp_label.add_sibling(hp_bar)
	xp_label.add_sibling(xp_bar)


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.08, 0.9)
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_color
	fg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


## Texto que sobe e some. `world_pos` é posição do mundo (2D); convertida pra tela.
func spawn_float_text(text: String, color: Color, world_pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 18)
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos
	label.position = screen_pos - Vector2(20, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func _player_world_pos() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		return player.global_position + Vector2(0, -50)
	return Vector2.ZERO


func _on_player_damaged(amount: int) -> void:
	if get_tree().get_first_node_in_group("player"):
		spawn_float_text("-%d vida" % amount, Color(1, 0.35, 0.35), _player_world_pos())


func _on_leveled_up(new_level: int) -> void:
	if get_tree().get_first_node_in_group("player"):
		spawn_float_text("Nível %d!" % new_level, Color(1, 0.9, 0.3), _player_world_pos() + Vector2(0, -20))
