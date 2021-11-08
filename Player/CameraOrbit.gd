extends Spatial


export (float) var look_sensitivity : float = 40.0
export (float) var min_look_angle : float = -20.0
export (float) var max_look_angle : float = 75.0

var mouse_delta : Vector2 = Vector2.ZERO

onready var player : KinematicBody = get_parent()
onready var camera := $Camera


func _input(event : InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_delta = event.relative


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


func move_camera_to_scene(new_scene : Spatial):
	var transform : Transform = camera.global_transform
	remove_child(camera)
	new_scene.add_child(camera)
	camera.global_transform = transform
