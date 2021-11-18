extends Spatial

const PickedUpEffect := preload("res://Effects/DeathEffect.tscn")

export (PackedScene) var weapon

onready var parent := get_parent()  # For death effect + debug, could be scene root


func _create_picked_up_effect():
	var picked_up_effect := PickedUpEffect.instance()
	parent.add_child(picked_up_effect)
	picked_up_effect.global_transform.origin = global_transform.origin
	picked_up_effect.emitting = true


func _on_PlayerDetectionZone_body_entered(body):
	if body.has_method("pickup_weapon"):
		body.pickup_weapon(weapon)
		_create_picked_up_effect()
		queue_free()
