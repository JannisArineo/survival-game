extends Node

# Building Upgrade System: Twig -> Wood -> Stone -> Metal
# RMB auf platziertes Gebaeude um es zu upgraden

enum Tier { WOOD, STONE, METAL }

const UPGRADE_COSTS = {
	Tier.STONE: {"stone": 100},
	Tier.METAL: {"metal_fragment": 50}
}

const TIER_COLORS = {
	Tier.WOOD: Color(0.5, 0.35, 0.15),
	Tier.STONE: Color(0.55, 0.55, 0.58),
	Tier.METAL: Color(0.6, 0.62, 0.68)
}

const TIER_NAMES = {
	Tier.WOOD: "Holz",
	Tier.STONE: "Stein",
	Tier.METAL: "Metall"
}

var current_tier: Tier = Tier.WOOD
var parent_building: StaticBody3D

func _ready():
	parent_building = get_parent()

func try_upgrade() -> bool:
	var next_tier = current_tier + 1
	if next_tier > Tier.METAL:
		GameManager.show_notification.emit("Maximales Upgrade erreicht!", Color(1.0, 0.8, 0.3))
		return false

	var cost = UPGRADE_COSTS[next_tier]
	for item_id in cost:
		if not Inventory.has_item(item_id, cost[item_id]):
			var item = CraftingDB.get_item(item_id)
			var name = item.display_name if item else item_id
			GameManager.show_notification.emit(
				"Brauche: " + str(cost[item_id]) + "x " + name,
				Color(0.9, 0.4, 0.2)
			)
			return false

	# Kosten abziehen
	for item_id in cost:
		Inventory.remove_item(item_id, cost[item_id])

	current_tier = next_tier as Tier
	_apply_tier_visual()

	GameManager.show_notification.emit(
		"Upgrade zu " + TIER_NAMES[current_tier] + "!",
		Color(0.3, 0.9, 0.5)
	)
	return true

func _apply_tier_visual():
	var color = TIER_COLORS[current_tier]
	for child in parent_building.get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = 0.85 if current_tier == Tier.STONE else (0.5 if current_tier == Tier.METAL else 0.9)
			mat.metallic = 0.3 if current_tier == Tier.METAL else 0.0
			child.material_override = mat

func get_tier_name() -> String:
	return TIER_NAMES[current_tier]
