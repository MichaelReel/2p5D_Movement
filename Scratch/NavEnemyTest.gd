extends KinematicBody


onready var nav : Navigation = get_parent() # Replace with path exports?
onready var player := $"../../Player"

var path := []
var path_node := 0
var speed := 600

func _ready():
	pass
	

func _physics_process(delta : float):
	if path_node < path.size():
		var direction = path[path_node] - global_transform.origin
		
		if direction.length() < 1:
			path_node += 1
		else:
			move_and_slide(direction.normalized() * speed * delta, Vector3.UP)


func move_to(target_pos : Vector3):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0


func _on_Timer_timeout():
	move_to(player.global_transform.origin)
