extends ProgressBar

@export var showTime: float = 10
var timer: float = 0

func _process(delta):
	if timer - delta > 0:
		timer -= delta
	else:
		timer = 0
		visible = false
	
func changeValue(val: float):
	visible = true
	value = val
	timer = showTime
	
