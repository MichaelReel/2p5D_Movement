extends StaticBody3D

## This MeshInstance3D has a PlaneMesh with 128 rows and 128 ranks of vertices
## It's created with 126 subdivides, giving 127 squares, thus 128 vertices in both dimensions
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

## This CollisionShape3D has HeightMapShape3D with 128 rows and 128 ranks of vertices
## It's offset by half a meter along x and z to make up for movement in the mesh
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

## This dispatcher is configured with an image size of 128 by 128
## Both the input textures are also set to these dimensions
@onready var terrain_compute_dispatcher: Node = %TerrainComputeDispatcher

func _ready() -> void:
	if terrain_compute_dispatcher.has_method("dispatch"):
		terrain_compute_dispatcher.call("dispatch")
	else:
		printerr("Oh no!")
		return
	
	var vertices: PackedVector3Array = await terrain_compute_dispatcher.get_output_vertices()
	
	# Setting the mix_value high is okay for images, by ruinous for geometry, re-scale can fix a bit
	var scaling: float = (1.0 / terrain_compute_dispatcher.mix_value) * 10.0
	var y_scaling_vector: Vector3 = Vector3(1.0, scaling, 1.0)
	var y_scaled_vertices: PackedVector3Array = PackedVector3Array(
		Array(vertices).map(func (vector: Vector3) -> Vector3: return vector * y_scaling_vector)
	)
	var scaled_y_coords: PackedFloat32Array = PackedFloat32Array(
		Array(y_scaled_vertices).map(func (vector: Vector3) -> float: return vector.y)
	)
	scaled_y_coords.reverse()
	
	# Update Collision Height Map from y_Coords
	var collision_height_map_shape: HeightMapShape3D = collision_shape_3d.shape
	collision_height_map_shape.set_map_data(scaled_y_coords)
	
	# 
	var terrain_mesh_shape: PlaneMesh = mesh_instance_3d.mesh
	var terrain_mesh_array: = terrain_mesh_shape.get_mesh_arrays()
	var _old_mesh_array: PackedVector3Array = terrain_mesh_array[Mesh.ARRAY_VERTEX]
	terrain_mesh_array[Mesh.ARRAY_VERTEX] = y_scaled_vertices
	
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, terrain_mesh_array)
	arr_mesh.regen_normal_maps()
	mesh_instance_3d.mesh = arr_mesh
