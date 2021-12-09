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
const COMMODITY_MAX := 100
const COMMODITY_MIN := 0


export (float) var max_speed := 5.0
export (float) var friction := 200.0
export (float) var acceleration := 10.0
export (float) var arrival_range := 1.0
export (float) var path_arrival_range := 1.0
export (float) var chase_update_time := 1.0
export (float) var soft_push_factor := 20.0
export (float) var hurt_timeout := 0.4
export (float) var commodity_desire_threshold := 60

onready var parent := get_parent()  # For death effect + debug, could be scene root
onready var nav : Navigation = get_parent()  # Specifically for navigation

onready var face_material : SpatialMaterial = $MeshInstance.get_surface_material(0)
onready var commodity_detection_zone := $CommodityDetectionZone
onready var wander_controller = $WanderController
onready var soft_collision := $SoftCollision
onready var stats := $Stats
onready var hurt_box := $Vunerable
onready var extraction_timer := $ExtractTimer


#onready var invunerability_animation_player := $InvunerabilityAnimationPlayer
onready var state := _pick_random_state(NON_CHASE_STATES)
onready var chase_reset_time := chase_update_time
onready var commodity_level := rand_range(COMMODITY_MIN, COMMODITY_MAX)

var velocity := Vector3.ZERO
var path := []
var path_node := 0


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
	path.clear()
	path_node = 0
	wander_controller.start_wander_timer()


func _to_wander_state():
	wander_controller.update_target_position()
	_path_to_global_position(wander_controller.target_position)


func _to_chase_state():
	var commodity : Spatial = commodity_detection_zone.commodities[0]
	if commodity != null:
		_path_to_global_position(commodity.global_transform.origin)


func _to_extract_state():
	path.clear()
	path_node = 0
	extraction_timer.start()


func _in_idle_state(delta : float):
	_seek_commodities()
	if wander_controller.get_time_left() == 0:
		_next_non_in_chase_state()
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
	_update_velocity_for_pathed_position(delta)


func _in_wander_state(delta : float):
	_seek_commodities()
	if path_node >= path.size():
		_next_non_in_chase_state()
	_update_velocity_for_pathed_position(delta)
	
	if global_transform.origin.distance_to(wander_controller.target_position) <= arrival_range:
		_set_state(IDLE)


func _in_chase_state(delta : float):
	chase_reset_time -= delta
	if chase_reset_time <= 0 or path_node >= path.size():
		chase_reset_time = chase_update_time
		var commodity : Spatial = commodity_detection_zone.commodities[0]
		if commodity != null:
			_path_to_global_position(commodity.global_transform.origin)
		else:
			_next_non_in_chase_state()
		
	_update_velocity_for_pathed_position(delta)


func _in_extract_state(delta : float):
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
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
	velocity = move_and_slide(velocity, Vector3.UP)


func _path_to_global_position(target_pos : Vector3):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0


func _update_velocity_for_pathed_position(delta : float):
	if path_node < path.size():
		var distance : float = global_transform.origin.distance_to(path[path_node])
		var direction : Vector3 = global_transform.origin.direction_to(path[path_node])
		if distance <= path_arrival_range:
			path_node += 1
		else:
			velocity = velocity.move_toward(direction * max_speed, acceleration * delta)


func _commodity_desired() -> bool:
	return commodity_level < commodity_desire_threshold


func _seek_commodities():
	if _commodity_desired() and commodity_detection_zone.can_recall_commodity():
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


func _on_ConsumeTimer_timeout():
	commodity_level -= 1


func _on_CommodityExtractionZone_commodity_available():
	if state == CHASE:
		_set_state(EXTRACT)


func _on_ExtractTimer_timeout():
	commodity_level += 1
	if commodity_level >= COMMODITY_MAX:
		commodity_level = COMMODITY_MAX
		extraction_timer.stop()
		_next_non_in_chase_state()
