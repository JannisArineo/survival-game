extends StaticBody3D

var has_fiber: bool = true
var respawn_time: float = 75.0

func _ready():
	collision_layer = 4
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Hanf ernten"
	interactable.interacted.connect(_on_harvest)
	add_child(interactable)

func _on_harvest(_player: Node3D):
	if not has_fiber:
		GameManager.show_notification.emit("Bereits geerntet", Color(0.6, 0.6, 0.6))
		return
	has_fiber = false
	var count = randi_range(3, 8)
	Inventory.add_item("fiber", count)
	AudioManager.play_pickup()
	GameManager.show_notification.emit("+" + str(count) + " Faser", Color(0.65, 0.8, 0.4))
	visible = false
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn():
	has_fiber = true
	visible = true

func _create_visual():
	# Stiel
	var stiel = MeshInstance3D.new()
	var stiel_cyl = CylinderMesh.new()
	stiel_cyl.top_radius = 0.04
	stiel_cyl.bottom_radius = 0.06
	stiel_cyl.height = 1.2
	stiel.mesh = stiel_cyl
	var stiel_mat = StandardMaterial3D.new()
	stiel_mat.albedo_color = Color(0.35, 0.55, 0.2)
	stiel.material_override = stiel_mat
	stiel.position.y = 0.6
	add_child(stiel)

	# Blaetter
	for i in 3:
		var leaf = MeshInstance3D.new()
		var leaf_box = BoxMesh.new()
		leaf_box.size = Vector3(0.6, 0.05, 0.15)
		leaf.mesh = leaf_box
		var leaf_mat = StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.3, 0.65, 0.2)
		leaf.material_override = leaf_mat
		leaf.position.y = 0.8 + i * 0.2
		leaf.rotation.y = i * (TAU / 3.0)
		add_child(leaf)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = 1.2
	col.shape = shape
	col.position.y = 0.6
	add_child(col)
