extends CharacterBody2D
@export var health: int = 5
@export var speed: int = 200
@export var baseDecel: float = 0.5
var decelSpeed: float = 0.5
@export var crashPower: float = 10
@export var crashDecel: float = 2
@export var highVelocity: float = 2000
@export var landingPower: float = 0.5

@export var staggerPower: float = 50
@export var camRot: float = 0.1
@export var gravPower = 1000
@export var maxGrav = 2000
var curGrav = 0
@onready var gun = $gun
@onready var cam = $Camera2D

var staggerDelta: float = 10
var staggerCounter: float = 0
var staggered: bool = false

var GM: Node2D
var prePos = Vector2(-1, -1)
var curCollides := {}

func _ready():
	decelSpeed = baseDecel
	cam.ignore_rotation = false
	
func receiveGM(gm):
	GM = gm
	gun.GM = gm
	
func _physics_process(delta):

	#dprint(str(velocity.x) + " abs " + str(abs(velocity.x)) + " -abs: " + str(-abs(velocity.x)))
	var decel = Vector2(-sign(velocity.x), -sign(velocity.y)) * decelSpeed * delta
	#print(str(velocity) + " " + str(velocity.length()) + " decel " + str(decel))
	var check = velocity + decel
	if check.length() < 20:
		velocity = Vector2.ZERO
	else:
		velocity += decel
	if staggerCounter - delta * staggerDelta > 0:
		staggerCounter -= delta * staggerDelta
	else:
		stagger(false)
	if !staggered:
		var direction = Input.get_vector("left", "right", "up", "down")
		if direction != Vector2.ZERO:
			direction = direction.rotated(cam.rotation)
			velocity += direction * speed * delta
			curGrav = 0
		else:
			if curGrav + gravPower < maxGrav:
				curGrav += gravPower
			else:
				curGrav = maxGrav
	var power = min(velocity.length() / highVelocity, 500)
	camGrav(delta)
	move_and_slide()
	if global_position != prePos:
		#print("moved")
		GM.occludeChunks(self)
	prePos = global_position
	#slideCollision()
	var colCount = get_slide_collision_count()
	for i in colCount:
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is TileMapLayer:
			crash(collision, power)
			#GM.playerDie(self)

func crash(col: KinematicCollision2D, power: float):
	if power < landingPower:
		return
	#print("hit at " + str(global_position) + " form " + str(col.get_position()))
	#print(str(velocity.length()) + " / " + str(highVelocity) + " = " + str(power))
	if health > 0:
		var blast = global_position - col.get_position()
		var energy: Vector2 = blast * crashPower * power
		if energy.length() < 10000:
			velocity = energy
			decelSpeed = crashDecel
		stagger(true)
	else:
		GM.playerDie(self)
	health -= 1

func stagger(stagged: bool):
	if stagged:
		staggerCounter = staggerPower
		staggered = true
	else:
		staggerCounter = 0
		staggered = false
		decelSpeed = baseDecel
		
func camGrav(delta):
	cam.rotation_degrees += camRot * delta
	var grav = Vector2.DOWN.rotated(cam.rotation)
	#if !boosting:
	velocity += grav * delta * curGrav
