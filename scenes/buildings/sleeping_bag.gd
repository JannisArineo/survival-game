extends StaticBody3D

var owner_id: String = "player"  # Fuer spaeteres Multiplayer

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Schlafsack (Respawn-Punkt setzen)"
	interactable.interacted.connect(_on_set_spawn)
	add_child(interactable)

func _on_set_spawn(_player: Node3D):
	GameManager.respawn_position = global_position + Vector3(0, 1, 0)
	GameManager.show_notification.emit("Respawn-Punkt gesetzt!", Color(0.4, 0.8, 1.0))

func _create_visual():
	# Liegende Rolle (Schlafsack)
	var bag_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.35
	cyl.height = 1.8
	bag_mesh.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.35, 0.6)
	mat.roughness = 0.95
	bag_mesh.material_override = mat
	bag_mesh.rotation.z = PI / 2.0
	bag_mesh.position.y = 0.3
	add_child(bag_mesh)

	# Kopfteil (heller)
	var head_mesh = MeshInstance3D.new()
	var head_cyl = CylinderMesh.new()
	head_cyl.top_radius = 0.32
	head_cyl.bottom_radius = 0.32
	head_cyl.height = 0.25
	head_mesh.mesh = head_cyl
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.8, 0.75, 0.65)
	head_mesh.material_override = head_mat
	head_mesh.rotation.z = PI / 2.0
	head_mesh.position = Vector3(0.9, 0.3, 0)
	add_child(head_mesh)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.8, 0.6, 0.7)
	col.shape = shape
	col.position.y = 0.3
	add_child(col)
