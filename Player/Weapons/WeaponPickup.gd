extends Spatial

const PickedUpEffect := preload("res://Effects/CollectEffect.tscn")

export (PackedScene) var weapon

onready var mesh_instance := $MeshInstance
onready var parent := get_parent()  # For death effect + debug, could be scene root

var picked_up_effect

func _ready():
	picked_up_effect = PickedUpEffect.instance()
	picked_up_effect.draw_pass_1 = mesh_instance.mesh


func _create_picked_up_effect():
	parent.add_child(picked_up_effect)
	picked_up_effect.global_transform.origin = global_transform.origin
	picked_up_effect.emitting = true


func _on_PlayerDetectionZone_body_entered(body):
	if body.has_method("pickup_weapon") and body.pickup_weapon(weapon, mesh_instance.mesh):
		_create_picked_up_effect()
		queue_free()
