class_name RecipeData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var ingredients: Dictionary = {} # item_id -> count
@export var result_id: String = ""
@export var result_count: int = 1
