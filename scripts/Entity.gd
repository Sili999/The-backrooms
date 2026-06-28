extends CharacterBody3D
## Die Bedrohung von Level 0 — ein STALKER.
##
## Zustände:
##   WANDER – zielloses Umherwandern (leises Ambient)
##   STALK  – LAUTLOS hinter den Spieler pirschen; erfriert, sobald der Spieler
##            hinschaut (Weeping-Angel-Prinzip)
##   REVEAL – steht hinter dem Spieler -> lauter Schrei + kurze reglose Pause
##   CHASE  – ERST DANACH schnelle, hörbare Verfolgung
##
## Wissen über den Spieler:
##   - grob  (über Lärm-Alarm, distanzunabhängig, mit Streuung)
##   - exakt (nur bei tatsächlicher Sichtlinie)
## Kein Kampf — nur Distanz halten, weglaufen, verstecken, LEISE sein.

signal caught_player

enum EState { WANDER, STALK, REVEAL, CHASE }

@export var wander_speed: float = 2.2
@export var stalk_speed: float = 2.6
@export var chase_speed: float = 5.2
@export var catch_range: float = 1.4

@export var detection_range: float = 16.0     # max. Reichweite für EXAKTE Ortung (Sichtlinie)
@export var close_sense_range: float = 3.0     # Nah-Sinn: spürt den Spieler unabhängig von Sicht
@export var fov_degrees: float = 160.0         # weiter Sichtkegel der Entität
@export var eye_height: float = 1.6
@export var steer_probe: float = 1.8

@export var stalk_distance: float = 3.5        # Abstand hinter dem Spieler beim Pirschen
@export var reveal_distance: float = 3.8       # Nähe, ab der der Schreck ausgelöst wird
@export var player_fov_degrees: float = 100.0  # „schaut der Spieler her?"
@export var stalk_timeout: float = 12.0        # spätestens dann Schreck (falls Spieler ständig dreht)
@export var reveal_pause: float = 0.7          # reglose Schreck-Pause vor der Jagd
@export var lose_memory: float = 4.0           # Gedächtnis nach Sichtverlust
@export var position_uncertainty: float = 4.0  # Streuung der grob bekannten Position (Lärm)
@export var freeze_when_seen: bool = true

var player: CharacterBody3D
var _state: int = EState.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)

var _aware: bool = false
var _has_exact: bool = false
var _known_pos: Vector3 = Vector3.ZERO
var _lose_timer: float = 0.0

var _wander_dir: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0
var _stalk_timer: float = 0.0
var _reveal_timer: float = 0.0

var _sound: AudioStreamPlayer3D
var _alert: AudioStreamPlayer3D
var _noise: Node


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

	_alert = AudioStreamPlayer3D.new()
	_alert.max_distance = 40.0
	_alert.unit_size = 10.0
	add_child(_alert)
	var ap := "res://assets/audio/entity_alert.ogg"
	if ResourceLoader.exists(ap):
		_alert.stream = load(ap) as AudioStream

	_noise = get_tree().get_first_node_in_group("noise_system")
	if _noise:
		_noise.alarm_triggered.connect(_on_alarm)
	_pick_new_wander_dir()


func _build_body() -> void:
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


# ---------------------------------------------------------------------------
# Lärm-Alarm: distanzUNabhängig (Ziel 1). Setzt nur eine GROBE Position.
# ---------------------------------------------------------------------------
func _on_alarm(pos: Vector3, _loudness: float) -> void:
	if _state == EState.CHASE or _state == EState.REVEAL:
		return
	_aware = true
	_has_exact = false
	var jitter := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if jitter.length() > 0.01:
		jitter = jitter.normalized() * randf_range(0.0, position_uncertainty)
	_known_pos = pos + jitter
	if _state == EState.WANDER:
		_enter_stalk()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	# --- Wahrnehmung: exakte Ortung nur bei Sichtlinie ---
	if _can_see_exact():
		_aware = true
		_has_exact = true
		_known_pos = player.global_position
		_lose_timer = lose_memory
	else:
		_has_exact = false
		if _lose_timer > 0.0:
			_lose_timer -= delta

	match _state:
		EState.STALK:
			_do_stalk(delta)
		EState.REVEAL:
			_do_reveal(delta)
		EState.CHASE:
			_do_chase(delta)
		_:
			_do_wander(delta)

	# Ausrichtung: normalerweise zur Laufrichtung; beim Schreck zum Spieler
	var face := Vector3(velocity.x, 0.0, velocity.z)
	if _state == EState.REVEAL:
		var fd := player.global_position - global_position
		fd.y = 0.0
		if fd.length() > 0.05:
			face = fd
	if face.length() > 0.05:
		var t := global_position + face
		look_at(Vector3(t.x, global_position.y, t.z), Vector3.UP)

	move_and_slide()

	if _flat_dist(player.global_position) <= catch_range and not player.get("hidden"):
		emit_signal("caught_player")


# ---------------------------------------------------------------------------
# Zustände
# ---------------------------------------------------------------------------
func _do_wander(_delta: float) -> void:
	_set_presence(1.0)
	if _aware:
		_enter_stalk()
		return
	_wander_timer -= _delta
	if _wander_timer <= 0.0:
		_pick_new_wander_dir()
	velocity.x = _wander_dir.x * wander_speed
	velocity.z = _wander_dir.z * wander_speed
	if get_slide_collision_count() > 0:
		_pick_new_wander_dir()


func _do_stalk(delta: float) -> void:
	_set_presence(0.1)   # LAUTLOS
	if not _aware:
		velocity.x = 0.0
		velocity.z = 0.0
		_enter_wander()
		return

	_stalk_timer += delta

	# Erfrieren, sobald der Spieler herschaut
	if freeze_when_seen and _player_sees_entity():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var target: Vector3
	if _has_exact:
		target = _behind_target()
		if _flat_dist(player.global_position) <= reveal_distance and _in_rear_arc() and not _player_sees_entity():
			_enter_reveal()
			return
		if _stalk_timer >= stalk_timeout:
			_enter_reveal()
			return
	else:
		target = _known_pos
		if _flat_dist(_known_pos) < 2.0:
			# grobe Stelle erreicht, kein Sichtkontakt -> Spur kalt
			_aware = false
			velocity.x = 0.0
			velocity.z = 0.0
			_enter_wander()
			return

	var dir := target - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var h := _steer_toward(dir.normalized()) * stalk_speed
	velocity.x = h.x
	velocity.z = h.z


func _do_reveal(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_reveal_timer -= delta
	if _reveal_timer <= 0.0:
		_state = EState.CHASE


func _do_chase(_delta: float) -> void:
	_set_presence(6.0)
	if not _has_exact and _lose_timer <= 0.0:
		_enter_stalk()   # verloren -> wieder lautlos pirschen
		return
	var target := player.global_position if _has_exact else _known_pos
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		return
	var h := _steer_toward(dir.normalized()) * chase_speed
	velocity.x = h.x
	velocity.z = h.z


func _enter_wander() -> void:
	_state = EState.WANDER
	_pick_new_wander_dir()


func _enter_stalk() -> void:
	_state = EState.STALK
	_stalk_timer = 0.0


func _enter_reveal() -> void:
	_state = EState.REVEAL
	_reveal_timer = reveal_pause
	_set_presence(6.0)
	if _alert and _alert.stream and not _alert.playing:
		_alert.play()


# ---------------------------------------------------------------------------
# Wahrnehmung & Geometrie
# ---------------------------------------------------------------------------
func _can_see_exact() -> bool:
	if player.get("hidden"):
		return false
	var to_p := player.global_position - global_position
	var flat := Vector3(to_p.x, 0.0, to_p.z)
	var d := flat.length()
	if d <= close_sense_range:
		return true
	if d > detection_range:
		return false
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		return false
	if fwd.normalized().dot(flat.normalized()) < cos(deg_to_rad(fov_degrees * 0.5)):
		return false
	return _los_between(global_position + Vector3(0, eye_height, 0),
		player.global_position + Vector3(0, eye_height * 0.9, 0))


func _player_sees_entity() -> bool:
	var pf := -player.global_transform.basis.z
	pf.y = 0.0
	if pf.length() < 0.01:
		return false
	pf = pf.normalized()
	var to_e := global_position - player.global_position
	to_e.y = 0.0
	if to_e.length() < 0.01:
		return true
	if pf.dot(to_e.normalized()) < cos(deg_to_rad(player_fov_degrees * 0.5)):
		return false
	return _los_between(player.global_position + Vector3(0, eye_height, 0),
		global_position + Vector3(0, eye_height, 0))


func _behind_target() -> Vector3:
	var pf := -player.global_transform.basis.z
	pf.y = 0.0
	if pf.length() < 0.01:
		pf = Vector3.FORWARD
	pf = pf.normalized()
	return player.global_position - pf * stalk_distance


func _in_rear_arc() -> bool:
	var pf := -player.global_transform.basis.z
	pf.y = 0.0
	if pf.length() < 0.01:
		return true
	pf = pf.normalized()
	var to_e := global_position - player.global_position
	to_e.y = 0.0
	if to_e.length() < 0.01:
		return true
	return pf.dot(to_e.normalized()) < -0.2   # Entität im Rücken des Spielers


func _los_between(a: Vector3, b: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return true
	var q := PhysicsRayQueryParameters3D.create(a, b, 1, [get_rid()])
	return space.intersect_ray(q).is_empty()


func _steer_toward(desired: Vector3) -> Vector3:
	if desired.length() < 0.01:
		return Vector3.ZERO
	var space := get_world_3d().direct_space_state
	if space == null:
		return desired
	var origin := global_position + Vector3(0, 0.6, 0)
	for a in [0.0, 35.0, -35.0, 70.0, -70.0]:
		var dir := desired.rotated(Vector3.UP, deg_to_rad(a))
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * steer_probe, 1, [get_rid()])
		if space.intersect_ray(q).is_empty():
			return dir
	return desired


func _set_presence(v: float) -> void:
	if _sound:
		_sound.unit_size = v


func _flat_dist(p: Vector3) -> float:
	return Vector3(global_position.x - p.x, 0.0, global_position.z - p.z).length()


func _pick_new_wander_dir() -> void:
	var ang := randf() * TAU
	_wander_dir = Vector3(cos(ang), 0, sin(ang)).normalized()
	_wander_timer = randf_range(2.0, 5.0)
