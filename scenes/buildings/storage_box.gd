extends StaticBody3D

const BOX_SLOTS = 20
var slots: Array = []
var is_open: bool = false

func _ready():
	collision_layer = 8
	collision_mask = 0
	slots.resize(BOX_SLOTS)
	for i in BOX_SLOTS:
		slots[i] = null
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Kiste oeffnen"
	interactable.interacted.connect(_on_open)
	add_child(interactable)

func _on_open(_player: Node3D):
	_show_contents()

func _show_contents():
	# Schneller Loot-Transfer: alles in Inventar transferieren
	var transferred = 0
	for i in BOX_SLOTS:
		if slots[i] != null:
			var remaining = Inventory.add_item(slots[i].item_id, slots[i].count)
			if remaining == 0:
				slots[i] = null
				transferred += 1
	if transferred > 0:
		GameManager.show_notification.emit("Kiste geleert!", Color(0.9, 0.7, 0.3))
	else:
		GameManager.show_notification.emit("Kiste ist leer", Color(0.6, 0.6, 0.6))

func add_to_box(item_id: String, count: int) -> int:
	var remaining = count
	for i in BOX_SLOTS:
		if remaining <= 0:
			break
		if slots[i] != null and slots[i].item_id == item_id:
			slots[i].count += remaining
			remaining = 0
	for i in BOX_SLOTS:
		if remaining <= 0:
			break
		if slots[i] == null:
			slots[i] = {item_id = item_id, count = remaining}
			remaining = 0
	return remaining

func _create_visual():
	var body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.7, 0.7)
	body_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.35, 0.15)
	mat.roughness = 0.9
	body_mesh.material_override = mat
	body_mesh.position.y = 0.35
	add_child(body_mesh)

	# Deckel
	var lid = MeshInstance3D.new()
	var lid_box = BoxMesh.new()
	lid_box.size = Vector3(1.02, 0.08, 0.72)
	lid.mesh = lid_box
	var lid_mat = StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.45, 0.3, 0.1)
	lid_mat.roughness = 0.85
	lid.material_override = lid_mat
	lid.position.y = 0.74
	add_child(lid)

	# Schloss
	var lock = MeshInstance3D.new()
	var lock_box = BoxMesh.new()
	lock_box.size = Vector3(0.12, 0.12, 0.05)
	lock.mesh = lock_box
	var lock_mat = StandardMaterial3D.new()
	lock_mat.albedo_color = Color(0.8, 0.65, 0.1)
	lock_mat.metallic = 0.8
	lock.material_override = lock_mat
	lock.position = Vector3(0, 0.5, 0.36)
	add_child(lock)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 0.7, 0.7)
	col.shape = shape
	col.position.y = 0.35
	add_child(col)
