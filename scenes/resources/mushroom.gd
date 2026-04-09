extends StaticBody3D

@export var is_poisonous: bool = false
var has_mushroom: bool = true
var respawn_time: float = 60.0

func _ready():
	collision_layer = 4
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Pilz pflücken"
	interactable.interacted.connect(_on_pick)
	add_child(interactable)

func _on_pick(_player: Node3D):
	if not has_mushroom:
		return
	has_mushroom = false
	var item_id = "poison_mushroom" if is_poisonous else "mushroom"
	Inventory.add_item(item_id, 1)
	AudioManager.play_pickup()
	GameManager.show_notification.emit("+1 " + ("Gift-Pilz" if is_poisonous else "Pilz"), Color(0.6, 0.9, 0.3))
	visible = false
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn():
	has_mushroom = true
	visible = true

func _create_visual():
	# Stiel
	var stiel_mesh = MeshInstance3D.new()
	var stiel_cyl = CylinderMesh.new()
	stiel_cyl.top_radius = 0.06
	stiel_cyl.bottom_radius = 0.08
	stiel_cyl.height = 0.25
	stiel_mesh.mesh = stiel_cyl
	var stiel_mat = StandardMaterial3D.new()
	stiel_mat.albedo_color = Color(0.9, 0.85, 0.75)
	stiel_mesh.material_override = stiel_mat
	stiel_mesh.position.y = 0.125
	add_child(stiel_mesh)

	# Hut
	var hut_mesh = MeshInstance3D.new()
	var hut_sphere = SphereMesh.new()
	hut_sphere.radius = 0.2
	hut_sphere.height = 0.25
	hut_mesh.mesh = hut_sphere
	var hut_mat = StandardMaterial3D.new()
	hut_mat.albedo_color = Color(0.85, 0.2, 0.1) if not is_poisonous else Color(0.3, 0.7, 0.15)
	hut_mesh.material_override = hut_mat
	hut_mesh.position.y = 0.3
	add_child(hut_mesh)

	# Punkte auf dem Hut
	var dot_mesh = MeshInstance3D.new()
	var dot_sphere = SphereMesh.new()
	dot_sphere.radius = 0.04
	dot_sphere.height = 0.05
	dot_mesh.mesh = dot_sphere
	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = Color(1, 1, 1)
	dot_mesh.material_override = dot_mat
	dot_mesh.position = Vector3(0.07, 0.4, 0.07)
	add_child(dot_mesh)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.2
	shape.height = 0.4
	col.shape = shape
	col.position.y = 0.2
	add_child(col)
