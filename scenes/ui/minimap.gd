extends Control

# Einfache Canvas-basierte Minimap
# Zeigt Spielerposition, Umgebung und bekannte Punkte als Dots

const MAP_SIZE = 120.0  # Pixel
const WORLD_RANGE = 200.0  # Welt-Einheiten die dargestellt werden

var player_dot: ColorRect
var north_label: Label
var map_panel: PanelContainer
var dot_container: Control

var tracked_entities: Array = []
var enemy_dots: Dictionary = {}  # node -> dot

func _ready():
	_create_map_ui()

func _create_map_ui():
	# Hintergrund
	map_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.05, 0.85)
	style.border_color = Color(0.3, 0.5, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	map_panel.add_theme_stylebox_override("panel", style)
	map_panel.custom_minimum_size = Vector2(MAP_SIZE + 10, MAP_SIZE + 10)
	add_child(map_panel)

	# Dot-Container
	dot_container = Control.new()
	dot_container.custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	map_panel.add_child(dot_container)

	# Kompass-Punkte
	var n_label = Label.new()
	n_label.text = "N"
	n_label.add_theme_font_size_override("font_size", 9)
	n_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	n_label.position = Vector2(MAP_SIZE / 2 - 4, 0)
	dot_container.add_child(n_label)

	# Spieler-Dot (immer in der Mitte)
	player_dot = ColorRect.new()
	player_dot.size = Vector2(8, 8)
	player_dot.color = Color(0.3, 0.9, 0.3)
	player_dot.position = Vector2(MAP_SIZE / 2 - 4, MAP_SIZE / 2 - 4)
	dot_container.add_child(player_dot)

	# Spieler-Dreieck (zeigt Blickrichtung)
	# Wir machen einfach einen quadrat-dot

func _process(_delta):
	if GameManager.player == null:
		return
	_update_entity_dots()

func _update_entity_dots():
	var player = GameManager.player
	var player_pos = player.global_position

	# Feinde tracken
	var enemies = get_tree().get_nodes_in_group("enemies")
	# Wir nutzen alle CharacterBody3D die keine Player sind als Feinde
	var all_chars = get_tree().get_nodes_in_group("")

	# Einfacherer Ansatz: finde alle Nodes mit receive_hit (= Enemies)
	# Da wir keine Groups haben, scannen wir die World-Kinder
	var world = get_tree().current_scene.find_child("World", true, false)
	if world:
		for child in world.get_children():
			if child is CharacterBody3D and child != player:
				if not enemy_dots.has(child):
					# Neuen Dot erstellen
					var dot = ColorRect.new()
					dot.size = Vector2(5, 5)
					dot.color = Color(0.9, 0.2, 0.2)
					dot_container.add_child(dot)
					enemy_dots[child] = dot
				if is_instance_valid(child):
					var rel = child.global_position - player_pos
					var map_x = MAP_SIZE / 2 + (rel.x / WORLD_RANGE) * MAP_SIZE - 2.5
					var map_z = MAP_SIZE / 2 + (rel.z / WORLD_RANGE) * MAP_SIZE - 2.5
					enemy_dots[child].position = Vector2(
						clampf(map_x, 0, MAP_SIZE - 5),
						clampf(map_z, 0, MAP_SIZE - 5)
					)
					enemy_dots[child].visible = abs(rel.x) < WORLD_RANGE and abs(rel.z) < WORLD_RANGE

	# Tote Dots entfernen
	var to_remove = []
	for node in enemy_dots:
		if not is_instance_valid(node):
			enemy_dots[node].queue_free()
			to_remove.append(node)
	for n in to_remove:
		enemy_dots.erase(n)
