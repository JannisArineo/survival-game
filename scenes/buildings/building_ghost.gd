extends Node3D

# Bau-System das am Player haengt
# Wird vom Player gesteuert wenn ein Building-Item in der Hotbar ist

var ghost_instance: Node3D = null
var ghost_material: StandardMaterial3D
var can_place: bool = false
var grid_size: float = 2.0
var current_building_item: ItemData = null

func _ready():
	ghost_material = StandardMaterial3D.new()
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.albedo_color = Color(0, 1, 0, 0.4)
	ghost_material.no_depth_test = true

func _process(delta):
	var item = Inventory.get_selected_item_data()

	if item == null or item.item_type != ItemData.ItemType.BUILDING:
		_clear_ghost()
		return

	if item != current_building_item:
		_clear_ghost()
		_create_ghost(item)
		current_building_item = item

	_update_ghost_position()

func _create_ghost(item: ItemData):
	if item.building_scene.is_empty():
		return

	if not ResourceLoader.exists(item.building_scene):
		# Fallback: einfache Box
		ghost_instance = _create_fallback_ghost(item.id)
	else:
		ghost_instance = load(item.building_scene).instantiate()

	# Ghost Material auf alle MeshInstances anwenden
	_apply_ghost_material(ghost_instance)

	# Collision deaktivieren
	_disable_collision(ghost_instance)

	add_child(ghost_instance)

func _create_fallback_ghost(building_id: String) -> Node3D:
	var node = Node3D.new()
	var mesh_instance = MeshInstance3D.new()
	var mesh: Mesh

	match building_id:
		"foundation":
			var box = BoxMesh.new()
			box.size = Vector3(4, 0.3, 4)
			mesh = box
		"wall":
			var box = BoxMesh.new()
			box.size = Vector3(4, 3, 0.2)
			mesh = box
		"door":
			var box = BoxMesh.new()
			box.size = Vector3(1.2, 2.5, 0.15)
			mesh = box
		"campfire":
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.4
			cylinder.bottom_radius = 0.5
			cylinder.height = 0.3
			mesh = cylinder
		"furnace":
			var box = BoxMesh.new()
			box.size = Vector3(1.2, 1.0, 1.2)
			mesh = box
		"storage_box":
			var box = BoxMesh.new()
			box.size = Vector3(1.0, 0.7, 0.7)
			mesh = box
		"half_wall":
			var box = BoxMesh.new()
			box.size = Vector3(4, 1.5, 0.2)
			mesh = box
		"floor_tile":
			var box = BoxMesh.new()
			box.size = Vector3(4, 0.15, 4)
			mesh = box
		"stairs":
			var box = BoxMesh.new()
			box.size = Vector3(4, 1.5, 2)
			mesh = box
		"sleeping_bag":
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.35
			cyl.bottom_radius = 0.35
			cyl.height = 1.8
			mesh = cyl
		"workbench":
			var box = BoxMesh.new()
			box.size = Vector3(1.5, 0.9, 0.8)
			mesh = box
		"crop_plot":
			var box = BoxMesh.new()
			box.size = Vector3(1.2, 0.2, 1.2)
			mesh = box
		"spike_trap":
			var box = BoxMesh.new()
			box.size = Vector3(1.4, 0.4, 1.4)
			mesh = box
		"tool_cupboard":
			var box = BoxMesh.new()
			box.size = Vector3(0.8, 1.2, 0.4)
			mesh = box
		_:
			var box = BoxMesh.new()
			box.size = Vector3(2, 2, 2)
			mesh = box

	mesh_instance.mesh = mesh
	node.add_child(mesh_instance)
	return node

func _apply_ghost_material(node: Node):
	if node is MeshInstance3D:
		node.material_override = ghost_material
	for child in node.get_children():
		_apply_ghost_material(child)

func _disable_collision(node: Node):
	if node is CollisionShape3D:
		node.disabled = true
	if node is StaticBody3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_disable_collision(child)

func _update_ghost_position():
	if ghost_instance == null or GameManager.player == null:
		return

	var camera = GameManager.player.get_node("Head/Camera3D")
	var from = camera.global_position
	var forward = -camera.global_basis.z
	var target_pos = from + forward * 5.0

	# Snap to grid
	target_pos.x = snapped(target_pos.x, grid_size)
	target_pos.z = snapped(target_pos.z, grid_size)

	# Raycast fuer Bodenhöhe
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(target_pos.x, target_pos.y + 10, target_pos.z),
		Vector3(target_pos.x, target_pos.y - 20, target_pos.z)
	)
	query.collision_mask = 1 # Terrain only
	var result = space.intersect_ray(query)
	if result:
		target_pos.y = result.position.y

	ghost_instance.global_position = target_pos

	# Placement check
	can_place = _check_can_place(target_pos)
	ghost_material.albedo_color = Color(0, 1, 0, 0.4) if can_place else Color(1, 0, 0, 0.4)

func _check_can_place(pos: Vector3) -> bool:
	# Einfacher Check: nicht zu nah am Spieler
	if GameManager.player == null:
		return false
	var dist = pos.distance_to(GameManager.player.global_position)
	return dist > 2.0 and dist < 15.0

func try_place() -> bool:
	if not can_place or ghost_instance == null or current_building_item == null:
		return false

	var pos = ghost_instance.global_position
	var item_id = Inventory.get_selected_item().item_id

	if not Inventory.remove_item(item_id, 1):
		return false

	# Echtes Gebaeude platzieren
	var building: Node3D
	if not current_building_item.building_scene.is_empty() and ResourceLoader.exists(current_building_item.building_scene):
		building = load(current_building_item.building_scene).instantiate()
	else:
		building = _create_placed_building(item_id)

	building.global_position = pos

	# Zur Welt hinzufuegen
	get_tree().current_scene.add_child(building)

	return true

func _create_placed_building(building_id: String) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 8 # buildings layer
	body.collision_mask = 0

	var mesh_instance = MeshInstance3D.new()
	var collision = CollisionShape3D.new()
	var shape: Shape3D
	var mesh: Mesh

	match building_id:
		"foundation":
			var box = BoxMesh.new()
			box.size = Vector3(4, 0.3, 4)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(4, 0.3, 4)
			shape = box_shape
		"wall":
			var box = BoxMesh.new()
			box.size = Vector3(4, 3, 0.2)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(4, 3, 0.2)
			shape = box_shape
			body.position.y = 1.5
		"door":
			var box = BoxMesh.new()
			box.size = Vector3(1.2, 2.5, 0.15)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(1.2, 2.5, 0.15)
			shape = box_shape
			body.position.y = 1.25
		"campfire":
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.4
			cyl.bottom_radius = 0.5
			cyl.height = 0.3
			mesh = cyl
			var cyl_shape = CylinderShape3D.new()
			cyl_shape.radius = 0.5
			cyl_shape.height = 0.3
			shape = cyl_shape
			body.set_script(preload("res://scenes/buildings/campfire.gd"))
		"furnace":
			var furnace = StaticBody3D.new()
			furnace.set_script(preload("res://scenes/buildings/furnace.gd"))
			return furnace
		"storage_box":
			var sbox = StaticBody3D.new()
			sbox.set_script(preload("res://scenes/buildings/storage_box.gd"))
			return sbox
		"sleeping_bag":
			var bag = StaticBody3D.new()
			bag.set_script(preload("res://scenes/buildings/sleeping_bag.gd"))
			return bag
		"workbench":
			var wb = StaticBody3D.new()
			wb.set_script(preload("res://scenes/buildings/workbench.gd"))
			return wb
		"crop_plot":
			var cp = StaticBody3D.new()
			cp.set_script(preload("res://scenes/buildings/crop_plot.gd"))
			return cp
		"spike_trap":
			var st = StaticBody3D.new()
			st.set_script(preload("res://scenes/buildings/spike_trap.gd"))
			return st
		"tool_cupboard":
			var tc = StaticBody3D.new()
			tc.set_script(preload("res://scenes/buildings/tool_cupboard.gd"))
			return tc
		"half_wall":
			var box = BoxMesh.new()
			box.size = Vector3(4, 1.5, 0.2)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(4, 1.5, 0.2)
			shape = box_shape
			body.position.y = 0.75
		"floor_tile":
			var box = BoxMesh.new()
			box.size = Vector3(4, 0.15, 4)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(4, 0.15, 4)
			shape = box_shape
		"stairs":
			var box = BoxMesh.new()
			box.size = Vector3(4, 1.5, 2)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(4, 1.5, 2)
			shape = box_shape
			body.position.y = 0.75
		_:
			var box = BoxMesh.new()
			box.size = Vector3(2, 2, 2)
			mesh = box
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(2, 2, 2)
			shape = box_shape

	var mat = StandardMaterial3D.new()
	var item = CraftingDB.get_item(building_id)
	mat.albedo_color = item.icon_color if item else Color(0.5, 0.4, 0.3)
	mat.roughness = 0.9
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat

	collision.shape = shape

	body.add_child(mesh_instance)
	body.add_child(collision)

	return body

func _clear_ghost():
	if ghost_instance:
		ghost_instance.queue_free()
		ghost_instance = null
	current_building_item = null
