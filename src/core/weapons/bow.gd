extends Node3D
class_name BowWeapon

@export var arrow_speed := 25.0
@export var arrow_damage := 15.0

const ARROW_SCENE := preload("res://src/core/weapons/arrow.tscn")

@onready var arrow_spawn: Marker3D = $ArrowSpawn

func attack() -> void:
	var arrow: CharacterBody3D = ARROW_SCENE.instantiate()
	get_tree().root.add_child(arrow)
	arrow.global_transform = arrow_spawn.global_transform
	arrow.speed = arrow_speed
	arrow.damage = arrow_damage
