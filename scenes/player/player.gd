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

# Bow
var bow_drawn: bool = false
var bow_draw_time: float = 0.0
const MAX_BOW_DRAW = 2.0
const BOW_MIN_FORCE = 15.0
const BOW_MAX_FORCE = 45.0

# Durability (item_id -> current_durability)
var tool_durability: Dictionary = {}

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
		var item_data = Inventory.get_selected_item_data()
		if item_data and item_data.weapon_type == "bow":
			_start_bow_draw()
		else:
			_try_attack()

	if event.is_action_released("attack"):
		if bow_drawn:
			_release_bow()

	if event.is_action_pressed("pause"):
		_toggle_pause()

	# Ruestung anlegen mit R
	if event.is_action_pressed("equip_armor"):
		_try_equip_armor()

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

	# Head bob + Footstep Sounds
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

	# Bow draw
	if bow_drawn:
		bow_draw_time = minf(bow_draw_time + delta, MAX_BOW_DRAW)

	# Interaction raycast check
	_check_interaction()

	# Survival ticks
	_process_survival(delta)

func _process_survival(delta):
	# Hunger sinkt
	hunger = maxf(0.0, hunger - 0.1 * delta)
	# Durst sinkt schneller
	thirst = maxf(0.0, thirst - 0.15 * delta)

	# Waerme: nachts sinkt sie + Wettereinfluss
	var cold_mult = WeatherManager.get_cold_multiplier() if is_instance_valid(WeatherManager) else 1.0
	if GameManager.is_night:
		warmth = maxf(0.0, warmth - 0.2 * delta * cold_mult)
	else:
		warmth = minf(100.0, warmth + 0.3 * delta)

	# Regen macht auch kalt
	if is_instance_valid(WeatherManager) and WeatherManager.current_weather != WeatherManager.WeatherType.CLEAR:
		warmth = maxf(0.0, warmth - 0.1 * delta * cold_mult)

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
	# Armor Reduktion
	if is_instance_valid(ArmorManager):
		amount = ArmorManager.apply_damage_reduction(amount)
	health = maxf(0.0, health - amount)
	if amount > 1.0:
		shake_amount = 0.02
		if damage_overlay:
			_flash_damage()
		_spawn_damage_number(amount)
	if health <= 0.0:
		_die()

func heal(amount: float):
	health = minf(max_health, health + amount)

func _die():
	is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_death()
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
		return

	# Essen/Trinken aus Hotbar
	var item_data = Inventory.get_selected_item_data()
	if item_data == null:
		return
	if item_data.item_type == ItemData.ItemType.FOOD:
		var slot = Inventory.get_selected_item()
		hunger = minf(100.0, hunger + item_data.hunger_restore)
		thirst = minf(100.0, thirst + item_data.thirst_restore)
		if item_data.heal_amount != 0:
			health = clampf(health + item_data.heal_amount, 0, max_health)
		Inventory.remove_item(slot.item_id, 1)
		AudioManager.play_pickup()
	elif item_data.item_type == ItemData.ItemType.MEDICAL:
		var slot = Inventory.get_selected_item()
		heal(item_data.heal_amount)
		Inventory.remove_item(slot.item_id, 1)
		AudioManager.play_pickup()
	elif item_data.item_type == ItemData.ItemType.ARMOR:
		var slot = Inventory.get_selected_item()
		ArmorManager.equip(slot.item_id)

func _try_attack():
	if attack_cooldown > 0:
		return
	attack_cooldown = ATTACK_RATE

	_swing_hand()
	AudioManager.play_attack()

	var damage = BASE_DAMAGE
	var item_data = Inventory.get_selected_item_data()
	if item_data and item_data.item_type == ItemData.ItemType.TOOL:
		damage = item_data.damage
		_use_durability(item_data)

	if attack_ray and attack_ray.is_colliding():
		var collider = attack_ray.get_collider()
		if collider:
			var hit_pos = attack_ray.get_collision_point()
			AudioManager.play_hit(hit_pos, "stone")
			if collider.has_method("receive_hit"):
				collider.receive_hit(damage, self)
			elif collider.get_parent() and collider.get_parent().has_method("receive_hit"):
				collider.get_parent().receive_hit(damage, self)

# === BOW SYSTEM ===

func _start_bow_draw():
	if not Inventory.has_item("arrow", 1):
		GameManager.show_notification.emit("Keine Pfeile!", Color(0.9, 0.3, 0.3))
		return
	bow_drawn = true
	bow_draw_time = 0.0
	AudioManager.play_bow_draw()

func _release_bow():
	if not bow_drawn:
		return
	bow_drawn = false
	if bow_draw_time < 0.3:  # Zu frueh losgelassen
		return

	var force = lerp(BOW_MIN_FORCE, BOW_MAX_FORCE, bow_draw_time / MAX_BOW_DRAW)
	_shoot_arrow(force)
	Inventory.remove_item("arrow", 1)
	AudioManager.play_bow_release()

	var item_data = Inventory.get_selected_item_data()
	if item_data:
		_use_durability(item_data)

func _shoot_arrow(force: float):
	var arrow_script = preload("res://scenes/items/arrow.gd")
	var arrow = RigidBody3D.new()
	arrow.set_script(arrow_script)
	arrow.damage = 25.0 * (force / BOW_MAX_FORCE)
	arrow.fired_by = self

	get_tree().current_scene.add_child(arrow)

	var cam = camera
	arrow.global_position = cam.global_position + (-cam.global_basis.z * 1.0)

	var direction = -cam.global_basis.z
	arrow.linear_velocity = direction * force
	arrow.global_rotation = cam.global_rotation

# === DURABILITY ===

func _use_durability(item_data: ItemData):
	if item_data.max_durability <= 0:
		return
	var current = tool_durability.get(item_data.id, item_data.max_durability)
	current -= 1.0
	if current <= 0:
		current = 0
		GameManager.show_notification.emit(item_data.display_name + " ist kaputt!", Color(0.9, 0.4, 0.1))
		Inventory.remove_item(item_data.id, 1)
		tool_durability.erase(item_data.id)
	else:
		tool_durability[item_data.id] = current

func get_durability_percent(item_data: ItemData) -> float:
	if item_data == null or item_data.max_durability <= 0:
		return 1.0
	var current = tool_durability.get(item_data.id, item_data.max_durability)
	return current / item_data.max_durability

func get_durability_data() -> Dictionary:
	return tool_durability.duplicate()

func _try_equip_armor():
	var item_data = Inventory.get_selected_item_data()
	if item_data and item_data.item_type == ItemData.ItemType.ARMOR:
		var slot = Inventory.get_selected_item()
		if ArmorManager.equip(slot.item_id):
			GameManager.show_notification.emit(item_data.display_name + " angelegt", Color(0.3, 0.8, 0.9))

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

func _spawn_damage_number(amount: float):
	# Damage number wird im 3D-Raum gespawnt
	var label = Label3D.new()
	label.text = "-" + str(int(amount))
	label.font_size = 48
	label.modulate = Color(1.0, 0.3, 0.2)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_tree().current_scene.add_child(label)
	label.global_position = global_position + Vector3(0, 2, 0)

	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y + 1.5, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

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
