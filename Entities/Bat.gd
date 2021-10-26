extends KinematicBody


export (int) var current_HP : int = 10
export (int) var max_HP : int = 10

export (float) var move_speed : float = 5.0
export (float) var gravity : float = 9.8


var vel := Vector3.ZERO


func _physics_process(delta : float):
	# Reset velocity except jump/gravity (necessary?)
	vel.x = 0.0
	vel.z = 0.0
	
	# Gravity!
	vel.y -= gravity * delta

	# Move the player along the current velocity
	vel = move_and_slide(vel, Vector3.UP)
