extends CharacterBody2D
@export var energy: float = 5
var energyMax
@export var thrustSpeed: int = 200
@export var thrustCost: float = 0.1
@export var baseDecel: float = 0.5
var decelSpeed: float = 0.5
@export var crashPower: float = 10
@export var crashDecel: float = 2
@export var highVelocity: float = 2000
@export var landingPower: float = 0.5
@export var walkSpeed: float = 500

@export var staggerPower: float = 50
@export var invincibleTime: float = 20
@export var gravPower = 1000
@export var maxGrav = 2000
@export var blastScene: PackedScene
@export var gunScene: PackedScene
@export var energyMode = false

var curGrav = 0
var cam: Camera2D
var gun
#@onready var energySprite = $deetSprite
var energySprite
@onready var thrustSprite = $thrustSprite
@onready var groundCheck = $RayCast2D
@onready var bodySprite = $BodySprite

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
	bodySprite.play("idle_front")
	setEnergySaturate()

func setEnergySaturate():
	if energySprite:
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
	if Input.is_action_just_pressed("energize"):
		energyMode = !energyMode
		if energyMode && !staggered:
			bodySprite.play("in_air")
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
	if !control(delta):
		if curGrav + gravPower < maxGrav:
			curGrav += gravPower
		else:
			curGrav = maxGrav
	else:
		curGrav = 0
	camGrav(delta)
	#print(velocity.length())
	var power = min(velocity.length(), highVelocity) / highVelocity
	#camGrav(delta)
	var myVelocity = velocity
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
		if collider is TileMapLayer && power >= landingPower:
			var myDir = myVelocity.normalized().angle()
			#print(rad_to_deg(myDir))
			var crashDir = ((global_position/32) - (collision.get_position()/32)).normalized()
			crashDir.y *= -1
			crashDir = crashDir.angle()
			var diff = rad_to_deg(wrapf(myDir - crashDir, -PI, PI))
			
			if abs(diff) < 45:
				#print("collided at " + str(power) + " " + str(diff))
				crash(collision.get_position(), power)
				#if Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
				"""
				print("my pos: " + str(global_position) + " collision " + str(collision.get_position()))
				print("my dir: " + str(int(rad_to_deg(myDir))) + " crash: " + str(int(rad_to_deg(crashDir))))
				print("angular diff: " + str(int(diff)))
				
			else:
				print(str(rad_to_deg(myDir)) + " " + str(rad_to_deg(crashDir)))
				"""
			#GM.playerDie(self)
	if rPauseTimer - delta > 0:
		#print(rPauseTimer)
		rPauseTimer -= delta
	else:
		rPauseTimer = 0
		if energy < energyMax:
			#print("charging " + str(rechargeSpeed * delta) + " " + str(energy))
			changeEnergy(rechargeSpeed * delta, false)
		

func control(delta: float):
	if staggered:
		return false
	if energyMode:
		return thrust(delta)
	else:
		return walk(delta)

var grounded: bool = false

func walk(delta: float):
	if groundCheck.is_colliding():
		grounded = true
		var normal: Vector2 = groundCheck.get_collision_normal()
		rotation = normal.angle() + deg_to_rad(90)
		#print(normal.angle())
	else:
		grounded = false
		rotation = cam.rotation

	if Input.is_action_pressed("move_up") && grounded:
		#print("jumP " + str(cam.rotation))
		var jump = Vector2(0, -1)
		jump = jump.rotated(cam.rotation)
		#print(jump)
		velocity += jump * delta * 3000
	
	var dir = 0;
	if Input.is_action_pressed("move_left"):
		dir -= 1
		bodySprite.flip_h = true
	if Input.is_action_pressed("move_right"):
		dir += 1
		bodySprite.flip_h = false
	if dir != 0:
		var move = Vector2(dir, 0)
		move = move.rotated(rotation)
		velocity += move * delta * walkSpeed
	if !staggered:
		if grounded:
			if dir == 0:
				bodySprite.play("idle_side")
			else:
				bodySprite.play("walk")
		else:
			bodySprite.play("in_air")
	return grounded
	
@export var rotSpeed: float = 0.1

func thrust(delta: float):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		#print(str(direction) + " " + str(direction.length()))
		var angle = direction.rotated(deg_to_rad(90) + cam.rotation).angle()
		rotation = lerp_angle(rotation, angle, delta * rotSpeed)
		if abs(angle - rotation) < 0.1:
			rotation = angle
		velocity += -Vector2.DOWN.rotated(rotation) * thrustSpeed * delta * direction.length()
		thrustSprite.visible = true
		return true
	else:
		thrustSprite.visible = false
		return false

func camGrav(delta):
	#print("my rot: " + str(rotation) + " cam rot " + str(cam.rotation))
	if energyMode:
		if abs(cam.rotation - rotation) > 0.1:
			rotation = lerp_angle(rotation, cam.rotation, delta * cam.rotSpeed)
		elif rotation != cam.rotation:
			rotation = cam.rotation
	else:
		pass
		#rotation = cam.rotation
	
	if curGrav > 0:
		var grav = Vector2.DOWN.rotated(cam.rotation)
		velocity += grav * delta * curGrav
	
func crash(pos: Vector2, power: float):
	print(power)
	if power < landingPower:
		return
	print(str(power) + " < " + str(landingPower))
	if !invincible:
		invulnerate(true)
		if energyMode:
			blowUp()

			if energy > 0:
				changeEnergy(-10, true)
				blasted(pos, power)
			else:
				GM.playerDie(self)
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
		bodySprite.play("hurt")
	elif staggered:
		bodySprite.play("in_air")
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
	
func blowUp():
	var blast = blastScene.instantiate()
	blast.GM = GM
	blast.blastPower = 0
	blast.lifeTime = 5
	blast.global_position = global_position
	get_tree().get_current_scene().add_child(blast)
