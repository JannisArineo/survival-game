extends Node3D

const CHUNK_SIZE = 32
const QUAD_SIZE = 2.0
const MAX_HEIGHT = 25.0

var chunk_x: int = 0
var chunk_z: int = 0
var noise: FastNoiseLite
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var resource_spawner: Node3D

func initialize(cx: int, cz: int, noise_gen: FastNoiseLite):
	chunk_x = cx
	chunk_z = cz
	noise = noise_gen
	position = Vector3(cx * CHUNK_SIZE * QUAD_SIZE, 0, cz * CHUNK_SIZE * QUAD_SIZE)
	_generate_mesh()
	_spawn_resources()

func _generate_mesh():
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(CHUNK_SIZE + 1):
		for z in range(CHUNK_SIZE + 1):
			var world_x = chunk_x * CHUNK_SIZE + x
			var world_z = chunk_z * CHUNK_SIZE + z
			var height = _get_height(world_x, world_z)
			var color = _get_color(height)

			surface_tool.set_color(color)
			surface_tool.set_uv(Vector2(x / float(CHUNK_SIZE), z / float(CHUNK_SIZE)))

			if x < CHUNK_SIZE and z < CHUNK_SIZE:
				var v0 = Vector3(x * QUAD_SIZE, height, z * QUAD_SIZE)
				var v1 = Vector3((x + 1) * QUAD_SIZE, _get_height(world_x + 1, world_z), z * QUAD_SIZE)
				var v2 = Vector3(x * QUAD_SIZE, _get_height(world_x, world_z + 1), (z + 1) * QUAD_SIZE)
				var v3 = Vector3((x + 1) * QUAD_SIZE, _get_height(world_x + 1, world_z + 1), (z + 1) * QUAD_SIZE)

				# Normalen berechnen
				var n1 = (v1 - v0).cross(v2 - v0).normalized()
				var n2 = (v2 - v1).cross(v3 - v1).normalized()

				# Tri 1
				surface_tool.set_normal(n1)
				surface_tool.set_color(_get_color(v0.y))
				surface_tool.add_vertex(v0)
				surface_tool.set_color(_get_color(v1.y))
				surface_tool.add_vertex(v1)
				surface_tool.set_color(_get_color(v2.y))
				surface_tool.add_vertex(v2)

				# Tri 2
				surface_tool.set_normal(n2)
				surface_tool.set_color(_get_color(v1.y))
				surface_tool.add_vertex(v1)
				surface_tool.set_color(_get_color(v3.y))
				surface_tool.add_vertex(v3)
				surface_tool.set_color(_get_color(v2.y))
				surface_tool.add_vertex(v2)

	var mesh = surface_tool.commit()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Material das Vertex Colors nutzt
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	# Collision
	static_body = StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	add_child(static_body)

func _get_height(world_x: int, world_z: int) -> float:
	# Mehrere Noise-Oktaven fuer interessanteres Terrain
	var h = noise.get_noise_2d(world_x * 0.8, world_z * 0.8) * MAX_HEIGHT
	h += noise.get_noise_2d(world_x * 2.0, world_z * 2.0) * MAX_HEIGHT * 0.3
	h += noise.get_noise_2d(world_x * 0.2, world_z * 0.2) * MAX_HEIGHT * 2.0
	return h

func _get_color(height: float) -> Color:
	# Wasser-Level
	if height < -2.0:
		return Color(0.15, 0.3, 0.6)  # Tiefes Wasser
	elif height < 0.0:
		return Color(0.2, 0.4, 0.7)   # Flaches Wasser
	elif height < 1.0:
		return Color(0.76, 0.7, 0.5)  # Sand
	elif height < 8.0:
		return Color(0.2, 0.55, 0.15) # Gras
	elif height < 14.0:
		return Color(0.25, 0.45, 0.12)# Dunkles Gras
	elif height < 20.0:
		return Color(0.4, 0.38, 0.35) # Fels
	else:
		return Color(0.85, 0.85, 0.9) # Schnee

func _spawn_resources():
	resource_spawner = Node3D.new()
	resource_spawner.name = "Resources"
	add_child(resource_spawner)

	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(chunk_x, chunk_z))

	var tree_scene = preload("res://scenes/resources/tree.tscn")
	var rock_scene = preload("res://scenes/resources/rock.tscn")
	var ore_scene = preload("res://scenes/resources/ore.tscn")
	var berry_script = preload("res://scenes/resources/berry_bush.gd")
	var mushroom_script = preload("res://scenes/resources/mushroom.gd")
	var loot_script = preload("res://scenes/world/loot_crate.gd")
	var fish_script = preload("res://scenes/resources/fish_node.gd")
	var hemp_script = preload("res://scenes/resources/hemp_plant.gd")

	for i in 16:
		var rx = rng.randf_range(1, CHUNK_SIZE - 1)
		var rz = rng.randf_range(1, CHUNK_SIZE - 1)
		var world_x = chunk_x * CHUNK_SIZE + rx
		var world_z = chunk_z * CHUNK_SIZE + rz
		var height = _get_height(int(world_x), int(world_z))

		# Nur auf Gras spawnen
		if height < 1.0 or height > 14.0:
			continue

		var instance: Node3D
		var roll = rng.randf()
		if roll < 0.45:
			instance = tree_scene.instantiate()
		elif roll < 0.65:
			instance = rock_scene.instantiate()
		elif roll < 0.75:
			instance = ore_scene.instantiate()
		elif roll < 0.85:
			# Beeren-Busch
			instance = StaticBody3D.new()
			instance.set_script(berry_script)
		elif roll < 0.87:
			# Pilz
			instance = StaticBody3D.new()
			instance.set_script(mushroom_script)
		elif roll < 0.92:
			# Hanf-Pflanze
			instance = StaticBody3D.new()
			instance.set_script(hemp_script)
		elif roll < 0.97:
			# Loot Crate (selten)
			instance = StaticBody3D.new()
			instance.set_script(loot_script)
		else:
			# Fish Node (nur nahe Wasser)
			if height > 1.5:
				continue
			instance = StaticBody3D.new()
			instance.set_script(fish_script)

		instance.position = Vector3(rx * QUAD_SIZE, height, rz * QUAD_SIZE)
		resource_spawner.add_child(instance)

func get_height_at_world(world_pos: Vector3) -> float:
	var local_x = (world_pos.x - position.x) / QUAD_SIZE
	var local_z = (world_pos.z - position.z) / QUAD_SIZE
	var world_x = chunk_x * CHUNK_SIZE + local_x
	var world_z = chunk_z * CHUNK_SIZE + local_z
	return _get_height(int(world_x), int(world_z))
