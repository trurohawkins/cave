extends Node2D

var body = []
var GM

func birth(gm):
	GM = gm
	GM.setCell(global_position/32, 2)
	body.append(global_position/32)
