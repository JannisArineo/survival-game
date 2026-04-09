extends CharacterBody3D

# Movement
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.5
const JUMP_VELOCITY = 5.5
const ACCELERATION = 10.0
const DECELERATION = 8.0

# Mouse
const MOUSE_SENSITIVITY = 0.002
var camera_rotation_x: float = 0.0

# Head bob
const BOB_FREQ = 2.4
const BOB_AMP = 0.04
var bob_timer: float = 0.0

# Interaction
const INTERACT_DISTANCE = 3.5
var current_interactable: Interactable = null

# Survival stats
var health: float = 100.0
var max_health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var warmth: float = 100.0

# Combat
var attack_cooldown: float = 0.0
const ATTACK_RATE = 0.5
const BASE_DAMAGE = 10.0

# Camera shake
var shake_amount: float = 0.0
var shake_decay: float = 5.0

# References
@onready var camera = $Head/Camera3D
@onready var head = $Head
@onready var interact_ray = $Head/Camera3D/InteractRay
@onready var attack_ray = $Head/Camera3D/AttackRay
@onready var hand_mesh = $Head/Camera3D/HandMesh
@onready var damage_overlay = $UI/DamageOverlay

var is_dead: bool = false
var inventory_open: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.player = self

func _unhandled_input(event):
	if is_dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_rotation_x = clampf(camera_rotation_x - event.relative.y * MOUSE_SENSITIVITY, -PI/2.0, PI/2.0)
		head.rotation.x = camera_rotation_x

	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("attack") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_try_attack()

	if event.is_action_pressed("pause"):
		_toggle_pause()

func _physics_process(delta):
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	# Jump
	if Input.is_action_pressed("jump") and is_on_floor() and not inventory_open:
		velocity.y = JUMP_VELOCITY

	# Movement
	var speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var input_dir = Vector2.ZERO
	if not inventory_open:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)

	move_and_slide()

	# Head bob
	if is_on_floor() and direction:
		bob_timer += delta * velocity.length()
		var bob_offset = sin(bob_timer * BOB_FREQ) * BOB_AMP
		camera.position.y = bob_offset
	else:
		bob_timer = 0.0
		camera.position.y = lerp(camera.position.y, 0.0, delta * 10.0)

	# Camera shake
	if shake_amount > 0:
		camera.h_offset = randf_range(-shake_amount, shake_amount)
		camera.v_offset = randf_range(-shake_amount, shake_amount)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

	# Attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# Interaction raycast check
	_check_interaction()

	# Survival ticks
	_process_survival(delta)

func _process_survival(delta):
	# Hunger sinkt
	hunger = maxf(0.0, hunger - 0.1 * delta)
	# Durst sinkt schneller
	thirst = maxf(0.0, thirst - 0.15 * delta)

	# Waerme: nachts sinkt sie
	if GameManager.is_night:
		warmth = maxf(0.0, warmth - 0.2 * delta)
	else:
		warmth = minf(100.0, warmth + 0.3 * delta)

	# Health Effekte
	if hunger <= 0.0:
		take_damage(0.5 * delta)
	if thirst <= 0.0:
		take_damage(0.8 * delta)
	if warmth <= 10.0:
		take_damage(0.3 * delta)

	# Health Regen wenn alles gut
	if hunger > 50.0 and thirst > 30.0:
		health = minf(max_health, health + 0.2 * delta)

func take_damage(amount: float):
	if is_dead:
		return
	health = maxf(0.0, health - amount)
	if amount > 1.0:
		shake_amount = 0.02
		if damage_overlay:
			_flash_damage()
	if health <= 0.0:
		_die()

func heal(amount: float):
	health = minf(max_health, health + amount)

func _die():
	is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.player_died.emit()

func _check_interaction():
	if interact_ray and interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider:
			var interactable = _find_interactable(collider)
			if interactable and interactable != current_interactable:
				current_interactable = interactable
			elif not interactable:
				current_interactable = null
		else:
			current_interactable = null
	else:
		current_interactable = null

func _find_interactable(node: Node) -> Interactable:
	# Suche in dem Node und seinen Kindern nach einem Interactable
	for child in node.get_children():
		if child is Interactable:
			return child
	if node.get_parent():
		for child in node.get_parent().get_children():
			if child is Interactable:
				return child
	return null

func _try_interact():
	if current_interactable and current_interactable.can_interact(self):
		current_interactable.interact(self)

	# Essen/Trinken aus Hotbar
	var item_data = Inventory.get_selected_item_data()
	if item_data == null:
		return
	if item_data.item_type == ItemData.ItemType.FOOD:
		var slot = Inventory.get_selected_item()
		hunger = minf(100.0, hunger + item_data.hunger_restore)
		thirst = minf(100.0, thirst + item_data.thirst_restore)
		Inventory.remove_item(slot.item_id, 1)
	elif item_data.item_type == ItemData.ItemType.MEDICAL:
		var slot = Inventory.get_selected_item()
		heal(item_data.heal_amount)
		Inventory.remove_item(slot.item_id, 1)

func _try_attack():
	if attack_cooldown > 0:
		return
	attack_cooldown = ATTACK_RATE

	# Hand swing animation (simple)
	_swing_hand()

	var damage = BASE_DAMAGE
	var item_data = Inventory.get_selected_item_data()
	if item_data and item_data.item_type == ItemData.ItemType.TOOL:
		damage = item_data.damage

	if attack_ray and attack_ray.is_colliding():
		var collider = attack_ray.get_collider()
		if collider:
			# Suche HitboxComponent oder resource_base
			if collider.has_method("receive_hit"):
				collider.receive_hit(damage, self)
			elif collider.get_parent() and collider.get_parent().has_method("receive_hit"):
				collider.get_parent().receive_hit(damage, self)

func _swing_hand():
	if hand_mesh:
		var tween = create_tween()
		tween.tween_property(hand_mesh, "rotation:x", -0.5, 0.1)
		tween.tween_property(hand_mesh, "rotation:x", 0.0, 0.2)

func _flash_damage():
	if damage_overlay:
		var tween = create_tween()
		damage_overlay.modulate = Color(1, 0, 0, 0.3)
		tween.tween_property(damage_overlay, "modulate", Color(1, 0, 0, 0), 0.3)

func toggle_inventory():
	inventory_open = !inventory_open
	if inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_pause():
	GameManager.paused = !GameManager.paused
	get_tree().paused = GameManager.paused
	if GameManager.paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func apply_warmth(amount: float, delta: float):
	warmth = minf(100.0, warmth + amount * delta)
