extends Node

signal weather_changed(weather_type: String)

enum WeatherType { CLEAR, RAIN, FOG, STORM }

var current_weather: WeatherType = WeatherType.CLEAR
var weather_timer: float = 0.0
var weather_duration: float = 0.0

var rain_particles: GPUParticles3D = null
var fog_overlay: ColorRect = null

# Wieviel extra Kaelteverlust bei Regen/Storm
const RAIN_COLD_MULTIPLIER = 2.0
const STORM_COLD_MULTIPLIER = 4.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_next_weather_duration()

func _process(delta):
	if GameManager.paused:
		return
	weather_timer += delta
	if weather_timer >= weather_duration:
		weather_timer = 0.0
		_pick_new_weather()

func _set_next_weather_duration():
	weather_duration = randf_range(300.0, 900.0)  # 5-15 Minuten

func _pick_new_weather():
	_set_next_weather_duration()
	var roll = randf()
	var new_weather: WeatherType

	if roll < 0.5:
		new_weather = WeatherType.CLEAR
	elif roll < 0.75:
		new_weather = WeatherType.FOG
	elif roll < 0.92:
		new_weather = WeatherType.RAIN
	else:
		new_weather = WeatherType.STORM

	if new_weather != current_weather:
		set_weather(new_weather)

func set_weather(type: WeatherType):
	current_weather = type
	_apply_weather(type)
	weather_changed.emit(_weather_name(type))
	GameManager.show_notification.emit(_weather_name(type), _weather_color(type))

func _apply_weather(type: WeatherType):
	_clear_effects()
	match type:
		WeatherType.RAIN:
			_spawn_rain(false)
			AudioManager.set_rain(true)
		WeatherType.STORM:
			_spawn_rain(true)
			AudioManager.set_rain(true)
		WeatherType.FOG:
			_apply_fog(0.05, 40.0)
			AudioManager.set_rain(false)
		WeatherType.CLEAR:
			AudioManager.set_rain(false)

func _clear_effects():
	if rain_particles and is_instance_valid(rain_particles):
		rain_particles.queue_free()
		rain_particles = null
	_apply_fog(0.0, 0.0)
	AudioManager.set_rain(false)

func _spawn_rain(is_storm: bool):
	if GameManager.player == null:
		return

	rain_particles = GPUParticles3D.new()
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0.1 if is_storm else 0.0, -1, 0.0)
	mat.spread = 5.0
	mat.initial_velocity_min = 15.0 if is_storm else 8.0
	mat.initial_velocity_max = 20.0 if is_storm else 12.0
	mat.gravity = Vector3(0, -20, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.1
	mat.color = Color(0.6, 0.75, 0.9, 0.6)

	var mesh = SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.15

	rain_particles.process_material = mat
	rain_particles.draw_pass_1 = mesh
	rain_particles.amount = 800 if is_storm else 400
	rain_particles.lifetime = 1.5
	rain_particles.visibility_aabb = AABB(Vector3(-25, -30, -25), Vector3(50, 35, 50))
	rain_particles.position.y = 20.0

	GameManager.player.add_child(rain_particles)

func _apply_fog(density: float, depth: float):
	var world_node = get_tree().current_scene.find_child("World", true, false)
	if world_node == null:
		return
	var env_node = world_node.find_child("WorldEnvironment", true, false)
	if env_node == null:
		return
	var env: Environment = env_node.environment
	if env == null:
		return
	if density > 0.0:
		env.fog_enabled = true
		env.fog_density = density
		env.fog_depth_end = depth
		env.fog_depth_begin = 5.0
		env.fog_light_color = Color(0.7, 0.7, 0.75)
	else:
		env.fog_enabled = false

func get_cold_multiplier() -> float:
	match current_weather:
		WeatherType.RAIN: return RAIN_COLD_MULTIPLIER
		WeatherType.STORM: return STORM_COLD_MULTIPLIER
		_: return 1.0

func _weather_name(type: WeatherType) -> String:
	match type:
		WeatherType.CLEAR: return "Klarer Himmel"
		WeatherType.RAIN: return "Regen"
		WeatherType.FOG: return "Nebel"
		WeatherType.STORM: return "Sturm"
	return "Unbekannt"

func _weather_color(type: WeatherType) -> Color:
	match type:
		WeatherType.CLEAR: return Color(1.0, 0.9, 0.3)
		WeatherType.RAIN: return Color(0.4, 0.6, 0.9)
		WeatherType.FOG: return Color(0.7, 0.7, 0.8)
		WeatherType.STORM: return Color(0.5, 0.4, 0.6)
	return Color.WHITE
