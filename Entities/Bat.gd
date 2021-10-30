extends KinematicBody


enum {
	IDLE,
	WANDER,
	CHASE
}

# const DeathEffect := preload("<path_to_death_effect_scene>"
const NON_CHASE_STATES := [IDLE, WANDER]

export (float) var max_speed := 10.0
export (float) var friction := 200.0
export (float) var acceleration := 10.0
export (float) var arrival_range := 1.0

onready var player_detection_zone := $PlayerDetectionZone
onready var parent := get_parent()  # For death effect, could be scene root
onready var wander_controller = $WanderController
onready var state := _pick_random_state(NON_CHASE_STATES)
onready var nav : Navigation = get_parent()

var velocity := Vector3.ZERO
var path := []
var path_node := 0
var cast_path := []

func _physics_process(delta : float):
	match state:
		IDLE:
			_idle_state(delta)
		WANDER:
			_wander_state(delta)
		CHASE:
			_chase_state(delta)

	look_at(global_transform.origin + velocity, Vector3.UP)
	velocity = move_and_slide(velocity, Vector3.UP)

func _idle_state(delta : float):
	_non_chase_state()
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)


func _wander_state(delta : float):
	_non_chase_state()
	_accelerate_to_pathed_position(delta)
	
	if global_transform.origin.distance_to(wander_controller.target_position) <= arrival_range:
		_next_non_chase_state()


func _non_chase_state():
	_seek_player()
	if wander_controller.get_time_left() == 0:
		_next_non_chase_state()


func _next_non_chase_state():
	state = _pick_random_state(NON_CHASE_STATES)
	wander_controller.start_wander_timer()


func _chase_state(delta):
	var player : Spatial = player_detection_zone.player
	if player != null:
		_path_to_global_position(player.global_transform.origin)
	else:
		_next_non_chase_state()
		
	_accelerate_to_pathed_position(delta)


func _path_to_global_position(target_pos : Vector3):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0
	
	# Draw?
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


func _accelerate_to_pathed_position(delta : float):
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
		state = CHASE


func _pick_random_state(state_list : Array) -> int:
	state_list.shuffle()
	return state_list.front()


func _on_WanderController_target_position_updated(target_position):
	if state == WANDER:
		_path_to_global_position(target_position)
	
