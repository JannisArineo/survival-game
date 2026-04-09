extends Node

# AudioManager - Procedural Sound System
# Alle Sounds werden als synthetische Toene generiert (kein externes Audio noetig)

var ambient_player: AudioStreamPlayer
var footstep_timer: float = 0.0
var footstep_interval: float = 0.45

var ambient_day: AudioStreamPlayer
var ambient_night: AudioStreamPlayer
var rain_player: AudioStreamPlayer

var is_raining: bool = false

signal footstep_played

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_players()

func _setup_players():
	ambient_day = AudioStreamPlayer.new()
	ambient_day.volume_db = -20
	add_child(ambient_day)

	ambient_night = AudioStreamPlayer.new()
	ambient_night.volume_db = -30
	add_child(ambient_night)

	rain_player = AudioStreamPlayer.new()
	rain_player.volume_db = -15
	add_child(rain_player)

func _process(delta):
	if GameManager.player == null or GameManager.paused:
		return

	_process_footsteps(delta)
	_process_ambient()

func _process_footsteps(delta):
	var player = GameManager.player
	var is_moving = player.velocity.length() > 0.5 and player.is_on_floor()
	var is_sprinting = Input.is_action_pressed("sprint")

	if is_moving:
		footstep_interval = 0.3 if is_sprinting else 0.45
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			footstep_timer = 0.0
			play_footstep(player.global_position)

func _process_ambient():
	pass  # Ambient tones werden als AudioStreamGenerators implementiert wenn noetig

func play_footstep(pos: Vector3):
	footstep_played.emit()
	# Verwende AudioStreamGenerator fuer prozedurale Sounds
	var stream = _create_footstep_stream()
	var player_node = AudioStreamPlayer3D.new()
	player_node.stream = stream
	player_node.volume_db = -10
	player_node.max_distance = 15.0
	get_tree().current_scene.add_child(player_node)
	player_node.global_position = pos
	player_node.play()
	get_tree().create_timer(0.5).timeout.connect(player_node.queue_free)

func play_hit(pos: Vector3, material: String = "wood"):
	var stream = _create_hit_stream(material)
	_play_3d_sound(stream, pos, -5.0, 0.3)

func play_attack():
	var stream = _create_swing_stream()
	_play_2d_sound(stream, -8.0, 0.2)

func play_craft():
	var stream = _create_craft_stream()
	_play_2d_sound(stream, -10.0, 0.3)

func play_pickup():
	var stream = _create_pickup_stream()
	_play_2d_sound(stream, -12.0, 0.15)

func play_build():
	var stream = _create_build_stream()
	_play_2d_sound(stream, -6.0, 0.4)

func play_death():
	var stream = _create_death_stream()
	_play_2d_sound(stream, -3.0, 1.0)

func play_bow_draw():
	var stream = _create_bow_draw_stream()
	_play_2d_sound(stream, -8.0, 0.5)

func play_bow_release():
	var stream = _create_bow_release_stream()
	_play_2d_sound(stream, -6.0, 0.2)

func set_rain(active: bool):
	is_raining = active

func _play_3d_sound(stream: AudioStream, pos: Vector3, vol: float, dur: float):
	if stream == null:
		return
	var node = AudioStreamPlayer3D.new()
	node.stream = stream
	node.volume_db = vol
	node.max_distance = 20.0
	get_tree().current_scene.add_child(node)
	node.global_position = pos
	node.play()
	get_tree().create_timer(dur + 0.1).timeout.connect(node.queue_free)

func _play_2d_sound(stream: AudioStream, vol: float, dur: float):
	if stream == null:
		return
	var node = AudioStreamPlayer.new()
	node.stream = stream
	node.volume_db = vol
	add_child(node)
	node.play()
	get_tree().create_timer(dur + 0.1).timeout.connect(node.queue_free)

# Procedural Audio Generators
func _create_footstep_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 2205  # 0.1 sek
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var envelope = exp(-t * 30.0)
		var noise_val = (randf() * 2.0 - 1.0) * envelope
		var tone = sin(t * TAU * 80.0) * envelope * 0.3
		var sample = int((noise_val * 0.7 + tone) * 60) + 128
		data[i] = clampi(sample, 0, 255)
	stream.data = data
	return stream

func _create_hit_stream(material: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 4410
	var data = PackedByteArray()
	data.resize(samples)
	var freq = 120.0 if material == "wood" else 200.0
	for i in samples:
		var t = float(i) / 22050.0
		var envelope = exp(-t * 20.0)
		var v = sin(t * TAU * freq) * envelope * 0.6 + (randf() * 2 - 1) * envelope * 0.4
		data[i] = clampi(int(v * 80) + 128, 0, 255)
	stream.data = data
	return stream

func _create_swing_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 2200
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var sweep = sin(t * TAU * (200.0 + t * 500.0))
		var envelope = exp(-t * 15.0)
		data[i] = clampi(int(sweep * envelope * 50) + 128, 0, 255)
	stream.data = data
	return stream

func _create_craft_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 6615
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var freq = 440.0 + t * 200.0
		var envelope = sin(t * PI / 0.3) if t < 0.3 else 0.0
		data[i] = clampi(int(sin(t * TAU * freq) * envelope * 60) + 128, 0, 255)
	stream.data = data
	return stream

func _create_pickup_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 3307
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var freq = 880.0 + t * 440.0
		var envelope = exp(-t * 10.0)
		data[i] = clampi(int(sin(t * TAU * freq) * envelope * 50) + 128, 0, 255)
	stream.data = data
	return stream

func _create_build_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 8820
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var envelope = exp(-t * 8.0)
		var v = (randf() * 2 - 1) * envelope * 0.8 + sin(t * TAU * 60.0) * envelope * 0.2
		data[i] = clampi(int(v * 70) + 128, 0, 255)
	stream.data = data
	return stream

func _create_death_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 22050
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var freq = 200.0 - t * 100.0
		var envelope = exp(-t * 3.0)
		data[i] = clampi(int(sin(t * TAU * freq) * envelope * 70) + 128, 0, 255)
	stream.data = data
	return stream

func _create_bow_draw_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 11025
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var tension = t * 2.0
		var v = (randf() * 2 - 1) * 0.3 + sin(t * TAU * (80.0 + tension * 40)) * 0.2
		data[i] = clampi(int(v * 40) + 128, 0, 255)
	stream.data = data
	return stream

func _create_bow_release_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BIT
	stream.mix_rate = 22050
	var samples = 4410
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / 22050.0
		var envelope = exp(-t * 20.0)
		var v = (randf() * 2 - 1) * envelope * 0.7 + sin(t * TAU * 300.0) * envelope * 0.3
		data[i] = clampi(int(v * 70) + 128, 0, 255)
	stream.data = data
	return stream
