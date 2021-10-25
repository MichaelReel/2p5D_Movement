extends KinematicBody


export (int) var current_HP : int = 10
export (int) var max_HP : int = 10
export (int) var damage : int = 1
export (int) var gold : int = 0
export (float) var attach_rate : float = 0.3
export (float) var move_speed : float = 5.0
export (float) var jump_force : float = 6.0
export (float) var gravity : float = 9.8

var last_attack_time : int = 0
var vel := Vector3.ZERO

onready var camera := $CameraOrbit
onready var attack_ray_cast := $AttackRayCast


func _physics_process(delta : float):
	# Reset velocity except jump/gravity (necessary?)
	vel.x = 0.0
	vel.z = 0.0
	
	# Get the input mouse vector
	var input = Vector3(
		Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
		0,
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	).normalized() 
	
	# Get the look direction, modified by the input vector 
	# BTW, much of this relies on the camera and player looking in the +z direction
	var dir : Vector3 = (transform.basis.z * input.z + transform.basis.x * input.x)
	vel.x = dir.x * move_speed
	vel.z = dir.z * move_speed
	
	# Gravity!
	vel.y -= gravity * delta
	
	# Jump input
	if Input.is_action_pressed("move_jump") and is_on_floor():
		vel.y = jump_force
	
	# Move the player along the current velocity
	vel = move_and_slide(vel, Vector3.UP)
