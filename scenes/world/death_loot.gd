extends StaticBody3D

# Spawnt beim Tod des Spielers - enthaelt sein ganzes Inventar
var loot_items: Array = []

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Dein Koerper (E - alles nehmen)"
	interactable.interacted.connect(_on_loot)
	add_child(interactable)

	# Nach 10 Minuten despawnen
	get_tree().create_timer(600.0).timeout.connect(queue_free)

func _on_loot(_player: Node3D):
	if loot_items.is_empty():
		GameManager.show_notification.emit("Koerper bereits geplundert", Color(0.6, 0.6, 0.6))
		return

	var count = 0
	for item in loot_items:
		Inventory.add_item(item.item_id, item.count)
		count += item.count
	loot_items.clear()

	GameManager.show_notification.emit("Items zurueckgeholt: " + str(count), Color(0.3, 0.9, 0.5))
	queue_free()

func _create_visual():
	# Sack / Koerper - rotes Kreuz
	var body_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.6
	body_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.15, 0.15)
	mat.roughness = 0.9
	body_mesh.material_override = mat
	body_mesh.position.y = 0.3
	add_child(body_mesh)

	# Glow
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.3, 0.3)
	light.light_energy = 0.8
	light.omni_range = 3.0
	light.position.y = 0.5
	add_child(light)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	col.shape = shape
	col.position.y = 0.3
	add_child(col)
