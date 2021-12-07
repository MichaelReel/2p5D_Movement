extends Area

var commodities : Array = []


func can_see_commodity() -> bool:
	# Will worry about commodity types later
	return not commodities.empty()


func _on_CommodityDetectionZone_area_entered(area):
	if not commodities.has(area):
		commodities.append(area)
