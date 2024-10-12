extends CharacterBody3D


enum {
	IDLE,
	WANDER,
	CHASE
}

const DeathEffect := preload("res://Effects/DeathEffect.tscn")
const NON_CHASE_STATES := [IDLE, WANDER]
const STATE_COLORS := {
	IDLE: Color(1.0, 1.0, 0.0, 1.0),
	WANDER: Color(0.0, 1.0, 0.0, 1.0),
	CHASE: Color(1.0, 0.0, 0.0, 1.0),
}

@export var max_speed := 5.0
@export var friction := 200.0
@export var acceleration := 10.0
@export var arrival_range := 1.0
@export var chase_update_time := 1.0
@export var soft_push_factor := 20.0
@export var hurt_timeout := 0.4

@onready var parent := get_parent()  # For death effect + debug, could be scene root
@onready var nav : NavigationAgent3D = $NavigationAgent3D
@onready var wing_material : StandardMaterial3D = $AnimatedComponents/Body/LeftWingPivot/WingMesh.get_surface_override_material(0)
@onready var player_detection_zone := $PlayerDetectionZone
@onready var wander_controller = $WanderController
@onready var soft_collision := $SoftCollision
@onready var stats := $Stats
@onready var hurt_box := %Vunerable
@onready var invunerability_animation_player := $InvunerabilityAnimationPlayer
@onready var state := _pick_random_state(NON_CHASE_STATES)
@onready var chase_reset_time := chase_update_time


func _physics_process(delta : float):
	match state:
		IDLE:
			_in_idle_state(delta)
		WANDER:
			_in_wander_state(delta)
		CHASE:
			_in_chase_state(delta)
	
	_update_soft_collisions(delta)
	_apply_velocity()


func reset_start_position():
	wander_controller.reset_start_position()


func _set_state(new_state : int):
	if state != new_state:
		state = new_state
		
		match state:
			IDLE:
				_to_idle_state()
			WANDER:
				_to_wander_state()
			CHASE:
				_to_chase_state()
		
		wing_material.albedo_color = STATE_COLORS[state]


func _to_idle_state():
	wander_controller.start_wander_timer()


func _to_wander_state():
	wander_controller.update_target_position()
	_path_to_global_position(wander_controller.target_position)


func _to_chase_state():
	var player : Node3D = player_detection_zone.player
	if player != null:
		_path_to_global_position(player.global_transform.origin)


func _in_idle_state(delta : float):
	_seek_player()
	if wander_controller.get_time_left() == 0:
		_next_non_in_chase_state()
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
	_update_velocity_for_pathed_position(delta)


func _in_wander_state(delta : float):
	_seek_player()
	if nav.is_navigation_finished():
		_next_non_in_chase_state()
	_update_velocity_for_pathed_position(delta)
	
	if global_transform.origin.distance_to(wander_controller.target_position) <= arrival_range:
		_set_state(IDLE)


func _in_chase_state(delta):
	chase_reset_time -= delta
	if chase_reset_time <= 0 or nav.is_navigation_finished():
		chase_reset_time = chase_update_time
		var player : Node3D = player_detection_zone.player
		if player != null:
			_path_to_global_position(player.global_transform.origin)
		else:
			_next_non_in_chase_state()
		
	_update_velocity_for_pathed_position(delta)


func _next_non_in_chase_state():
	_set_state(_pick_random_state(NON_CHASE_STATES))


func _update_soft_collisions(delta : float):
	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * soft_push_factor


func _apply_velocity():
	var facing := global_transform.origin + Vector3(velocity.x, 0, velocity.z)
	if facing != global_transform.origin:
		look_at(facing, Vector3.UP)
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	velocity = velocity


func _path_to_global_position(target_pos : Vector3):
	nav.set_target_position(target_pos)


func _update_velocity_for_pathed_position(delta : float):
	if nav.is_navigation_finished():
		return

	var path_next : Vector3 = nav.get_next_path_position()
	var direction : Vector3 = global_transform.origin.direction_to(path_next)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)


func _seek_player():
	if player_detection_zone.can_see_player():
		_set_state(CHASE)


func _pick_random_state(state_list : Array) -> int:
	return state_list.pick_random()


func _create_death_effect():
	var death_effect := DeathEffect.instantiate()
	parent.add_child(death_effect)
	death_effect.global_transform.origin = global_transform.origin
	death_effect.emitting = true


func _on_Stats_no_health():
	_create_death_effect()
	queue_free()


func _on_Vunerable_damage_received(damage):
	stats.health -= damage
	hurt_box.start_invincibility(hurt_timeout)


func _on_Vunerable_invincibility_started():
	invunerability_animation_player.play("start")


func _on_Vunerable_invincibility_ended():
	invunerability_animation_player.play("stop")


func _on_InvunerabilityAnimationPlayer_animation_finished(_anim_name):
	wing_material.albedo_color = STATE_COLORS[state]
