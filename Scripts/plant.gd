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
			if grow(body[g]):
				break
		counter = 0
	else:
		counter += 1
		
func grow(pos: Vector2i):
	var startD = randi() % dirs.size()
	for i in range(dirs.size()):
		var g = pos + dirs[(startD+i)%dirs.size()]
		var chunk = land.getCell(g)
		var l = land
		if chunk:
			l = chunk[0]
			g = chunk[1]
		if l.get_cell_source_id(g) == -1:
			l.setCell(2, g, true)
			body.append(g)
			return true
	return false

func checkGrowth(chunk, pos):
	if chunk.get_source_id(pos) == -1:
		chunk.setCell(2, pos, true)
		
