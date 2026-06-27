extends CharacterBody3D
## First-Person-Controller: Maus-Look, WASD, Sprint mit Ausdauer, Headbob,
## (optionale) Schrittgeräusche. Kein Kampf — reine Erkundung/Flucht.

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 2.0
@export var mouse_sensitivity: float = 0.0025
@export var accel: float = 12.0
@export var push_strength: float = 2.5     # Impuls, mit dem Props angestoßen werden

@export var stamina_max: float = 100.0
var stamina: float = 100.0
@export var stamina_drain: float = 22.0   # pro Sekunde beim Rennen
@export var stamina_regen: float = 14.0   # pro Sekunde in Ruhe

# Bewegungslärm pro Sekunde (siehe NoiseSystem)
@export var noise_sprint: float = 55.0
@export var noise_walk: float = 12.0
@export var noise_crouch: float = 2.0

const HEAD_HEIGHT_STAND: float = 1.6
const HEAD_HEIGHT_CROUCH: float = 1.15

var _head: Node3D
var _camera: Camera3D
var _footsteps: AudioStreamPlayer

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)
var _bob_time: float = 0.0
var _step_accum: float = 0.0
var _crouching: bool = false


func _ready() -> void:
	add_to_group("player")
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

	# Schleichen / Sprint + Ausdauer
	_crouching = Input.is_action_pressed("crouch")
	var moving := direction.length() > 0.1
	var wants_sprint := Input.is_action_pressed("sprint") and moving and stamina > 0.0 and not _crouching
	var speed := walk_speed
	if wants_sprint:
		speed = sprint_speed
		stamina = maxf(0.0, stamina - stamina_drain * delta)
	else:
		if _crouching:
			speed = crouch_speed
		stamina = minf(stamina_max, stamina + stamina_regen * delta)

	# Horizontale Bewegung mit etwas Beschleunigung
	var target := direction * speed
	velocity.x = lerpf(velocity.x, target.x, accel * delta)
	velocity.z = lerpf(velocity.z, target.z, accel * delta)

	move_and_slide()

	_push_rigid_props()
	_emit_movement_noise(delta, moving, wants_sprint)
	_apply_headbob(delta, moving, speed)
	_handle_footsteps(delta, moving, speed)


func _push_rigid_props() -> void:
	# CharacterBody3D schiebt RigidBodies in Godot 4 nicht automatisch — manuell anstoßen.
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is RigidBody3D:
			var push_dir := -col.get_normal()
			push_dir.y = 0.0
			if push_dir.length() > 0.01:
				(collider as RigidBody3D).apply_central_impulse(push_dir.normalized() * push_strength)


func _emit_movement_noise(delta: float, moving: bool, sprinting: bool) -> void:
	if not (moving and is_on_floor()):
		return
	var rate := noise_walk
	if sprinting:
		rate = noise_sprint
	elif _crouching:
		rate = noise_crouch
	NoiseSystem.emit_noise(global_position, rate * delta)


func _apply_headbob(delta: float, moving: bool, speed: float) -> void:
	var base_y := HEAD_HEIGHT_CROUCH if _crouching else HEAD_HEIGHT_STAND
	if moving and is_on_floor():
		_bob_time += delta * speed * 1.6
		var bob_y := sin(_bob_time) * 0.045
		var bob_x := cos(_bob_time * 0.5) * 0.03
		var target := Vector3(bob_x, base_y + bob_y, 0)
		_head.position = _head.position.lerp(target, delta * 10.0)
	else:
		_head.position = _head.position.lerp(Vector3(0, base_y, 0), delta * 6.0)


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
