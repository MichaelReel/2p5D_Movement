extends KinematicBody


enum {
	IDLE,
	WANDER,
	CHASE,
	EXTRACT,
}

const DeathEffect := preload("res://Effects/DeathEffect.tscn")
const NON_CHASE_STATES := [IDLE, WANDER]
const STATE_COLORS := {
	IDLE: Color(1.0, 1.0, 0.0, 1.0),
	WANDER: Color(0.0, 1.0, 0.0, 1.0),
	CHASE: Color(1.0, 0.0, 0.0, 1.0),
	EXTRACT: Color(1.0, 0.5, 0.0, 1.0),
}


export (float) var max_speed := 5.0
export (float) var friction := 200.0
export (float) var acceleration := 10.0
export (float) var arrival_range := 1.0
export (float) var chase_update_time := 1.0
export (float) var soft_push_factor := 20.0
export (float) var hurt_timeout := 0.4
export (float) var commodity_desire_threshold := 60.0

onready var parent := get_parent()  # For death effect + debug, could be scene root
onready var nav : NavigationAgent = $NavigationAgent

onready var face_material : SpatialMaterial = $MeshInstance.get_surface_material(0)
onready var wander_controller = $WanderController
onready var soft_collision := $SoftCollision
onready var stats := $Stats
onready var hurt_box := $Vunerable
onready var commodity_controller := $CommodityController


#onready var invunerability_animation_player := $InvunerabilityAnimationPlayer
onready var state := _pick_random_state(NON_CHASE_STATES)
onready var chase_reset_time := chase_update_time

var _velocity := Vector3.ZERO


func _physics_process(delta : float):
	match state:
		IDLE:
			_in_idle_state(delta)
		WANDER:
			_in_wander_state(delta)
		CHASE:
			_in_chase_state(delta)
		EXTRACT:
			_in_extract_state(delta)
	
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
			EXTRACT:
				_to_extract_state()
		
		face_material.albedo_color = STATE_COLORS[state]


func _to_idle_state():
	wander_controller.start_wander_timer()


func _to_wander_state():
	wander_controller.update_target_position()
	_path_to_global_position(wander_controller.target_position)


func _to_chase_state():
	var commodity_position = commodity_controller.priority_commodity_position()
	_path_to_global_position(commodity_position)


func _to_extract_state():
	commodity_controller.begin_extraction()


func _in_idle_state(delta : float):
	_seek_commodities()
	if wander_controller.get_time_left() == 0:
		_next_non_in_chase_state()
	_velocity = _velocity.move_toward(Vector3.ZERO, friction * delta)
	_update_velocity_for_pathed_position(delta)


func _in_wander_state(delta : float):
	_seek_commodities()
	if nav.is_navigation_finished():
		_next_non_in_chase_state()
	_update_velocity_for_pathed_position(delta)
	
	if global_transform.origin.distance_to(wander_controller.target_position) <= arrival_range:
		_set_state(IDLE)


func _in_chase_state(delta : float):
	chase_reset_time -= delta
	if chase_reset_time <= 0 or nav.is_navigation_finished():
		chase_reset_time = chase_update_time
		if commodity_controller.desired_commodity_in_range():
			_path_to_global_position(commodity_controller.priority_commodity_position())
		else:
			_next_non_in_chase_state()
		
	_update_velocity_for_pathed_position(delta)


func _in_extract_state(delta : float):
	_velocity = _velocity.move_toward(Vector3.ZERO, friction * delta)
	_update_velocity_for_pathed_position(delta)


func _next_non_in_chase_state():
	_set_state(_pick_random_state(NON_CHASE_STATES))


func _update_soft_collisions(delta : float):
	if soft_collision.is_colliding():
		_velocity += soft_collision.get_push_vector() * delta * soft_push_factor


func _apply_velocity():
	var facing := global_transform.origin + Vector3(_velocity.x, 0, _velocity.z)
	if facing != global_transform.origin:
		look_at(facing, Vector3.UP)
	_velocity = move_and_slide(_velocity, Vector3.UP)


func _path_to_global_position(target_pos : Vector3):
	nav.set_target_location(target_pos)


func _update_velocity_for_pathed_position(delta : float):
	if nav.is_navigation_finished():
		return

	var path_node : Vector3 = nav.get_next_location()
	var direction : Vector3 = global_transform.origin.direction_to(path_node)
	_velocity = _velocity.move_toward(direction * max_speed, acceleration * delta)


func _seek_commodities():
	if commodity_controller.desired_commodity_in_range():
		_set_state(CHASE)


func _pick_random_state(state_list : Array) -> int:
	state_list.shuffle()
	return state_list.front()


func _create_death_effect():
	var death_effect := DeathEffect.instance()
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
	pass
#	invunerability_animation_player.play("start")


func _on_Vunerable_invincibility_ended():
	pass
#	invunerability_animation_player.play("stop")


#func _on_InvunerabilityAnimationPlayer_animation_finished(_anim_name):
#	face_material.albedo_color = STATE_COLORS[state]


func _on_CommodityController_extraction_started():
	_set_state(EXTRACT)


func _on_CommodityController_extraction_complete():
	_next_non_in_chase_state()
