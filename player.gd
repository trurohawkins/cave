extends CharacterBody2D
@export var speed: int = 200
@export var map: TileMapLayer

var curCollides := {}

func _ready():
	pass

func _physics_process(_delta):

	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	var dirAdj = velocity.normalized()
	move_and_slide()
	#slideCollision()
	var newCollides := {}
	var colCount = get_slide_collision_count()
	for i in colCount:
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is TileMapLayer:
			#var colDir = collision.get_position() - position
			var colPos = collision.get_position()
			#var dirAdj = velocity.normalized()#colDir.normalized * 20
			var tilePos = collider.local_to_map(colPos + dirAdj)
			# add chunk id later on
			newCollides[tilePos] = true
			if not curCollides.has(tilePos):
				collider.receiveCollision(tilePos)
			curCollides = newCollides
	"""
	var shape = $CollisionShape2D.shape
	var topLeft = map.local_to_map(global_position - shape.extents)
	var botRight = map.local_to_map(global_position + shape.extents)

	var dir = velocity.normalized()
	if dir.x != 0 or dir.y != 0:
		print("pos: " + str(global_position))
		print("physics " + str(map.local_to_map(global_position)))
		print("TL: " + str(topLeft) + " BR: " + str(botRight))
		for x in range(topLeft.x, botRight.x+1):
			for y in range(topLeft.y, botRight.y+1):
				var pos = Vector2i(round(x), round(y))
				dir = Vector2i(velocity.normalized().x, velocity.normalized().y)
				var fin = pos + dir
				fin = Vector2i(round(fin.x), round(fin.y))
				print(str(pos) + " + " + str(dir) + " " + str(fin))
				#map.receiveCollision(pos)
	"""
