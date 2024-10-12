extends Sprite2D


@onready var viewport : SubViewport = $SubViewport
@onready var icon := $SubViewport/InventoryIcon

func _process(_delta):
	texture = viewport.get_texture()

func set_icon_mesh(mesh : Mesh):
	icon.set_icon_mesh(mesh)

func set_selected_state(selected : bool):
	icon.set_fov_highlight(selected)
