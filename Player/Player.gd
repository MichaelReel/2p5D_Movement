extends KinematicBody


const DeathEffect := preload("res://Effects/PlayerDeathEffect.tscn")
const FOOT_ROTATION_THRESHOLD := deg2rad(45)

enum {
	MOVE,
	JUMP,
	STAND
}

export (float) var acceleration := 150.0
export (float) var air_friction := 4.0
export (float) var ground_friction := 80.0
export (float) var max_speed := 5.0
export (float) var jump_force := 10.0
export (float) var gravity := 25.0
export (bool) var air_control := true
export (float) var spawn_timeout := 1.0
export (float) var hurt_timeout := 0.3

onready var torso := $Body/Torso
# The weapon stuff needs to be refactored out
onready var weapon_animation_player := $Body/Torso/WeaponHolder/MeleeWeaponHolder/AnimationPlayer
onready var attack_ray_cast := $Body/Torso/WeaponHolder/MeleeWeaponHolder/AttackRayCast
onready var hurt_box := $Vunerable
onready var invincibility_animation_player := $InvincibilityAnimationPlayer
onready var lower_body := $Body/Waist
onready var lower_body_animation_player := $Body/Waist/AnimationPlayer
onready var camera_arm := $Body/Torso/CameraOrbit
onready var stats := PlayerStats
onready var parent := get_parent()

var velocity := Vector3.ZERO
var horizontal_velocity := Vector2.ZERO
var ground_orientation := Vector2.UP
var state : int = STAND
var back_peddle : bool = false


func _ready():
	var _err = stats.connect("no_health", self, "_on_PlayerStats_no_health")
	hurt_box.start_invincibility(spawn_timeout)


func _physics_process(delta):
	var input_vector := _normalized_input_vector()
	perform_input_movement(delta, input_vector)
	
	# Gravity!
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta

	# Jump input
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity += Vector3.UP * jump_force
		_try_state(JUMP)
		
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if Input.is_action_just_pressed("move_attack"):
		weapon_animation_player.play("attack")


func perform_input_movement(delta : float, input_vector : Vector2):
	# Get the basis of the player facing direction in 2 Dimensions
	var facing_basis : Basis = torso.transform.basis
	var basis_z := Vector2(facing_basis.z.x, facing_basis.z.z)
	var basis_x := Vector2(facing_basis.x.x, facing_basis.x.z)
	if input_vector != Vector2.ZERO and _movement_allowed():
		# Speed up - Apply player WSAD movement as horizontal acceleration
		var horizonal_dir := basis_z * input_vector.y + basis_x * input_vector.x
		horizontal_velocity = horizontal_velocity.move_toward(
			horizonal_dir * max_speed, acceleration * delta
		)
		_rotate_lower_body_moving(horizonal_dir, input_vector.y < 0)
		_try_state(MOVE)
	else:
		# Slow down - apply horizontal friction
		var friction = air_friction
		if is_on_floor():
			friction = ground_friction
		horizontal_velocity = horizontal_velocity.move_toward(Vector2.ZERO, friction * delta)
		_rotate_lower_body(basis_z)
		_try_state(STAND)
		
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y


func _rotate_lower_body_moving(to_facing: Vector2, reverse: bool):
	# When walking backwards, reverse the animation and the facing direction
	back_peddle = reverse
	if back_peddle:
		to_facing = Vector2.ZERO - to_facing
	_rotate_lower_body(to_facing)


func _rotate_lower_body(to_facing: Vector2):
	if state == STAND:
		var rot_diff : float = ground_orientation.angle_to(to_facing)
		if rot_diff >= FOOT_ROTATION_THRESHOLD:
			_reposition_feet(to_facing)
			lower_body_animation_player.play("shuffle_from_left")
		elif rot_diff <= -FOOT_ROTATION_THRESHOLD:
			_reposition_feet(to_facing)
			lower_body_animation_player.play("shuffle_from_right")
	else:
		_reposition_feet(to_facing)


func _shuffle_complete():
	lower_body_animation_player.play("stand")


func _reposition_feet(to_facing: Vector2):
	# Just move for now, but would like to have a little shuffle animation here
	var dir = Vector3(to_facing.x, 0, to_facing.y)
	lower_body.look_at(transform.origin - dir, Vector3.UP)
	ground_orientation = to_facing


func end_attack():
	weapon_animation_player.play("idle")


func _movement_allowed() -> bool:
	"""
	Player can always accelerate if they are on the ground
	If in the air, then `air_control` must be set to allow acceleration
	"""
	return air_control or is_on_floor()


func _normalized_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	).normalized()


func _on_Vunerable_damage_received(damage):
	stats.health -= damage
	hurt_box.start_invincibility(hurt_timeout)


func _on_Vunerable_invincibility_started():
	invincibility_animation_player.play("start")


func _on_Vunerable_invincibility_ended():
	invincibility_animation_player.play("stop")


func _move_camera_to_parent():
	camera_arm.move_camera_to_scene(parent)


func _create_death_effect():
	var death_effect := DeathEffect.instance()
	parent.add_child(death_effect)
	death_effect.global_transform.origin = global_transform.origin
	death_effect.emitting = true


func _on_PlayerStats_no_health():
	_move_camera_to_parent()
	_create_death_effect()
	queue_free()


func _try_state(new_state : int):
	match state:
		MOVE:
			_try_from_move(new_state)
		JUMP:
			_try_from_jump(new_state)
		STAND:
			_try_from_stand(new_state)


func _try_from_move(new_state : int):
	match new_state:
		JUMP:
			lower_body_animation_player.play("jump")
			state = JUMP
		STAND:
			lower_body_animation_player.play("stand")
			state = STAND


func _try_from_jump(new_state : int):
	if is_on_floor():
		match new_state:
			MOVE:
				_play_body_running_animation()
				state = MOVE
			STAND:
				lower_body_animation_player.play("stand")
				state = STAND


func _try_from_stand(new_state : int):
	match new_state:
		MOVE:
			_play_body_running_animation()
			state = MOVE
		JUMP:
			lower_body_animation_player.play("jump")
			state = JUMP


func _play_body_running_animation():
	if back_peddle:
		lower_body_animation_player.play_backwards("run")
	else:
		lower_body_animation_player.play("run")

