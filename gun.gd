extends Node2D
@export var turnSpeed: float = 5
@export var coolDown: float = 5
var coolDelta: float = 10
var coolTimer: float = 0
var shooting: bool = false
@export var bulletScene: PackedScene

@onready var spawnPoint = $barrel/muzzle

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			shooting = true
		elif event.is_released():
			shooting = false

func _process(delta):
	var targAngle = (get_global_mouse_position() - global_position).angle()
	rotation = lerp_angle(rotation, targAngle, delta * turnSpeed)
	if coolTimer - delta * coolDelta > 0:
		coolTimer -= delta * coolDelta
	else:
		coolTimer = 0
	if shooting:
		spawnBullet()

func spawnBullet():
	if bulletScene and coolTimer <= 0:
		coolTimer = coolDown
		var bullet = bulletScene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = spawnPoint.global_position
		bullet.global_rotation = spawnPoint.global_rotation
