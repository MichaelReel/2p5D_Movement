extends Spatial


export (float) var look_sensitivity : float = 15.0
export (float) var min_look_angle : float = -20.0
export (float) var max_look_angle : float = 75.0

var mouse_delta : Vector2 = Vector2.ZERO

onready var player : KinematicBody = get_parent()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event : InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_delta = event.relative
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta : float):
	# Get the input mouse movement
	var cam_rot = Vector3(mouse_delta.y, mouse_delta.x, 0) * look_sensitivity * delta
	
	# Tilt the camera arm, up and down
	rotation_degrees.x += cam_rot.x
	rotation_degrees.x = clamp(rotation_degrees.x, min_look_angle, max_look_angle)
	
	# Rotate the player left and right
	player.rotation_degrees.y -= cam_rot.y
	
	# Clear the mouse_delta
	mouse_delta = Vector2.ZERO
