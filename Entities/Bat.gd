extends KinematicBody


enum {
	IDLE,
	WANDER,
	CHASE
}

# const DeathEffect := preload("<path_to_death_effect_scene>"
const NON_in_chase_stateS := [IDLE, WANDER]
const STATE_COLORS := {
	IDLE: Color(1.0, 1.0, 0.0, 1.0),
	WANDER: Color(0.0, 1.0, 0.0, 1.0),
	CHASE: Color(1.0, 0.0, 0.0, 1.0),
}

export (float) var max_speed := 5.0
export (float) var friction := 200.0
export (float) var acceleration := 10.0
export (float) var arrival_range := 1.0

onready var wing_material : SpatialMaterial = $AnimatedComponents/LeftWingPivot/WingMesh.get_surface_material(0)
onready var player_detection_zone := $PlayerDetectionZone
onready var parent := get_parent()  # For death effect, could be scene root
onready var wander_controller = $WanderController
onready var state := _pick_random_state(NON_in_chase_stateS)
onready var nav : Navigation = get_parent()

var velocity := Vector3.ZERO
var path := []
var path_node := 0
var cast_path := []


func _physics_process(delta : float):
	match state:
		IDLE:
			_in_idle_state(delta)
		WANDER:
			_in_wander_state(delta)
		CHASE:
			_in_chase_state(delta)
	
	_apply_velocity()


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
	wander_controller.start_wander_timer()

func _to_chase_state():
	var player : Spatial = player_detection_zone.player
	if player != null:
		_path_to_global_position(player.global_transform.origin)


func _in_idle_state(delta : float):
	_non_in_chase_state()
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
	_update_velocity_for_pathed_position(delta)


func _in_wander_state(delta : float):
	_non_in_chase_state()
	_update_velocity_for_pathed_position(delta)
	
	if global_transform.origin.distance_to(wander_controller.target_position) <= arrival_range:
		_set_state(IDLE)


func _in_chase_state(delta):
	if path_node >= path.size():
		var player : Spatial = player_detection_zone.player
		if player != null:
			_path_to_global_position(player.global_transform.origin)
		else:
			_next_non_in_chase_state()
		
	_update_velocity_for_pathed_position(delta)


func _non_in_chase_state():
	_seek_player()
	if wander_controller.get_time_left() == 0:
		_next_non_in_chase_state()


func _next_non_in_chase_state():
	_set_state(_pick_random_state(NON_in_chase_stateS))


func _apply_velocity():
	var facing := global_transform.origin + Vector3(velocity.x, 0, velocity.z)
	if facing != global_transform.origin:
		look_at(facing, Vector3.UP)
	velocity = move_and_slide(velocity, Vector3.UP)


func _path_to_global_position(target_pos : Vector3):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0
	
	# Draw - Use raycasts to show up the path for debug
	for rc in cast_path:
		parent.remove_child(rc)
		rc.queue_free()
	cast_path.clear()
	for pn in len(path) - 1:
		cast_path.append(RayCast.new())
		cast_path[pn].global_transform.origin = path[pn]
		cast_path[pn].set_cast_to(path[pn + 1] - path[pn])
		cast_path[pn].set_enabled(true)
		parent.add_child(cast_path[pn])


func _update_velocity_for_pathed_position(delta : float):
	if path_node < path.size():
		var distance : float = global_transform.origin.distance_to(path[path_node])
		var direction : Vector3 = global_transform.origin.direction_to(path[path_node])
#		direction.y = 0
		if distance <= 0.2:
			path_node += 1
		else:
			velocity = velocity.move_toward(direction * max_speed, acceleration * delta)


func _seek_player():
	if player_detection_zone.can_see_player():
		_set_state(CHASE)


func _pick_random_state(state_list : Array) -> int:
	state_list.shuffle()
	return state_list.front()


func _on_WanderController_target_position_updated(target_position):
	if state == WANDER:
		_path_to_global_position(target_position)
	
