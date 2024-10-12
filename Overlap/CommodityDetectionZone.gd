extends Area3D

var commodities : Dictionary = {}


func can_recall_commodity(type : int) -> bool:
	# Will worry about commodity types later
	return commodities.has(type) and not commodities[type].is_empty()


func _on_CommodityDetectionZone_area_entered(area):
	var type : int = area.type
	if not commodities.has(type):
		commodities[type] = []
	if not commodities.has(area):
		commodities[type].append(area)
