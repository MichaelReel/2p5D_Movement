extends CharacterBody3D


@export var gravity := 25.0
@export var damage := 1.0

var velocity := Vector3.ZERO


func _physics_process(delta):
	
	# Gravity!
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta

	var collision : KinematicCollision3D = move_and_collide(velocity * delta)
	
	if collision:
		# Stop the projectile, also give other collisions a chance
		velocity = Vector3.ZERO
		gravity = 0.0


func _on_Timer_timeout():
	queue_free()
