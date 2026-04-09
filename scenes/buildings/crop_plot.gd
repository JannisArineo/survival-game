extends StaticBody3D

# Anbau-System: Samen pflanzen, waessern, ernten
enum GrowthStage { EMPTY, SEEDED, GROWING, READY }

@export var crop_type: String = "berry_seed"

const GROW_TIME = 120.0  # 2 Minuten Wachstumszeit
const CROP_YIELDS = {
	"berry_seed": {"item": "berries", "min": 3, "max": 6},
	"mushroom_seed": {"item": "mushroom", "min": 2, "max": 4},
	"hemp_seed": {"item": "fiber", "min": 5, "max": 10},
}

var stage: GrowthStage = GrowthStage.EMPTY
var grow_timer: float = 0.0
var is_watered: bool = false

var plant_mesh: MeshInstance3D
var interactable: Interactable

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

	interactable = Interactable.new()
	interactable.interaction_text = _get_interact_text()
	interactable.interacted.connect(_on_interact)
	add_child(interactable)

func _process(delta):
	if stage == GrowthStage.GROWING:
		if is_watered:
			grow_timer += delta * 1.5  # Bewaessert = 50% schneller
		else:
			grow_timer += delta
		_update_plant_visual()
		if grow_timer >= GROW_TIME:
			stage = GrowthStage.READY
			GameManager.show_notification.emit("Ernte bereit!", Color(0.5, 0.9, 0.3))
			interactable.interaction_text = "Ernten (E)"

func _on_interact(player: Node3D):
	match stage:
		GrowthStage.EMPTY:
			_try_plant()
		GrowthStage.SEEDED, GrowthStage.GROWING:
			if not is_watered:
				_water()
			else:
				GameManager.show_notification.emit("Bereits bewaessert", Color(0.4, 0.6, 0.9))
		GrowthStage.READY:
			_harvest()

func _try_plant():
	# Suche nach passendem Samen im Inventar
	for seed_id in CROP_YIELDS.keys():
		if Inventory.has_item(seed_id, 1):
			Inventory.remove_item(seed_id, 1)
			crop_type = seed_id
			stage = GrowthStage.SEEDED
			grow_timer = 0.0
			interactable.interaction_text = "Bewaessern (E)"
			GameManager.show_notification.emit("Gepflanzt: " + seed_id, Color(0.5, 0.8, 0.3))
			_update_plant_visual()
			return
	GameManager.show_notification.emit("Kein Samen im Inventar", Color(0.8, 0.5, 0.3))

func _water():
	is_watered = true
	stage = GrowthStage.GROWING
	interactable.interaction_text = "Waechst... (bewaessert)"
	GameManager.show_notification.emit("Bewaessert! Waechst schneller", Color(0.4, 0.65, 0.95))
	_update_plant_visual()

func _harvest():
	var yield_data = CROP_YIELDS.get(crop_type, {"item": "berries", "min": 2, "max": 4})
	var count = randi_range(yield_data.min, yield_data.max)
	Inventory.add_item(yield_data.item, count)

	# Chance auf Samen-Rueckgabe
	if randf() < 0.5:
		Inventory.add_item(crop_type, 1)

	GameManager.show_notification.emit("Geerntet: +" + str(count) + " " + yield_data.item, Color(0.8, 0.95, 0.3))
	AudioManager.play_pickup()

	# Reset
	stage = GrowthStage.EMPTY
	grow_timer = 0.0
	is_watered = false
	interactable.interaction_text = "Pflanzen (E)"
	_update_plant_visual()

func _update_plant_visual():
	if plant_mesh == null:
		return
	var growth = clampf(grow_timer / GROW_TIME, 0.0, 1.0)
	match stage:
		GrowthStage.EMPTY:
			plant_mesh.visible = false
		GrowthStage.SEEDED:
			plant_mesh.visible = true
			plant_mesh.scale = Vector3(0.3, 0.2, 0.3)
		GrowthStage.GROWING:
			plant_mesh.visible = true
			plant_mesh.scale = Vector3(0.3 + growth * 0.7, 0.2 + growth * 0.8, 0.3 + growth * 0.7)
		GrowthStage.READY:
			plant_mesh.visible = true
			plant_mesh.scale = Vector3(1.0, 1.0, 1.0)

func _get_interact_text() -> String:
	match stage:
		GrowthStage.EMPTY: return "Pflanzen (E)"
		GrowthStage.SEEDED: return "Bewaessern (E)"
		GrowthStage.GROWING: return "Waechst..."
		GrowthStage.READY: return "Ernten (E)"
	return "E"

func _create_visual():
	# Erd-Bett
	var soil = MeshInstance3D.new()
	var soil_box = BoxMesh.new()
	soil_box.size = Vector3(1.2, 0.15, 1.2)
	soil.mesh = soil_box
	var soil_mat = StandardMaterial3D.new()
	soil_mat.albedo_color = Color(0.3, 0.2, 0.1)
	soil_mat.roughness = 1.0
	soil.material_override = soil_mat
	soil.position.y = 0.075
	add_child(soil)

	# Pflanze (dynamisch skaliert)
	plant_mesh = MeshInstance3D.new()
	var plant_sphere = SphereMesh.new()
	plant_sphere.radius = 0.3
	plant_sphere.height = 0.5
	plant_mesh.mesh = plant_sphere
	var plant_mat = StandardMaterial3D.new()
	plant_mat.albedo_color = Color(0.3, 0.7, 0.2)
	plant_mesh.material_override = plant_mat
	plant_mesh.position.y = 0.5
	plant_mesh.visible = false
	add_child(plant_mesh)

	# Holz-Rahmen
	for i in 4:
		var plank = MeshInstance3D.new()
		var plank_box = BoxMesh.new()
		var is_x = i < 2
		plank_box.size = Vector3(1.25 if is_x else 0.08, 0.12, 0.08 if is_x else 1.25)
		plank.mesh = plank_box
		var plank_mat = StandardMaterial3D.new()
		plank_mat.albedo_color = Color(0.45, 0.3, 0.15)
		plank.material_override = plank_mat
		var offset = (0.6 if i % 2 == 0 else -0.6)
		plank.position = Vector3(
			offset if not is_x else 0,
			0.06,
			offset if is_x else 0
		)
		add_child(plank)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 0.2, 1.2)
	col.shape = shape
	col.position.y = 0.1
	add_child(col)
