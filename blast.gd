extends Area2D
@export var startSize = 10
@export var endSize = 60
@export var speed: float = 50
@export var power: float = 100
@export var hitCost: float = 5
@export var lifeTime: float = 100
var lifeDelta = 30
@onready var sprite = $Sprite2D
@onready var circle = $CollisionShape2D.shape
var hit = []
var GM: Node2D
var blastPower = 0.5

func _ready():
	circle.radius = startSize

func _process(delta):
	#position += Vector2.RIGHT.rotated(rotation) * speed * delta
	#print(circle.radius)
	if lifeTime - delta > 0:
		lifeTime -= delta
	else:
		pass
		#queue_free()
	if circle.radius + speed * delta < endSize:
		circle.radius += speed * delta
	else:
		print("dead at " + str(circle.radius))
		queue_free()
	if sprite.scale.x < endSize/15:
		sprite.scale.x += speed/2.5 * delta
		sprite.scale.y += speed/2.5 * delta

func _on_body_entered(body):
	if body is TileMapLayer:
		getCollisions()
	else:
		if body.has_method("blasted"):
			body.blasted(global_position, blastPower)

func getCollisions():
	var shape = $CollisionShape2D.shape
	var square = Vector2(shape.radius * scale.x, shape.radius * scale.y)
	"""
	var topLeft = map.local_to_map(global_position - square)
	var botRight = map.local_to_map(global_position + square)
	"""
	var topLeft = (global_position - square) / 32
	var botRight = (global_position + square) / 32

	for x in range(topLeft.x, botRight.x+1):
		for y in range(topLeft.y, botRight.y+1):
			var pos = Vector2i(round(x), round(y))
			if pos.distance_to(global_position/32) < square.x/32 + randi_range(0, 4):
				var mc = GM.posToChunk(pos)
				if mc not in hit:
					#print(str(pos) + " " + str(power))
					hit.append(mc)
					if power > 0:
						#mc[0].receiveCollision(mc[1])
						GM.checkCollision(mc)
						losePower(hitCost)
					else:
						break
		if power <= 0:
			break
			#dir = Vector2i(velocity.normalized().x, velocity.normalized().y)
			#var fin = pos + dir
			#fin = Vector2i(round(fin.x), round(fin.y))
			#print(str(pos) + " + " + str(dir) + " " + str(fin))
			#map.receiveCollision(pos)
	#for h in hit:


func losePower(amnt: float):
	if power - amnt > 0:
		power -= amnt
	elif power != 0:
		power = 0
		print("dead at " + str(circle.radius))
		queue_free()
