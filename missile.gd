extends CharacterBody2D
@export var speed: float = 50
@export var decelSpeed: float = 1
@export var power: float = 100
@export var hitCost: float = 5

@export var blastScene: PackedScene
var lifeDelta = 10
var GM: Node2D

func _ready():
	velocity += Vector2.RIGHT.rotated(rotation) * speed

func _process(delta):
	losePower(delta * lifeDelta)
	var decel = Vector2(-sign(velocity.x), -sign(velocity.y)) * decelSpeed * delta
	#print(str(velocity) + " " + str(velocity.length()) + " decel " + str(decel))
	var check = velocity + decel
	if check.length() < 20:
		velocity = Vector2.ZERO
	else:
		velocity += decel
	move_and_slide()
	var colCount = get_slide_collision_count()
	for i in colCount:
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is TileMapLayer:
			blowUp()

func blowUp():
	queue_free()
	var blast = blastScene.instantiate()
	blast.GM = GM
	blast.global_position = global_position
	get_tree().get_current_scene().add_child(blast)

func losePower(amnt: float):
	if power - amnt > 0:
		power -= amnt
	else:
		queue_free()
