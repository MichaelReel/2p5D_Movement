extends Node

signal no_health
signal health_fraction_of_max(fraction_health)


func _on_Player_no_health():
	emit_signal("no_health")

func _on_Player_health_fraction_of_max(fraction_health: float):
	emit_signal("health_fraction_of_max", fraction_health)
