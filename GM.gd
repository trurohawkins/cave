extends Node2D
@export var playerScene: PackedScene
@export var chunkScene: PackedScene
@export var mapSize: Vector2i
@export var chunkSize: Vector2i
var grid = []
var size: Vector2

@export var spawnPoint: Vector2
@export var respawnRate = 100
@export var energyBar: ProgressBar

var respawnCounter = 0
var shaders = []

func _ready():
	spawnMap()
	var player = spawnPlayer()
	occludeChunks(player)

func spawnMap():
	size = Vector2(mapSize.x * chunkSize.x, mapSize.y * chunkSize.y)
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
			#if x == mapSize.x / 2 && y == mapSize.y / 2:
				#cur.hollowCenter(75)
			#var poo = cur.get_cell_tile_data(Vector2i(0, 0)).material
			shaders.append(cur.material)
	shapeMap()
	for x in range(mapSize.x):
		for y in range(mapSize.y):
			var cur = grid[x][y]
			cur.tileChunk()
			#print(cur.neighbors)
	#spawnPoint = Vector2((mapSize.x / 2 * chunkSize.x + chunkSize.x/2) * 32, (mapSize.y / 2 * chunkSize.y + chunkSize.y/2) * 32)
	get_viewport().connect("size_changed", Callable(self, "onResize"))
	#onResize()

func shapeMap():
	var center = Vector2(size.x/2, size.y/2)
	"""
	for x in range(size.x):
		for y in range(size.y):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist >= size.x/2:
				var mc = posToChunk(pos)
				var chunk = mc[0]
				grid[chunk[0]][chunk[1]].set_cell(mc[1], -1)
	"""
	makeHole(center, size.x/2, size.x/5, true, false)

	var tunnels = 50#clamp(randi(), 35, 35)
	for i in range(tunnels):
		tunnel()
	spawnPoint = center * 32
	spawnPoint.y += 20 * 32#grounds player at start
	makeHole(center, 20, 20, false, true)
	

func tunnel():
	var center = Vector2(size.x/2, size.y/2)
	var chasm = 5
	var move = 20
	var dither = 5
	var m: int = size.x -30
	var pos = Vector2(randi()%m, randi()%m)
	var length = clamp(randi(), 5, 10)
	for i in range(length):
		if pos.distance_to(center) < size.x/2 - chasm - 75:
			makeHole(pos, chasm, 0, false, false)
		pos += Vector2(randi_range(-move, move), randi_range(-move, move))
		chasm = max(5, chasm + randi_range(-dither, dither))

func makeHole(pos: Vector2, radius: float, shell: int, fill: bool, perfect: bool):
	#print("making hole of size " + str(radius*2) + " at " + str(pos))
	var center = Vector2(size.x/2, size.y/2)
	var r = shell + radius
	var scape = []#[[-90, 40, -15]]#, [15, 10, 20]]
	if !perfect:
		var num = 30#randi() % 10
		for i in range(num):
			#angle, width, height 
			scape.append([randi_range(-180, 180), randi_range(5, 20), randi_range(-r/5, r/5)])

	for x in range(-r, r):
		for y in range(-r, r):
			var p = Vector2(pos.x + x, pos.y + y)
			var mc = posToChunk(p)
			var chunk = mc[0]
			var angle = rad_to_deg((pos - p).angle())
			#print(angle)
			var curRad = radius
			var cur = TYPE_NIL
			var closest = INF
			for s in scape:
				if abs(angle - s[0]) < closest:
					closest = abs(angle - s[0])
					cur = s
			if cur is Array:
				var delta = abs(angle - cur[0])
				if delta < cur[1]:
					var fallOff = sin((1.0 - delta / cur[1]) * PI / 2.0)
					curRad += cur[2] * fallOff
			#print(str(p) + " " + str(angle))
			#print(chunk)
			if chunk[0] >= 0 && chunk[0] < mapSize[0] && chunk[1] >= 0 && chunk[1] < mapSize[1]:#print(pos.distance_to(p))
				if mc[1].x >= 0 && mc[1].y >= 0 && mc[1].x < size.x && mc[1].y < size.y:
					if center.distance_to(p) < size.x/2:
						if pos.distance_to(p) < curRad:
							if !fill:
								grid[chunk[0]][chunk[1]].set_cell(mc[1], -1)
							else:
								grid[chunk[0]][chunk[1]].set_cell(mc[1], 1, Vector2i(0, 4))
						elif pos.distance_to(p) < curRad + shell:
							if !fill:
								grid[chunk[0]][chunk[1]].set_cell(mc[1], 1, Vector2i(0, 4))
							else:
								grid[chunk[0]][chunk[1]].set_cell(mc[1], -1)
					else:
						grid[chunk[0]][chunk[1]].set_cell(mc[1], -1)
			
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
			grid[x][y].occlude(false)#dist >1)
