extends Node

var items: Dictionary = {}
var recipes: Array[RecipeData] = []

func _ready():
	_register_items()
	_register_recipes()

func get_item(id: String) -> ItemData:
	if items.has(id):
		return items[id]
	return null

func get_craftable_recipes() -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	for recipe in recipes:
		if can_craft(recipe):
			result.append(recipe)
	return result

func can_craft(recipe: RecipeData) -> bool:
	for item_id in recipe.ingredients:
		if not Inventory.has_item(item_id, recipe.ingredients[item_id]):
			return false
	return true

func craft(recipe: RecipeData) -> bool:
	if not can_craft(recipe):
		return false
	for item_id in recipe.ingredients:
		Inventory.remove_item(item_id, recipe.ingredients[item_id])
	Inventory.add_item(recipe.result_id, recipe.result_count)
	return true

func _make_item(id: String, display_name: String, color: Color, type: ItemData.ItemType,
		stack_size: int = 99, damage: float = 0.0, harvest_speed: float = 1.0,
		heal_amount: float = 0.0, hunger_restore: float = 0.0, thirst_restore: float = 0.0,
		warmth_bonus: float = 0.0, building_scene: String = "") -> ItemData:
	var item = ItemData.new()
	item.id = id
	item.display_name = display_name
	item.icon_color = color
	item.item_type = type
	item.stack_size = stack_size
	item.damage = damage
	item.harvest_speed = harvest_speed
	item.heal_amount = heal_amount
	item.hunger_restore = hunger_restore
	item.thirst_restore = thirst_restore
	item.warmth_bonus = warmth_bonus
	item.building_scene = building_scene
	items[id] = item
	return item

func _make_recipe(id: String, display_name: String, ingredients: Dictionary,
		result_id: String, result_count: int = 1) -> RecipeData:
	var recipe = RecipeData.new()
	recipe.id = id
	recipe.display_name = display_name
	recipe.ingredients = ingredients
	recipe.result_id = result_id
	recipe.result_count = result_count
	recipes.append(recipe)
	return recipe

func _register_items():
	# Materials
	_make_item("wood", "Holz", Color(0.55, 0.35, 0.15), ItemData.ItemType.MATERIAL)
	_make_item("stone", "Stein", Color(0.5, 0.5, 0.5), ItemData.ItemType.MATERIAL)
	_make_item("metal", "Metall", Color(0.7, 0.7, 0.75), ItemData.ItemType.MATERIAL)
	_make_item("animal_hide", "Tierfell", Color(0.6, 0.4, 0.2), ItemData.ItemType.MATERIAL)

	# Tools
	_make_item("wood_axe", "Holzaxt", Color(0.55, 0.35, 0.15), ItemData.ItemType.TOOL,
		1, 15.0, 1.5)
	_make_item("stone_axe", "Steinaxt", Color(0.5, 0.5, 0.5), ItemData.ItemType.TOOL,
		1, 25.0, 2.0)
	_make_item("metal_axe", "Metallaxt", Color(0.7, 0.7, 0.75), ItemData.ItemType.TOOL,
		1, 40.0, 3.0)

	# Food
	_make_item("raw_meat", "Rohes Fleisch", Color(0.8, 0.2, 0.2), ItemData.ItemType.FOOD,
		20, 0.0, 1.0, 0.0, 10.0)
	_make_item("cooked_meat", "Gebratenes Fleisch", Color(0.6, 0.3, 0.1), ItemData.ItemType.FOOD,
		20, 0.0, 1.0, 0.0, 30.0)

	# Medical
	_make_item("bandage", "Bandage", Color(0.9, 0.9, 0.9), ItemData.ItemType.MEDICAL,
		10, 0.0, 1.0, 25.0)

	# Buildings
	_make_item("foundation", "Fundament", Color(0.4, 0.3, 0.2), ItemData.ItemType.BUILDING,
		10, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, "res://scenes/buildings/foundation.tscn")
	_make_item("wall", "Wand", Color(0.45, 0.35, 0.2), ItemData.ItemType.BUILDING,
		10, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, "res://scenes/buildings/wall.tscn")
	_make_item("door", "Tuer", Color(0.5, 0.35, 0.15), ItemData.ItemType.BUILDING,
		10, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, "res://scenes/buildings/door.tscn")
	_make_item("campfire", "Lagerfeuer", Color(0.9, 0.5, 0.1), ItemData.ItemType.BUILDING,
		5, 0.0, 1.0, 0.0, 0.0, 0.0, 10.0, "res://scenes/buildings/campfire.tscn")

func _register_recipes():
	_make_recipe("craft_wood_axe", "Holzaxt", {"wood": 50}, "wood_axe")
	_make_recipe("craft_stone_axe", "Steinaxt", {"wood": 100, "stone": 50}, "stone_axe")
	_make_recipe("craft_metal_axe", "Metallaxt", {"wood": 100, "metal": 50}, "metal_axe")
	_make_recipe("craft_foundation", "Fundament", {"wood": 200, "stone": 100}, "foundation")
	_make_recipe("craft_wall", "Wand", {"wood": 150, "stone": 50}, "wall")
	_make_recipe("craft_door", "Tuer", {"wood": 100}, "door")
	_make_recipe("craft_campfire", "Lagerfeuer", {"wood": 10, "stone": 5}, "campfire")
	_make_recipe("craft_bandage", "Bandage", {"animal_hide": 3}, "bandage")
	_make_recipe("craft_cooked_meat", "Gebratenes Fleisch", {"raw_meat": 1}, "cooked_meat")
