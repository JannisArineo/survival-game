extends StaticBody3D

@export var berry_type: String = "berries"
@export var drop_count_min: int = 2
@export var drop_count_max: int = 5
@export var respawn_time: float = 90.0

var has_berries: bool = true
var original_color: Color = Color(0.7, 0.1, 0.1)

var berry_mesh: MeshInstance3D

func _ready():
	collision_layer = 4
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Beeren pflücken"
	interactable.interacted.connect(_on_pick)
	add_child(interactable)

func _on_pick(_player: Node3D):
	if not has_berries:
		GameManager.show_notification.emit("Strauch ist leer", Color(0.6, 0.6, 0.6))
		return

	has_berries = false
	var count = randi_range(drop_count_min, drop_count_max)
	Inventory.add_item(berry_type, count)
	AudioManager.play_pickup()
	GameManager.show_notification.emit("+" + str(count) + " Beeren", Color(0.8, 0.2, 0.3))
	_set_empty_visual()
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _set_empty_visual():
	if berry_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.35, 0.2)
		berry_mesh.material_override = mat

func _respawn():
	has_berries = true
	if berry_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = original_color
		berry_mesh.material_override = mat

func _create_visual():
	# Busch-Basis (gruener Busch)
	var bush_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 0.8
	bush_mesh.mesh = sphere
	var bush_mat = StandardMaterial3D.new()
	bush_mat.albedo_color = Color(0.2, 0.45, 0.15)
	bush_mat.roughness = 1.0
	bush_mesh.material_override = bush_mat
	bush_mesh.position.y = 0.4
	add_child(bush_mesh)

	# Beeren (rote kleine Kugeln)
	berry_mesh = MeshInstance3D.new()
	var berry_sphere = SphereMesh.new()
	berry_sphere.radius = 0.55
	berry_sphere.height = 0.7
	berry_mesh.mesh = berry_sphere
	var berry_mat = StandardMaterial3D.new()
	berry_mat.albedo_color = original_color
	berry_mat.roughness = 0.6
	berry_mesh.material_override = berry_mat
	berry_mesh.scale = Vector3(0.4, 0.4, 0.4)
	berry_mesh.position = Vector3(0.2, 0.7, 0.2)
	add_child(berry_mesh)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	col.position.y = 0.4
	add_child(col)
