extends CharacterBody3D
## Die Bedrohung von Level 0: wandert zufällig umher und verfolgt den Spieler,
## sobald er in Reichweite ist. Kontakt → Game Over. Kein Kampf möglich —
## nur Distanz halten, weglaufen, verstecken.

signal caught_player

@export var wander_speed: float = 2.2
@export var chase_speed: float = 5.2
@export var detection_range: float = 16.0
@export var catch_range: float = 1.4

var player: CharacterBody3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 14.0)
var _wander_dir: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0
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

	var horizontal: Vector3
	if dist < detection_range:
		# Verfolgen
		horizontal = to_player.normalized() * chase_speed
		# der Spieler hört die Bedrohung näherkommen
		if _sound and dist < detection_range:
			_sound.unit_size = 6.0
	else:
		# Wandern
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_pick_new_wander_dir()
		horizontal = _wander_dir * wander_speed

	velocity.x = horizontal.x
	velocity.z = horizontal.z

	# Zum Spieler/zur Laufrichtung ausrichten
	var look := horizontal
	look.y = 0.0
	if look.length() > 0.05:
		var target := global_position + look
		look_at(Vector3(target.x, global_position.y, target.z), Vector3.UP)

	move_and_slide()

	# Bei Kollision mit Wand neue Wanderrichtung wählen
	if get_slide_collision_count() > 0 and dist >= detection_range:
		_pick_new_wander_dir()

	if dist <= catch_range:
		emit_signal("caught_player")


func _pick_new_wander_dir() -> void:
	var ang := randf() * TAU
	_wander_dir = Vector3(cos(ang), 0, sin(ang)).normalized()
	_wander_timer = randf_range(2.0, 5.0)
