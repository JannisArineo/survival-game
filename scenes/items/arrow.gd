extends RigidBody3D

var damage: float = 25.0
var fired_by: Node3D = null
var has_hit: bool = false

func _ready():
	collision_layer = 0
	collision_mask = 1 | 2 | 4 | 8 | 16  # Alles ausser der Pfeil selbst
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	continuous_cd = true

	# Mesh erstellen
	var mesh_instance = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.01
	cyl.bottom_radius = 0.01
	cyl.height = 0.6
	mesh_instance.mesh = cyl
	mesh_instance.rotation.z = PI / 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.1)
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	# Kollision
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.02
	capsule.height = 0.6
	col.shape = capsule
	col.rotation.z = PI / 2.0
	add_child(col)

	# Auto-Destroy nach 10 Sekunden
	get_tree().create_timer(10.0).timeout.connect(queue_free)

func _physics_process(_delta):
	if has_hit:
		return
	# Pfeil zeigt in Flugrichtung
	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity.normalized(), Vector3.UP)
		rotation.x += PI / 2.0

func _on_body_entered(body: Node):
	if has_hit:
		return
	if body == fired_by:
		return

	has_hit = true

	# Schaden austeilen
	if body.has_method("receive_hit"):
		body.receive_hit(damage, fired_by)
	elif body.get_parent() and body.get_parent().has_method("receive_hit"):
		body.get_parent().receive_hit(damage, fired_by)
	elif body.has_method("take_damage"):
		body.take_damage(damage)

	# Stecken bleiben
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Nach 5 Sekunden verschwinden
	get_tree().create_timer(5.0).timeout.connect(queue_free)
