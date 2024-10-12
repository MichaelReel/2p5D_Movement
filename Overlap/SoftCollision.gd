extends Area3D


func is_colliding():
	return get_overlapping_areas().size() > 0


func get_push_vector() -> Vector3:
	var areas := get_overlapping_areas()
	var push_vector := Vector3.ZERO
	if is_colliding():
		var area : Area3D = areas[0]
		push_vector = area.global_transform.origin.direction_to(
			global_transform.origin
		).normalized()
		push_vector.y = 0.0
	return push_vector
