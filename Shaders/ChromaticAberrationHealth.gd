extends ColorRect


const offset_multiplier : float = 10.0
const pulse_multiplier : float = 8.0


func _ready():
	_reset_shader_params()

func _reset_shader_params():
		material.set_shader_parameter("offset", 0.0)
		material.set_shader_parameter("pulse_speed", 0.0)

func _on_TestTrialsView_health_fraction_of_max(fraction_health):
	if fraction_health > 0.0:
		material.set_shader_parameter("offset", (1.0 - fraction_health) * offset_multiplier)
		material.set_shader_parameter("pulse_speed", (1.0 - fraction_health) * pulse_multiplier)
	else:
		_reset_shader_params()
