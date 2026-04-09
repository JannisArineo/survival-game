extends StaticBody3D

const WARMTH_RADIUS = 8.0
const WARMTH_AMOUNT = 15.0

var fire_particles: GPUParticles3D
var light: OmniLight3D

func _ready():
	_create_fire_effect()
	_create_light()

	# Interactable fuer Kochen
	var interactable = Interactable.new()
	interactable.interaction_text = "Fleisch kochen"
	interactable.interacted.connect(_on_cook)
	add_child(interactable)

func _process(delta):
	# Waerme an Spieler geben wenn nah genug
	if GameManager.player:
		var dist = global_position.distance_to(GameManager.player.global_position)
		if dist < WARMTH_RADIUS:
			var factor = 1.0 - (dist / WARMTH_RADIUS)
			GameManager.player.apply_warmth(WARMTH_AMOUNT * factor, delta)

	# Licht flackern
	if light:
		light.light_energy = randf_range(1.5, 2.5)

func _on_cook(player: Node3D):
	if Inventory.has_item("raw_meat", 1):
		Inventory.remove_item("raw_meat", 1)
		Inventory.add_item("cooked_meat", 1)

func _create_fire_effect():
	fire_particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 2, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = Color(1.0, 0.5, 0.1)
	mat.color_ramp = _create_fire_gradient()

	var mesh = SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16

	fire_particles.process_material = mat
	fire_particles.draw_pass_1 = mesh
	fire_particles.amount = 30
	fire_particles.lifetime = 0.8
	fire_particles.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	fire_particles.position.y = 0.3
	add_child(fire_particles)

func _create_fire_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 0.8, 0.2, 1.0),
		Color(1.0, 0.3, 0.0, 0.8),
		Color(0.3, 0.1, 0.0, 0.0)
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return gradient

func _create_light():
	light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 2.0
	light.omni_range = 10.0
	light.position.y = 1.0
	light.shadow_enabled = true
	add_child(light)
