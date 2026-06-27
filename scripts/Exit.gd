extends Area3D
## Ausgang aus Level 0 — das Ziel des Spiels. Eine leuchtend grüne Türöffnung,
## die als Landmarke heraussticht. Hindurchgehen = Entkommen (Sieg-Loop).

func _ready() -> void:
	add_to_group("exit")
	collision_layer = 0
	collision_mask = 4   # nur den Spieler (Layer 4) erkennen
	monitoring = true
	_build_body()
	body_entered.connect(_on_body_entered)


func _build_body() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.05, 0.05, 0.05)
	frame_mat.roughness = 0.9

	# Türrahmen (zwei Pfosten + Sturz)
	_add_box(Vector3(0.18, 2.4, 0.3), Vector3(-0.7, 1.2, 0), frame_mat)
	_add_box(Vector3(0.18, 2.4, 0.3), Vector3(0.7, 1.2, 0), frame_mat)
	_add_box(Vector3(1.58, 0.22, 0.3), Vector3(0, 2.3, 0), frame_mat)

	# Leuchtende grüne Öffnung (Beacon)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.1, 0.6, 0.2)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 1.0, 0.35)
	glow_mat.emission_energy_multiplier = 2.5
	_add_box(Vector3(1.3, 2.2, 0.06), Vector3(0, 1.15, 0), glow_mat)

	# grünes Licht für Sichtbarkeit in der Ferne
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 1.0, 0.4)
	light.light_energy = 2.0
	light.omni_range = 8.0
	light.position = Vector3(0, 1.6, 0.5)
	add_child(light)

	# Auslöse-Zone
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 2.2, 0.8)
	col.shape = shape
	col.position = Vector3(0, 1.1, 0)
	add_child(col)


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.on_exit_reached()
