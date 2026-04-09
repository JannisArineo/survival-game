extends Control

@onready var grid = $Panel/MarginContainer/VBoxContainer/GridContainer
@onready var title_label = $Panel/MarginContainer/VBoxContainer/TitleLabel

var slots_ui: Array = []
var dragging_from: int = -1

# Armor slots UI
var armor_panel: VBoxContainer
var armor_slot_buttons: Dictionary = {}

func _ready():
	visible = false
	_create_slots()
	_create_armor_panel()
	Inventory.inventory_changed.connect(_update_slots)
	if is_instance_valid(ArmorManager):
		ArmorManager.armor_changed.connect(_update_armor_slots)

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible
		if visible:
			_update_slots()
			_update_armor_slots()

func _create_slots():
	for i in Inventory.MAX_SLOTS:
		var slot = _create_slot(i)
		grid.add_child(slot)
		slots_ui.append(slot)

func _create_slot(index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(55, 55)
	btn.clip_text = true

	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	stylebox.border_color = Color(0.3, 0.3, 0.3)
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", stylebox)

	var hover_style = stylebox.duplicate()
	hover_style.border_color = Color(0.6, 0.6, 0.3)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_slot_pressed.bind(index))
	btn.add_theme_font_size_override("font_size", 10)

	return btn

func _create_armor_panel():
	# Armor-Panel rechts neben dem Inventar
	var parent = $Panel/MarginContainer/VBoxContainer
	armor_panel = VBoxContainer.new()
	armor_panel.add_theme_constant_override("separation", 6)
	parent.add_child(armor_panel)

	var armor_title = Label.new()
	armor_title.text = "-- Ruestung --"
	armor_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	armor_title.add_theme_font_size_override("font_size", 14)
	armor_title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.55))
	armor_panel.add_child(armor_title)

	var slots_info = {
		"head": "Kopf",
		"chest": "Brust",
		"legs": "Beine",
		"feet": "Fuesse"
	}

	for slot_id in ["head", "chest", "legs", "feet"]:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		var slot_label = Label.new()
		slot_label.text = slots_info[slot_id] + ":"
		slot_label.custom_minimum_size.x = 60
		slot_label.add_theme_font_size_override("font_size", 12)
		slot_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		var item_btn = Button.new()
		item_btn.text = "- leer -"
		item_btn.custom_minimum_size = Vector2(140, 32)
		item_btn.add_theme_font_size_override("font_size", 11)
		item_btn.pressed.connect(_on_armor_unequip.bind(slot_id))

		hbox.add_child(slot_label)
		hbox.add_child(item_btn)
		armor_panel.add_child(hbox)
		armor_slot_buttons[slot_id] = item_btn

	# Armor-Wert Anzeige
	var armor_value_label = Label.new()
	armor_value_label.name = "ArmorValueLabel"
	armor_value_label.text = "Schutz: 0%"
	armor_value_label.add_theme_font_size_override("font_size", 12)
	armor_value_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	armor_panel.add_child(armor_value_label)

func _on_armor_unequip(slot_id: String):
	if is_instance_valid(ArmorManager):
		ArmorManager.unequip(slot_id)

func _update_armor_slots():
	if not is_instance_valid(ArmorManager):
		return
	for slot_id in armor_slot_buttons:
		var btn = armor_slot_buttons[slot_id]
		var item_id = ArmorManager.equipped.get(slot_id, "")
		if item_id.is_empty():
			btn.text = "- leer -"
			btn.modulate = Color(0.6, 0.6, 0.6)
		else:
			var item = CraftingDB.get_item(item_id)
			btn.text = item.display_name if item else item_id
			btn.modulate = item.icon_color.lightened(0.2) if item else Color.WHITE

	var armor_val_label = armor_panel.find_child("ArmorValueLabel", true, false)
	if armor_val_label:
		var pct = int(ArmorManager.get_total_armor() * 100)
		armor_val_label.text = "Schutz: " + str(pct) + "%"

func _on_slot_pressed(index: int):
	if dragging_from == -1:
		if Inventory.slots[index] != null:
			# Pruefen ob Ruestung: dann direkt anlegen
			var item = CraftingDB.get_item(Inventory.slots[index].item_id)
			if item and item.item_type == ItemData.ItemType.ARMOR and is_instance_valid(ArmorManager):
				ArmorManager.equip(item.id)
				_update_slots()
				_update_armor_slots()
				return
			dragging_from = index
			_highlight_slot(index, true)
	else:
		Inventory.swap_slots(dragging_from, index)
		_highlight_slot(dragging_from, false)
		dragging_from = -1
		_update_slots()

func _highlight_slot(index: int, highlight: bool):
	var btn = slots_ui[index]
	var stylebox = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if highlight:
		stylebox.border_color = Color(1.0, 0.8, 0.2)
		stylebox.set_border_width_all(2)
	else:
		stylebox.border_color = Color(0.3, 0.3, 0.3)
		stylebox.set_border_width_all(1)

func _update_slots():
	for i in Inventory.MAX_SLOTS:
		var btn = slots_ui[i]
		var slot_data = Inventory.slots[i]
		if slot_data != null:
			var item = CraftingDB.get_item(slot_data.item_id)
			if item:
				var count_str = " x" + str(slot_data.count) if slot_data.count > 1 else ""
				btn.text = item.display_name + count_str
				btn.modulate = item.icon_color.lightened(0.3)
			else:
				btn.text = "?"
				btn.modulate = Color.WHITE
		else:
			btn.text = ""
			btn.modulate = Color.WHITE
