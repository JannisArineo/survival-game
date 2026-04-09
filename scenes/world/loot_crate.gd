extends StaticBody3D

var loot_table: Array = [
	{"item_id": "metal_fragment", "min": 5, "max": 20, "weight": 30},
	{"item_id": "stone_axe", "min": 1, "max": 1, "weight": 15},
	{"item_id": "metal_axe", "min": 1, "max": 1, "weight": 5},
	{"item_id": "bandage", "min": 2, "max": 5, "weight": 20},
	{"item_id": "cooked_meat", "min": 3, "max": 8, "weight": 25},
	{"item_id": "bow", "min": 1, "max": 1, "weight": 8},
	{"item_id": "arrow", "min": 10, "max": 25, "weight": 20},
	{"item_id": "cloth_shirt", "min": 1, "max": 1, "weight": 12},
	{"item_id": "bone_armor", "min": 1, "max": 1, "weight": 6},
	{"item_id": "wood", "min": 50, "max": 150, "weight": 35},
	{"item_id": "stone", "min": 30, "max": 80, "weight": 35},
	{"item_id": "high_quality_metal", "min": 1, "max": 5, "weight": 4},
]

var has_been_looted: bool = false
var respawn_time: float = 600.0  # 10 Minuten

var glow_light: OmniLight3D

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Kiste looten"
	interactable.interacted.connect(_on_loot)
	add_child(interactable)

func _on_loot(_player: Node3D):
	if has_been_looted:
		GameManager.show_notification.emit("Kiste bereits geplundert", Color(0.6, 0.6, 0.6))
		return

	has_been_looted = true
	_give_random_loot()
	_set_looted_visual()

	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _give_random_loot():
	# 2-4 zufaellige Items aus Loot-Table
	var loot_count = randi_range(2, 4)
	var received = []

	for i in loot_count:
		var item = _pick_random_item()
		if item == null:
			continue
		var count = randi_range(item.min, item.max)
		Inventory.add_item(item.item_id, count)
		received.append(item.item_id + " x" + str(count))

	if received.size() > 0:
		GameManager.show_notification.emit("Geplundert: " + ", ".join(received), Color(1.0, 0.8, 0.2))

func _pick_random_item() -> Dictionary:
	var total_weight = 0
	for item in loot_table:
		total_weight += item.weight

	var roll = randi_range(0, total_weight - 1)
	var cumulative = 0
	for item in loot_table:
		cumulative += item.weight
		if roll < cumulative:
			return item
	return loot_table[0]

func _set_looted_visual():
	if glow_light:
		glow_light.light_color = Color(0.4, 0.4, 0.4)
		glow_light.light_energy = 0.0

func _respawn():
	has_been_looted = false
	if glow_light:
		glow_light.light_color = Color(0.9, 0.7, 0.2)
		glow_light.light_energy = 0.5

func _create_visual():
	# Kiste (olivgruene Militaerkiste)
	var body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 0.6, 0.7)
	body_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.35, 0.2)
	mat.roughness = 0.9
	body_mesh.material_override = mat
	body_mesh.position.y = 0.3
	add_child(body_mesh)

	# Streifen
	for i in 2:
		var stripe = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(1.22, 0.05, 0.72)
		stripe.mesh = s_box
		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.15, 0.22, 0.12)
		stripe.material_override = s_mat
		stripe.position = Vector3(0, 0.15 + i * 0.25, 0)
		add_child(stripe)

	# Gluehen (ungelootet)
	glow_light = OmniLight3D.new()
	glow_light.light_color = Color(0.9, 0.7, 0.2)
	glow_light.light_energy = 0.5
	glow_light.omni_range = 4.0
	glow_light.position.y = 0.8
	add_child(glow_light)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 0.6, 0.7)
	col.shape = shape
	col.position.y = 0.3
	add_child(col)
