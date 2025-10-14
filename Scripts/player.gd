extends CharacterBody2D
@export var energy: float = 5
var energyMax
@export var speed: int = 200
@export var thrustCost: float = 0.1
@export var baseDecel: float = 0.5
var decelSpeed: float = 0.5
@export var crashPower: float = 10
@export var crashDecel: float = 2
@export var highVelocity: float = 2000
@export var landingPower: float = 0.5

@export var staggerPower: float = 50
@export var invincibleTime: float = 20
@export var camRot: float = 0.1
@export var gravPower = 1000
@export var maxGrav = 2000
@export var blastScene: PackedScene
var curGrav = 0
@onready var gun = $gun
@onready var cam = $Camera2D
@onready var energySprite = $deetSprite
@onready var handEnergySprite = $gun/hand/deet

var staggerDelta: float = 10
var staggerCounter: float = 0
var staggered: bool = false

var invicinbleDelta: float = 10
var invincibleCounter: float = 0
var invincible: bool = false

var GM: Node2D
var prePos = Vector2(-1, -1)
var curCollides := {}

var rechargePause: float = 1
var rPauseTimer = 0
var rechargeSpeed: float = 3#0.2


func _ready():
	decelSpeed = baseDecel
	cam.ignore_rotation = false
	energyMax = energy
	energySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
	handEnergySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
	
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
	if invincibleCounter - delta * invicinbleDelta > 0:
		invincibleCounter -= delta * invicinbleDelta
	else:
		invulnerate(false)
	if !staggered:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if direction != Vector2.ZERO && energy > thrustCost * delta:
			direction = direction.rotated(cam.rotation)
			velocity += direction * speed * delta
			curGrav = 0
			changeEnergy(-thrustCost * delta, true)
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
			crash(collision.get_position(), power)
			#GM.playerDie(self)
	if rPauseTimer - delta > 0:
		#print(rPauseTimer)
		rPauseTimer -= delta
	else:
		rPauseTimer = 0
		if energy < energyMax:
			#print("charging " + str(rechargeSpeed * delta) + " " + str(energy))
			changeEnergy(rechargeSpeed * delta, false)
		

func crash(pos: Vector2, power: float):
	if power < landingPower:
		return
	if !invincible:
		invulnerate(true)
		blowUp()
		#print("hit at " + str(global_position) + " form " + str(col.get_position()))
		#print(str(velocity.length()) + " / " + str(highVelocity) + " = " + str(power))
		if energy > 0:
			changeEnergy(-10, true)
			blasted(pos, power)
		else:
			GM.playerDie(self)

func changeEnergy(amnt: float, pause: bool):
	if amnt == 0:
		return
	if amnt > 0:
		if energy + amnt < energyMax:
			energy += amnt
		else:
			energy = energyMax
	else:
		if energy + amnt > 0:
			energy += amnt
		else:
			energy = 0
	if pause:
		rPauseTimer = rechargePause
	energySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
	handEnergySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))

func blasted(pos, power):
	var blast = global_position - pos
	var blastPower: Vector2 = blast * crashPower * power
	if blastPower.length() < 10000:
		velocity += blastPower
		decelSpeed = crashDecel
	stagger(true)
	
func stagger(stagged: bool):
	if stagged:
		staggerCounter = staggerPower
		staggered = true
	else:
		staggerCounter = 0
		staggered = false
		decelSpeed = baseDecel

func invulnerate(on: bool):
	if on:
		invincible = true
		invincibleCounter = invincibleTime
	else:
		invincible = false
		invincibleCounter = 0
	
func camGrav(delta):
	cam.rotation_degrees += camRot * delta
	var grav = Vector2.DOWN.rotated(cam.rotation)
	#if !boosting:
	velocity += grav * delta * curGrav
	
func blowUp():
	var blast = blastScene.instantiate()
	blast.GM = GM
	blast.endSize = 20
	blast.blastPower = 0
	blast.lifeTime = 5
	blast.global_position = global_position
	get_tree().get_current_scene().add_child(blast)
	
