extends Node3D
## GameManager — Orchestriert das gesamte Spiel:
## Eingabe-Aktionen, WorldEnvironment (Nebel/Atmosphäre), UI (Menü/HUD/Tod),
## Instanziierung von Spieler, Raum-Generator, Entität und Sanity-System.
## Bewusst Code-lastig, damit die .tscn-Dateien schlank und robust bleiben.

enum State { MENU, PLAYING, PAUSED, DEAD }

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENTITY_SCENE := preload("res://scenes/Entity.tscn")

var state: int = State.MENU

var player: CharacterBody3D
var room_generator: Node3D
var entity: CharacterBody3D
var sanity: Node

# UI-Referenzen
var ui_layer: CanvasLayer
var menu_panel: Control
var hud: Control
var death_panel: Control
var pause_panel: Control
var stamina_bar: ColorRect
var sanity_bar: ColorRect
var vignette: ColorRect
var hum_player: AudioStreamPlayer
var stinger_player: AudioStreamPlayer


func _ready() -> void:
	# Auch während get_tree().paused weiter Eingaben/Updates erhalten,
	# damit Esc die Pause wieder aufheben kann.
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input()
	_build_environment()
	_build_ui()
	_build_ambient_audio()
	_show_menu()


# ---------------------------------------------------------------------------
# Eingabe-Aktionen zur Laufzeit registrieren (hält project.godot schlank)
# ---------------------------------------------------------------------------
func _setup_input() -> void:
	_add_action("move_forward", [KEY_W, KEY_UP])
	_add_action("move_back", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("interact", [KEY_E])
	_add_key_action("sprint", KEY_SHIFT)
	_add_key_action("pause", KEY_ESCAPE)


func _add_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_key_action(action: String, key: int) -> void:
	_add_action(action, [key])


# ---------------------------------------------------------------------------
# Atmosphäre: WorldEnvironment mit gelblichem Nebel, Glow, niedrigem Ambient
# ---------------------------------------------------------------------------
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.0)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.46, 0.28)
	env.ambient_light_energy = 0.35

	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.57, 0.34)
	env.fog_light_energy = 1.0
	env.fog_density = 0.05
	env.fog_sky_affect = 0.0

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05

	we.environment = env
	add_child(we)


# ---------------------------------------------------------------------------
# Dauer-Brummen (lädt CC0-Asset, falls vorhanden — sonst stiller Platzhalter)
# ---------------------------------------------------------------------------
func _build_ambient_audio() -> void:
	hum_player = AudioStreamPlayer.new()
	hum_player.bus = "Master"
	var path := "res://assets/audio/hum_loop.ogg"
	if ResourceLoader.exists(path):
		var stream := load(path)
		hum_player.stream = stream
		# Schleife sicherstellen, falls das Asset es unterstützt:
		if stream is AudioStreamOggVorbis:
			stream.loop = true
	add_child(hum_player)

	# Tod-/Schreck-Stinger (one-shot)
	stinger_player = AudioStreamPlayer.new()
	var sp := "res://assets/audio/stinger.ogg"
	if ResourceLoader.exists(sp):
		stinger_player.stream = load(sp)
	add_child(stinger_player)


# ---------------------------------------------------------------------------
# UI komplett im Code aufgebaut (Menü / HUD / Pause / Tod)
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# --- HUD ---
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)

	# Fadenkreuz
	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 22)
	cross.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-7, -16)
	hud.add_child(cross)

	# Stamina-Leiste
	hud.add_child(_make_label("AUSDAUER", Vector2(24, -64), Control.PRESET_BOTTOM_LEFT))
	stamina_bar = _make_bar(Vector2(24, -44), Color(0.4, 0.8, 1.0), Control.PRESET_BOTTOM_LEFT)
	hud.add_child(_bar_bg(stamina_bar))
	hud.add_child(stamina_bar)

	# Sanity-Leiste
	hud.add_child(_make_label("VERSTAND", Vector2(24, -104), Control.PRESET_BOTTOM_LEFT))
	sanity_bar = _make_bar(Vector2(24, -84), Color(0.8, 0.3, 0.3), Control.PRESET_BOTTOM_LEFT)
	hud.add_child(_bar_bg(sanity_bar))
	hud.add_child(sanity_bar)

	# Tunnelblick-Vignette (verdunkelt bei niedrigem Verstand)
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(vignette)

	# --- Startmenü ---
	menu_panel = _make_overlay("THE BACKROOMS",
		"Level 0\n\n[ Enter ] oder Klick — Eintreten\n\nWASD bewegen  ·  Maus sehen  ·  Shift rennen  ·  Esc Pause")
	ui_layer.add_child(menu_panel)

	# --- Pause ---
	pause_panel = _make_overlay("PAUSE", "[ Esc ] — Fortsetzen")
	pause_panel.visible = false
	ui_layer.add_child(pause_panel)

	# --- Tod ---
	death_panel = _make_overlay("ES HAT DICH GEFUNDEN",
		"Du bist in den Backrooms verloren.\n\n[ Enter ] — Erneut versuchen")
	death_panel.visible = false
	ui_layer.add_child(death_panel)


func _make_label(text: String, offset: Vector2, preset: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 0.8))
	l.set_anchors_preset(preset)
	l.position = offset
	return l


func _make_bar(offset: Vector2, color: Color, preset: int) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = color
	bar.set_anchors_preset(preset)
	bar.position = offset
	bar.size = Vector2(220, 12)
	return bar


func _bar_bg(bar: ColorRect) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bg.position = bar.position - Vector2(2, 2)
	bg.size = Vector2(224, 16)
	return bg


func _make_overlay(title: String, body: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.0, 0.92)
	root.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-260, -90)
	vbox.custom_minimum_size = Vector2(520, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.35))
	vbox.add_child(title_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer)

	var body_label := Label.new()
	body_label.text = body
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	vbox.add_child(body_label)

	return root


# ---------------------------------------------------------------------------
# Zustands-Übergänge
# ---------------------------------------------------------------------------
func _show_menu() -> void:
	state = State.MENU
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_panel.visible = true
	hud.visible = false
	pause_panel.visible = false
	death_panel.visible = false


func start_game() -> void:
	# Falls Neustart: alte Welt entfernen
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(room_generator):
		room_generator.queue_free()
	if is_instance_valid(entity):
		entity.queue_free()
	if is_instance_valid(sanity):
		sanity.queue_free()

	# Spieler
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = Vector3(0, 1.2, 0)

	# Raum-Generator
	room_generator = preload("res://scripts/RoomGenerator.gd").new()
	room_generator.name = "RoomGenerator"
	add_child(room_generator)
	room_generator.set("player", player)

	# Verstand-System
	sanity = preload("res://scripts/Sanity.gd").new()
	sanity.name = "Sanity"
	add_child(sanity)

	# Entität (mit leichtem Versatz starten lassen)
	entity = ENTITY_SCENE.instantiate()
	add_child(entity)
	entity.global_position = Vector3(0, 1.0, -24)
	entity.set("player", player)
	if entity.has_signal("caught_player"):
		entity.connect("caught_player", Callable(self, "_on_player_caught"))

	# Brummen starten
	if hum_player and hum_player.stream:
		hum_player.play()

	state = State.PLAYING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	menu_panel.visible = false
	pause_panel.visible = false
	death_panel.visible = false
	hud.visible = true


func _on_player_caught() -> void:
	if state != State.PLAYING:
		return
	_game_over()


func _game_over() -> void:
	state = State.DEAD
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.visible = false
	death_panel.visible = true
	if hum_player and hum_player.playing:
		hum_player.stop()
	if stinger_player and stinger_player.stream:
		stinger_player.play()


func _toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_panel.visible = true
	elif state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		pause_panel.visible = false


# ---------------------------------------------------------------------------
# Eingabe & Update
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING or state == State.PAUSED:
			_toggle_pause()
		return

	var confirm := (event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)) \
			or (event is InputEventMouseButton and event.pressed)

	if not confirm:
		return

	if state == State.MENU:
		start_game()
	elif state == State.DEAD:
		start_game()


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	if not is_instance_valid(player):
		return

	var entity_dist := 999.0
	if is_instance_valid(entity):
		entity_dist = player.global_position.distance_to(entity.global_position)

	# Verstand aktualisieren
	if is_instance_valid(sanity):
		sanity.update_sanity(delta, entity_dist)
		var s: float = sanity.get("value")
		sanity_bar.size.x = 220.0 * clampf(s / 100.0, 0.0, 1.0)
		vignette.color.a = (1.0 - clampf(s / 100.0, 0.0, 1.0)) * 0.65
		if s <= 0.0:
			_game_over()

	# Ausdauer-Anzeige
	var stam: float = player.get("stamina")
	var stam_max: float = player.get("stamina_max")
	if stam_max > 0.0:
		stamina_bar.size.x = 220.0 * clampf(stam / stam_max, 0.0, 1.0)
