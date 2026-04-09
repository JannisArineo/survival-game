extends Control

@onready var recipe_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RecipeList
@onready var craft_button = $Panel/MarginContainer/VBoxContainer/CraftButton
@onready var info_label = $Panel/MarginContainer/VBoxContainer/InfoLabel

var selected_recipe: RecipeData = null
var recipe_buttons: Array = []

func _ready():
	visible = false
	craft_button.pressed.connect(_on_craft)
	_build_recipe_list()
	Inventory.inventory_changed.connect(_refresh_recipes)

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible
		if visible:
			_refresh_recipes()

func _build_recipe_list():
	for recipe in CraftingDB.recipes:
		var btn = Button.new()
		btn.text = recipe.display_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 35)
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

	var text = selected_recipe.display_name + "\n\nBenoetigt:\n"
	for item_id in selected_recipe.ingredients:
		var item = CraftingDB.get_item(item_id)
		var needed = selected_recipe.ingredients[item_id]
		var have = Inventory.get_item_count(item_id)
		var color = "green" if have >= needed else "red"
		text += "  [color=%s]%s: %d/%d[/color]\n" % [color, item.display_name, have, needed]

	var result_item = CraftingDB.get_item(selected_recipe.result_id)
	text += "\nErgebnis: %s x%d" % [result_item.display_name, selected_recipe.result_count]

	info_label.text = text
	craft_button.disabled = not CraftingDB.can_craft(selected_recipe)

func _on_craft():
	if selected_recipe and CraftingDB.craft(selected_recipe):
		_update_info()
		_refresh_recipes()

func _refresh_recipes():
	for entry in recipe_buttons:
		var can = CraftingDB.can_craft(entry.recipe)
		entry.button.modulate = Color.WHITE if can else Color(0.5, 0.5, 0.5)
	if selected_recipe:
		_update_info()
