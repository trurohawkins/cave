extends Node2D

var body = []
var cur = 0
var GM
var land
@export var speed: int = 100
var counter = 0
var dirs = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0)]

func birth(gm, chunk):
	GM = gm
	GM.setCell(global_position/32, 2)
	body.append(global_position/32)
	land = chunk

func _process(_delta: float) -> void:
	if counter > speed:
		for i in range(body.size()):
			var g = (cur + i) % body.size()
			if checkValid(g):
				if grow(body[g]):
					break
			else:
				body.remove_at(g)
				i -= 1
		counter = 0
	else:
		counter += 1

func checkValid(index: int):
	var pos =  body[index]
	var chunk = check(pos)
	if chunk[0].get_cell_source_id(chunk[1]) == -1:
		return false
	var full = 0
	for d in dirs:
		var chk = Vector2i(pos) + d
		chunk = check(chk)
		if chunk[0].get_cell_source_id(chunk[1]) != -1:
			full += 1
	#if it hs no neighbors it is floating so we remove, 
	#if it has full neighbors there is no need to grow from it anymore
		#unless one of its neighbors dies
	if full == 0:# || full == 4:
		return false
				
	return true

func check(pos: Vector2i):
	var chunk = land.getCell(pos)
	var l = land
	if chunk:
		l = chunk[0]
		pos = chunk[1]
	return [l, pos]
	
func grow(pos: Vector2i):
	var startD = randi() % dirs.size()
	for i in range(dirs.size()):
		var g = pos + dirs[(startD+i)%dirs.size()]
		var chunk = check(g)
		if chunk[0].get_cell_source_id(chunk[1]) == -1:
			chunk[0].setCell(2, chunk[1], true)
			body.append(chunk[1])
			return true
	return false

func checkGrowth(chunk, pos):
	if chunk.get_source_id(pos) == -1:
		chunk.setCell(2, pos, true)
		
