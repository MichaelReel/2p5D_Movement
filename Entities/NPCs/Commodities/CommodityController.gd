extends Node3D

signal commodity_desired(type)
signal commodity_exhausted(type)
signal extraction_started
signal extraction_complete


@onready var commodities := $CarriedCommodities.get_children()
@onready var extraction_timer := $ExtractTimer
@onready var commodity_detection_zone := $CommodityDetectionZone


var commodity_map := {}
var desire_queue := []
var extracting


func _ready():
	for commodity in commodities:
		commodity_map[commodity.type] = commodity
		var _err = commodity.connect("commodity_desired", Callable(self, "_on_Commodity_commodity_desired"))
		_err = commodity.connect("commodity_exhausted", Callable(self, "_on_Commodity_commodity_exhausted"))
		_err = commodity.connect("commodity_replenished", Callable(self, "_on_Commodity_commodity_replenished"))


func desired_commodity_in_range() -> bool:
	var any_desired_in_range := false
	for type in commodity_map.keys():
		var desired : bool = commodity_map[type].desired()
		var in_range : bool = commodity_detection_zone.can_recall_commodity(type)
		if desired and in_range:
			any_desired_in_range = true
			break
	return any_desired_in_range


func priority_commodity_position() -> Vector3:
	if desire_queue.is_empty():
		# Something cleared the queue, sit still and await state to change
		return global_transform.origin
	
	while not commodity_detection_zone.can_recall_commodity(desire_queue.front()):
		# TODO: Need to guard against an infinite loop here
		desire_queue.push_back(desire_queue.pop_front()) 
	
	var commodity : Node3D = commodity_detection_zone.commodities[desire_queue.front()][0]
	return commodity.global_transform.origin


func begin_extraction() -> void:
	extraction_timer.start()


func _on_Commodity_commodity_desired(type : int) -> void:
	desire_queue.push_back(type)
	emit_signal("commodity_desired", type)


func _on_Commodity_commodity_exhausted(type : int) -> void:
	emit_signal("commodity_exhausted", type)


func _on_Commodity_commodity_replenished(_type : int) -> void:
	extraction_timer.stop()
	desire_queue.erase(extracting)
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


