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
@export var minWalk: float = 50
@export var maxWalk: float = 1700
@export var walkAccel: float = 0.1
@export var walkDecel: float = 1

@export var staggerPower: float = 50
@export var invincibleTime: float = 20
var gravPower = 35
@export var flyGrav = 1400
@export var flyGAccel = 35
@export var walkGAccel = 500
@export var walkGrav = 2500
var maxGrav = 1400
@export var blastScene: PackedScene
@export var gunScene: PackedScene
@export var energyMode = false

var curGrav = 0
var cam: Camera2D
var gun
#@onready var energySprite = $deetSprite
@onready var energySprite = $energySprite
@onready var thrustSprite = $thrustSprite
@onready var groundCheck = $GroundCheck
@onready var forwardCheck = $ForwardCheck
@onready var bodySprite: AnimatedSprite2D = $BodySprite
@onready var clean = $Cleaner

@onready var body = $CollisionShape2D

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

var idle: int = 100
var crouching: int = 0
var dead: int = 0

func _ready():
	decelSpeed = baseDecel
	energyMax = energy
	gun = gunScene.instantiate()
	gun.global_position = global_position
	get_tree().current_scene.add_child(gun)
	gun.player = self
	gun.scale = scale / 2
	#adddwdbodySprite.play("rise")
	#setEnergySaturate()

func setEnergySprite():
	if energySprite && energyMode:
		var curEnergy = energy/energyMax
		energySprite.visible =  curEnergy > 0.1
		if curEnergy > 0.66:
			energySprite.frame_coords.y = 2
		elif curEnergy > 0.33:
			energySprite.frame_coords.y = 1
		elif curEnergy > 0.1:
			energySprite.frame_coords.y = 0
	bodySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
		#gun.handEnergySprite.material.set_shader_parameter("desaturation", 1.0 - (energy/energyMax))
	
func receiveGM(gm, camera):
	print("sawned at " + str(global_position/32))
	GM = gm
	gun.GM = gm
	clean.GM = gm
	cam = camera
	cam.follow = self
	cam.global_position = global_position
	gun.cam = cam

func setEnergyMode(on: bool):
	energyMode = on
	energySprite.visible = energyMode
	if energyMode:
		if !staggered:
			bodySprite.play("in_air")
			decelSpeed = baseDecel
		setEnergySprite()
		GM.setPlayerLight(500, Vector3(0.4, 1.0, 0.2))
		maxGrav = flyGrav
		gravPower = flyGAccel
	else:
		decelSpeed = walkDecel
		maxGrav = walkGrav
		gravPower = walkGAccel
		GM.setPlayerLight(300, Vector3(0.5, 0.5, 0.5))
			
func _physics_process(delta):
	if dead > 0:
		if dead == 1:
			bodySprite.play("hurt")
		elif dead == 50:
			GM.playerDie()
		dead += 1
		return
	if Input.is_action_just_pressed("energize"):
		if !energyMode || energy/energyMax > 0.1:
			setEnergyMode(!energyMode)
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
	print("grav: " + str(curGrav))
	if velocity != Vector2.ZERO:
		var power = min(velocity.length(), highVelocity) / highVelocity
		print("power: " + str(power) + " velo: " + str(velocity))
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
			if collider is TileMapLayer:
				var myDir = myVelocity.normalized().angle()
				#print(rad_to_deg(myDir))
				var crashDir = ((global_position/32) - (collision.get_position()/32)).normalized()
				crashDir.y *= -1
				crashDir = crashDir.angle()
				var diff = rad_to_deg(wrapf(myDir - crashDir, -PI, PI))
				if power >= landingPower:

					
					if abs(diff) < 45:
						crash(collision.get_position(), power)
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
var curDir: int = 0
var curWalk: float = 0
var jumping: int = 0
var jumpMax: int = 1
var jumpPow: int = 3000
var curJump = 0

func walk(delta: float):
	if groundCheck.is_colliding():
		var colPoint : Vector2 = groundCheck.get_collision_point()
		var dist = colPoint.distance_to(global_position)
		if dist > 33:
			var diff = dist - 33
			global_position.y += diff
		grounded = true
		var normal: Vector2 = groundCheck.get_collision_normal()
		rotation = normal.angle() + deg_to_rad(90)
		#print(normal.angle())
	else:
		grounded = false
		rotation = cam.rotation
	var jump = Vector2(0, 0)
	if Input.is_action_just_pressed("move_up") && jumping < jumpMax:
		jumping += 1
		curJump = 0
		#print("jumP " + str(cam.rotation))
	if jumping != 0:
		if curJump + delta < 0.5:
			curJump += delta
		else:
			curJump = 0.5
			jumping = 0
		var jPower = 700 * sin(curJump * 1 * TAU)
		#print("curJump: " + str(curJump) + " jumpung: " + str(jPower))
		jump = Vector2(0, -1)
		jump = jump.rotated(cam.rotation)
		#print(jump)
		jump = jump * jPower
	if Input.is_action_just_pressed("move_down"):
		bodySprite.play_backwards("rise")
		velocity = Vector2.ZERO
		crouching = 1
		idle = 100
	elif Input.is_action_just_released("move_down"):
		bodySprite.play("rise")

	var dir = 0;
	var walkDir = Vector2(0, 0)

	if crouching == 0:
		if Input.is_action_pressed("move_left"):
			dir -= 1
			bodySprite.flip_h = true
		if Input.is_action_pressed("move_right"):
			dir += 1
			bodySprite.flip_h = false
		if !(Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right")):
			dir = 0
		forwardCheck.target_position = Vector2(24 * dir, 0)
		if dir != 0:
			if curDir != dir:
				curWalk = 0
			else:
				curWalk += walkAccel
			curDir = dir
		else:
			if curWalk - walkDecel > 0:
				curWalk -= walkDecel
			else:
				curWalk = 0
		walkSpeed = lerpf(minWalk, maxWalk, curWalk)
		var move = Vector2(curDir, 0)
		move = move.rotated(rotation)
		walkDir = move * delta * walkSpeed
	if forwardCheck.is_colliding():
		walkDir = Vector2(0,0)
		curWalk = 0
	var grav = Vector2.DOWN.rotated(cam.rotation) * delta * curGrav
	#print(str(grav) + " " + str(jump))
	velocity = walkDir + jump + grav
	if grounded:
		if !crouching:
			if dir == 0:
				if idle < 100:
					bodySprite.play("idle_side")
					idle += 1
				else:
					bodySprite.play("idle_front")
			else:
				bodySprite.play("walk")
				idle = 0
	else:
		bodySprite.play("in_air")
	return grounded
	
@export var rotSpeed: float = 0.1

func thrust(delta: float):
	if velocity != Vector2.ZERO:
		var decel = Vector2(-sign(velocity.x), -sign(velocity.y)) * decelSpeed * delta
		#print(str(velocity) + " " + str(velocity.length()) + " decel " + str(decel))
		var check = velocity + decel
		#print(" check length: " + str(check.length()))
		if check.length() < 20:
			velocity = Vector2.ZERO
		else:
			#print(str(velocity) + " + " + str(decel) + " = " + str(velocity + decel))
			velocity += decel
	camGrav(delta)
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		#print(str(direction) + " " + str(direction.length()))
		var angle = direction.rotated(deg_to_rad(90) + cam.rotation).angle()
		rotation = lerp_angle(rotation, angle, delta * rotSpeed)
		if abs(angle - rotation) < 0.1:
			rotation = angle
		velocity += -Vector2.DOWN.rotated(rotation) * thrustSpeed * delta * direction.length()
		energySprite.frame_coords.x = 1
		#thrustSprite.visible = true
		return true
	else:
		#thrustSprite.visible = false
		energySprite.frame_coords.x = 0
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
	#print(power)
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
				die()
		else:
			die()

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
		if energy/energyMax < 0.1 && energyMode:
			setEnergyMode(false)
	if pause:
		rPauseTimer = rechargePause
	setEnergySprite()

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
		print("not staggered")
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

func die():
	dead = 1
	#GM.playerDie(self)

func _on_body_sprite_animation_finished():
	if bodySprite.animation == "rise":
		if bodySprite.frame == 0:
			crouching = 2
		else:
			crouching = 0


func _on_body_sprite_animation_changed():
	#print("new animation " + bodySprite.animation)
	pass


func _on_body_sprite_frame_changed():
	if bodySprite.animation == "rise":
		var progress = float(bodySprite.frame) / float(bodySprite.sprite_frames.get_frame_count("rise"))
		print(str(bodySprite.frame) + " " + str(progress))
		var rect: RectangleShape2D = body.shape
		rect.size.y = lerp(30, 60, progress)
		body.position.y = lerp(18.0, 3.0, progress)
