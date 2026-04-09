extends StaticBody3D

# Werkbank: schaltet erweiterte Crafting-Rezepte frei
# Spieler muss in der Naehe sein um advanced Items zu craften

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Werkbank benutzen (Crafting-Boost)"
	interactable.interacted.connect(_on_use)
	add_child(interactable)

func _on_use(_player: Node3D):
	GameManager.near_workbench = true
	GameManager.workbench_timer = 10.0
	GameManager.show_notification.emit("Werkbank aktiv! (+10 Sek Crafting-Bonus)", Color(0.9, 0.75, 0.3))

func _process(delta):
	if GameManager.player:
		var dist = global_position.distance_to(GameManager.player.global_position)
		if dist < 4.0:
			GameManager.near_workbench = true

func _create_visual():
	# Tisch-Platte
	var top = MeshInstance3D.new()
	var top_box = BoxMesh.new()
	top_box.size = Vector3(1.5, 0.08, 0.8)
	top.mesh = top_box
	var top_mat = StandardMaterial3D.new()
	top_mat.albedo_color = Color(0.5, 0.35, 0.18)
	top_mat.roughness = 0.85
	top.material_override = top_mat
	top.position.y = 0.9
	add_child(top)

	# 4 Beine
	for xi in 2:
		for zi in 2:
			var leg = MeshInstance3D.new()
			var leg_box = BoxMesh.new()
			leg_box.size = Vector3(0.08, 0.9, 0.08)
			leg.mesh = leg_box
			var leg_mat = StandardMaterial3D.new()
			leg_mat.albedo_color = Color(0.4, 0.28, 0.12)
			leg.material_override = leg_mat
			leg.position = Vector3(
				-0.65 + xi * 1.3,
				0.45,
				-0.32 + zi * 0.64
			)
			add_child(leg)

	# Werkzeuge auf dem Tisch (Deko)
	var tool = MeshInstance3D.new()
	var tool_box = BoxMesh.new()
	tool_box.size = Vector3(0.4, 0.05, 0.08)
	tool.mesh = tool_box
	var tool_mat = StandardMaterial3D.new()
	tool_mat.albedo_color = Color(0.65, 0.65, 0.68)
	tool_mat.metallic = 0.7
	tool.material_override = tool_mat
	tool.position = Vector3(0.3, 0.95, 0.1)
	tool.rotation.y = 0.3
	add_child(tool)

	# Vise (Schraubstock, Deko)
	var vise = MeshInstance3D.new()
	var vise_box = BoxMesh.new()
	vise_box.size = Vector3(0.15, 0.12, 0.2)
	vise.mesh = vise_box
	var vise_mat = StandardMaterial3D.new()
	vise_mat.albedo_color = Color(0.3, 0.3, 0.32)
	vise_mat.metallic = 0.5
	vise.material_override = vise_mat
	vise.position = Vector3(-0.5, 0.96, 0)
	add_child(vise)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 0.9, 0.8)
	col.shape = shape
	col.position.y = 0.45
	add_child(col)
