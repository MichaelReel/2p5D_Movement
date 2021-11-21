extends Node

signal items_updated()
signal selection_updated(selected_item, slot_index)

const MAX_SLOTS := 8

var inventory_slots := []
var slot_icon_meshes := []
var selected_slot : int


func _ready():
	# Start with empty inventory
	for _i in range(MAX_SLOTS):
		inventory_slots.append(null)
		slot_icon_meshes.append(null)


func pickup_item(item : Spatial, mesh : Mesh) -> bool:
	"""
	Attempt to add an item to the inventory.
	
	Return:
		If the item can be added return true,
		if it can't be added return false.
	"""
	var i = 0
	while i < MAX_SLOTS and inventory_slots[i] != null:
		i += 1
	
	if i < MAX_SLOTS:
		inventory_slots[i] = item
		slot_icon_meshes[i] = mesh
		emit_signal("items_updated")
		return select_slot(i)
	
	return false


func select_slot(slot_index : int) -> bool:
	"""
	Set the item in the slot_index as selected, if there is an item in that slot
	"""
	if inventory_slots[slot_index] != null:
		selected_slot = slot_index
		emit_signal("selection_updated", inventory_slots[slot_index], slot_index)
		return true
	return false


func get_icon_meshes() -> Array:
	return slot_icon_meshes
