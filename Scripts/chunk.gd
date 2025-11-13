extends TileMapLayer
@export var chunkSize: float = 3
var neighbors
var dir4 = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]
var dir8 = [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1), 
Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1)]
var rotations = [
0, 
TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
]
var gridPos
var toBeDestroyed: Array = []
@export var destructionSpeed: float = 100
@export var plantScene: PackedScene
var plants: Array = []

#lights
var lightPos: Array = []
var lightRadii: Array = []
var lightColors: Array = []

func _ready():
	modulate = Color(0.2,0.1,0.3)
	visible = false
	modulate = Color(1, 1, 1)
	#modulate = Color(randf(), randf(), randf(), 1)
	#set_cell(Vector2i(1,1), -1)

func plantSeed(pos: Vector2, gm):
	var seed = plantScene.instantiate()
	seed.global_position = pos
	seed.birth(gm)
	get_tree().current_scene.add_child(seed)

func setPlayerLight(radius: float, color: Vector3):
	material.set_shader_parameter("playerRadius", radius)
	material.set_shader_parameter("playerColor", color)

func _process(delta: float):
	var amnt = destructionSpeed * delta
	for i in range(amnt):
		if toBeDestroyed.size() > 0:
			var cell = toBeDestroyed.pop_at(0)
			destroyCell(cell)
		else:
			break

func spawnChunk():
	for x in range(chunkSize):
		for y in range(chunkSize):
			set_cell(Vector2i(x, y), 1, Vector2i(0,4))

func hollowCenter(chasm: int):
	var spot = chunkSize/2
	for x in range(chasm):
		for y in range(chasm):
			var xp = spot + x - chasm/2
			var yp = spot + y - chasm/2
			set_cell(Vector2i(xp, yp), -1)

func tileChunk():
	#print(neighbors)
	for x in range(chunkSize):
		for y in range(chunkSize):
			tileBlock(x, y)

func tileBlock(x: int, y: int):
	var block = Vector2i(x,y)
	var id = get_cell_source_id(block)
	if id == 2:
		print("tiling plant")
		#print("block " + str(x) + str(y))
	if id == -1:
		return
	
	var start = 0
	var startSide = start
	var mostOpen = -1
	for i in range(4):
		var openSides = 0
		start = (start + i) % 4
		for j in range(4):
			var cur = (start + j) % 4
			#print("  checking " + str(block + dir4[cur]) + " " + str(checkCell(block + dir4[cur])))
			if checkCell(block + dir4[cur]) != id:
				openSides += 1
			else:
				break
		#print("side: " + str(start) + " open: " + str(mostOpen))
		if openSides > mostOpen:
			mostOpen = openSides
			startSide = start
	if mostOpen == 1:
		var oppoSide = (startSide + 2) % 4
		if checkCell(block + dir4[oppoSide]) == -1:
			mostOpen = 5
		else:
			var nextCorn = ((startSide*2) + 3) % 8
			var preCorn = ((startSide*2) + 5) % 8
			var nc: bool = checkCell(block + dir8[nextCorn]) != -1
			var pc: bool = checkCell(block + dir8[preCorn]) != -1
			if !nc && !pc:
				mostOpen = 13
			elif !nc:
				mostOpen = 11
			elif !pc:
				mostOpen = 12
	elif mostOpen == 2:
		var oppoCorn = ((startSide*2) + 5) % 8
		if checkCell(block + dir8[oppoCorn]) == -1:
			mostOpen = 14
	elif mostOpen == 0:
		var check = 0
		var mostCorn = -1
		start = 7
		var s = 7
		for i in range(0, 4):
			var corners = 0
			start = (s + (i*2)) % 8
			for j in range(0, 4):
				var cur = (start + (j*2)) % 8
				if checkCell(block + dir8[cur]) == -1:
					corners += 1
				else:
					break
			if corners > mostCorn:
				mostCorn = corners
				check = i
		#if x == 2 && y == 2:
			#print(mostCorn)
		if mostCorn != 0:
			mostOpen = 6 + (mostCorn-1)
			startSide = check
		else:
			mostOpen = 0
	if id == 2:
		print(mostOpen)
	set_cell(Vector2i(x, y), id, Vector2i(0, mostOpen), rotations[(startSide)%4])
	#print(str(startSide))
	
func checkCell(pos):
	#checks if pos is out of ounds and returns value from neighbors
	var chunk = getCell(pos)
	if chunk:
		return chunk[0].get_cell_source_id(chunk[1])
	else:
		return get_cell_source_id(pos)
	
func getCell(pos):
	var xOffset = 0
	var yOffset = 0
	if pos.x < 0:
		xOffset = -1
	elif pos.x >= chunkSize:
		xOffset = 1
	if pos.y < 0:
		yOffset = -1
	elif pos.y >= chunkSize:
		yOffset = 1
	if xOffset == 0 && yOffset == 0:
		pass
	else:
		for i in range(8):
			if Vector2i(xOffset, yOffset) == dir8[i]:
				if neighbors[i]:
					#print("need to check neighbor to the + " + str(i) + ". " + str(dir8[i]))
					if xOffset != 0:
						if xOffset < 0:
							pos.x = chunkSize - 1
						else:
							pos.x = 0
					if yOffset != 0:
						if yOffset < 0:
							pos.y = chunkSize - 1
						else:
							pos.y = 0
					return [neighbors[i], pos]
					#print("got " + str(block) + " from pos " + str(pos))
	return TYPE_NIL
	
func receiveCollision(pos: Vector2i, preCalc: bool):
	#print("tile map " + str(gridPos) + " collided with " + str(pos))
	if not preCalc:
		pos.x -= gridPos.x * chunkSize
		pos.y -= gridPos.y * chunkSize
	if !pos in toBeDestroyed:
		#print("appending " + str(pos))
		toBeDestroyed.append(pos)

func setCell(id: int, pos: Vector2i, preCalc: bool):
	if not preCalc:
		pos.x -= gridPos.x * chunkSize
		pos.y -= gridPos.y * chunkSize
	#print("setting " + str(pos) + " to " + str(id))
	set_cell(pos, id, Vector2i(0, 0))
	tileBlock(pos.x, pos.y)

func destroyCell(pos: Vector2i):
	set_cell(pos, -1)
	for x in range(-1, 2):
		for y in range(-1, 2):
			#if x != 0 or y != 0:
			#print(str(x) + ", " + str(y))
			var block = Vector2i(pos.x + x, pos.y + y)
			var chunk = getCell(block)
			if chunk is Array:
				chunk[0].check_and_tile(chunk[1])
			else:
				check_and_tile(block)
				
func check_and_tile(pos):
	if get_cell_source_id(pos) != -1:
		tileBlock(pos.x, pos.y)
		
func occlude(on: bool, playerPos: Vector2):
	visible = !on
	if visible:
		material.set_shader_parameter("playerPos", playerPos)

	#turning off collisions makes it so projectiles can fly through without destroying
	#collision_enabled = !on

func addLight(pos: Vector2, radius: float, color: Vector3):
	if lightPos.size() < 16:
		lightPos.append(pos)
		lightRadii.append(radius)
		lightColors.append(color)
		var lights = []
		var radii = []
		var colors = []
		for i in range(16):
			if i < lightPos.size():
				print(lightPos[i])
				lights.append(lightPos[i])
				radii.append(lightRadii[i])
				colors.append(lightColors[i])
			else:
				lights.append(Vector2.ZERO)
				radii.append(0)
				colors.append(Vector3.ZERO)
		
		material.set_shader_parameter("lightPos", lights)
		material.set_shader_parameter("lightRadii", radii)
		material.set_shader_parameter("lightColors", colors)
		material.set_shader_parameter("lightCount", lightPos.size())
		material.set_shader_parameter("ambientColor", Vector3(0, 0, 0))
