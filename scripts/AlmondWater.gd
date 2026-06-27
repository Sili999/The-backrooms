extends Area3D
## Almond Water — das kanonische Überlebens-Item der Backrooms.
## Beim Hineinlaufen stellt es einen Teil des Verstands (Sanity) wieder her.
## Schwebt/dreht sich leicht, damit es im Halbdunkel auffindbar ist.

@export var restore_amount: float = 35.0

var _mesh: Node3D
var _base_y: float = 0.6
var _t: float = 0.0


func _ready() -> void:
	add_to_group("almond_water")
	# Nur den Spieler (Kollisions-Layer 4) erkennen, nichts kollidieren lassen
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	_build_body()
	body_entered.connect(_on_body_entered)


func _build_body() -> void:
	_mesh = Node3D.new()
	_mesh.position = Vector3(0, _base_y, 0)
	add_child(_mesh)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.85, 0.72, 0.85)
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.7, 0.5)
	mat.emission_energy_multiplier = 0.6

	# Flaschenkörper
	var body := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.09
	bm.bottom_radius = 0.10
	bm.height = 0.30
	body.mesh = bm
	body.material_override = mat
	_mesh.add_child(body)

	# Flaschenhals
	var neck := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.035
	nm.bottom_radius = 0.05
	nm.height = 0.12
	neck.mesh = nm
	neck.material_override = mat
	neck.position = Vector3(0, 0.20, 0)
	_mesh.add_child(neck)

	# Erkennungs-Collider (etwas großzügig, damit Aufsammeln sich gut anfühlt)
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	col.position = Vector3(0, _base_y, 0)
	add_child(col)


func _process(delta: float) -> void:
	_t += delta
	if _mesh:
		_mesh.position.y = _base_y + sin(_t * 2.0) * 0.06
		_mesh.rotate_y(delta * 1.5)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.on_almond_water_collected(restore_amount)
	queue_free()
