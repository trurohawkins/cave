extends Camera2D

@export var rotSpeed: float = 0.5
@export var follow: Node2D

func _ready():
	ignore_rotation = false

func _process(delta):
	rotation_degrees += rotSpeed * delta
	if follow:
		global_position = follow.global_position
	#var grav = Vector2.DOWN.rotated(rotation)
	#velocity += grav * delta * curGrav
