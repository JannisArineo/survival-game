extends Node3D

@onready var world = $World
@onready var player = $Player
@onready var building_ghost = $BuildingGhost

func _ready():
	# Player erstmal einfrieren bis Terrain da ist
	player.set_physics_process(false)
	player.set_process(false)
	_place_player_on_ground()

func _input(event):
	if event.is_action_pressed("attack"):
		var item = Inventory.get_selected_item_data()
		if item and item.item_type == ItemData.ItemType.BUILDING:
			if building_ghost.try_place():
				get_viewport().set_input_as_handled()

	# RMB = Gebaeude upgraden (wenn kein Bogen gespannt)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var player = GameManager.player
		if player and not player.bow_drawn:
			_try_upgrade_building()

func _try_upgrade_building():
	if GameManager.player == null:
		return
	var camera = GameManager.player.get_node_or_null("Head/Camera3D")
	if camera == null:
		return
	var space = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_basis.z * 5.0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 8  # buildings layer
	var result = space.intersect_ray(query)
	if result.is_empty():
		return
	var collider = result.collider
	if collider == null:
		return
	var body = collider if collider is StaticBody3D else collider.get_parent()
	if body == null:
		return
	var upgrade = body.find_child("BuildingUpgrade", true, false)
	if upgrade:
		upgrade.try_upgrade()
	else:
		# Upgrade-Komponente hinzufuegen wenn noch keine da
		var upgrade_script = preload("res://scenes/buildings/building_upgrade.gd")
		var new_upgrade = Node.new()
		new_upgrade.name = "BuildingUpgrade"
		new_upgrade.set_script(upgrade_script)
		body.add_child(new_upgrade)
		GameManager.show_notification.emit(
			"RMB nochmal fuer Upgrade (aktuell: Holz)",
			Color(0.8, 0.75, 0.5)
		)

func _place_player_on_ground():
	# Warte bis Terrain-Chunks generiert und Physik registriert sind
	for i in 30:
		await get_tree().process_frame
	# Nochmal warten fuer physics
	await get_tree().create_timer(0.5).timeout

	var space = get_world_3d().direct_space_state
	var placed = false

	# Versuche an verschiedenen Positionen
	for attempt in 20:
		var from = Vector3(0, 200, 0)
		var to = Vector3(0, -100, 0)
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 1

		var result = space.intersect_ray(query)
		if result:
			player.global_position = result.position + Vector3(0, 2, 0)
			placed = true
			break
		await get_tree().process_frame

	if not placed:
		player.global_position = Vector3(0, 30, 0)

	# Player aktivieren
	player.set_physics_process(true)
	player.set_process(true)
	player.velocity = Vector3.ZERO
