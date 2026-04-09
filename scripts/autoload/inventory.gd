extends Node

signal inventory_changed
signal hotbar_changed
signal selected_slot_changed(index: int)

const MAX_SLOTS = 30
const HOTBAR_SLOTS = 6

var slots: Array = [] # Array of {item_id: String, count: int} or null
var selected_hotbar: int = 0

func _ready():
	slots.resize(MAX_SLOTS)
	for i in MAX_SLOTS:
		slots[i] = null

func _input(event):
	if event is InputEventKey and event.pressed:
		for i in HOTBAR_SLOTS:
			if event.is_action("hotbar_" + str(i + 1)):
				select_hotbar(i)
				return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_hotbar((selected_hotbar - 1 + HOTBAR_SLOTS) % HOTBAR_SLOTS)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_hotbar((selected_hotbar + 1) % HOTBAR_SLOTS)

func select_hotbar(index: int):
	selected_hotbar = clampi(index, 0, HOTBAR_SLOTS - 1)
	selected_slot_changed.emit(selected_hotbar)

func get_selected_item() -> Dictionary:
	if slots[selected_hotbar] == null:
		return {}
	return slots[selected_hotbar]

func get_selected_item_data() -> ItemData:
	var slot = get_selected_item()
	if slot.is_empty():
		return null
	return CraftingDB.get_item(slot.item_id)

func add_item(item_id: String, count: int = 1) -> int:
	var item_data = CraftingDB.get_item(item_id)
	if item_data == null:
		return count
	var remaining = count
	# erst existierende Stacks auffuellen
	for i in MAX_SLOTS:
		if remaining <= 0:
			break
		if slots[i] != null and slots[i].item_id == item_id:
			var space = item_data.stack_size - slots[i].count
			var to_add = mini(remaining, space)
			if to_add > 0:
				slots[i].count += to_add
				remaining -= to_add
	# dann leere Slots nehmen
	for i in MAX_SLOTS:
		if remaining <= 0:
			break
		if slots[i] == null:
			var to_add = mini(remaining, item_data.stack_size)
			slots[i] = {item_id = item_id, count = to_add}
			remaining -= to_add
	inventory_changed.emit()
	if selected_hotbar < HOTBAR_SLOTS:
		hotbar_changed.emit()
	return remaining

func remove_item(item_id: String, count: int = 1) -> bool:
	if get_item_count(item_id) < count:
		return false
	var remaining = count
	for i in range(MAX_SLOTS - 1, -1, -1):
		if remaining <= 0:
			break
		if slots[i] != null and slots[i].item_id == item_id:
			var to_remove = mini(remaining, slots[i].count)
			slots[i].count -= to_remove
			remaining -= to_remove
			if slots[i].count <= 0:
				slots[i] = null
	inventory_changed.emit()
	hotbar_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	var total = 0
	for slot in slots:
		if slot != null and slot.item_id == item_id:
			total += slot.count
	return total

func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

func swap_slots(from: int, to: int):
	var temp = slots[from]
	slots[from] = slots[to]
	slots[to] = temp
	inventory_changed.emit()
	hotbar_changed.emit()
