extends StaticBody3D

# Fisch-Node: spawnt an Wasser-Stellen, E druecken = angeln
@export var drop_count_min: int = 1
@export var drop_count_max: int = 3
var has_fish: bool = true
var respawn_time: float = 120.0
var fish_mesh: MeshInstance3D
var bob_timer: float = 0.0

func _ready():
	collision_layer = 4
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Angeln (E)"
	interactable.interacted.connect(_on_fish)
	add_child(interactable)

func _process(delta):
	# Sanftes auf und ab wippen (Floater-Animation)
	bob_timer += delta
	position.y = sin(bob_timer * 1.5) * 0.1 - 0.8

func _on_fish(_player: Node3D):
	if not has_fish:
		GameManager.show_notification.emit("Hier gibt es keine Fische", Color(0.5, 0.6, 0.8))
		return
	has_fish = false
	var count = randi_range(drop_count_min, drop_count_max)
	Inventory.add_item("raw_fish", count)
	AudioManager.play_pickup()
	GameManager.show_notification.emit("+" + str(count) + " Roher Fisch", Color(0.4, 0.65, 0.9))
	if fish_mesh:
		fish_mesh.visible = false
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn():
	has_fish = true
	if fish_mesh:
		fish_mesh.visible = true

func _create_visual():
	# Floater/Boje
	var float_mesh = MeshInstance3D.new()
	var float_cyl = CylinderMesh.new()
	float_cyl.top_radius = 0.06
	float_cyl.bottom_radius = 0.06
	float_cyl.height = 0.3
	float_mesh.mesh = float_cyl
	var float_mat = StandardMaterial3D.new()
	float_mat.albedo_color = Color(0.9, 0.1, 0.1)
	float_mesh.material_override = float_mat
	float_mesh.position.y = 0.15
	add_child(float_mesh)

	# Fisch unter Wasser (sichtbar)
	fish_mesh = MeshInstance3D.new()
	var fish_box = BoxMesh.new()
	fish_box.size = Vector3(0.25, 0.08, 0.5)
	fish_mesh.mesh = fish_box
	var fish_mat = StandardMaterial3D.new()
	fish_mat.albedo_color = Color(0.4, 0.65, 0.9)
	fish_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fish_mat.albedo_color.a = 0.7
	fish_mesh.material_override = fish_mat
	fish_mesh.position.y = -0.5
	add_child(fish_mesh)

	# Schnur
	var line_mesh = MeshInstance3D.new()
	var line_cyl = CylinderMesh.new()
	line_cyl.top_radius = 0.005
	line_cyl.bottom_radius = 0.005
	line_cyl.height = 0.8
	line_mesh.mesh = line_cyl
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.85, 0.8, 0.7)
	line_mesh.material_override = line_mat
	line_mesh.position.y = -0.2
	add_child(line_mesh)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = 0.5
	col.shape = shape
	add_child(col)
