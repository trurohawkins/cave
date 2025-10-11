extends TileMapLayer
@export var chunkSize: int = 3
var dir4 = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]
var dir8 = [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1), 
Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1)]
var rotations = [
0, 
TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V,
TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V,
TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H,
]

func _ready():
	spawnChunk()
	tileChunk()
	print(map_to_local(Vector2i(2,2)))
	#set_cell(Vector2i(1,1), -1)
	
func spawnChunk():
	for x in range(chunkSize):
		for y in range(chunkSize):
			set_cell(Vector2i(x, y), 1, Vector2i(0,4))
	
func tileChunk():
	for x in range(chunkSize):
		for y in range(chunkSize):
			tileBlock(x, y)

func tileBlock(x: int, y: int):
		#print("block " + str(x) + str(y))
	var block = Vector2i(x,y)
	var start = 0
	var startSide = start
	var mostOpen = -1
	for i in range(4):
		var openSides = 0
		start = (start + i) % 4
		for j in range(4):
			var cur = (start + j) % 4
			#print("  checking " + str(block + dir4[cur]) + " " + str(get_cell_source_id(block + dir4[cur])))
			if get_cell_source_id(block + dir4[cur]) == -1:
				openSides += 1
			else:
				break
		#print("side: " + str(start) + " open: " + str(mostOpen))
		if openSides > mostOpen:
			mostOpen = openSides
			startSide = start
	if mostOpen == 1:
		var oppoSide = (startSide + 2) % 4
		if get_cell_source_id(block + dir4[oppoSide]) == -1:
			mostOpen = 5
		else:
			var nextCorn = ((startSide*2) + 3) % 8
			var preCorn = ((startSide*2) + 5) % 8
			var nc: bool = get_cell_source_id(block + dir8[nextCorn]) != -1
			var pc: bool = get_cell_source_id(block + dir8[preCorn]) != -1
			if !nc && !pc:
				mostOpen = 13
			elif !nc:
				mostOpen = 11
			elif !pc:
				mostOpen = 12
	elif mostOpen == 2:
		var oppoCorn = ((startSide*2) + 5) % 8
		if get_cell_source_id(block + dir8[oppoCorn]) == -1:
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
				if get_cell_source_id(block + dir8[cur]) == -1:
					corners += 1
				else:
					break
			if corners > mostCorn:
				mostCorn = corners
				check = i
		if x == 2 && y == 2:
			print(mostCorn)
		if mostCorn != 0:
			mostOpen = 6 + (mostCorn-1)
			startSide = check
		else:
			mostOpen = 0
	set_cell(Vector2i(x, y), 1, Vector2i(0, mostOpen), rotations[(startSide)%4])
	#print(str(startSide))
		
func receiveCollision(pos: Vector2i):
	#print("tile map collided with " + str(pos))
	set_cell(pos, -1)
	for x in range(-1, 2):
		for y in range(-1, 2):
			#if x != 0 or y != 0:
			#print(str(x) + ", " + str(y))
			var block = Vector2i(pos.x + x, pos.y + y)
			if get_cell_source_id(block) != -1:
				tileBlock(block.x, block.y)
