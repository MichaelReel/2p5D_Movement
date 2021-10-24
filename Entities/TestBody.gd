extends KinematicBody

var velocity := Vector3.ZERO
var gravity := 9.8


func _physics_process(delta : float):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)
	
