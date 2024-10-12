extends Node3D


const Projectile = preload("res://Player/Weapons/RangeWeapon/Projectile.tscn")

@export var projectile_speed := 75.0
@export var projectile_gravity := 1.0
@export var damage := 1.0

@onready var weapon_animation_player := $AnimationPlayer
@onready var mesh_instance := $MeshInstance3D
@onready var scene_root := get_tree().get_root()


func perform_attack():
	weapon_animation_player.play("attack")


func _create_projectile():
	"""
	Call from the appropriate frame in the animation to create a projectile
	"""
	var projectile : CharacterBody3D = Projectile.instantiate()
	var basis = get_global_transform().basis
	var firing_direction : Vector3 = basis.z
	
	scene_root.add_child(projectile)
	projectile.global_transform = get_global_transform()
	projectile.velocity = firing_direction * projectile_speed
	projectile.gravity = projectile_gravity
	projectile.damage = damage
