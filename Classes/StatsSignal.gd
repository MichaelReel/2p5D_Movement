extends Node

signal no_health
signal health_fraction_of_max(fraction_health)


func _on_Player_no_health():
	no_health.emit()

func _on_Player_health_fraction_of_max(fraction_health: float):
	health_fraction_of_max.emit(fraction_health)
