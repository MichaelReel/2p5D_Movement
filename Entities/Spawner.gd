extends Node3D


const Bat := preload("res://Entities/Enemies/Bat.tscn")

@export var press_timeout := 1.5

@onready var animation_player := $AnimationPlayer
@onready var press_box := $Vunerable
@onready var parent := get_parent()


var spawn_locations := []


func _ready():
	for child in get_children():
		if child is Marker3D:
			spawn_locations.append(child.global_transform.origin)


func _spawn_related_entities():
	for location in spawn_locations:
		var bat = Bat.instantiate()
		parent.add_child(bat)
		bat.global_transform.origin = location
		bat.reset_start_position()
		


func _on_Vunerable_damage_received(_damage):
	_spawn_related_entities()
	press_box.start_invincibility(press_timeout)


func _on_Vunerable_invincibility_started():
	animation_player.play("press")


func _on_Vunerable_invincibility_ended():
	animation_player.play("reset")

