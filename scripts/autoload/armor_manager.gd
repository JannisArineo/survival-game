extends Node

signal armor_changed

# slot_name -> item_id or ""
var equipped: Dictionary = {
	"head": "",
	"chest": "",
	"legs": "",
	"feet": ""
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func equip(item_id: String) -> bool:
	var item = CraftingDB.get_item(item_id)
	if item == null or item.item_type != ItemData.ItemType.ARMOR:
		return false

	var slot = _get_slot_name(item.armor_slot)
	if slot.is_empty():
		return false

	# Altes Item zurueck ins Inventar
	if not equipped[slot].is_empty():
		Inventory.add_item(equipped[slot], 1)

	# Aus Inventar entfernen
	Inventory.remove_item(item_id, 1)

	equipped[slot] = item_id
	armor_changed.emit()
	return true

func unequip(slot_name: String):
	if not equipped.has(slot_name):
		return
	if equipped[slot_name].is_empty():
		return
	Inventory.add_item(equipped[slot_name], 1)
	equipped[slot_name] = ""
	armor_changed.emit()

func get_total_armor() -> float:
	var total = 0.0
	for slot in equipped:
		if not equipped[slot].is_empty():
			var item = CraftingDB.get_item(equipped[slot])
			if item:
				total += item.armor_value
	return minf(total, 0.75)  # Max 75% Schadensreduktion

func apply_damage_reduction(damage: float) -> float:
	return damage * (1.0 - get_total_armor())

func _get_slot_name(slot: int) -> String:
	match slot:
		ItemData.ArmorSlot.HEAD: return "head"
		ItemData.ArmorSlot.CHEST: return "chest"
		ItemData.ArmorSlot.LEGS: return "legs"
		ItemData.ArmorSlot.FEET: return "feet"
	return ""

func get_equipped_display() -> Dictionary:
	var result = {}
	for slot in equipped:
		if not equipped[slot].is_empty():
			var item = CraftingDB.get_item(equipped[slot])
			result[slot] = item.display_name if item else "?"
		else:
			result[slot] = "-"
	return result
