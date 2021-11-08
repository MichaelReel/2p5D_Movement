extends KinematicBody


const DeathEffect := preload("res://Effects/PlayerDeathEffect.tscn")

export (float) var acceleration := 150.0
export (float) var air_friction := 4.0
export (float) var ground_friction := 80.0
export (float) var max_speed := 5.0
export (float) var jump_force := 10.0
export (float) var gravity := 25.0
export (bool) var air_control := true
export (float) var spawn_timeout := 1.0
export (float) var hurt_timeout := 0.3

onready var animation_player := $AnimationPlayer
onready var attack_ray_cast := $WeaponHolder/MeleeWeaponHolder/AttackRayCast
onready var hurt_box := $Vunerable
onready var invincibility_animation_player := $InvincibilityAnimationPlayer
onready var camera_arm := $CameraOrbit
onready var stats := PlayerStats
onready var parent := get_parent()

var velocity := Vector3.ZERO
var horizontal_velocity := Vector2.ZERO


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
		
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if Input.is_action_just_pressed("move_attack"):
		animation_player.play("attack")


func perform_input_movement(delta : float, input_vector : Vector2):
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


func end_attack():
	animation_player.play("idle")


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
	print("Health: " + str(stats.health))


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
	
