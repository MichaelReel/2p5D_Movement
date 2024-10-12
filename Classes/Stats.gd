extends Node


signal no_health
signal health_changed(value)
signal max_health_changed(value)

@export var max_health: int = 1: set = set_max_health
var health : int = max_health: set = set_health


func _ready():
	self.health = max_health


func set_max_health(value : int):
	max_health = value
	self.health = int(min(health, max_health))
	max_health_changed.emit(max_health)


func set_health(value : int):
	health = value
	health_changed.emit(health)
	if health <= 0:
		no_health.emit()


func get_health_as_fraction() -> float:
	if health <= 0:
		return 0.0
	return float(max_health) / float(health)
