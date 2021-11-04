extends Area


signal invincibility_started
signal invincibility_ended
signal damage_received(damage)

const HitEffect := preload("res://Effects/HitEffect.tscn")

onready var parent := get_tree().current_scene
onready var timer := $Timer
onready var collision_shape := $CollisionShape

var invincible : bool = false setget _set_invincible


func _set_invincible(value : bool):
	if invincible == value:
		return
	invincible = value
	if invincible:
		emit_signal("invincibility_started")
	else:
		emit_signal("invincibility_ended")


func start_invincibility(duration : float):
	self.invincible = true
	timer.start(duration)


func create_hit_effect(ray_cast: RayCast):
	var hit_effect := HitEffect.instance()
	parent.add_child(hit_effect)
	hit_effect.global_transform.origin = ray_cast.global_transform.origin
	hit_effect.emitting = true
	


func _on_Timer_timeout():
	self.invincible = false


func _on_Vunerable_invincibility_started():
	collision_shape.set_deferred("disabled", true)
	set_deferred("monitorable", false)


func _on_Vunerable_invincibility_ended():
	collision_shape.disabled = false
	monitorable = true


func ray_cast_hit(ray_cast: RayCast, damage : int):
	"""Call on this area by ray cast that detects the collision"""
	emit_signal("damage_received", damage)
	create_hit_effect(ray_cast)
