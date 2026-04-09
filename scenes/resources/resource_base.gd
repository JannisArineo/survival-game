extends StaticBody3D

signal destroyed

@export var resource_id: String = "wood"
@export var drop_count_min: int = 3
@export var drop_count_max: int = 8
@export var max_health: float = 50.0
@export var respawn_time: float = 120.0

var current_health: float
var is_destroyed: bool = false
var original_scale: Vector3

func _ready():
	current_health = max_health
	original_scale = scale
	collision_layer = 4 # resources layer
	collision_mask = 0

func receive_hit(damage: float, attacker: Node3D = null):
	if is_destroyed:
		return

	# Tool-Bonus pruefen
	var item_data = Inventory.get_selected_item_data()
	if item_data and item_data.item_type == ItemData.ItemType.TOOL:
		damage *= item_data.harvest_speed

	current_health -= damage

	# Treffer-Animation
	_hit_animation()

	# Partikel spawnen
	_spawn_hit_particles()

	if current_health <= 0:
		_drop_resources()
		_destroy()

func _hit_animation():
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 0.9, 0.05)
	tween.tween_property(self, "scale", original_scale, 0.1)

func _spawn_hit_particles():
	var particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -10, 0)
	mat.color = _get_particle_color()

	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1

	particles.process_material = mat
	particles.draw_pass_1 = mesh
	particles.amount = 8
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.8
	particles.emitting = true

	get_parent().add_child(particles)
	particles.global_position = global_position + Vector3(0, 1, 0)

	# Cleanup nach Lifetime
	get_tree().create_timer(1.0).timeout.connect(func(): particles.queue_free())

func _get_particle_color() -> Color:
	match resource_id:
		"wood": return Color(0.55, 0.35, 0.15)
		"stone": return Color(0.5, 0.5, 0.5)
		"metal": return Color(0.6, 0.6, 0.65)
		_: return Color.WHITE

func _drop_resources():
	var rng = RandomNumberGenerator.new()
	var count = rng.randi_range(drop_count_min, drop_count_max)
	Inventory.add_item(resource_id, count)

func _destroy():
	is_destroyed = true
	destroyed.emit()

	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(func():
		visible = false
		# Respawn timer
		get_tree().create_timer(respawn_time).timeout.connect(_respawn)
	)

func _respawn():
	is_destroyed = false
	current_health = max_health
	visible = true
	var tween = create_tween()
	scale = Vector3.ZERO
	tween.tween_property(self, "scale", original_scale, 0.5)
