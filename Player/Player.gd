extends CharacterBody3D

signal no_health
signal health_fraction_of_max(fraction_health)


const DeathEffect := preload("res://Effects/PlayerDeathEffect.tscn")
const FOOT_ROTATION_THRESHOLD := deg_to_rad(45)

enum {
	MOVE,
	JUMP,
	STAND
}

@export_group("Movement")
@export var max_speed := 5.0
@export var acceleration := 150.0
@export var air_friction := 4.0
@export var ground_friction := 80.0
@export var jump_force := 10.0
@export var gravity := 25.0
@export var air_control := true

@export_group("Invincibility")
@export var spawn_timeout := 1.0
@export var hurt_timeout := 0.3

# External nodes
@onready var stats: Node = PlayerStats
@onready var inventory: Node = InventoryManager
@onready var parent: Node3D = get_parent()

# Internal nodes
@onready var torso: Node3D = $Body/Torso
@onready var lower_body: Node3D = $Body/Waist
@onready var weapon_wielder: Node3D = %WeaponWielder
@onready var hurt_box: Area3D = $Vunerable
@onready var invincibility_animation_player: AnimationPlayer = %InvincibilityAnimationPlayer
@onready var lower_body_animation_player: AnimationPlayer = %AnimationPlayer
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera_3d: Camera3D = %Camera3D

var horizontal_velocity := Vector2.ZERO
var ground_orientation := Vector2.UP
var state : int = STAND
var back_peddle : bool = false


func _ready():
	var _err = stats.no_health.connect(_on_PlayerStats_no_health)
	_err = inventory.selection_updated.connect(_on_Inventory_item_selected)
	hurt_box.start_invincibility(spawn_timeout)


func _physics_process(delta):
	var input_vector := Input.get_vector("move_right", "move_left",  "move_backward", "move_forward")
	perform_input_movement(delta, input_vector)
	
	# Gravity!
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta

	# Jump input
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity += Vector3.UP * jump_force
		_try_state(JUMP)
		
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	velocity = velocity
	
	if Input.is_action_just_pressed("move_attack"):
		for weapon in weapon_wielder.get_children():
			if weapon.has_method("perform_attack"):
				weapon.perform_attack()

	if Input.is_action_just_released("inventory_down"):
		inventory.select_next_occupied_slot()
		
	if Input.is_action_just_released("inventory_up"):
		inventory.select_next_occupied_slot(false)


func perform_input_movement(delta : float, input_vector : Vector2):
	# Get the basis of the player facing direction in 2 Dimensions
	var facing_basis : Basis = torso.global_basis #  .transform.basis
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


func _movement_allowed() -> bool:
	"""
	Player can always accelerate if they are on the ground
	If in the air, then `air_control` must be set to allow acceleration
	"""
	return air_control or is_on_floor()


func _on_Vunerable_damage_received(damage):
	stats.health -= damage
	hurt_box.start_invincibility(hurt_timeout)

	health_fraction_of_max.emit(stats.get_health_as_fraction())


func _on_Vunerable_invincibility_started():
	invincibility_animation_player.play("start")


func _on_Vunerable_invincibility_ended():
	invincibility_animation_player.play("stop")


func _move_camera_to_parent():
	camera_pivot.move_camera_to_scene(parent)


func _create_death_effect():
	var death_effect := DeathEffect.instantiate()
	parent.add_child(death_effect)
	death_effect.global_transform.origin = global_transform.origin
	death_effect.emitting = true


func _on_PlayerStats_no_health():
	_move_camera_to_parent()
	_create_death_effect()
	no_health.emit()
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


func pickup_weapon(item_scene : PackedScene, icon_mesh : Mesh) -> bool:
	var item_instance = item_scene.instantiate()
	return inventory.pickup_item(item_instance, icon_mesh)


func _on_Inventory_item_selected(item_instance, _index):
	for child in weapon_wielder.get_children():
		weapon_wielder.remove_child(child)
	weapon_wielder.add_child(item_instance)
