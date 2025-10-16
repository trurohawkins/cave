extends Node2D
@export var turnSpeed: float = 5
@export var coolDown: float = 5
@export var kickBack: float = 10

var coolDelta: float = 10
var coolTimer: float = 0
var shooting: bool = false
@export var useMouse = false
@export var bulletScene: PackedScene
@export var player: CharacterBody2D
@export var shotCost: float = 5
@onready var spawnPoint = $hand/muzzle
@onready var handEnergySprite = $hand/deet
var GM: Node2D
var cam: Camera2D

func _input(event):
	if useMouse:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				shooting = true
			elif event.is_released():
				shooting = false
	else:
		if event.is_action_pressed("shoot"):
			shooting = true
		elif event.is_action_released("shoot"):
			shooting = false

func _process(delta):
	if !player:
		return
	global_position = player.global_position
	if useMouse:
		var targAngle = (get_global_mouse_position() - global_position).angle()
		rotation = lerp_angle(rotation, targAngle, delta * turnSpeed)
	else:
		var direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if direction != Vector2.ZERO:
			#print(str(direction) + " " + str(direction.length()))
			var angle = direction.rotated(cam.rotation).angle()
			rotation = lerp_angle(rotation, angle, delta * turnSpeed)
			if abs(angle - rotation) < 0.1:
				rotation = angle
		"""
		var left = 0
		if Input.is_action_pressed("aim_left"):
			left = -1
			
		var right = 0
		if Input.is_action_pressed("aim_right"):
			right = 1
		var direction = left + right
		if direction != 0:
			rotation += direction * turnSpeed * delta
		"""
	if coolTimer - delta * coolDelta > 0:
		coolTimer -= delta * coolDelta
	else:
		coolTimer = 0
	if shooting:
		spawnBullet()

func spawnBullet():
	if bulletScene and coolTimer <= 0 && player.energy > shotCost:
		player.changeEnergy(-shotCost, true)
		coolTimer = coolDown
		var bullet = bulletScene.instantiate()
		bullet.GM = GM
		bullet.global_position = spawnPoint.global_position
		bullet.global_rotation = spawnPoint.global_rotation
		bullet.velocity = player.velocity / 2
		print(spawnPoint.global_rotation)
		get_tree().current_scene.add_child(bullet)
