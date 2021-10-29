extends KinematicBody


export (int) var current_HP : int = 10
export (int) var max_HP : int = 10
export (float) var move_speed : float = 500.0
export (float) var gravity : float = 9.8


onready var nav : Navigation = get_parent() 
onready var player := $"../../Player"   # Need to get with collision areas


var vel := Vector3.ZERO
var path := []
var path_node := 0


func _physics_process(delta : float):
	if path_node < path.size():
		var direction = path[path_node] - global_transform.origin
		# direction.y -= gravity * delta
		
		if direction.length() < 1:
			path_node += 1
		else:
			vel = move_and_slide(direction.normalized() * move_speed * delta, Vector3.UP)


func move_to(target_pos : Vector3):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0


func _on_Timer_timeout():
	move_to(player.global_transform.origin)
