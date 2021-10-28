extends Spatial


export (Rect2) var floor_space := Rect2(Vector2(-20, -20), Vector2(40, 40))
export (int, 1, 10) var grid_height := 4
export (int, 1, 10) var retaining_wall_height := 10
export (float) var noise_threshold := 0.20
export (float) var threshold_per_level := 0.05


onready var navigation := $Navigation
onready var grid_map := $GridMap
onready var mesh_lib : MeshLibrary = grid_map.mesh_library
onready var cube := mesh_lib.find_item_by_name("cube")
onready var cube_water := mesh_lib.find_item_by_name("cube_water")
onready var cube_dirt := mesh_lib.find_item_by_name("cube_dirt")
onready var cube_rock := mesh_lib.find_item_by_name("cube_rock")
onready var cube_grass := mesh_lib.find_item_by_name("cube_grass")
onready var space := GridMap.INVALID_CELL_ITEM
onready var noise := OpenSimplexNoise.new()


func _ready():
	_create_flat_base()
	_setup_noise()
	_create_water_features()
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
		cube_grass
	)

func _create_water_features():
	_AABB_noise_fill(
		AABB(
			Vector3(floor_space.position.x, -1, floor_space.position.y),
			Vector3(floor_space.size.x, 1, floor_space.size.y)
		),
		cube_water
	)

func _create_noise_layers():
	_AABB_noise_fill(
		AABB(
			Vector3(floor_space.position.x, 0, floor_space.position.y),
			Vector3(floor_space.size.x, grid_height, floor_space.size.y)
		),
		cube_dirt
	)

func _create_retaining_wall():
	_AABB_walled_area(
		AABB(
			Vector3(floor_space.position.x, 0, floor_space.position.y),
			Vector3(floor_space.size.x, retaining_wall_height, floor_space.size.y)
		),
		cube_rock
	)


func _AABB_noise_fill(bounds: AABB, tile: int):
	for y in range(bounds.position.y, bounds.end.y):
		for z in range(bounds.position.z, bounds.end.z):
			for x in range(bounds.position.x, bounds.end.x):
				if _noise_threshold(x, y, z):
					grid_map.set_cell_item(x, y, z, tile)


func _noise_threshold(x : int, y : int, z : int) -> bool:
	var value := noise.get_noise_2d(x, z)
	return abs(value) < noise_threshold - (y * threshold_per_level)


func _AABB_walled_area(bounds: AABB, tile: int):
	_AABB_fill(
		AABB(
			Vector3(bounds.position.x, bounds.position.y, bounds.position.z),
			Vector3(bounds.size.x, bounds.size.y, 1)
		),
		tile
	)
	_AABB_fill(
		AABB(
			Vector3(bounds.position.x, bounds.position.y, bounds.end.z - 1),
			Vector3(bounds.size.x, bounds.size.y, 1)
		),
		tile
	)
	_AABB_fill(
		AABB(
			Vector3(bounds.position.x, bounds.position.y, bounds.position.z + 1),
			Vector3(1, bounds.size.y, bounds.size.z - 2)
		),
		tile
	)
	_AABB_fill(
		AABB(
			Vector3(bounds.end.x - 1, bounds.position.y, bounds.position.z + 1),
			Vector3(1, bounds.size.y, bounds.size.z - 2)
		),
		tile
	)


func _AABB_fill(bounds: AABB, tile: int):
	for y in range(bounds.position.y, bounds.end.y):
		for z in range(bounds.position.z, bounds.end.z):
			for x in range(bounds.position.x, bounds.end.x):
				grid_map.set_cell_item(x, y, z, tile)

