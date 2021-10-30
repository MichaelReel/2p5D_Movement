extends Area

var player : Spatial = null


func can_see_player() -> bool:
	return player != null


func _on_PlayerDetectionZone_body_entered(body : Spatial):
	# Only the player should be on the player layer,
	# if not, add more checks here
	if player == null:
		player = body


func _on_PlayerDetectionZone_body_exited(body : Spatial):
	if player == body:
		player = null
