extends Node3D
# Holds information about a commodity

signal commodity_desired(type)
signal commodity_exhausted(type)
signal commodity_replenished(type)

const COMMODITY_MAX := 100
const COMMODITY_MIN := 0

@export var type : int = Commodity.TYPES.WATER
@export var desire_threshold := 30
@export var exhaust_threshold := 5
@export var consume_rate := 2
@export var extract_rate := 10
@export var level := COMMODITY_MAX
@export var min_color := Color.RED
@export var max_color := Color.GREEN


@onready var state_material : StandardMaterial3D = $MeshInstance3D.get_surface_override_material(0)


func consume() -> void:
	level -= consume_rate
	_update_material_indicator()
	if level <= 0:
		level = 0
	elif level <= exhaust_threshold and level + consume_rate > exhaust_threshold:
		emit_signal("commodity_exhausted", type)
	elif level <= desire_threshold and level + consume_rate > desire_threshold:
		emit_signal("commodity_desired", type)


func desired() -> bool:
	return level <= desire_threshold


func extract() -> void:
	level += extract_rate
	_update_material_indicator()
	if level >= COMMODITY_MAX:
		level = COMMODITY_MAX
		emit_signal("commodity_replenished", type)


func _update_material_indicator() -> void:
	var ratio : float = inverse_lerp(COMMODITY_MIN, COMMODITY_MAX, level)
	var color : Color = lerp(min_color, max_color, ratio)
	state_material.albedo_color = color
