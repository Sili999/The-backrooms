extends StaticBody3D
## Versteck (Spind/Schrank). Der Spieler kann per Interaktion (E) hineinsteigen
## und ist für die Entität unsichtbar, bis er wieder herauskommt.
## Solide Geometrie (Welt-Layer 1) — blockiert auch Sicht/Steering der Entität.

func _ready() -> void:
	add_to_group("hideable")
	collision_layer = 1
	collision_mask = 0
	_build_body()


func _build_body() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.24, 0.22)
	mat.metallic = 0.5
	mat.roughness = 0.6

	# Korpus
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.85, 2.0, 0.6)
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = Vector3(0, 1.0, 0)
	add_child(mesh)

	# Tür-Lamellen als dunkle Front (rein optisch)
	var front_mat := StandardMaterial3D.new()
	front_mat.albedo_color = Color(0.10, 0.12, 0.11)
	front_mat.roughness = 0.8
	var front := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(0.78, 1.8, 0.04)
	front.mesh = fbox
	front.material_override = front_mat
	front.position = Vector3(0, 1.0, 0.31)
	add_child(front)

	# Kollision
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.85, 2.0, 0.6)
	col.shape = shape
	col.position = Vector3(0, 1.0, 0)
	add_child(col)
