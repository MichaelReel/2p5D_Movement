extends Spatial


export (Rect2) var floor_space := Rect2(Vector2(-20, -20), Vector2(40, 40))
export (int, 1, 10) var grid_height := 2


onready var grid_map := $GridMap
onready var mesh_lib : MeshLibrary = grid_map.mesh_library
onready var cube := mesh_lib.find_item_by_name("cube")
onready var space := GridMap.INVALID_CELL_ITEM
onready var noise := OpenSimplexNoise.new()


func _ready():
	_create_flat_base()
	_setup_noise()
	_create_noise_layers()
	_create_retaining_wall()


func _setup_noise():
#	randomize()
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 20.0
	noise.persistence = 0.8


func _create_flat_base():
	_AABB_fill(
		AABB(
			Vector3(floor_space.position.x, -1, floor_space.position.y),
			Vector3(floor_space.size.x, 1, floor_space.size.y)
		),
		cube
	)


func _create_noise_layers():
	_AABB_noise_fill(
		AABB(
			Vector3(floor_space.position.x, 0, floor_space.position.y),
			Vector3(floor_space.size.x, grid_height, floor_space.size.y)
		),
		cube
	)

func _create_retaining_wall():
	_AABB_fill(
		AABB(
			Vector3(floor_space.position.x, 0, floor_space.position.y),
			Vector3(floor_space.size.x, grid_height, 1)
		),
		cube
	)
	_AABB_fill(
		AABB(
			Vector3(floor_space.position.x, 0, floor_space.end.y - 1),
			Vector3(floor_space.size.x, grid_height, 1)
		),
		cube
	)
	_AABB_fill(
		AABB(
			Vector3(floor_space.position.x, 0, floor_space.position.y + 1),
			Vector3(1, grid_height, floor_space.size.y - 2)
		),
		cube
	)
	_AABB_fill(
		AABB(
			Vector3(floor_space.end.x - 1, 0, floor_space.position.y + 1),
			Vector3(1, grid_height, floor_space.size.y - 2)
		),
		cube
	)


func _AABB_noise_fill(bounds: AABB, tile: int):
	for y in range(bounds.position.y, bounds.end.y):
		for z in range(bounds.position.z, bounds.end.z):
			for x in range(bounds.position.x, bounds.end.x):
				if _noise_threshold(x, y, z):
					grid_map.set_cell_item(x, y, z, tile)


func _noise_threshold(x : int, y : int, z : int) -> bool:
	var value := noise.get_noise_3d(x, y, z)
	return abs(value) > 0.25


func _AABB_fill(bounds: AABB, tile: int):
	for y in range(bounds.position.y, bounds.end.y):
		for z in range(bounds.position.z, bounds.end.z):
			for x in range(bounds.position.x, bounds.end.x):
				grid_map.set_cell_item(x, y, z, tile)
	
