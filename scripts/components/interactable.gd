class_name Interactable
extends Node

signal interacted(player: Node3D)

@export var interaction_text: String = "Interagieren"
@export var requires_item: String = "" # item_id oder leer

func interact(player: Node3D):
	interacted.emit(player)

func get_prompt() -> String:
	return "E - " + interaction_text

func can_interact(_player: Node3D) -> bool:
	if requires_item.is_empty():
		return true
	return Inventory.has_item(requires_item)
