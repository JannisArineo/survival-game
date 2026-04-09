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

func get_all_recipes() -> Array[RecipeData]:
	return recipes

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
	AudioManager.play_craft()
	return true

func _make_item(id: String, display_name: String, color: Color, type: ItemData.ItemType,
		stack_size: int = 99, damage: float = 0.0, harvest_speed: float = 1.0,
		heal_amount: float = 0.0, hunger_restore: float = 0.0, thirst_restore: float = 0.0,
		warmth_bonus: float = 0.0, building_scene: String = "",
		max_durability: float = 0.0, armor_value: float = 0.0,
		armor_slot: ItemData.ArmorSlot = ItemData.ArmorSlot.NONE,
		weapon_type: String = "", category: ItemData.ItemCategory = ItemData.ItemCategory.MISC,
		fuel_value: float = 0.0, smelt_result: String = "", smelt_count: int = 0) -> ItemData:
	var item = ItemData.new()
	item.id = id
	item.display_name = display_name
	item.icon_color = color
	item.item_type = type
	item.item_category = category
	item.stack_size = stack_size
	item.damage = damage
	item.harvest_speed = harvest_speed
	item.heal_amount = heal_amount
	item.hunger_restore = hunger_restore
	item.thirst_restore = thirst_restore
	item.warmth_bonus = warmth_bonus
	item.building_scene = building_scene
	item.max_durability = max_durability
	item.armor_value = armor_value
	item.armor_slot = armor_slot
	item.weapon_type = weapon_type
	item.fuel_value = fuel_value
	item.smelt_result = smelt_result
	item.smelt_result_count = smelt_count
	items[id] = item
	return item

func _make_recipe(id: String, display_name: String, ingredients: Dictionary,
		result_id: String, result_count: int = 1, category: String = "") -> RecipeData:
	var recipe = RecipeData.new()
	recipe.id = id
	recipe.display_name = display_name
	recipe.ingredients = ingredients
	recipe.result_id = result_id
	recipe.result_count = result_count
	recipe.category = category
	recipes.append(recipe)
	return recipe

func _register_items():
	# === MATERIALIEN ===
	_make_item("wood", "Holz", Color(0.55, 0.35, 0.15), ItemData.ItemType.MATERIAL,
		99, 0, 1, 0, 0, 0, 0, "", 0, 0, ItemData.ArmorSlot.NONE, "",
		ItemData.ItemCategory.MISC, 5.0)
	_make_item("stone", "Stein", Color(0.5, 0.5, 0.5), ItemData.ItemType.MATERIAL)
	_make_item("metal", "Metall (Alt)", Color(0.7, 0.7, 0.75), ItemData.ItemType.MATERIAL)
	_make_item("animal_hide", "Tierfell", Color(0.6, 0.4, 0.2), ItemData.ItemType.MATERIAL)
	_make_item("fiber", "Faser", Color(0.7, 0.65, 0.5), ItemData.ItemType.MATERIAL)
	_make_item("feather", "Feder", Color(0.95, 0.95, 0.95), ItemData.ItemType.MATERIAL)
	_make_item("bone", "Knochen", Color(0.85, 0.8, 0.7), ItemData.ItemType.MATERIAL)
	_make_item("charcoal", "Holzkohle", Color(0.2, 0.2, 0.2), ItemData.ItemType.MATERIAL)
	_make_item("stone_ore", "Stein-Erz", Color(0.55, 0.55, 0.6), ItemData.ItemType.MATERIAL,
		99, 0, 1, 0, 0, 0, 0, "", 0, 0, ItemData.ArmorSlot.NONE, "",
		ItemData.ItemCategory.PROGRESSION, 0, "metal_fragment", 2)
	_make_item("metal_ore", "Metall-Erz", Color(0.65, 0.7, 0.75), ItemData.ItemType.MATERIAL,
		99, 0, 1, 0, 0, 0, 0, "", 0, 0, ItemData.ArmorSlot.NONE, "",
		ItemData.ItemCategory.PROGRESSION, 0, "high_quality_metal", 1)
	_make_item("metal_fragment", "Metallfragment", Color(0.75, 0.78, 0.82), ItemData.ItemType.MATERIAL,
		99, 0, 1, 0, 0, 0, 0, "", 0, 0, ItemData.ArmorSlot.NONE, "",
		ItemData.ItemCategory.PROGRESSION)
	_make_item("high_quality_metal", "HQ Metall", Color(0.85, 0.9, 0.95), ItemData.ItemType.MATERIAL,
		50, 0, 1, 0, 0, 0, 0, "", 0, 0, ItemData.ArmorSlot.NONE, "",
		ItemData.ItemCategory.PROGRESSION)
	_make_item("rope", "Seil", Color(0.7, 0.55, 0.3), ItemData.ItemType.MATERIAL)
	_make_item("cloth", "Stoff", Color(0.8, 0.75, 0.65), ItemData.ItemType.MATERIAL)

	# === TOOLS ===
	_make_item("wood_axe", "Holzaxt", Color(0.55, 0.35, 0.15), ItemData.ItemType.TOOL,
		1, 15.0, 1.5, 0, 0, 0, 0, "", 100.0, 0, ItemData.ArmorSlot.NONE, "melee",
		ItemData.ItemCategory.SURVIVAL)
	_make_item("stone_axe", "Steinaxt", Color(0.5, 0.5, 0.5), ItemData.ItemType.TOOL,
		1, 25.0, 2.0, 0, 0, 0, 0, "", 200.0, 0, ItemData.ArmorSlot.NONE, "melee",
		ItemData.ItemCategory.SURVIVAL)
	_make_item("metal_axe", "Metallaxt", Color(0.7, 0.7, 0.75), ItemData.ItemType.TOOL,
		1, 40.0, 3.0, 0, 0, 0, 0, "", 400.0, 0, ItemData.ArmorSlot.NONE, "melee",
		ItemData.ItemCategory.SURVIVAL)
	_make_item("metal_pickaxe", "Metallhacke", Color(0.72, 0.72, 0.78), ItemData.ItemType.TOOL,
		1, 35.0, 2.5, 0, 0, 0, 0, "", 350.0, 0, ItemData.ArmorSlot.NONE, "melee",
		ItemData.ItemCategory.SURVIVAL)
	_make_item("spear", "Speer", Color(0.55, 0.45, 0.2), ItemData.ItemType.TOOL,
		1, 30.0, 1.0, 0, 0, 0, 0, "", 150.0, 0, ItemData.ArmorSlot.NONE, "melee",
		ItemData.ItemCategory.COMBAT)
	_make_item("metal_blade", "Metallklinge", Color(0.78, 0.8, 0.85), ItemData.ItemType.TOOL,
		1, 55.0, 1.0, 0, 0, 0, 0, "", 300.0, 0, ItemData.ArmorSlot.NONE, "melee",
		ItemData.ItemCategory.COMBAT)
	_make_item("stone_pickaxe", "Steinhacke", Color(0.5, 0.5, 0.5), ItemData.ItemType.TOOL,
		1, 20.0, 2.0, 0, 0, 0, 0, "", 180.0)

	# === WEAPONS ===
	_make_item("bow", "Bogen", Color(0.55, 0.4, 0.2), ItemData.ItemType.WEAPON,
		1, 0, 1, 0, 0, 0, 0, "", 200.0, 0, ItemData.ArmorSlot.NONE, "bow",
		ItemData.ItemCategory.COMBAT)
	_make_item("arrow", "Pfeil", Color(0.6, 0.45, 0.15), ItemData.ItemType.WEAPON,
		99, 25.0, 1, 0, 0, 0, 0, "", 0, 0, ItemData.ArmorSlot.NONE, "ammo",
		ItemData.ItemCategory.COMBAT)
	arrow_item_setup()

	# === FOOD ===
	_make_item("raw_meat", "Rohes Fleisch", Color(0.8, 0.2, 0.2), ItemData.ItemType.FOOD,
		20, 0, 1, 0, 10.0, 0, 0)
	_make_item("cooked_meat", "Gebratenes Fleisch", Color(0.6, 0.3, 0.1), ItemData.ItemType.FOOD,
		20, 0, 1, 0, 30.0, 5.0, 5.0)
	_make_item("berries", "Beeren", Color(0.75, 0.15, 0.25), ItemData.ItemType.FOOD,
		30, 0, 1, 5.0, 8.0, 10.0, 0)
	_make_item("mushroom", "Pilz", Color(0.55, 0.8, 0.25), ItemData.ItemType.FOOD,
		20, 0, 1, 0, 15.0, 5.0, 0)
	_make_item("poison_mushroom", "Gift-Pilz", Color(0.4, 0.7, 0.15), ItemData.ItemType.FOOD,
		20, 0, 1, -20.0, 5.0, 5.0, 0)
	_make_item("raw_fish", "Roher Fisch", Color(0.5, 0.65, 0.8), ItemData.ItemType.FOOD,
		20, 0, 1, 0, 8.0, 5.0, 0)
	_make_item("cooked_fish", "Gebratener Fisch", Color(0.75, 0.55, 0.3), ItemData.ItemType.FOOD,
		20, 0, 1, 0, 25.0, 8.0, 3.0)

	# === MEDICAL ===
	_make_item("bandage", "Bandage", Color(0.9, 0.9, 0.9), ItemData.ItemType.MEDICAL,
		10, 0, 1, 25.0)
	_make_item("medkit", "Medizin-Kit", Color(0.2, 0.8, 0.3), ItemData.ItemType.MEDICAL,
		5, 0, 1, 60.0)
	_make_item("antiseptic", "Antiseptikum", Color(0.4, 0.85, 0.9), ItemData.ItemType.MEDICAL,
		10, 0, 1, 15.0)

	# === ARMOR ===
	_make_item("cloth_shirt", "Stoffhemd", Color(0.75, 0.7, 0.6), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 5.0, "", 0, 0.05, ItemData.ArmorSlot.CHEST)
	_make_item("cloth_pants", "Stoffhose", Color(0.65, 0.62, 0.55), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 3.0, "", 0, 0.03, ItemData.ArmorSlot.LEGS)
	_make_item("bone_armor", "Knochen-Ruestung", Color(0.85, 0.78, 0.65), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 0, "", 0, 0.15, ItemData.ArmorSlot.CHEST)
	_make_item("leather_jacket", "Lederjacke", Color(0.45, 0.3, 0.15), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 8.0, "", 0, 0.12, ItemData.ArmorSlot.CHEST)
	_make_item("metal_chest", "Metallruestung", Color(0.7, 0.72, 0.76), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 0, "", 0, 0.25, ItemData.ArmorSlot.CHEST)
	_make_item("bone_helmet", "Knochenhelm", Color(0.82, 0.77, 0.65), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 0, "", 0, 0.10, ItemData.ArmorSlot.HEAD)
	_make_item("metal_helmet", "Metallhelm", Color(0.68, 0.7, 0.74), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 0, "", 0, 0.20, ItemData.ArmorSlot.HEAD)
	_make_item("boots", "Stiefel", Color(0.35, 0.25, 0.15), ItemData.ItemType.ARMOR,
		1, 0, 1, 0, 0, 0, 5.0, "", 0, 0.05, ItemData.ArmorSlot.FEET)

	# === BUILDINGS ===
	_make_item("foundation", "Fundament", Color(0.4, 0.3, 0.2), ItemData.ItemType.BUILDING,
		10, 0, 1, 0, 0, 0, 0, "res://scenes/buildings/foundation.tscn")
	_make_item("wall", "Wand", Color(0.45, 0.35, 0.2), ItemData.ItemType.BUILDING,
		10, 0, 1, 0, 0, 0, 0, "res://scenes/buildings/wall.tscn")
	_make_item("door", "Tuer", Color(0.5, 0.35, 0.15), ItemData.ItemType.BUILDING,
		10, 0, 1, 0, 0, 0, 0, "res://scenes/buildings/door.tscn")
	_make_item("campfire", "Lagerfeuer", Color(0.9, 0.5, 0.1), ItemData.ItemType.BUILDING,
		5, 0, 1, 0, 0, 0, 10.0, "res://scenes/buildings/campfire.tscn")
	_make_item("furnace", "Schmelzofen", Color(0.5, 0.45, 0.4), ItemData.ItemType.BUILDING,
		3, 0, 1, 0, 0, 0, 0, "res://scenes/buildings/furnace.tscn")
	_make_item("storage_box", "Lagerkiste", Color(0.5, 0.35, 0.15), ItemData.ItemType.BUILDING,
		5, 0, 1, 0, 0, 0, 0, "res://scenes/buildings/storage_box.tscn")
	_make_item("half_wall", "Halbwand", Color(0.45, 0.35, 0.2), ItemData.ItemType.BUILDING,
		10, 0, 1, 0, 0, 0, 0, "")
	_make_item("floor_tile", "Boden", Color(0.42, 0.32, 0.2), ItemData.ItemType.BUILDING,
		10, 0, 1, 0, 0, 0, 0, "")
	_make_item("stairs", "Treppe", Color(0.48, 0.38, 0.22), ItemData.ItemType.BUILDING,
		5, 0, 1, 0, 0, 0, 0, "")

func arrow_item_setup():
	if items.has("arrow"):
		items["arrow"].is_ammo = true
		items["arrow"].ammo_type = "bow"

func _register_recipes():
	# === UEBERLEBEN ===
	_make_recipe("craft_wood_axe", "Holzaxt", {"wood": 50}, "wood_axe", 1, "survival")
	_make_recipe("craft_stone_axe", "Steinaxt", {"wood": 100, "stone": 50}, "stone_axe", 1, "survival")
	_make_recipe("craft_metal_axe", "Metallaxt", {"wood": 100, "metal_fragment": 50}, "metal_axe", 1, "survival")
	_make_recipe("craft_stone_pickaxe", "Steinhacke", {"wood": 75, "stone": 75}, "stone_pickaxe", 1, "survival")
	_make_recipe("craft_metal_pickaxe", "Metallhacke", {"wood": 75, "metal_fragment": 75}, "metal_pickaxe", 1, "survival")
	_make_recipe("craft_bandage", "Bandage", {"animal_hide": 3}, "bandage", 1, "survival")
	_make_recipe("craft_medkit", "Medizin-Kit", {"bandage": 3, "antiseptic": 2}, "medkit", 1, "survival")
	_make_recipe("craft_antiseptic", "Antiseptikum", {"berries": 5, "charcoal": 2}, "antiseptic", 1, "survival")
	_make_recipe("craft_rope", "Seil", {"fiber": 10}, "rope", 2, "survival")
	_make_recipe("craft_cloth", "Stoff", {"animal_hide": 2}, "cloth", 3, "survival")

	# === KOCHEN ===
	_make_recipe("craft_cooked_meat", "Gebratenes Fleisch", {"raw_meat": 1}, "cooked_meat", 1, "food")
	_make_recipe("craft_cooked_fish", "Gebratener Fisch", {"raw_fish": 1}, "cooked_fish", 1, "food")

	# === KAMPF ===
	_make_recipe("craft_spear", "Speer", {"wood": 100, "stone": 25}, "spear", 1, "combat")
	_make_recipe("craft_metal_blade", "Metallklinge", {"metal_fragment": 30, "wood": 20}, "metal_blade", 1, "combat")
	_make_recipe("craft_bow", "Bogen", {"wood": 100, "fiber": 20}, "bow", 1, "combat")
	_make_recipe("craft_arrow", "Pfeile (10)", {"wood": 20, "feather": 5}, "arrow", 10, "combat")

	# === RUESTUNG ===
	_make_recipe("craft_cloth_shirt", "Stoffhemd", {"cloth": 15}, "cloth_shirt", 1, "armor")
	_make_recipe("craft_cloth_pants", "Stoffhose", {"cloth": 10}, "cloth_pants", 1, "armor")
	_make_recipe("craft_bone_armor", "Knochen-Ruestung", {"bone": 20, "animal_hide": 5}, "bone_armor", 1, "armor")
	_make_recipe("craft_bone_helmet", "Knochenhelm", {"bone": 12, "animal_hide": 3}, "bone_helmet", 1, "armor")
	_make_recipe("craft_leather_jacket", "Lederjacke", {"animal_hide": 15, "rope": 3}, "leather_jacket", 1, "armor")
	_make_recipe("craft_boots", "Stiefel", {"animal_hide": 8, "rope": 2}, "boots", 1, "armor")
	_make_recipe("craft_metal_chest", "Metallruestung", {"metal_fragment": 50, "rope": 5}, "metal_chest", 1, "armor")
	_make_recipe("craft_metal_helmet", "Metallhelm", {"metal_fragment": 30, "rope": 3}, "metal_helmet", 1, "armor")

	# === GEBAEUDE ===
	_make_recipe("craft_foundation", "Fundament", {"wood": 200, "stone": 100}, "foundation", 1, "building")
	_make_recipe("craft_wall", "Wand", {"wood": 150, "stone": 50}, "wall", 1, "building")
	_make_recipe("craft_half_wall", "Halbwand", {"wood": 80, "stone": 30}, "half_wall", 1, "building")
	_make_recipe("craft_floor", "Boden", {"wood": 100, "stone": 30}, "floor_tile", 1, "building")
	_make_recipe("craft_stairs", "Treppe", {"wood": 120, "stone": 40}, "stairs", 1, "building")
	_make_recipe("craft_door", "Tuer", {"wood": 100}, "door", 1, "building")
	_make_recipe("craft_campfire", "Lagerfeuer", {"wood": 10, "stone": 5}, "campfire", 1, "building")
	_make_recipe("craft_furnace", "Schmelzofen", {"stone": 200, "wood": 50}, "furnace", 1, "building")
	_make_recipe("craft_storage_box", "Lagerkiste", {"wood": 150, "rope": 5}, "storage_box", 1, "building")
