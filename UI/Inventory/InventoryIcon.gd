extends Spatial


onready var mesh_instance := $MeshInstance

func set_icon_mesh(mesh : Mesh):
	mesh_instance.set_mesh(mesh)
