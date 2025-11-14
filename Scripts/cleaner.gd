extends Area2D

var cleaning: Array = []
var GM

var cleanTime : float = 0.5
var counter : float = 0

func _physics_process(delta: float) -> void:
	if counter > cleanTime:
		counter = 0;
		for mc in cleaning:
			if GM.checkCell(mc)  == 2:
				GM.checkCollision(mc)
		cleaning.clear()
	elif counter >= 0:
		counter += delta

func _on_body_entered(body):
	if body is TileMapLayer:
		var col = getCollisions()
		for mc in col:
			if mc not in cleaning:
				cleaning.append(mc)

				#print("appending " + str(mc) + " " + str(GM.checkCell(mc)))
			'''
			if cleaning.size() == 1:
				counter = 0
			'''

func getCollisions():
	var col = []
	var shape = $CollisionShape2D.shape
	var square = Vector2(shape.size.x * scale.x / 2, shape.size.y * scale.y / 2)
	var topLeft = (global_position - square) / 32
	var botRight = (global_position + square) / 32
	for x in range(topLeft.x, botRight.x+1):
		for y in range(topLeft.y, botRight.y+1):
			var pos = Vector2i(round(x), round(y))
			var mc = GM.posToChunk(pos)
			if mc not in col:
				col.append(mc)
	return col
				
func _on_body_exited(body: Node2D) -> void:
	if body is TileMapLayer:
		var col = getCollisions()
		for mc in col:
			if mc in cleaning:
				#print("removing " + str(mc))
				cleaning.erase(mc)
				'''
				if cleaning.size() == 0:
					counter = -1
				'''
