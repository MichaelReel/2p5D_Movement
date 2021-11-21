extends Sprite


onready var viewport : Viewport = $Viewport
onready var icon := $Viewport/InventoryIcon

func _process(_delta):
	texture = viewport.get_texture()

func set_icon_mesh(mesh : Mesh):
	icon.set_icon_mesh(mesh)
