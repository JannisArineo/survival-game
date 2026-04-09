extends StaticBody3D

const DAMAGE = 20.0
const TRIGGER_RADIUS = 1.2
var triggered_by: Array = []
var cooldowns: Dictionary = {}

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

func _process(delta):
	# Cooldowns runterzaehlen
	for entity in cooldowns.keys():
		cooldowns[entity] -= delta
		if cooldowns[entity] <= 0:
			cooldowns.erase(entity)

	# Pruefen ob Entities in Reichweite
	var entities = _get_nearby_entities()
	for entity in entities:
		if not cooldowns.has(entity):
			_trigger(entity)

func _get_nearby_entities() -> Array:
	var result = []
	# Player
	if GameManager.player:
		var dist = global_position.distance_to(GameManager.player.global_position)
		if dist < TRIGGER_RADIUS:
			result.append(GameManager.player)
	# Feinde
	var world = get_tree().current_scene.find_child("World", true, false)
	if world:
		for child in world.get_children():
			if child is CharacterBody3D and child != GameManager.player:
				var dist = global_position.distance_to(child.global_position)
				if dist < TRIGGER_RADIUS:
					result.append(child)
	return result

func _trigger(entity: Node3D):
	cooldowns[entity] = 1.0  # 1 Sekunde Cooldown
	if entity.has_method("take_damage"):
		entity.take_damage(DAMAGE)
	elif entity.has_method("receive_hit"):
		entity.receive_hit(DAMAGE)
	# Visual Feedback
	_flash()

func _flash():
	var tween = create_tween()
	for spike in get_children():
		if spike is MeshInstance3D:
			var mat = spike.material_override as StandardMaterial3D
			if mat:
				tween.tween_property(mat, "albedo_color", Color(1.0, 0.2, 0.1), 0.05)
				tween.tween_property(mat, "albedo_color", Color(0.55, 0.5, 0.45), 0.3)

func _create_visual():
	# Basis-Brett
	var base = MeshInstance3D.new()
	var base_box = BoxMesh.new()
	base_box.size = Vector3(1.4, 0.1, 1.4)
	base.mesh = base_box
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.4, 0.3, 0.15)
	base.material_override = base_mat
	base.position.y = 0.05
	add_child(base)

	# Spitzen (3x3 Grid)
	for xi in 3:
		for zi in 3:
			var spike = MeshInstance3D.new()
			var spike_cyl = CylinderMesh.new()
			spike_cyl.top_radius = 0.0
			spike_cyl.bottom_radius = 0.05
			spike_cyl.height = 0.4
			spike.mesh = spike_cyl
			var spike_mat = StandardMaterial3D.new()
			spike_mat.albedo_color = Color(0.55, 0.5, 0.45)
			spike_mat.metallic = 0.4
			spike.material_override = spike_mat
			spike.position = Vector3(
				-0.4 + xi * 0.4,
				0.3,
				-0.4 + zi * 0.4
			)
			add_child(spike)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.4, 0.4, 1.4)
	col.shape = shape
	col.position.y = 0.2
	add_child(col)
