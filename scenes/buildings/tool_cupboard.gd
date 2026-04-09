extends StaticBody3D

# Tool Cupboard: schuetzt Gebaeude in der Naehe vor Decay
# Ohne TC verfallen Gebaeude nach 24h (Spielzeit)
const PROTECT_RADIUS = 30.0

var authorized_players: Array = ["player"]  # Fuer Multiplayer-Erweiterung

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()
	GameManager.register_tool_cupboard(self)

	var interactable = Interactable.new()
	interactable.interaction_text = "Werkzeugschrank (Schutz-Radius: 30m)"
	interactable.interacted.connect(_on_open)
	add_child(interactable)

func _on_open(_player: Node3D):
	var wood = Inventory.get_item_count("wood")
	var stone = Inventory.get_item_count("stone")
	GameManager.show_notification.emit(
		"TC aktiv! Schutzradius: 30m | Holz: " + str(wood) + " Stein: " + str(stone),
		Color(0.4, 0.8, 0.4)
	)

func is_position_protected(pos: Vector3) -> bool:
	return global_position.distance_to(pos) < PROTECT_RADIUS

func _create_visual():
	# Schrank-Koerper
	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.8, 1.2, 0.4)
	body.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.25, 0.12)
	mat.roughness = 0.9
	body.material_override = mat
	body.position.y = 0.6
	add_child(body)

	# Tuer
	var door = MeshInstance3D.new()
	var door_box = BoxMesh.new()
	door_box.size = Vector3(0.38, 1.1, 0.05)
	door.mesh = door_box
	var door_mat = StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.4, 0.3, 0.15)
	door.material_override = door_mat
	door.position = Vector3(0.2, 0.6, 0.22)
	add_child(door)

	# Schloss
	var lock = MeshInstance3D.new()
	var lock_box = BoxMesh.new()
	lock_box.size = Vector3(0.08, 0.08, 0.06)
	lock.mesh = lock_box
	var lock_mat = StandardMaterial3D.new()
	lock_mat.albedo_color = Color(0.75, 0.6, 0.1)
	lock_mat.metallic = 0.8
	lock.material_override = lock_mat
	lock.position = Vector3(0.2, 0.6, 0.25)
	add_child(lock)

	# Gruen-gluehen wenn aktiv
	var light = OmniLight3D.new()
	light.light_color = Color(0.3, 1.0, 0.4)
	light.light_energy = 0.3
	light.omni_range = 3.0
	light.position.y = 1.3
	add_child(light)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 1.2, 0.4)
	col.shape = shape
	col.position.y = 0.6
	add_child(col)
