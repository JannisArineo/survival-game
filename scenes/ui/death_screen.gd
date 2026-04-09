extends CanvasLayer

@onready var panel = $Panel

func _ready():
	visible = false
	GameManager.player_died.connect(_on_player_died)

func _on_player_died():
	visible = true
	get_tree().paused = true

func _on_respawn_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()
