extends Node3D
## Prozeduraler, endloser Raum-Generator im Backrooms-Level-0-Stil.
## Chunk-/Grid-basiert: generiert modulare Boden-, Decken-, Wand- und Lampen-
## Segmente um den Spieler herum und gibt entfernte Chunks wieder frei.
## Deterministisch geseedet → "déjà-vu", aber nie exakt gleich.

@export var tile_size: float = 4.0      # Kantenlänge einer Zelle (m)
@export var chunk_cells: int = 4        # Zellen pro Chunk-Seite
@export var wall_height: float = 3.0
@export var view_radius: int = 2        # geladene Chunks um den Spieler (in jede Richtung)
@export var wall_density: float = 0.42  # Anteil Zellen mit Wandsegment
@export var prop_density: float = 0.07  # Anteil leerer Zellen mit umstoßbarem Prop
@export var almond_density: float = 0.03 # Anteil leerer Zellen mit Almond Water
@export var world_seed: int = 1337

var player: CharacterBody3D
var _chunks: Dictionary = {}            # Vector2i -> Node3D

var _mat_wall: StandardMaterial3D
var _mat_floor: StandardMaterial3D
var _mat_ceiling: StandardMaterial3D
var _mat_light: StandardMaterial3D

const FLICKER := preload("res://scripts/FlickerLight.gd")
const PROP := preload("res://scripts/KnockableProp.gd")
const ALMOND := preload("res://scripts/AlmondWater.gd")


func _ready() -> void:
	world_seed = randi()
	_build_materials()


func _build_materials() -> void:
	_mat_wall = _make_material(Color(0.80, 0.74, 0.34), "res://assets/textures/wallpaper_yellow.png", 2.0)
	_mat_floor = _make_material(Color(0.52, 0.47, 0.29), "res://assets/textures/carpet.png", 4.0)
	_mat_ceiling = _make_material(Color(0.70, 0.67, 0.52), "res://assets/textures/ceiling.png", 4.0)

	_mat_light = StandardMaterial3D.new()
	_mat_light.albedo_color = Color(1.0, 0.98, 0.85)
	_mat_light.emission_enabled = true
	_mat_light.emission = Color(1.0, 0.96, 0.8)
	_mat_light.emission_energy_multiplier = 3.0


func _make_material(color: Color, tex_path: String, uv_scale: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	m.metallic = 0.0
	if ResourceLoader.exists(tex_path):
		m.albedo_texture = load(tex_path) as Texture2D
		m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	return m


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var cw := chunk_cells * tile_size
	var pc := Vector2i(
		int(floor(player.global_position.x / cw)),
		int(floor(player.global_position.z / cw))
	)

	# Fehlende Chunks im Sichtbereich erzeugen
	for dx in range(-view_radius, view_radius + 1):
		for dz in range(-view_radius, view_radius + 1):
			var key := Vector2i(pc.x + dx, pc.y + dz)
			if not _chunks.has(key):
				_chunks[key] = _generate_chunk(key)

	# Entfernte Chunks freigeben
	for key in _chunks.keys():
		if abs(key.x - pc.x) > view_radius + 1 or abs(key.y - pc.y) > view_radius + 1:
			var node: Node = _chunks[key]
			if is_instance_valid(node):
				node.queue_free()
			_chunks.erase(key)


func _generate_chunk(coord: Vector2i) -> Node3D:
	var cw := chunk_cells * tile_size
	var chunk := Node3D.new()
	chunk.name = "chunk_%d_%d" % [coord.x, coord.y]
	add_child(chunk)
	var origin := Vector3(coord.x * cw, 0.0, coord.y * cw)
	var center := origin + Vector3(cw * 0.5, 0.0, cw * 0.5)

	# Boden (mit Kollision)
	chunk.add_child(_make_box(
		Vector3(cw, 0.2, cw), center + Vector3(0, -0.1, 0), _mat_floor, true))
	# Decke (ohne Kollision nötig)
	chunk.add_child(_make_box(
		Vector3(cw, 0.2, cw), center + Vector3(0, wall_height + 0.1, 0), _mat_ceiling, false))

	# Zellen: Wände, Pfeiler, Lampen
	for ix in range(chunk_cells):
		for iz in range(chunk_cells):
			var cell_seed := _cell_seed(coord.x * chunk_cells + ix, coord.y * chunk_cells + iz)
			var rng := RandomNumberGenerator.new()
			rng.seed = cell_seed
			var cell_center := origin + Vector3(
				(ix + 0.5) * tile_size, 0.0, (iz + 0.5) * tile_size)

			var r := rng.randf()
			if r < wall_density:
				# Wandsegment, zufällig entlang X oder Z ausgerichtet
				var along_x := rng.randf() < 0.5
				var size: Vector3
				if along_x:
					size = Vector3(tile_size, wall_height, 0.25)
				else:
					size = Vector3(0.25, wall_height, tile_size)
				chunk.add_child(_make_box(
					size, cell_center + Vector3(0, wall_height * 0.5, 0), _mat_wall, true))
			elif r < wall_density + 0.10:
				# gelegentlich ein Pfeiler
				chunk.add_child(_make_box(
					Vector3(0.5, wall_height, 0.5),
					cell_center + Vector3(0, wall_height * 0.5, 0), _mat_wall, true))

			elif rng.randf() < prop_density:
				# leere Zelle: gelegentlich ein umstoßbares Objekt
				_add_prop(chunk, cell_center, rng)
			elif rng.randf() < almond_density:
				# leere Zelle: selten Almond Water
				_add_almond_water(chunk, cell_center)

			# Deckenlampe in regelmäßigem Raster
			var gx := coord.x * chunk_cells + ix
			var gz := coord.y * chunk_cells + iz
			if (gx % 2 == 0) and (gz % 2 == 0):
				_add_ceiling_light(chunk, cell_center)

	return chunk


func _make_box(size: Vector3, pos: Vector3, mat: Material, with_collision: bool) -> Node3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos

	if not with_collision:
		return mesh

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	mesh.position = Vector3.ZERO
	body.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _add_ceiling_light(parent: Node3D, cell_center: Vector3) -> void:
	# emissives Panel
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.4, 0.06, 0.5)
	panel.mesh = pm
	panel.material_override = _mat_light
	panel.position = cell_center + Vector3(0, wall_height - 0.05, 0)
	parent.add_child(panel)

	# flackerndes Licht
	var light := FLICKER.new()
	light.position = cell_center + Vector3(0, wall_height - 0.3, 0)
	light.omni_range = tile_size * 2.6
	light.light_color = Color(1.0, 0.96, 0.82)
	light.base_energy = 1.8
	light.light_energy = 1.8
	light.shadow_enabled = false
	parent.add_child(light)


func _add_almond_water(parent: Node3D, cell_center: Vector3) -> void:
	var item = ALMOND.new()
	item.position = cell_center
	parent.add_child(item)


func _add_prop(parent: Node3D, cell_center: Vector3, rng: RandomNumberGenerator) -> void:
	var prop = PROP.new()
	prop.kind = 1 if rng.randf() < 0.4 else 0
	prop.position = cell_center + Vector3(
		rng.randf_range(-1.0, 1.0), 0.4, rng.randf_range(-1.0, 1.0))
	parent.add_child(prop)


func _cell_seed(gx: int, gz: int) -> int:
	# deterministischer Hash aus globalen Zellkoordinaten + Welt-Seed
	var h := world_seed
	h = (h * 73856093) ^ (gx * 19349663) ^ (gz * 83492791)
	return abs(h)
