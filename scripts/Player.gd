extends CharacterBody3D
## First-Person-Controller: Maus-Look, WASD, Sprint mit Ausdauer, Headbob,
## (optionale) Schrittgeräusche. Kein Kampf — reine Erkundung/Flucht.

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var mouse_sensitivity: float = 0.0025
@export var accel: float = 12.0

@export var stamina_max: float = 100.0
var stamina: float = 100.0
@export var stamina_drain: float = 22.0   # pro Sekunde beim Rennen
@export var stamina_regen: float = 14.0   # pro Sekunde in Ruhe

var _head: Node3D
var _camera: Camera3D
var _footsteps: AudioStreamPlayer

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)
var _bob_time: float = 0.0
var _step_accum: float = 0.0


func _ready() -> void:
	_head = $Head
	_camera = $Head/Camera
	_footsteps = get_node_or_null("Footsteps")
	stamina = stamina_max

	# Optionales Schrittgeräusch laden (defensiv)
	if _footsteps:
		var p := "res://assets/audio/footstep_01.ogg"
		if ResourceLoader.exists(p):
			_footsteps.stream = load(p) as AudioStream


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		_head.rotation.x = clampf(_head.rotation.x, -1.4, 1.4)


func _physics_process(delta: float) -> void:
	# Schwerkraft
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	# Eingaberichtung
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Sprint + Ausdauer
	var moving := direction.length() > 0.1
	var wants_sprint := Input.is_action_pressed("sprint") and moving and stamina > 0.0
	var speed := walk_speed
	if wants_sprint:
		speed = sprint_speed
		stamina = maxf(0.0, stamina - stamina_drain * delta)
	else:
		stamina = minf(stamina_max, stamina + stamina_regen * delta)

	# Horizontale Bewegung mit etwas Beschleunigung
	var target := direction * speed
	velocity.x = lerpf(velocity.x, target.x, accel * delta)
	velocity.z = lerpf(velocity.z, target.z, accel * delta)

	move_and_slide()

	_apply_headbob(delta, moving, speed)
	_handle_footsteps(delta, moving, speed)


func _apply_headbob(delta: float, moving: bool, speed: float) -> void:
	if moving and is_on_floor():
		_bob_time += delta * speed * 1.6
		var bob_y := sin(_bob_time) * 0.045
		var bob_x := cos(_bob_time * 0.5) * 0.03
		_head.position = Vector3(bob_x, 1.6 + bob_y, 0)
	else:
		_head.position = _head.position.lerp(Vector3(0, 1.6, 0), delta * 6.0)


func _handle_footsteps(delta: float, moving: bool, speed: float) -> void:
	if not (moving and is_on_floor()):
		return
	if not _footsteps or _footsteps.stream == null:
		return
	_step_accum += delta * speed
	if _step_accum >= 4.5:
		_step_accum = 0.0
		_footsteps.pitch_scale = randf_range(0.9, 1.1)
		_footsteps.play()
