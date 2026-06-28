extends RigidBody3D
## Umstoßbares Physik-Objekt (Kiste/Dose/Eimer). Wird der Prop angestoßen und
## bewegt sich schneller als ein Schwellwert, meldet er einen Geräuschausschlag
## an das NoiseSystem und spielt einen 3D-Aufprallsound.

@export var noise_amount: float = 50.0
@export var motion_threshold: float = 1.2   # Mindestgeschwindigkeit für "angestoßen"
@export var report_cooldown: float = 0.6
@export var kind: int = 0                    # 0 = Kiste, 1 = Dose/Zylinder

var _cooldown: float = 0.0
var _impact: AudioStreamPlayer3D
var _noise: Node   # Laufzeit-Referenz aufs Geräusch-Singleton


func _ready() -> void:
	add_to_group("prop")
	_noise = get_tree().get_first_node_in_group("noise_system")
	can_sleep = true
	mass = 2.0
	collision_layer = 1
	collision_mask = 1
	_build_body()
	_impact = AudioStreamPlayer3D.new()
	_impact.max_distance = 28.0
	add_child(_impact)
	var p := "res://assets/audio/prop_impact.ogg"
	if ResourceLoader.exists(p):
		_impact.stream = load(p) as AudioStream


func _build_body() -> void:
	var mesh := MeshInstance3D.new()
	var shape := CollisionShape3D.new()
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9

	if kind == 1:
		# Dose / kleiner Zylinder
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.18
		cyl.bottom_radius = 0.18
		cyl.height = 0.42
		mesh.mesh = cyl
		var cs := CylinderShape3D.new()
		cs.radius = 0.18
		cs.height = 0.42
		shape.shape = cs
		mat.albedo_color = Color(0.45, 0.42, 0.30)
	else:
		# Pappkiste
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.5, 0.5)
		mesh.mesh = box
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.5, 0.5, 0.5)
		shape.shape = bs
		mat.albedo_color = Color(0.55, 0.43, 0.26)

	mesh.material_override = mat
	add_child(mesh)
	add_child(shape)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	var spd := linear_velocity.length()
	if spd > motion_threshold and _cooldown <= 0.0:
		_cooldown = report_cooldown
		var loud := noise_amount * clampf(spd / 4.0, 0.4, 1.5)
		if _noise:
			_noise.emit_noise(global_position, loud)
		if _impact and _impact.stream:
			_impact.pitch_scale = randf_range(0.9, 1.15)
			_impact.play()
