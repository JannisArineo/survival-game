extends CanvasLayer

@onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
@onready var hunger_bar = $MarginContainer/VBoxContainer/HungerBar
@onready var thirst_bar = $MarginContainer/VBoxContainer/ThirstBar
@onready var warmth_bar = $MarginContainer/VBoxContainer/WarmthBar
@onready var hotbar_container = $HotbarContainer
@onready var crosshair = $Crosshair
@onready var interaction_label = $InteractionLabel
@onready var day_label = $DayLabel

var hotbar_slots: Array = []

func _ready():
	_setup_hotbar()
	Inventory.hotbar_changed.connect(_update_hotbar)
	Inventory.selected_slot_changed.connect(_update_selection)

func _process(_delta):
	if GameManager.player == null:
		return
	var p = GameManager.player

	health_bar.value = p.health
	hunger_bar.value = p.hunger
	thirst_bar.value = p.thirst
	warmth_bar.value = p.warmth

	# Interaction prompt
	if p.current_interactable:
		interaction_label.text = p.current_interactable.get_prompt()
		interaction_label.visible = true
	else:
		# Zeige Hotbar-Item Info
		var item = Inventory.get_selected_item_data()
		if item:
			if item.item_type == ItemData.ItemType.FOOD:
				interaction_label.text = "E - " + item.display_name + " essen"
				interaction_label.visible = true
			elif item.item_type == ItemData.ItemType.MEDICAL:
				interaction_label.text = "E - " + item.display_name + " benutzen"
				interaction_label.visible = true
			elif item.item_type == ItemData.ItemType.BUILDING:
				interaction_label.text = "LMB - " + item.display_name + " platzieren"
				interaction_label.visible = true
			else:
				interaction_label.visible = false
		else:
			interaction_label.visible = false

	# Tag/Zeit
	var hour = GameManager.get_hour()
	var h = int(hour)
	var m = int((hour - h) * 60)
	day_label.text = "Tag %d  %02d:%02d" % [GameManager.current_day, h, m]

func _setup_hotbar():
	for i in Inventory.HOTBAR_SLOTS:
		var slot = _create_hotbar_slot(i)
		hotbar_container.add_child(slot)
		hotbar_slots.append(slot)
	_update_hotbar()
	_update_selection(0)

func _create_hotbar_slot(index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(60, 60)

	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.7)
	stylebox.border_color = Color(0.3, 0.3, 0.3, 0.8)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", stylebox)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = Vector2(40, 40)
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.name = "ItemColor"

	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.name = "CountLabel"

	var key_label = Label.new()
	key_label.text = str(index + 1)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	key_label.name = "KeyLabel"

	vbox.add_child(key_label)
	vbox.add_child(color_rect)
	vbox.add_child(label)
	panel.add_child(vbox)

	return panel

func _update_hotbar():
	for i in Inventory.HOTBAR_SLOTS:
		var slot_data = Inventory.slots[i]
		var panel = hotbar_slots[i]
		var color_rect = panel.get_node("VBoxContainer/ItemColor")
		var count_label = panel.get_node("VBoxContainer/CountLabel")

		if slot_data != null:
			var item = CraftingDB.get_item(slot_data.item_id)
			if item:
				color_rect.color = item.icon_color
				count_label.text = str(slot_data.count) if slot_data.count > 1 else ""
			else:
				color_rect.color = Color(0, 0, 0, 0)
				count_label.text = ""
		else:
			color_rect.color = Color(0, 0, 0, 0)
			count_label.text = ""

func _update_selection(index: int):
	for i in hotbar_slots.size():
		var panel = hotbar_slots[i]
		var stylebox = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if i == index:
			stylebox.border_color = Color(1.0, 0.8, 0.2, 1.0)
			stylebox.set_border_width_all(3)
		else:
			stylebox.border_color = Color(0.3, 0.3, 0.3, 0.8)
			stylebox.set_border_width_all(2)
