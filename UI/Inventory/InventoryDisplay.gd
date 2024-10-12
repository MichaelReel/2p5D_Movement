extends Control


@onready var inventory := InventoryManager
# Need to take care the size of this list is compatable with the Inventory itself:
@onready var slot_mappings := [
	$FrameRect/InventorySlot_0,
	$FrameRect/InventorySlot_1,
	$FrameRect/InventorySlot_2,
	$FrameRect/InventorySlot_3,
	$FrameRect/InventorySlot_4,
	$FrameRect/InventorySlot_5,
	$FrameRect/InventorySlot_6,
	$FrameRect/InventorySlot_7,
]
@onready var select_rect : Control = slot_mappings[0].get_node("SelectRect")

var selected_slot : int

func _ready():
	var _err = inventory.selection_updated.connect(_on_Inventory_item_selected)
	_err = inventory.items_updated.connect(_on_Inventory_items_updated)
	_on_Inventory_empty()


func _on_Inventory_item_selected(_item, index):
	slot_mappings[selected_slot].remove_child(select_rect)
	slot_mappings[selected_slot].set_selected_state(false)
	selected_slot = index
	slot_mappings[selected_slot].set_selected_state(true)
	slot_mappings[selected_slot].add_child(select_rect)
	select_rect.visible = true


func _on_Inventory_empty():
	select_rect.visible = false


func _on_Inventory_items_updated():
	print("Updating inventory")
	var mesh_list := inventory.get_icon_meshes()
	for i in range(len(slot_mappings)):
		slot_mappings[i].set_icon_mesh(mesh_list[i])
