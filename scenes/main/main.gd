extends Node3D

@onready var world = $World
@onready var player = $Player
@onready var building_ghost = $BuildingGhost
@onready var navigation_region = $NavigationRegion3D

func _ready():
	# Spieler auf Startposition setzen
	# Warte ein Frame damit Terrain geladen wird
	await get_tree().process_frame
	await get_tree().process_frame
	_place_player_on_ground()

func _input(event):
	# Building placement mit Linksklick wenn im Bau-Modus
	if event.is_action_pressed("attack"):
		var item = Inventory.get_selected_item_data()
		if item and item.item_type == ItemData.ItemType.BUILDING:
			if building_ghost.try_place():
				get_viewport().set_input_as_handled()

func _place_player_on_ground():
	var space = get_world_3d().direct_space_state
	var from = Vector3(0, 100, 0)
	var to = Vector3(0, -50, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1

	# Versuche mehrmals (Terrain muss erst generiert werden)
	for i in 10:
		var result = space.intersect_ray(query)
		if result:
			player.global_position = result.position + Vector3(0, 2, 0)
			return
		await get_tree().process_frame

	# Fallback
	player.global_position = Vector3(0, 30, 0)
