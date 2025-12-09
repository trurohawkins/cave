extends CanvasLayer

@onready var screen: ColorRect = $PHIL
@onready var text: RichTextLabel = $TESS
var targetColor: Color
var progress: float = 1.0
var fadeSpeed: float = 1
var GM
var textUp: String = ""
var onFinish: Callable = Callable()
var onEnd: Callable = Callable()
func _ready():
	targetColor = screen.color
	#fadeTo(Color.BLACK)
	
func _process(delta):
	#print("I am hud and I have phil")
	if screen.color != targetColor:
		screen.color = screen.color.lerp(targetColor, progress)
		#print(str(screen.color) + " -> " + str(targetColor))
		var step = fadeSpeed * delta
		#print(str(progress) + " + " + str(step))
		if progress + step < 0.65:
			progress += step
		elif progress != 0.65:
			progress = 0.65
		else:
			if text.text != textUp:
				text.text = textUp
				textUp = ""
			if onFinish.is_valid():
				onFinish.call()
				onFinish = Callable()
			#print("fwip fwip fwip" + str(progress))
	if text.text != "":
		if Input.is_action_just_pressed("shoot"):
			fadeTo(Color(0, 0, 0, 0))
			textUp = ""
			onFinish = Callable(GM, "spawnPlayer")
			

func fadeTo(color: Color):
	targetColor = color
	progress = 0

func deathSequence(gm):
	GM = gm
	fadeTo(Color.BLACK)
	textUp = "I had the strangest dream, There was something immense and it made my eyes hurt"
	onFinish = Callable(GM, "killPlayer")
