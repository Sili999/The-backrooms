extends CharacterBody3D
## Die Bedrohung von Level 0. Mini-Zustandsautomat:
##   WANDER      – zufälliges Umherwandern
##   INVESTIGATE – auf Lärm reagieren: zur Geräuschquelle gehen und den Umkreis absuchen
##   CHASE       – Spieler in Sichtweite verfolgen (Kontakt → Game Over)
## Kein Kampf möglich — nur Distanz halten, weglaufen, verstecken, LEISE sein.

signal caught_player

enum EState { WANDER, INVESTIGATE, CHASE }

@export var wander_speed: float = 2.2
@export var investigate_speed: float = 3.4
@export var chase_speed: float = 5.2
@export var detection_range: float = 16.0
@export var catch_range: float = 1.4
@export var hearing_radius: float = 22.0      # max. Distanz, in der Lärm die Entität erreicht
@export var investigate_duration: float = 8.0 # Sekunden Suche, bevor zurück zu WANDER

var player: CharacterBody3D
var _state: int = EState.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)
var _wander_dir: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0
var _investigate_pos: Vector3 = Vector3.ZERO
var _investigate_timer: float = 0.0
var _sound: AudioStreamPlayer3D


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

	# --- Zustandsübergänge ---
	if dist < detection_range:
		_state = EState.CHASE
	elif _state == EState.CHASE:
		# Spieler verloren → letzte Position untersuchen
		_state = EState.INVESTIGATE
		_investigate_pos = player.global_position
		_investigate_timer = investigate_duration

	# --- Bewegung nach Zustand ---
	var horizontal := Vector3.ZERO
	match _state:
		EState.CHASE:
			horizontal = to_player.normalized() * chase_speed
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

	# Bei Wandkollision (nicht im Chase) neue Richtung wählen
	if get_slide_collision_count() > 0 and _state == EState.WANDER:
		_pick_new_wander_dir()

	if dist <= catch_range:
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
		# noch unterwegs zur Geräuschquelle
		return to_target.normalized() * investigate_speed
	else:
		# am Ziel angekommen → Umkreis absuchen (gelegentlich Richtung wechseln)
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_pick_new_wander_dir()
		return _wander_dir * wander_speed


func _pick_new_wander_dir() -> void:
	var ang := randf() * TAU
	_wander_dir = Vector3(cos(ang), 0, sin(ang)).normalized()
	_wander_timer = randf_range(2.0, 5.0)
