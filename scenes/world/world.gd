extends Node3D

const RENDER_DISTANCE = 4 # Chunks in jede Richtung
const CHUNK_SIZE = 32
const QUAD_SIZE = 2.0

var noise: FastNoiseLite
var chunks: Dictionary = {} # Vector2i -> chunk node
var last_player_chunk: Vector2i = Vector2i(-999, -999)

@onready var sun: DirectionalLight3D = $Sun
@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var enemy_spawner = $EnemySpawner
@onready var water_plane = $WaterPlane

var spawn_timer: float = 0.0
const SPAWN_INTERVAL = 30.0

func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.015
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	# Wasser-Ebene
	_create_water_plane()

func _process(delta):
	if GameManager.player == null:
		return

	_update_chunks()
	_update_sun(delta)
	_update_enemy_spawns(delta)

func _update_chunks():
	var player_pos = GameManager.player.global_position
	var player_chunk = Vector2i(
		floori(player_pos.x / (CHUNK_SIZE * QUAD_SIZE)),
		floori(player_pos.z / (CHUNK_SIZE * QUAD_SIZE))
	)

	if player_chunk == last_player_chunk:
		return
	last_player_chunk = player_chunk

	# Neue Chunks laden
	var needed_chunks: Dictionary = {}
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for z in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk_pos = Vector2i(player_chunk.x + x, player_chunk.y + z)
			needed_chunks[chunk_pos] = true
			if not chunks.has(chunk_pos):
				_create_chunk(chunk_pos)

	# Alte Chunks entladen
	var to_remove: Array = []
	for chunk_pos in chunks:
		if not needed_chunks.has(chunk_pos):
			to_remove.append(chunk_pos)

	for chunk_pos in to_remove:
		chunks[chunk_pos].queue_free()
		chunks.erase(chunk_pos)

func _create_chunk(pos: Vector2i):
	var chunk_script = preload("res://scenes/world/terrain_chunk.gd")
	var chunk = Node3D.new()
	chunk.set_script(chunk_script)
	add_child(chunk)
	chunk.initialize(pos.x, pos.y, noise)
	chunks[pos] = chunk

func _update_sun(_delta):
	var angle = GameManager.get_sun_angle()
	sun.rotation_degrees = Vector3(angle, -30, 0)

	var intensity = GameManager.get_sun_intensity()
	sun.light_energy = lerp(0.05, 1.2, intensity)
	sun.light_color = _get_sun_color(GameManager.get_hour())

	# Ambient
	var env = environment.environment
	if env:
		env.ambient_light_energy = lerp(0.02, 0.4, intensity)
		env.ambient_light_color = _get_ambient_color(GameManager.get_hour())
		env.fog_light_color = _get_fog_color(GameManager.get_hour())

func _get_sun_color(hour: float) -> Color:
	if hour < 6.0 or hour > 19.0:
		return Color(0.2, 0.2, 0.4)
	elif hour < 8.0:
		return Color(1.0, 0.7, 0.4) # Morgenrot
	elif hour > 17.0:
		return Color(1.0, 0.6, 0.3) # Abendrot
	return Color(1.0, 0.95, 0.9)

func _get_ambient_color(hour: float) -> Color:
	if hour < 6.0 or hour > 19.0:
		return Color(0.05, 0.05, 0.15)
	return Color(0.6, 0.7, 0.8)

func _get_fog_color(hour: float) -> Color:
	if hour < 6.0 or hour > 19.0:
		return Color(0.02, 0.02, 0.05)
	return Color(0.5, 0.6, 0.7)

func _create_water_plane():
	var water = MeshInstance3D.new()
	water.name = "WaterPlane"
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(5000, 5000)
	water.mesh = plane_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.35, 0.65, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.3
	water.material_override = mat
	water.position.y = -1.0
	add_child(water)

func _update_enemy_spawns(delta):
	spawn_timer += delta
	if spawn_timer < SPAWN_INTERVAL:
		return
	spawn_timer = 0.0

	if GameManager.player == null:
		return

	# Mehr Spawns bei Nacht
	var spawn_count = 2 if GameManager.is_night else 1

	for i in spawn_count:
		_spawn_enemy()

func _spawn_enemy():
	var player_pos = GameManager.player.global_position
	var angle = randf() * TAU
	var dist = randf_range(40.0, 70.0)
	var spawn_pos = player_pos + Vector3(cos(angle) * dist, 50, sin(angle) * dist)

	# Raycast nach unten um Bodenhöhe zu finden
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(spawn_pos, spawn_pos + Vector3.DOWN * 100)
	query.collision_mask = 1
	var result = space.intersect_ray(query)
	if result.is_empty():
		return

	spawn_pos.y = result.position.y + 1.0

	# Wolf oder Baer
	var scene_path = "res://scenes/enemies/wolf.tscn" if randf() < 0.7 else "res://scenes/enemies/bear.tscn"
	if ResourceLoader.exists(scene_path):
		var enemy = load(scene_path).instantiate()
		enemy.global_position = spawn_pos
		add_child(enemy)
