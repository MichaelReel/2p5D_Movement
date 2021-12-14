extends Sprite3D
# Holds information about a commodity

signal commodity_desired(type)
signal commodity_exhausted(type)
signal commodity_replenished(type)

const COMMODITY_MAX := 100
const COMMODITY_MIN := 0

export var type : int = Commodity.TYPES.WATER
export (int) var desire_threshold := 60
export (int) var exhaust_threshold := 5
export (int) var consume_rate := 5
export (int) var extract_rate := 10
export (int) var level := COMMODITY_MAX


func _init(t : int = Commodity.TYPES.WATER):
	type = t


func consume() -> void:
	level -= consume_rate
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
	if level >= COMMODITY_MAX:
		level = COMMODITY_MAX
		emit_signal("commodity_replenished", type)
