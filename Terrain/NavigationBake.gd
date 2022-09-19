extends Navigation


onready var nav_mesh := $NavigationMeshInstance


func _ready():
	print("mesh agent radius: " + str(nav_mesh.navmesh.agent_radius))
	nav_mesh.bake_navigation_mesh(false)
