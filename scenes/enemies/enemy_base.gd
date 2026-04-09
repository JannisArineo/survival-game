extends CharacterBody3D

enum State { IDLE, WANDER, CHASE, ATTACK, FLEE, DEAD }

@export var max_health: float = 50.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 2.5
@export var chase_range: float = 20.0
@export var aggro_range: float = 10.0
@export var attack_cooldown: float = 1.5
@export var drop_items: Dictionary = {} # item_id -> {min, max}
@export var body_color: Color = Color(0.5, 0.5, 0.5)
@export var is_passive: bool = false # Greift nur an wenn provoziert

var current_health: float
var state: State = State.IDLE
var target: Node3D = null
var wander_target: Vector3
var attack_timer: float = 0.0
var idle_timer: float = 0.0
var provoked: bool = false
var gravity: float = 20.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var eye_left: MeshInstance3D = $BodyMesh/EyeLeft
@onready var eye_right: MeshInstance3D = $BodyMesh/EyeRight

func _ready():
	current_health = max_health
	collision_layer = 16 # enemies layer
	collision_mask = 3 # terrain + player

	# Farbe setzen
	if body_mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = body_color
		mat.roughness = 0.9
		body_mesh.material_override = mat

	_start_idle()

func _physics_process(delta):
	if state == State.DEAD:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Attack timer
	if attack_timer > 0:
		attack_timer -= delta

	match state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.FLEE:
			_process_flee(delta)

	move_and_slide()

func _process_idle(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		_start_wander()
		return

	# Aggro check
	_check_aggro()

func _process_wander(delta):
	if nav_agent.is_navigation_finished():
		_start_idle()
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * move_speed * 0.5
	velocity.z = direction.z * move_speed * 0.5

	# Drehen in Bewegungsrichtung
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

	_check_aggro()

func _process_chase(delta):
	if target == null or not is_instance_valid(target):
		_start_idle()
		return

	var dist = global_position.distance_to(target.global_position)

	if dist > chase_range:
		_start_idle()
		return

	if dist < attack_range:
		state = State.ATTACK
		velocity.x = 0
		velocity.z = 0
		return

	nav_agent.target_position = target.global_position
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func _process_attack(delta):
	if target == null or not is_instance_valid(target):
		_start_idle()
		return

	var dist = global_position.distance_to(target.global_position)
	if dist > attack_range * 1.5:
		state = State.CHASE
		return

	# Zum Ziel schauen
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0
	if dir.length() > 0.1:
		look_at(global_position + dir, Vector3.UP)

	if attack_timer <= 0:
		_do_attack()
		attack_timer = attack_cooldown

func _process_flee(delta):
	if target == null or not is_instance_valid(target):
		_start_idle()
		return

	var dir = (global_position - target.global_position).normalized()
	var flee_pos = global_position + dir * 20.0
	nav_agent.target_position = flee_pos

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * move_speed * 1.3
	velocity.z = direction.z * move_speed * 1.3

	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

	var dist = global_position.distance_to(target.global_position)
	if dist > chase_range * 1.5:
		_start_idle()

func _check_aggro():
	if GameManager.player == null:
		return
	var dist = global_position.distance_to(GameManager.player.global_position)

	if is_passive and not provoked:
		return

	# Nachts aggressiver
	var effective_range = aggro_range
	if GameManager.is_night:
		effective_range *= 1.5

	if dist < effective_range:
		target = GameManager.player
		state = State.CHASE

func _do_attack():
	if target and target.has_method("take_damage"):
		target.take_damage(attack_damage)
		# Attack Animation (einfach: nach vorne springen)
		var tween = create_tween()
		var forward = -global_basis.z * 0.5
		tween.tween_property(self, "position", position + forward, 0.1)
		tween.tween_property(self, "position", position, 0.15)

func receive_hit(damage: float, attacker: Node3D = null):
	current_health -= damage
	provoked = true

	# Hit flash
	_flash_hit()

	# Damage number
	_spawn_damage_number(damage)

	if current_health <= 0:
		_die()
		return

	# Aggro auf Angreifer
	if attacker:
		target = attacker
		if current_health < max_health * 0.2:
			state = State.FLEE
		else:
			state = State.CHASE

func _flash_hit():
	if body_mesh and body_mesh.material_override:
		var original_color = body_color
		var mat = body_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color.WHITE
		var tween = create_tween()
		tween.tween_property(mat, "albedo_color", original_color, 0.15)

func _spawn_damage_number(damage: float):
	var label = Label3D.new()
	label.text = str(int(damage))
	label.font_size = 48
	label.modulate = Color(1, 0.2, 0.2)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 2, 0)
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "position:y", 3.5, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _die():
	state = State.DEAD
	velocity = Vector3.ZERO

	# Drop loot
	for item_id in drop_items:
		var rng = RandomNumberGenerator.new()
		var count = rng.randi_range(drop_items[item_id].min, drop_items[item_id].max)
		Inventory.add_item(item_id, count)

	# Death animation
	var tween = create_tween()
	tween.tween_property(self, "scale:y", 0.1, 0.5)
	tween.parallel().tween_property(self, "rotation:z", PI / 2, 0.5)
	tween.tween_interval(2.0)
	tween.tween_callback(queue_free)

func _start_idle():
	state = State.IDLE
	idle_timer = randf_range(2.0, 5.0)
	velocity.x = 0
	velocity.z = 0
	target = null
	provoked = false

func _start_wander():
	state = State.WANDER
	var offset = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
	wander_target = global_position + offset
	nav_agent.target_position = wander_target
