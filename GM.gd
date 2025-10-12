extends Node2D
@export var playerScene: PackedScene
@export var chunkScene: PackedScene
@export var mapSize: Vector2i
@export var chunkSize: Vector2i
var grid = []

@export var spawnPoint: Vector2
@export var respawnRate = 100
var respawnCounter = 0

func _ready():
	spawnMap()
	var player = spawnPlayer()
	occludeChunks(player)

func spawnMap():
	for chunkX in range(mapSize.x):
		var col = []
		for chunkY in range(mapSize.y):
			var chunk = chunkScene.instantiate()
			var posX = chunkSize.x * chunkX * 32
			var posY = chunkSize.y * chunkY * 32
			#print("making chunk at " + str(posX) + ", " + str(posY))
			chunk.chunkSize = chunkSize.x
			chunk.global_position = Vector2(posX, posY)
			chunk.gridPos = Vector2i(chunkX, chunkY)
			get_tree().current_scene.add_child(chunk)
			col.append(chunk)
		grid.append(col)
	for x in range(mapSize.x):
		for y in range(mapSize.y):
			#print("chunk " + str(x) + ", " + str(y))
			var cur = grid[x][y]
			cur.neighbors = []
			addNeighbor(cur, 0, -1)
			addNeighbor(cur, -1, -1)
			addNeighbor(cur, -1, 0)
			addNeighbor(cur, -1, 1)
			addNeighbor(cur, 0, 1)
			addNeighbor(cur, 1, 1)
			addNeighbor(cur, 1, 0)
			addNeighbor(cur, 1, -1)
	for x in range(mapSize.x):
		for y in range(mapSize.y):
			var cur = grid[x][y]
			cur.spawnChunk()
			if x == mapSize.x / 2 && y == mapSize.y / 2:
				cur.hollowCenter(50)
	for x in range(mapSize.x):
		for y in range(mapSize.y):
			var cur = grid[x][y]
			cur.tileChunk()
			#print(cur.neighbors)
	spawnPoint = Vector2((mapSize.x / 2 * chunkSize.x + chunkSize.x/2) * 32, (mapSize.y / 2 * chunkSize.y + chunkSize.y/2) * 32)
				
func addNeighbor(chunk, x, y):
	var xp = chunk.gridPos.x + x
	var yp = chunk.gridPos.y + y
	if xp >= 0 && xp < mapSize.x && yp >= 0 && yp < mapSize.y:
		chunk.neighbors.append(grid[xp][yp])
	else:
		chunk.neighbors.append(TYPE_NIL)

func spawnPlayer():
	if playerScene:
		var player = playerScene.instantiate()
		get_tree().current_scene.add_child(player)
		player.global_position = spawnPoint
		player.GM = self
		return player

func playerDie(player):
	print("player is dead")
	player.queue_free()
	respawnCounter = respawnRate
	
func _process(delta):
	if respawnCounter > 0:
		respawnCounter -= delta * 10
		if respawnCounter <= 0:
			spawnPlayer()

func occludeChunks(player: CharacterBody2D):
	#spawnPoint = Vector2((mapSize.x / 2 * chunkSize.x + chunkSize.x/2) * 32, (mapSize.y / 2 * chunkSize.y + chunkSize.y/2) * 32)
	var px = int(player.global_position.x / 32 / chunkSize.x)
	var py = int(player.global_position.y / 32 / chunkSize.y)
	#print(str(px) + ", " + str(py))
	for x in mapSize.x:
		for y in mapSize.y:
			var dist = max(abs(x - px), abs(y - py))
			#print(str(x) + ", " + str(y) + " " + str(dist))
			#1 for square, figure out aspect ratio and do it per x and y
			grid[x][y].occlude(dist > 2)
