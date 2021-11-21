extends Control


onready var inventory := InventoryManager
# Need to take care the size of this list is compatable with the Inventory itself:
onready var slot_mappings := [
	$InventorySlot_0,
	$InventorySlot_1,
	$InventorySlot_2,
	$InventorySlot_3,
	$InventorySlot_4,
	$InventorySlot_5,
	$InventorySlot_6,
	$InventorySlot_7,
]

func _ready():
	var _err = inventory.connect("selection_updated", self, "_on_Inventory_item_selected")
	_err = inventory.connect("items_updated", self, "_on_Inventory_items_updated")


func _on_Inventory_item_selected(_item, index):
	print("Item selected: " + str(index))
	# TODO: Need some indication of selected item
	pass


func _on_Inventory_items_updated():
	print("Updating inventory")
	var mesh_list := inventory.get_icon_meshes()
	for i in range(len(slot_mappings)):
		slot_mappings[i].set_icon_mesh(mesh_list[i])
