extends Node2D
@export var playerScene: PackedScene
@export var chunkScene: PackedScene
@export var mapSize: Vector2i
@export var chunkSize: Vector2i
var grid = []

@export var spawnPoint: Vector2
@export var respawnRate = 100
var respawnCounter = 0
var shaders = []

func _ready():
	spawnMap()
	var player = spawnPlayer()
	occludeChunks(player)

func spawnMap():
	for chunkX in range(mapSize.x):
		var col = []
		for chunkY in range(mapSize.y):
			var chunk: TileMapLayer = chunkScene.instantiate()
			var posX = chunkSize.x * chunkX * 32
			var posY = chunkSize.y * chunkY * 32
			#print("making chunk at " + str(posX) + ", " + str(posY))
			chunk.chunkSize = chunkSize.x
			chunk.global_position = Vector2(posX, posY)
			chunk.gridPos = Vector2i(chunkX, chunkY)
			get_tree().current_scene.add_child(chunk)
			col.append(chunk)
			#shaders.append(chunk.tile_set.get_shader_material(1))
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
				cur.hollowCenter(75)
			#var poo = cur.get_cell_tile_data(Vector2i(0, 0)).material
			shaders.append(cur.material)
			#poo.set_shader_parameter("lightRadius", 300.0)
			#poo.set_shader_parameter("lightPos", Vector2(450.0, 230.0))
			"""
			for i in range(15):
				for j in range(5):
					print(str(i) + " " + str(j))
					var poo = cur.get_cell_tile_data(Vector2i(i, j)).material
					poo.set_shader_parameter("lightRadius", 300.0)
				#print(poo.get_shader_parameter("lightRadius"))
			"""
	for x in range(mapSize.x):
		for y in range(mapSize.y):
			var cur = grid[x][y]
			cur.tileChunk()
			#print(cur.neighbors)
	spawnPoint = Vector2((mapSize.x / 2 * chunkSize.x + chunkSize.x/2) * 32, (mapSize.y / 2 * chunkSize.y + chunkSize.y/2) * 32)
	spawnPoint.y += 1200#grounds player at start
	get_viewport().connect("size_changed", Callable(self, "onResize"))
	#onResize()
	
func onResize():
	for s in shaders:
		s.set_shader_parameter("lightRadius", 300.0)
		var viewport_size = get_viewport().get_visible_rect().size
		var screen_center = viewport_size / 2
		s.set_shader_parameter("lightPos", screen_center)
				
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
		player.receiveGM(self)
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

func posToChunk(pos: Vector2):
	var mapPos = Vector2i(pos.x, pos.y)
	var chunk = Vector2i(mapPos.x/chunkSize.x, mapPos.y/chunkSize.y)
	mapPos.x -= chunk.x * chunkSize.x
	mapPos.y -= chunk.y * chunkSize.y
	return [chunk, mapPos]
	
func checkCollision(mc):
	var chunk = mc[0]
	if chunk[0] >= 0 && chunk[0] < mapSize.x && chunk[1] >= 0 && chunk[1] < mapSize.y:
		chunk = grid[chunk[0]][chunk[1]]
		var map = mc[1]
		#print("chunk: " + str(mc[0]) + " pos: " + str(map))
		chunk.receiveCollision(map, true)
	
func occludeChunks(player: CharacterBody2D):
	#var mc = posToChunk(player.global_position)
	#spawnPoint = Vector2((mapSize.x / 2 * chunkSize.x + chunkSize.x/2) * 32, (mapSize.y / 2 * chunkSize.y + chunkSize.y/2) * 32)
	if player.global_position.x < 0 || player.global_position.y < 0 || player.global_position.x > chunkSize.x * mapSize.x * 32 || player.global_position.y > chunkSize.y * mapSize.y * 32:
		print("player has reached freedom!")
	var px = int(player.global_position.x / 32 / chunkSize.x)
	var py = int(player.global_position.y / 32 / chunkSize.y)
	for x in mapSize.x:
		for y in mapSize.y:
			var dist = max(abs(x - px), abs(y - py))
			#print(str(x) + ", " + str(y) + " " + str(dist))
			#1 for square, figure out aspect ratio and do it per x and y
			grid[x][y].occlude(dist >1)
