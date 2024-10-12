extends GPUParticles3D

func _on_Timer_timeout():
	if not emitting:
		queue_free()
