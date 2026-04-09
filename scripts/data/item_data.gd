class_name ItemData
extends Resource

enum ItemType { MATERIAL, TOOL, FOOD, BUILDING, MEDICAL }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color.WHITE
@export var stack_size: int = 99
@export var item_type: ItemType = ItemType.MATERIAL
@export var damage: float = 0.0
@export var harvest_speed: float = 1.0
@export var heal_amount: float = 0.0
@export var hunger_restore: float = 0.0
@export var thirst_restore: float = 0.0
@export var warmth_bonus: float = 0.0
@export var building_scene: String = ""
