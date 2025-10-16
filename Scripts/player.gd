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
@export var gravPower = 1000
@export var maxGrav = 2000
@export var blastScene: PackedScene
@export var gunScene: PackedScene

var curGrav = 0
var cam: Camera2D
var gun
@onready var energySprite = $deetSprite
@onready var thrustSprite = $thrustSprite

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
	energyMax = energy
	gun = gunScene.instantiate()
	gun.global_position = global_position
	get_tree().current_scene.add_child(gun)
	gun.player = self
	gun.scale = scale / 2
	setEnergySaturate()

func setEnergySaturate():
	energySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
	gun.handEnergySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
	
func receiveGM(gm, camera):
	GM = gm
	gun.GM = gm
	cam = camera
	cam.follow = self
	cam.global_position = global_position
	gun.cam = cam

	
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
		if !thrust(delta):
			if curGrav + gravPower < maxGrav:
				curGrav += gravPower
			else:
				curGrav = maxGrav
		else:
			curGrav = 0
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
		

@export var rotSpeed: float = 0.1

func thrust(delta: float):
	"""
	var power = 0
	if Input.is_action_pressed("move_left"):
		rotation -= rotSpeed * delta
		power += speed/2
	if Input.is_action_pressed("move_right"):
		rotation += rotSpeed * delta
		power += speed/2
	if power != 0:
		velocity += -Vector2.DOWN.rotated(rotation) * power * delta
		return true
	return false
	"""
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		#print(str(direction) + " " + str(direction.length()))
		var angle = direction.rotated(deg_to_rad(90) + cam.rotation).angle()
		rotation = lerp_angle(rotation, angle, delta * rotSpeed)
		if abs(angle - rotation) < 0.1:
			rotation = angle
		velocity += -Vector2.DOWN.rotated(rotation) * speed * delta * direction.length()
		thrustSprite.visible = true
		return true
	else:
		thrustSprite.visible = false
		return false
	"""
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO && energy > thrustCost * delta:
		direction = direction.rotated(cam.rotation)
		velocity += direction * speed * delta
		curGrav = 0
		changeEnergy(-thrustCost * delta, true)
		return true
	else:
		return false
	"""
	
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
	setEnergySaturate()

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
	#print("my rot: " + str(rotation) + " cam rot " + str(cam.rotation))
	if abs(cam.rotation - rotation) > 0.1:
		rotation = lerp_angle(rotation, cam.rotation, delta * cam.rotSpeed)
	elif rotation != cam.rotation:
		rotation = cam.rotation
	var grav = Vector2.DOWN.rotated(cam.rotation)
	velocity += grav * delta * curGrav
	
func blowUp():
	var blast = blastScene.instantiate()
	blast.GM = GM
	blast.blastPower = 0
	blast.lifeTime = 5
	blast.global_position = global_position
	get_tree().get_current_scene().add_child(blast)
