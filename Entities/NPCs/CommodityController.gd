extends Spatial

signal extraction_started
signal extraction_complete


const COMMODITY_MAX := 100
const COMMODITY_MIN := 0

export (float) var commodity_desire_threshold := 60

onready var commodity_level := rand_range(COMMODITY_MIN, COMMODITY_MAX)

onready var extraction_timer := $ExtractTimer
onready var commodity_detection_zone := $CommodityDetectionZone


func _commodity_desired() -> bool:
	return commodity_level < commodity_desire_threshold


func desired_commodity_in_range() -> bool:
	return _commodity_desired() and commodity_detection_zone.can_recall_commodity()


func priority_commodity_position() -> Vector3:
	var commodity : Spatial = commodity_detection_zone.commodities[0]
	return commodity.global_transform.origin


func begin_extraction():
	extraction_timer.start()


func _on_ConsumeTimer_timeout():
	commodity_level -= 1


func _on_CommodityExtractionZone_commodity_available():
	emit_signal("extraction_started")


func _on_ExtractTimer_timeout():
	commodity_level += 1
	if commodity_level >= COMMODITY_MAX:
		commodity_level = COMMODITY_MAX
		extraction_timer.stop()
		emit_signal("extraction_complete")
