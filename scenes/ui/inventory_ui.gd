extends Control

@onready var grid = $Panel/MarginContainer/VBoxContainer/GridContainer
@onready var title_label = $Panel/MarginContainer/VBoxContainer/TitleLabel

var slots_ui: Array = []
var dragging_from: int = -1

func _ready():
	visible = false
	_create_slots()
	Inventory.inventory_changed.connect(_update_slots)

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible
		_update_slots()

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

func _on_slot_pressed(index: int):
	if dragging_from == -1:
		if Inventory.slots[index] != null:
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
				btn.text = item.display_name + "\n" + str(slot_data.count)
				btn.modulate = item.icon_color.lightened(0.3)
			else:
				btn.text = ""
				btn.modulate = Color.WHITE
		else:
			btn.text = ""
			btn.modulate = Color.WHITE
