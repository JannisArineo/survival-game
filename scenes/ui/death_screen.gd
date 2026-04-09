extends CanvasLayer

@onready var panel = $Panel

var respawn_label: Label

func _ready():
	visible = false
	GameManager.player_died.connect(_on_player_died)
	_add_respawn_info()

func _add_respawn_info():
	# Respawn-Info Label dynamisch hinzufuegen
	respawn_label = Label.new()
	respawn_label.text = ""
	respawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	respawn_label.add_theme_font_size_override("font_size", 16)
	respawn_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	if panel:
		panel.add_child(respawn_label)

func _on_player_died():
	visible = true
	get_tree().paused = true

	# Zeige Respawn-Info
	if respawn_label:
		if GameManager.respawn_position != Vector3.ZERO:
			respawn_label.text = "Respawn-Punkt: Schlafsack"
		else:
			respawn_label.text = "Respawn-Punkt: Spawn (kein Schlafsack gesetzt)"

func _on_respawn_pressed():
	get_tree().paused = false
	_do_respawn()

func _do_respawn():
	# Stats zuruecksetzen
	var player = GameManager.player
	if player == null:
		get_tree().reload_current_scene()
		return

	player.health = player.max_health * 0.3  # Mit 30% HP respawnen
	player.hunger = 50.0
	player.thirst = 50.0
	player.warmth = 75.0
	player.is_dead = false
	player.set_physics_process(true)
	player.set_process(true)

	# Zum Schlafsack teleportieren
	if GameManager.respawn_position != Vector3.ZERO:
		player.global_position = GameManager.respawn_position
	else:
		player.global_position = Vector3(0, 50, 0)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	GameManager.show_notification.emit("Respawned!", Color(0.4, 0.9, 0.5))

func _on_quit_pressed():
	get_tree().quit()
