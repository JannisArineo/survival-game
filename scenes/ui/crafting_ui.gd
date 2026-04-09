extends Control

@onready var recipe_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RecipeList
@onready var craft_button = $Panel/MarginContainer/VBoxContainer/CraftButton
@onready var info_label = $Panel/MarginContainer/VBoxContainer/InfoLabel

var selected_recipe: RecipeData = null
var recipe_buttons: Array = []
var current_filter: String = ""

# Kategorie-Buttons werden dynamisch erstellt
var filter_container: HBoxContainer

func _ready():
	visible = false
	craft_button.pressed.connect(_on_craft)
	_setup_filter_buttons()
	_build_recipe_list()
	Inventory.inventory_changed.connect(_refresh_recipes)

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible
		if visible:
			_refresh_recipes()

func _setup_filter_buttons():
	# Filter-Bar ueber der Recipe-Liste einfuegen
	var panel = $Panel/MarginContainer/VBoxContainer
	filter_container = HBoxContainer.new()
	filter_container.add_theme_constant_override("separation", 4)
	panel.move_child(filter_container, 0)

	var categories = [
		{"id": "", "label": "Alle"},
		{"id": "survival", "label": "Ueberleben"},
		{"id": "food", "label": "Essen"},
		{"id": "combat", "label": "Kampf"},
		{"id": "armor", "label": "Ruestung"},
		{"id": "building", "label": "Bauen"},
	]

	for cat in categories:
		var btn = Button.new()
		btn.text = cat.label
		btn.custom_minimum_size = Vector2(70, 28)
		btn.pressed.connect(_set_filter.bind(cat.id))
		filter_container.add_child(btn)

func _set_filter(category: String):
	current_filter = category
	_build_recipe_list()

func _build_recipe_list():
	# Alte Buttons entfernen
	for child in recipe_list.get_children():
		child.queue_free()
	recipe_buttons.clear()

	for recipe in CraftingDB.recipes:
		if not current_filter.is_empty() and recipe.category != current_filter:
			continue

		var btn = Button.new()
		btn.text = recipe.display_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 35)

		# Zeige ob craftbar
		var can = CraftingDB.can_craft(recipe)
		btn.modulate = Color.WHITE if can else Color(0.55, 0.55, 0.55)

		btn.pressed.connect(_on_recipe_selected.bind(recipe))
		recipe_list.add_child(btn)
		recipe_buttons.append({button = btn, recipe = recipe})

func _on_recipe_selected(recipe: RecipeData):
	selected_recipe = recipe
	_update_info()

func _update_info():
	if selected_recipe == null:
		info_label.text = "Waehle ein Rezept"
		craft_button.disabled = true
		return

	var text = "[b]" + selected_recipe.display_name + "[/b]\n\nBenoetigt:\n"
	for item_id in selected_recipe.ingredients:
		var item = CraftingDB.get_item(item_id)
		var needed = selected_recipe.ingredients[item_id]
		var have = Inventory.get_item_count(item_id)
		var color = "green" if have >= needed else "red"
		var name = item.display_name if item else item_id
		text += "  [color=%s]%s: %d/%d[/color]\n" % [color, name, have, needed]

	var result_item = CraftingDB.get_item(selected_recipe.result_id)
	var result_name = result_item.display_name if result_item else selected_recipe.result_id
	text += "\nErgebnis: [color=yellow]%s x%d[/color]" % [result_name, selected_recipe.result_count]

	if info_label.has_method("parse_bbcode"):
		info_label.parse_bbcode(text)
	else:
		info_label.text = text.replace("[b]", "").replace("[/b]", "").replace("[color=green]", "").replace("[color=red]", "").replace("[color=yellow]", "").replace("[/color]", "")

	craft_button.disabled = not CraftingDB.can_craft(selected_recipe)

func _on_craft():
	if selected_recipe and CraftingDB.craft(selected_recipe):
		_update_info()
		_refresh_recipes()

func _refresh_recipes():
	for entry in recipe_buttons:
		var can = CraftingDB.can_craft(entry.recipe)
		entry.button.modulate = Color.WHITE if can else Color(0.55, 0.55, 0.55)
	if selected_recipe:
		_update_info()
