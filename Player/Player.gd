extends KinematicBody


enum {
	MOVE,
	ATTACK
}


export (float) var acceleration := 150.0
export (float) var air_friction := 4.0
export (float) var ground_friction := 80.0
export (float) var max_speed := 5.0
export (float) var jump_force := 10.0
export (float) var gravity := 25.0
export (bool) var air_control := true


var state : int = MOVE
var velocity := Vector3.ZERO
var horizontal_velocity := Vector2.ZERO


func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ATTACK:
			state = MOVE


func move_state(delta : float):
	var input_vector := _normalized_input_vector()
	if input_vector != Vector2.ZERO and _movement_allowed():
		# Speed up - Apply player WSAD movement as horizontal acceleration
		var basis_z := Vector2(transform.basis.z.x, transform.basis.z.z)
		var basis_x := Vector2(transform.basis.x.x, transform.basis.x.z)
		var horizonal_dir := basis_z * input_vector.y + basis_x * input_vector.x
		horizontal_velocity = horizontal_velocity.move_toward(
			horizonal_dir * max_speed, acceleration * delta
		)
	else:
		# Slow down - apply horizontal friction
		var friction = air_friction
		if is_on_floor():
			friction = ground_friction
		horizontal_velocity = horizontal_velocity.move_toward(Vector2.ZERO, friction * delta)
		
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
		
	# Gravity!
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta

	# Jump input
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity += Vector3.UP * jump_force
		
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if Input.is_action_just_pressed("move_attack"):
		state = ATTACK


func _movement_allowed() -> bool:
	return air_control or is_on_floor()


func _normalized_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	).normalized()
