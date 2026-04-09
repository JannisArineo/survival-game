class_name ItemData
extends Resource

enum ItemType { MATERIAL, TOOL, FOOD, BUILDING, MEDICAL, WEAPON, ARMOR }
enum ItemCategory { MISC, SURVIVAL, COMBAT, CONSTRUCTION, PROGRESSION }
enum ArmorSlot { NONE, HEAD, CHEST, LEGS, FEET }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color.WHITE
@export var stack_size: int = 99
@export var item_type: ItemType = ItemType.MATERIAL
@export var item_category: ItemCategory = ItemCategory.MISC
@export var damage: float = 0.0
@export var harvest_speed: float = 1.0
@export var heal_amount: float = 0.0
@export var hunger_restore: float = 0.0
@export var thirst_restore: float = 0.0
@export var warmth_bonus: float = 0.0
@export var building_scene: String = ""
@export var max_durability: float = 0.0  # 0 = unzerstoerbar
@export var armor_value: float = 0.0     # % damage reduction
@export var armor_slot: ArmorSlot = ArmorSlot.NONE
@export var weapon_type: String = ""     # "bow", "melee", ""
@export var is_ammo: bool = false
@export var ammo_type: String = ""       # ammo fuer welche Waffe
@export var fuel_value: float = 0.0      # fuer Furnace
@export var smelt_result: String = ""    # was wird geschmolzen zu
@export var smelt_result_count: int = 1
