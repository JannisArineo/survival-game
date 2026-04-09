extends Node

const SAVE_PATH = "user://savegame.json"
var auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL = 300.0  # 5 Minuten

signal game_saved
signal game_loaded

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if GameManager.paused:
		return
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		save_game()

func _input(event):
	if event.is_action_pressed("save_game"):
		save_game()

func save_game():
	var player = GameManager.player
	if player == null:
		return

	var save_data = {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {
			"position": {
				"x": player.global_position.x,
				"y": player.global_position.y,
				"z": player.global_position.z
			},
			"rotation_y": player.rotation.y,
			"health": player.health,
			"hunger": player.hunger,
			"thirst": player.thirst,
			"warmth": player.warmth
		},
		"game": {
			"current_day": GameManager.current_day,
			"current_time": GameManager.current_time
		},
		"inventory": _serialize_inventory(),
		"armor": _serialize_armor(),
		"tool_durability": _serialize_durability(player)
	}

	var json_str = JSON.stringify(save_data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		game_saved.emit()
		_show_save_notification()
		print("[SaveManager] Gespeichert!")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		print("[SaveManager] Fehler beim Laden!")
		return false

	var data = json.data
	_apply_save_data(data)
	game_loaded.emit()
	print("[SaveManager] Geladen!")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _serialize_inventory() -> Array:
	var result = []
	for slot in Inventory.slots:
		if slot == null:
			result.append(null)
		else:
			result.append({"item_id": slot.item_id, "count": slot.count})
	return result

func _serialize_armor() -> Dictionary:
	if not is_instance_valid(ArmorManager):
		return {}
	var result = {}
	for slot_name in ArmorManager.equipped:
		result[slot_name] = ArmorManager.equipped[slot_name]
	return result

func _serialize_durability(player: Node) -> Dictionary:
	if not player.has_method("get_durability_data"):
		return {}
	return player.get_durability_data()

func _apply_save_data(data: Dictionary):
	# Warte bis Player bereit ist
	await get_tree().create_timer(0.2).timeout

	var player = GameManager.player
	if player and data.has("player"):
		var p = data.player
		player.global_position = Vector3(p.position.x, p.position.y, p.position.z)
		player.rotation.y = p.rotation_y
		player.health = p.health
		player.hunger = p.hunger
		player.thirst = p.thirst
		player.warmth = p.warmth

	if data.has("game"):
		var g = data.game
		GameManager.current_day = g.current_day
		GameManager.current_time = g.current_time

	if data.has("inventory"):
		_apply_inventory(data.inventory)

	if data.has("armor") and is_instance_valid(ArmorManager):
		_apply_armor(data.armor)

func _apply_inventory(inv_data: Array):
	Inventory.slots.resize(Inventory.MAX_SLOTS)
	for i in inv_data.size():
		if i >= Inventory.MAX_SLOTS:
			break
		if inv_data[i] == null:
			Inventory.slots[i] = null
		else:
			Inventory.slots[i] = {"item_id": inv_data[i].item_id, "count": inv_data[i].count}
	Inventory.inventory_changed.emit()
	Inventory.hotbar_changed.emit()

func _apply_armor(armor_data: Dictionary):
	for slot_name in armor_data:
		ArmorManager.equipped[slot_name] = armor_data[slot_name]
	ArmorManager.armor_changed.emit()

func _show_save_notification():
	# Wird von HUD gecatcht ueber GameManager Signal
	GameManager.show_notification.emit("Spiel gespeichert!", Color(0.3, 0.9, 0.3))
