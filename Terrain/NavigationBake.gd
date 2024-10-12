extends Navigation


@onready var nav_mesh := $NavigationRegion3D


func _ready():
	print("mesh agent radius: " + str(nav_mesh.navigation_mesh.agent_radius))
	nav_mesh.bake_navigation_mesh(false)
