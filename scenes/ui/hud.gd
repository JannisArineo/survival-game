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
var hotbar_colors: Array = []
var hotbar_counts: Array = []
var hotbar_styles: Array = []
var hotbar_dur_bars: Array = []  # Durability bars

# Hit marker
var hit_marker: Control
var hit_marker_timer: float = 0.0

# Notification system
var notification_label: Label
var notification_timer: float = 0.0
var notification_queue: Array = []

# Armor display
var armor_panel: PanelContainer
var armor_labels: Dictionary = {}

# Weather indicator
var weather_label: Label

# Bow charge bar
var bow_bar: ProgressBar

func _ready():
	_setup_hotbar()
	_setup_hit_marker()
	_setup_notifications()
	_setup_armor_panel()
	_setup_weather_label()
	_setup_bow_bar()

	Inventory.hotbar_changed.connect(_update_hotbar)
	Inventory.selected_slot_changed.connect(_update_selection)
	GameManager.show_notification.connect(_queue_notification)
	if is_instance_valid(ArmorManager):
		ArmorManager.armor_changed.connect(_update_armor_display)

func _process(delta):
	if GameManager.player == null:
		return
	var p = GameManager.player

	# Smooth bar updates
	health_bar.value = lerp(health_bar.value, p.health, delta * 8.0)
	hunger_bar.value = lerp(hunger_bar.value, p.hunger, delta * 8.0)
	thirst_bar.value = lerp(thirst_bar.value, p.thirst, delta * 8.0)
	warmth_bar.value = lerp(warmth_bar.value, p.warmth, delta * 8.0)

	# Interaction prompt
	if p.current_interactable:
		interaction_label.text = p.current_interactable.get_prompt()
		interaction_label.visible = true
	else:
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
			elif item.item_type == ItemData.ItemType.ARMOR:
				interaction_label.text = "E / R - " + item.display_name + " anlegen"
				interaction_label.visible = true
			elif item.weapon_type == "bow":
				interaction_label.text = "LMB - Bogen spannen"
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

	# Hit marker fade
	if hit_marker_timer > 0:
		hit_marker_timer -= delta
		hit_marker.modulate.a = hit_marker_timer / 0.3
		if hit_marker_timer <= 0:
			hit_marker.visible = false

	# Notification
	_process_notifications(delta)

	# Durability update
	_update_durability_bars(p)

	# Bow charge
	_update_bow_bar(p)

func _setup_hotbar():
	for i in Inventory.HOTBAR_SLOTS:
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.08, 0.08, 0.08, 0.75)
		stylebox.border_color = Color(0.3, 0.3, 0.3, 0.8)
		stylebox.set_border_width_all(2)
		stylebox.set_corner_radius_all(4)

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 64)
		panel.add_theme_stylebox_override("panel", stylebox)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var key_label = Label.new()
		key_label.text = str(i + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		key_label.add_theme_font_size_override("font_size", 10)
		key_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(44, 44)
		color_rect.color = Color(0, 0, 0, 0)

		var count_label = Label.new()
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 11)

		# Durability bar
		var dur_bar = ProgressBar.new()
		dur_bar.custom_minimum_size = Vector2(50, 4)
		dur_bar.max_value = 1.0
		dur_bar.value = 1.0
		dur_bar.show_percentage = false
		var dur_style = StyleBoxFlat.new()
		dur_style.bg_color = Color(0.2, 0.8, 0.2)
		dur_bar.add_theme_stylebox_override("fill", dur_style)
		var dur_bg = StyleBoxFlat.new()
		dur_bg.bg_color = Color(0.15, 0.15, 0.15)
		dur_bar.add_theme_stylebox_override("background", dur_bg)
		dur_bar.visible = false

		vbox.add_child(key_label)
		vbox.add_child(color_rect)
		vbox.add_child(count_label)
		vbox.add_child(dur_bar)
		panel.add_child(vbox)
		hotbar_container.add_child(panel)

		hotbar_slots.append(panel)
		hotbar_colors.append(color_rect)
		hotbar_counts.append(count_label)
		hotbar_styles.append(stylebox)
		hotbar_dur_bars.append(dur_bar)

	_update_hotbar()
	_update_selection(0)

func _setup_hit_marker():
	hit_marker = Control.new()
	hit_marker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hit_marker.visible = false
	add_child(hit_marker)

	var size = 10
	var gap = 5
	var colors = [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9)]
	# 4 Linien: top, bottom, left, right
	for i in 4:
		var line = ColorRect.new()
		line.color = Color(1, 1, 1, 0.9)
		match i:
			0: # top
				line.size = Vector2(2, size)
				line.position = Vector2(-1, -(gap + size))
			1: # bottom
				line.size = Vector2(2, size)
				line.position = Vector2(-1, gap)
			2: # left
				line.size = Vector2(size, 2)
				line.position = Vector2(-(gap + size), -1)
			3: # right
				line.size = Vector2(size, 2)
				line.position = Vector2(gap, -1)
		hit_marker.add_child(line)

func show_hit_marker():
	hit_marker.visible = true
	hit_marker.modulate.a = 1.0
	hit_marker_timer = 0.3

func _setup_notifications():
	notification_label = Label.new()
	notification_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notification_label.position.y = 80
	notification_label.size.x = 600
	notification_label.position.x = -300
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 18)
	notification_label.add_theme_color_override("font_color", Color.WHITE)
	notification_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	notification_label.add_theme_constant_override("shadow_offset_x", 2)
	notification_label.add_theme_constant_override("shadow_offset_y", 2)
	notification_label.visible = false
	add_child(notification_label)

func _queue_notification(text: String, color: Color = Color.WHITE):
	notification_queue.append({"text": text, "color": color})

func _process_notifications(delta):
	if notification_timer > 0:
		notification_timer -= delta
		notification_label.modulate.a = minf(notification_timer / 0.3, 1.0) if notification_timer < 0.3 else 1.0
		if notification_timer <= 0:
			notification_label.visible = false
			if not notification_queue.is_empty():
				_show_next_notification()
	elif not notification_queue.is_empty():
		_show_next_notification()

func _show_next_notification():
	var notif = notification_queue.pop_front()
	notification_label.text = notif.text
	notification_label.add_theme_color_override("font_color", notif.color)
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	notification_timer = 2.5

func _setup_armor_panel():
	armor_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.7)
	style.set_corner_radius_all(6)
	armor_panel.add_theme_stylebox_override("panel", style)
	armor_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	armor_panel.position = Vector2(-180, 10)
	armor_panel.size = Vector2(160, 120)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	armor_panel.add_child(vbox)

	var title = Label.new()
	title.text = "Ruestung"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title)

	for slot in ["head", "chest", "legs", "feet"]:
		var hbox = HBoxContainer.new()
		var slot_label = Label.new()
		slot_label.text = slot.capitalize() + ":"
		slot_label.add_theme_font_size_override("font_size", 11)
		slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		slot_label.custom_minimum_size.x = 50
		var item_label = Label.new()
		item_label.text = "-"
		item_label.add_theme_font_size_override("font_size", 11)
		item_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		hbox.add_child(slot_label)
		hbox.add_child(item_label)
		vbox.add_child(hbox)
		armor_labels[slot] = item_label

	add_child(armor_panel)

func _update_armor_display():
	if not is_instance_valid(ArmorManager):
		return
	var display = ArmorManager.get_equipped_display()
	for slot in display:
		if armor_labels.has(slot):
			armor_labels[slot].text = display[slot]

func _setup_weather_label():
	weather_label = Label.new()
	weather_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	weather_label.position = Vector2(10, 70)
	weather_label.add_theme_font_size_override("font_size", 14)
	weather_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	weather_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	weather_label.add_theme_constant_override("shadow_offset_x", 1)
	weather_label.add_theme_constant_override("shadow_offset_y", 1)
	weather_label.text = ""
	add_child(weather_label)

	if is_instance_valid(WeatherManager):
		WeatherManager.weather_changed.connect(_on_weather_changed)

func _on_weather_changed(weather_name: String):
	weather_label.text = "Wetter: " + weather_name

func _setup_bow_bar():
	bow_bar = ProgressBar.new()
	bow_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_CENTER)
	bow_bar.position.y = -120
	bow_bar.position.x = -75
	bow_bar.size = Vector2(150, 12)
	bow_bar.max_value = 1.0
	bow_bar.value = 0.0
	bow_bar.show_percentage = false
	bow_bar.visible = false

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.8, 0.2)
	fill_style.set_corner_radius_all(3)
	bow_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.set_corner_radius_all(3)
	bow_bar.add_theme_stylebox_override("background", bg_style)
	add_child(bow_bar)

func _update_bow_bar(player):
	if player.bow_drawn:
		bow_bar.visible = true
		bow_bar.value = player.bow_draw_time / player.MAX_BOW_DRAW
	else:
		bow_bar.visible = false
		bow_bar.value = 0.0

func _update_durability_bars(player):
	for i in Inventory.HOTBAR_SLOTS:
		var slot_data = Inventory.slots[i]
		if slot_data != null:
			var item = CraftingDB.get_item(slot_data.item_id)
			if item and item.max_durability > 0:
				var pct = player.get_durability_percent(item)
				hotbar_dur_bars[i].visible = true
				hotbar_dur_bars[i].value = pct
				var fill_style = hotbar_dur_bars[i].get_theme_stylebox("fill") as StyleBoxFlat
				if fill_style:
					fill_style.bg_color = Color(1.0 - pct, pct, 0.0) # rot->gruen
			else:
				hotbar_dur_bars[i].visible = false
		else:
			hotbar_dur_bars[i].visible = false

func _update_hotbar():
	for i in Inventory.HOTBAR_SLOTS:
		var slot_data = Inventory.slots[i]
		if slot_data != null:
			var item = CraftingDB.get_item(slot_data.item_id)
			if item:
				hotbar_colors[i].color = item.icon_color
				hotbar_counts[i].text = str(slot_data.count) if slot_data.count > 1 else ""
			else:
				hotbar_colors[i].color = Color(0, 0, 0, 0)
				hotbar_counts[i].text = ""
		else:
			hotbar_colors[i].color = Color(0, 0, 0, 0)
			hotbar_counts[i].text = ""

func _update_selection(index: int):
	for i in hotbar_styles.size():
		if i == index:
			hotbar_styles[i].border_color = Color(1.0, 0.8, 0.2, 1.0)
			hotbar_styles[i].set_border_width_all(3)
			hotbar_styles[i].bg_color = Color(0.15, 0.15, 0.08, 0.85)
		else:
			hotbar_styles[i].border_color = Color(0.3, 0.3, 0.3, 0.8)
			hotbar_styles[i].set_border_width_all(2)
			hotbar_styles[i].bg_color = Color(0.08, 0.08, 0.08, 0.75)
