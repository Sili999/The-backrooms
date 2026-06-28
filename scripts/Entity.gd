extends CharacterBody3D
## Die Bedrohung von Level 0. Mini-Zustandsautomat:
##   WANDER      – zufälliges Umherwandern
##   INVESTIGATE – auf Lärm/letzte Sichtung reagieren: zur Position gehen und absuchen
##   CHASE       – Spieler verfolgen, SOLANGE er gesehen wird (Kontakt → Game Over)
## Kein Kampf möglich — nur Distanz halten, weglaufen, verstecken, LEISE sein.
##
## Erkennung ist sichtlinien-basiert (Raycast + Sichtkegel), nicht durch Wände.
## Verfolgen/Untersuchen nutzt leichtes Whisker-Steering, um Wände zu umgehen.

signal caught_player

enum EState { WANDER, INVESTIGATE, CHASE }

@export var wander_speed: float = 2.2
@export var investigate_speed: float = 3.4
@export var chase_speed: float = 5.2
@export var detection_range: float = 16.0
@export var catch_range: float = 1.4
@export var hearing_radius: float = 22.0      # max. Distanz, in der Lärm die Entität erreicht
@export var investigate_duration: float = 8.0 # Sekunden Suche, bevor zurück zu WANDER

# Sicht & Verhalten
@export var fov_degrees: float = 110.0        # Sichtkegel (gesamt)
@export var close_sense_range: float = 3.0    # Nah-Sinn: spürt/hört Spieler unabhängig von FOV/LoS
@export var lose_memory: float = 2.5          # Sekunden Verfolgen nach Sichtverlust (Hysterese)
@export var eye_height: float = 1.6           # Augenhöhe für Sichtlinien-Raycast
@export var steer_probe: float = 1.8          # Reichweite der Hindernis-Fühler

var player: CharacterBody3D
var _state: int = EState.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)
var _wander_dir: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0
var _investigate_pos: Vector3 = Vector3.ZERO
var _investigate_timer: float = 0.0
var _last_seen_pos: Vector3 = Vector3.ZERO
var _lose_timer: float = 0.0
var _sound: AudioStreamPlayer3D
var _alert: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("entity")
	_build_body()
	_sound = get_node_or_null("Sound")
	if _sound:
		var p := "res://assets/audio/entity_ambient.ogg"
		if ResourceLoader.exists(p):
			var stream := load(p) as AudioStream
			_sound.stream = stream
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			_sound.play()
	# Alarm-Knurren (einmalig beim Aufnehmen der Verfolgung)
	_alert = AudioStreamPlayer3D.new()
	_alert.max_distance = 30.0
	_alert.unit_size = 8.0
	add_child(_alert)
	var ap := "res://assets/audio/entity_alert.ogg"
	if ResourceLoader.exists(ap):
		_alert.stream = load(ap) as AudioStream

	# Auf Lärm-Alarme des Geräusch-Systems hören
	NoiseSystem.alarm_triggered.connect(_on_alarm)
	_pick_new_wander_dir()


func _build_body() -> void:
	# Schlanke, dunkle humanoide Silhouette als Platzhalter-Mesh
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.9
	mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.05)
	mat.roughness = 1.0
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.95, 0)
	add_child(mesh)


func _on_alarm(pos: Vector3, _loudness: float) -> void:
	# Beim Verfolgen ignorieren; sonst nur, wenn der Lärm nah genug ist.
	if _state == EState.CHASE:
		return
	if global_position.distance_to(pos) <= hearing_radius:
		_state = EState.INVESTIGATE
		_investigate_pos = pos
		_investigate_timer = investigate_duration


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	# --- Erkennung (Sichtlinie + Sichtkegel) mit Hysterese ---
	var seen := _can_see_player()
	if seen:
		# Beim erstmaligen Erfassen (nicht schon im CHASE) knurren
		if _state != EState.CHASE and _alert and _alert.stream and not _alert.playing:
			_alert.play()
		_state = EState.CHASE
		_last_seen_pos = player.global_position
		_lose_timer = lose_memory
	elif _state == EState.CHASE:
		# Sicht verloren → kurzes Gedächtnis, dann letzte Position untersuchen
		_lose_timer -= delta
		if _lose_timer <= 0.0:
			_state = EState.INVESTIGATE
			_investigate_pos = _last_seen_pos
			_investigate_timer = investigate_duration

	# --- Bewegung nach Zustand ---
	var horizontal := Vector3.ZERO
	match _state:
		EState.CHASE:
			# Bei Sicht zum Spieler, sonst zur letzten bekannten Position
			var target := player.global_position if seen else _last_seen_pos
			var to_target := target - global_position
			to_target.y = 0.0
			horizontal = _steer_toward(to_target.normalized()) * chase_speed
			if _sound:
				_sound.unit_size = 6.0
		EState.INVESTIGATE:
			horizontal = _update_investigate(delta)
			if _sound:
				_sound.unit_size = 3.0
		_:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_pick_new_wander_dir()
			horizontal = _wander_dir * wander_speed
			if _sound:
				_sound.unit_size = 1.0

	velocity.x = horizontal.x
	velocity.z = horizontal.z

	# Zur Laufrichtung ausrichten
	var look := horizontal
	look.y = 0.0
	if look.length() > 0.05:
		var t := global_position + look
		look_at(Vector3(t.x, global_position.y, t.z), Vector3.UP)

	move_and_slide()

	# Bei Wandkollision (nur Wandern) neue Richtung wählen
	if get_slide_collision_count() > 0 and _state == EState.WANDER:
		_pick_new_wander_dir()

	if dist <= catch_range and not player.get("hidden"):
		emit_signal("caught_player")


func _update_investigate(delta: float) -> Vector3:
	_investigate_timer -= delta
	if _investigate_timer <= 0.0:
		_state = EState.WANDER
		_pick_new_wander_dir()
		return _wander_dir * wander_speed

	var to_target := _investigate_pos - global_position
	to_target.y = 0.0
	if to_target.length() > 2.0:
		# noch unterwegs zur Position → Wände umgehen
		return _steer_toward(to_target.normalized()) * investigate_speed
	else:
		# am Ziel angekommen → Umkreis absuchen (gelegentlich Richtung wechseln)
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_pick_new_wander_dir()
		return _wander_dir * wander_speed


# --- Sichtprüfung -----------------------------------------------------------
func _can_see_player() -> bool:
	# Versteckter Spieler ist unsichtbar (auch für den Nah-Sinn)
	if player.get("hidden"):
		return false

	var to_p := player.global_position - global_position
	var flat := Vector3(to_p.x, 0.0, to_p.z)
	var d := flat.length()

	# Nah-Sinn: sehr nah wird der Spieler immer bemerkt (kein lautloses Vorbei)
	if d <= close_sense_range:
		return true
	if d > detection_range:
		return false

	# Sichtkegel
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return false
	forward = forward.normalized()
	if forward.dot(flat.normalized()) < cos(deg_to_rad(fov_degrees * 0.5)):
		return false

	return _has_line_of_sight()


func _has_line_of_sight() -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var eye := global_position + Vector3(0, eye_height, 0)
	var target := player.global_position + Vector3(0, eye_height * 0.9, 0)
	var q := PhysicsRayQueryParameters3D.create(eye, target, 1, [get_rid()])
	var hit := space.intersect_ray(q)
	return hit.is_empty()   # kein Treffer auf Welt-Layer 1 ⇒ freie Sicht


# --- Whisker-Steering: Wände umgehen ---------------------------------------
func _steer_toward(desired: Vector3) -> Vector3:
	if desired.length() < 0.01:
		return Vector3.ZERO
	var space := get_world_3d().direct_space_state
	if space == null:
		return desired
	var origin := global_position + Vector3(0, 0.6, 0)
	# Wunschrichtung zuerst, dann zunehmend ausweichende Winkel
	for a in [0.0, 35.0, -35.0, 70.0, -70.0]:
		var dir := desired.rotated(Vector3.UP, deg_to_rad(a))
		var to := origin + dir * steer_probe
		var q := PhysicsRayQueryParameters3D.create(origin, to, 1, [get_rid()])
		if space.intersect_ray(q).is_empty():
			return dir
	# alles blockiert → Wunschrichtung behalten (move_and_slide gleitet an Wand)
	return desired


func _pick_new_wander_dir() -> void:
	var ang := randf() * TAU
	_wander_dir = Vector3(cos(ang), 0, sin(ang)).normalized()
	_wander_timer = randf_range(2.0, 5.0)
