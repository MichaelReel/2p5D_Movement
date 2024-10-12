extends Control

@export var pixel_per_health: float = 20.0
@export var health_max_margin: float = 2.0
@export var health: float = 10: set = set_health
@export var max_health: float = 10: set = set_max_health
@export var health_gradient: Gradient

@onready var stats := PlayerStats
@onready var health_ui_full := $HealthRect
@onready var health_ui_empty := $BackgroundRect


func _ready():
	self.max_health = stats.max_health
	self.health = stats.health
	var _err = stats.connect("health_changed", Callable(self, "set_health"))
	_err = stats.connect("max_health_changed", Callable(self, "set_max_health"))


func set_health(value : float):
	health = clamp(value, 0, max_health)
	if health_ui_full != null:
		health_ui_full.size.x = health * pixel_per_health
		var health_lerp = inverse_lerp(0, max_health, health)
		health_ui_full.color = health_gradient.sample(health_lerp)


func set_max_health(value : float):
	max_health = max(value, 1)
	self.health = min(health, max_health)
	if health_ui_empty != null:
		health_ui_empty.size.x = max_health * pixel_per_health + (2 * health_max_margin)
