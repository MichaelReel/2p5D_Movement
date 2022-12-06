extends Node


signal no_health
signal health_changed(value)
signal max_health_changed(value)

export (int) var max_health : int = 1 setget set_max_health
var health : int = max_health setget set_health


func _ready():
	self.health = max_health


func set_max_health(value : int):
	max_health = value
	self.health = int(min(health, max_health))
	emit_signal("max_health_changed", max_health)


func set_health(value : int):
	health = value
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")


func get_health_as_fraction() -> float:
	if health <= 0:
		return 0.0
	return float(max_health) / float(health)
