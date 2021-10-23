extends Spatial


onready var grid_map := $GridMap
onready var mesh_lib : MeshLibrary = grid_map.mesh_library
onready var cube := mesh_lib.find_item_by_name("cube")


func _ready():
	_create_flat_base(AABB(Vector3(-2,-2,-1), Vector3(2, 2, 0)))


func _create_flat_base(bounds : AABB):
	grid_map.set_cell_item(0, 0, 0, cube)
	
