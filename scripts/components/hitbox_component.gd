class_name HitboxComponent
extends Area3D

signal hit(damage: float, attacker: Node3D)

@export var health_component: HealthComponent

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	pass

func receive_hit(damage: float, attacker: Node3D = null):
	hit.emit(damage, attacker)
	if health_component:
		health_component.take_damage(damage)
