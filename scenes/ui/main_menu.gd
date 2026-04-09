extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Load-Button nur anzeigen wenn Savefile existiert
	var load_btn = find_child("LoadButton", true, false)
	if load_btn:
		load_btn.visible = SaveManager.has_save()
		load_btn.pressed.connect(_on_load_pressed)

func _on_play_pressed():
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_load_pressed():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	# SaveManager laedt automatisch nach Scene-Wechsel (connected in main.gd)
	await get_tree().process_frame
	SaveManager.load_game()

func _on_quit_pressed():
	get_tree().quit()
