extends Node

signal time_changed(hour: float)
signal day_changed(day: int)
signal player_died

var day_length: float = 600.0 # 10 Minuten = 1 Tag
var current_time: float = 0.3 # Start um ~7:00 morgens (0.0 = Mitternacht, 0.5 = Mittag)
var current_day: int = 1
var is_night: bool = false
var paused: bool = false

var player: CharacterBody3D = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if paused:
		return
	current_time += delta / day_length
	if current_time >= 1.0:
		current_time -= 1.0
		current_day += 1
		day_changed.emit(current_day)
	is_night = current_time < 0.25 or current_time > 0.75
	time_changed.emit(current_time * 24.0)

func get_hour() -> float:
	return current_time * 24.0

func get_sun_angle() -> float:
	return current_time * 360.0 - 90.0

func get_sun_intensity() -> float:
	var hour = get_hour()
	if hour < 5.0 or hour > 20.0:
		return 0.05
	elif hour < 7.0:
		return lerp(0.05, 1.0, (hour - 5.0) / 2.0)
	elif hour > 18.0:
		return lerp(1.0, 0.05, (hour - 18.0) / 2.0)
	return 1.0
