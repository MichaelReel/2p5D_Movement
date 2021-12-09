extends Area

signal commodity_available()

var commodities : Array = []


func _on_CommodityExtractionZone_area_entered(area):
	# Worry about types later
	if not commodities.has(area):
		commodities.append(area)
		emit_signal("commodity_available")


func _on_CommodityExtractionZone_area_exited(area):
	if commodities.has(area):
		commodities.erase(area)
