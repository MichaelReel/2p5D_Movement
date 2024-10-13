extends Sprite2D


@onready var viewport : SubViewport = $SubViewport
@onready var icon := $SubViewport/InventoryIcon


func _ready() -> void:
	texture = viewport.get_texture()

func set_icon_mesh(mesh : Mesh) -> void:
	icon.set_icon_mesh(mesh)

func set_selected_state(selected : bool) -> void:
	icon.set_fov_highlight(selected)
