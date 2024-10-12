extends Area3D

signal commodity_available(type)

var commodities : Array = []


func _on_CommodityExtractionZone_area_entered(area):
	var type : int = area.type
	# Worry about types later
	if not commodities.has(area):
		commodities.append(area)
		emit_signal("commodity_available", type)


func _on_CommodityExtractionZone_area_exited(area):
	if commodities.has(area):
		commodities.erase(area)
