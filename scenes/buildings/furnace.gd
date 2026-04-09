extends StaticBody3D

const SMELT_TIME = 30.0

var fuel: int = 0
var input_item: String = ""
var input_count: int = 0
var output_item: String = ""
var output_count: int = 0
var smelt_timer: float = 0.0
var is_smelting: bool = false

var fire_particles: GPUParticles3D
var light: OmniLight3D

# Smelt-Tabelle
const SMELT_RECIPES = {
	"stone_ore": {"result": "metal_fragment", "count": 2},
	"metal_ore": {"result": "high_quality_metal", "count": 1},
	"wood": {"result": "charcoal", "count": 1}
}

func _ready():
	collision_layer = 8
	collision_mask = 0
	_create_visual()

	var interactable = Interactable.new()
	interactable.interaction_text = "Schmelzofen oeffnen"
	interactable.interacted.connect(_on_open)
	add_child(interactable)

func _process(delta):
	if is_smelting and fuel > 0:
		smelt_timer += delta
		if smelt_timer >= SMELT_TIME:
			smelt_timer = 0.0
			_produce_output()
			fuel -= 1
			if input_count <= 0 or fuel <= 0:
				_stop_smelting()

	if light:
		light.light_energy = randf_range(0.5, 1.5) if is_smelting else 0.0

func _on_open(player: Node3D):
	# Zeige Furnace-UI (simplifiziert: direkt Item hinzufuegen/entnehmen)
	# Fuer ein vollstaendiges UI braeuchten wir eine eigene Szene
	# Hier: Automatisch das erste smelzbare Item aus dem Inventar laden
	_auto_load_from_inventory()

func _auto_load_from_inventory():
	for recipe_input in SMELT_RECIPES:
		if Inventory.has_item(recipe_input, 1):
			var recipe = SMELT_RECIPES[recipe_input]
			input_item = recipe_input
			output_item = recipe.result
			output_count = recipe.count
			var count = Inventory.get_item_count(recipe_input)
			Inventory.remove_item(recipe_input, count)
			input_count = count

			# Holz als Treibstoff
			if Inventory.has_item("wood", 5):
				Inventory.remove_item("wood", 5)
				fuel += 5

			if input_count > 0 and fuel > 0:
				is_smelting = true
				_start_fire()
				GameManager.show_notification.emit(
					"Schmelze: " + input_item + " x" + str(input_count),
					Color(1.0, 0.6, 0.2)
				)
			return

func _produce_output():
	if output_item.is_empty():
		return
	Inventory.add_item(output_item, output_count)
	input_count -= 1
	GameManager.show_notification.emit(
		"+" + str(output_count) + " " + output_item,
		Color(0.8, 0.8, 0.3)
	)

func _stop_smelting():
	is_smelting = false
	_stop_fire()

func _start_fire():
	if fire_particles:
		fire_particles.emitting = true

func _stop_fire():
	if fire_particles:
		fire_particles.emitting = false

func _create_visual():
	# Basis (Stein-Box)
	var body_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 1.0, 1.2)
	body_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.3, 0.3)
	mat.roughness = 0.95
	body_mesh.material_override = mat
	body_mesh.position.y = 0.5
	add_child(body_mesh)

	# Oeffnung (dunkleres Rechteck vorne)
	var opening = MeshInstance3D.new()
	var opening_box = BoxMesh.new()
	opening_box.size = Vector3(0.5, 0.4, 0.05)
	opening.mesh = opening_box
	var open_mat = StandardMaterial3D.new()
	open_mat.albedo_color = Color(0.1, 0.07, 0.05)
	opening.material_override = open_mat
	opening.position = Vector3(0, 0.4, 0.61)
	add_child(opening)

	# Kollision
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 1.0, 1.2)
	col.shape = shape
	col.position.y = 0.5
	add_child(col)

	# Feuer-Partikel
	fire_particles = GPUParticles3D.new()
	var pmat = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 20.0
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3(0, 1, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.15
	pmat.color = Color(1.0, 0.4, 0.1)
	var fmesh = SphereMesh.new()
	fmesh.radius = 0.05
	fmesh.height = 0.1
	fire_particles.process_material = pmat
	fire_particles.draw_pass_1 = fmesh
	fire_particles.amount = 20
	fire_particles.lifetime = 0.6
	fire_particles.emitting = false
	fire_particles.position = Vector3(0, 0.8, 0)
	add_child(fire_particles)

	# Licht
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 0.0
	light.omni_range = 6.0
	light.position.y = 1.2
	add_child(light)
