extends CharacterBody3D

var velocity := Vector3.ZERO
var gravity := 9.8


func _physics_process(delta : float):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity * delta
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	velocity = velocity
	
