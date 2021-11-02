extends Particles

func _on_Timer_timeout():
	if not self.emitting:
		queue_free()
