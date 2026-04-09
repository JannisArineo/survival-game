extends CanvasLayer

@onready var sensitivity_slider = $Panel/VBoxContainer/SensitivitySlider
@onready var render_slider = $Panel/VBoxContainer/RenderSlider
@onready var sensitivity_label = $Panel/VBoxContainer/SensLabel
@onready var render_label = $Panel/VBoxContainer/RenderLabel

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		if visible:
			_resume()

func show_menu():
	visible = true

func _resume():
	visible = false
	GameManager.paused = false
	get_tree().paused = false
	if GameManager.player and not GameManager.player.inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	_resume()

func _on_quit_pressed():
	get_tree().quit()

func _on_sensitivity_changed(value: float):
	if sensitivity_label:
		sensitivity_label.text = "Maus-Sensitivitaet: %.3f" % value

func _on_render_changed(value: float):
	if render_label:
		render_label.text = "Render Distance: %d Chunks" % int(value)
