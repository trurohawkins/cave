extends Node2D

var body = []
var cur = 0
var GM
var land
@export var speed: int = 100
var drinkSpeed: int = 50
var evapSpeed: int = 10
@export var evapPower: int = 1

var counter = 0
var dirs = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0)]
@export var maxWater: int = 25
var water = 10

func birth(gm, chunk):
	GM = gm
	GM.setCell(global_position/32, 2)
	body.append(Vector2i(global_position/32))
	land = chunk
	drinkSpeed = speed / 2
	evapSpeed = speed / 4

func _process(_delta: float) -> void:
	if counter % evapSpeed == 0:
		#ssprint(water)
		if water >= evapPower:
			water -= evapPower
		else:
			if body.size() > 0:
				remove(body[randi() % body.size()])
		
	if counter % drinkSpeed == 0 && water < maxWater:
		var i = 0
		while i < body.size():
			var pos = body[i]
			var g = checkGround(pos)
			water += g
			if !checkValid(pos):
				remove(pos)
			else:
				i += 1
				
	if counter > speed:
		if water > 0:
			for i in range(body.size()):
				var g = (cur + i) % body.size()
				if grow(body[g]):
					cur = g
					break

		counter = 0
	else:
		counter += 1

func checkValid(pos: Vector2i):
	if checkCell(pos) == -1:
		return false
	var full = 0
	for d in dirs:
		var chk = Vector2i(pos) + d
		#chunk = check(chk)
		if checkCell(chk) != -1:
			full += 1
	#if it hs no neighbors it is floating so we remove, 
	#if it has full neighbors there is no need to grow from it anymore
		#unless one of its neighbors dies
	if full == 0:# || full == 4:
		return false
				
	return true

func checkCell(pos: Vector2i):
	var chunk = check(pos)
	return chunk[0].get_cell_source_id(chunk[1])

func check(pos: Vector2i):
	var chunk = land.getCell(pos)
	var l = land
	if chunk:
		l = chunk[0]
		pos = chunk[1]
	return [l, pos]

func remove(pos: Vector2i):
	body.erase(pos)
	var chunk = check(pos)
	#body.remove_at(index)
	chunk[0].destroyCell(chunk[1])

func grow(pos: Vector2i):
	var startD = randi() % dirs.size()
	for i in range(dirs.size()):
		var g = pos + dirs[(startD+i)%dirs.size()]
		var chunk = check(g)
		if chunk[0].get_cell_source_id(chunk[1]) == -1:
			chunk[0].setCell(2, chunk[1], true)
			body.append(Vector2i(chunk[1]))
			return true
	return false

func checkGround(pos: Vector2i):
	var ground = 0
	for i in range(dirs.size()):
		var chk = pos + dirs[i]
		if checkCell(chk) == 1:
			ground += 1
	return ground

func checkGrowth(chunk, pos):
	if chunk.get_source_id(pos) == -1:
		chunk.setCell(2, pos, true)
		
