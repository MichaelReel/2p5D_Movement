extends Spatial


onready var weapon_animation_player := $AnimationPlayer

func perform_attack():
	weapon_animation_player.play("attack")
