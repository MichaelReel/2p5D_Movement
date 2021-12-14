extends Spatial

signal commodity_desired(type)
signal commodity_exhausted(type)
signal extraction_started
signal extraction_complete


onready var commodities := $CarriedCommodities.get_children()
onready var extraction_timer := $ExtractTimer
onready var commodity_detection_zone := $CommodityDetectionZone


var commodity_map := {}
var extracting


func _ready():
	for commodity in commodities:
		commodity_map[commodity.type] = commodity
		var _err = commodity.connect("commodity_desired", self, "_on_Commodity_commodity_desired")
		_err = commodity.connect("commodity_exhausted", self, "_on_Commodity_commodity_exhausted")
		_err = commodity.connect("commodity_replenished", self, "_on_Commodity_commodity_replenished")


func desired_commodity_in_range() -> bool:
	var desired_and_in_range := false
	for type in commodity_map.keys():
		if commodity_map[type].desired() and commodity_detection_zone.can_recall_commodity():
			desired_and_in_range = true
	return desired_and_in_range


func priority_commodity_position() -> Vector3:
	var commodity : Spatial = commodity_detection_zone.commodities[0]
	return commodity.global_transform.origin


func begin_extraction() -> void:
	extraction_timer.start()


func _on_Commodity_commodity_desired(type : int) -> void:
	emit_signal("commodity_desired", type)


func _on_Commodity_commodity_exhausted(type : int) -> void:
	emit_signal("commodity_exhausted", type)


func _on_Commodity_commodity_replenished(_type : int) -> void:
	extraction_timer.stop()
	extracting = null
	emit_signal("extraction_complete")


func _on_ConsumeTimer_timeout() -> void:
	for type in commodity_map.keys():
		commodity_map[type].consume()


func _on_CommodityExtractionZone_commodity_available(type : int) -> void:
	# Assuming WATER, needs to part of the signal
	extracting = type
	emit_signal("extraction_started")


func _on_ExtractTimer_timeout() -> void:
	commodity_map[extracting].extract()


