extends Spatial

const HIGHLIGHT_FOV : float = 50.0

onready var mesh_instance := $MeshInstance
onready var camera := $Camera
onready var default_fov : float = camera.fov

func set_icon_mesh(mesh : Mesh):
	mesh_instance.set_mesh(mesh)


func set_fov_highlight(enabled : bool):
	camera.fov = HIGHLIGHT_FOV if enabled else default_fov
