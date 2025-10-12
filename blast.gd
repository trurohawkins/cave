extends Area2D
@export var speed: float = 50
@export var power: float = 100
@export var hitCost: float = 5
var lifeDelta = 10

func _ready():
	print("ready")

func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	losePower(delta * lifeDelta)

func _on_body_entered(body):
	if body is TileMapLayer:
		getCollsions(body)

func getCollsions(map):
	var shape = $CollisionShape2D.shape
	var square = Vector2(shape.radius * scale.x, shape.radius * scale.y)
	print(shape.radius)
	var topLeft = map.local_to_map(global_position - square)
	var botRight = map.local_to_map(global_position + square)

	#print("pos: " + str(global_position))
	#print("physics " + str(map.local_to_map(global_position)))
	#print("TL: " + str(topLeft) + " BR: " + str(botRight))
	var hit = []
	for x in range(topLeft.x, botRight.x+1):
		for y in range(topLeft.y, botRight.y+1):
			var pos = Vector2i(round(x), round(y))
			if pos not in hit:
				hit.append(pos)
			#dir = Vector2i(velocity.normalized().x, velocity.normalized().y)
			#var fin = pos + dir
			#fin = Vector2i(round(fin.x), round(fin.y))
			#print(str(pos) + " + " + str(dir) + " " + str(fin))
			#map.receiveCollision(pos)
	for h in hit:
		if power > 0:
			map.receiveCollision(h)
			losePower(hitCost)
		else:
			break

func losePower(amnt: float):
	if power - amnt > 0:
		power -= amnt
	else:
		queue_free()
