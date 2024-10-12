extends Node3D


@export var wander_min: float = 8.0
@export var wander_max: float = 32.0

@export var phase_min: float = 1.0
@export var phase_max: float = 3.0


@onready var start_position : Vector3 = global_transform.origin
@onready var target_position : Vector3 = start_position
@onready var timer := $Timer


func _ready():
	update_target_position()


func reset_start_position():
	start_position = global_transform.origin


func update_target_position():
	target_position = start_position + _get_random_target()


func _get_random_target() -> Vector3:
	var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	return random_dir * randf_range(wander_min, wander_max)


func get_time_left():
	return timer.time_left


func start_wander_timer():
	timer.start(randf_range(phase_min, phase_max))


func _on_Timer_timeout():
	update_target_position()
