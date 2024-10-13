extends Area3D


signal invincibility_started
signal invincibility_ended
signal damage_received(damage)

const HitEffect := preload("res://Effects/HitEffect.tscn")

@onready var parent := get_tree().current_scene
@onready var timer := $Timer
@onready var collision_shape := $CollisionShape3D

var invincible : bool = false: set = _set_invincible


func _set_invincible(value : bool):
	if invincible == value:
		return
	invincible = value
	if invincible:
		invincibility_started.emit()
	else:
		invincibility_ended.emit()


func start_invincibility(duration : float):
	self.invincible = true
	timer.start(duration)


func create_hit_effect(collider: Node3D):
	var hit_effect := HitEffect.instantiate()
	parent.add_child(hit_effect)
	hit_effect.global_transform.origin = collider.global_transform.origin
	hit_effect.emitting = true


func _on_Timer_timeout():
	self.invincible = false


func _on_Vunerable_invincibility_started():
	collision_shape.set_deferred("disabled", true)
	set_deferred("monitorable", false)


func _on_Vunerable_invincibility_ended():
	collision_shape.disabled = false
	monitorable = true


func _on_Vunerable_area_entered(area : Area3D):
	print("vunerable ", str(self), " entered by area ", str(area))
	var damage : float = 1
	if "damage" in area:
		damage = area.damage
	damage_received.emit(damage)
	create_hit_effect(area)


func _on_Vunerable_body_entered(body : Node):
	print("vunerable ", str(self), " entered by body ", str(body))
	var damage : float = 1
	if "damage" in body:
		damage = body.damage
	damage_received.emit(damage)
	create_hit_effect(body)
	body.queue_free()
