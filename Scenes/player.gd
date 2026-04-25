extends CharacterBody2D

# this all assumes gravity is 1960 px/s2
@export var SPEED = 500.0
@export var JUMP_VELOCITY = -1400.0
@export var GROUND_ACCELETATION = 200.0
@export var AIR_ACCELERATION = 40.0
@export var GROUND_FRICTION = 80.0
@export var AIR_FRICTION = 40.0
@export var ICE_FRICTION = 10.0
@export var GROUND_MAX_SPEED = 700.0
@export var AIR_MAX_SPEED = 700.0
@export var JUMP_RELEASE_FRICTION = 450.0
@export var DASH_SPEED = 1800
@export var DASH_TIME = 0.12 # in seconds

#gravity options
@export var baseGravity := 1960.0
@export var glideGravity := 300
@export var dashGravity := 0.0
@export var divingGravity := 2960.0

@export var divingSpeedBoost := 800
@export var divingDirection = Vector2(1,.08)

var dashDirection
var currentGravity:= baseGravity


@export var CoyoteJumpTime:float = .166 # in seconds
var floorTouchTimer = CoyoteJumpTime
var isDashAvailable:bool = true
var intendedVelocity = Vector2()
var dashTimer = 0.0

@onready var animationPlayer := $AnimationPlayer


# Implement a State Machine
enum States {IDLE,RUNNING,JUMPING, FALLING, DASHING, GLIDING, GROUND_BOUNCING, WALL_BOUNCING, DIVING, SLIDING}

var state: States = States.IDLE: set = SetState


func SetState(newState: States) -> void:
	var previousState := state
	state = newState


	if previousState in [States.GLIDING,States.DASHING]:
		currentGravity = baseGravity
	if state == States.GLIDING:
		animationPlayer.play("gliding")
		currentGravity = glideGravity
	if state == States.DASHING:
		animationPlayer.play("dashing")
		currentGravity = dashGravity
	if state == States.DIVING:
		animationPlayer.play("diving")
		currentGravity = divingGravity
	if state in [States.RUNNING, States.IDLE]:
		floorTouchTimer = CoyoteJumpTime
		isDashAvailable = true

	if state == States.IDLE:
		animationPlayer.play("idle")
	elif state == States.RUNNING:
		animationPlayer.play("run")
	elif state == States.JUMPING:
		animationPlayer.play("jump")


func _physics_process(delta: float) -> void:
	var omnidirection = Input.get_vector("move_left","move_right","move_up","move_down")
	var direction := Input.get_axis("move_left", "move_right")


	# State Transitions
	var is_initiating_jump :=  Input.is_action_pressed("ui_accept") and floorTouchTimer>0
	if is_initiating_jump:
		state = States.JUMPING

	elif state == States.JUMPING and velocity.y > 0.0:
		state = States.FALLING

	elif state in [States.JUMPING, States.FALLING, States.GLIDING, States.DASHING, States.DIVING, States.RUNNING, States.IDLE] and is_on_floor():
		state = States.IDLE

	elif state in [States.FALLING] and Input.is_action_pressed("PlayerGlide"):
		state = States.GLIDING

	elif state == States.GLIDING and Input.is_action_just_released("PlayerGlide"):
		state = States.FALLING

	elif state in [States.IDLE, States.RUNNING, States.JUMPING, States.FALLING, States.GLIDING] and Input.is_action_just_pressed("PlayerDash") and omnidirection.length()>0 and dashTimer==0 and isDashAvailable:
		state = States.DASHING
		dashTimer = DASH_TIME
		isDashAvailable = false
		dashDirection = omnidirection

	elif state in [States.IDLE, States.RUNNING, States.JUMPING, States.FALLING] and Input.is_action_just_pressed("PlayerDive"):
		state = States.DIVING
		velocity.x += divingSpeedBoost*direction*divingDirection.x
		velocity.y += divingSpeedBoost*divingDirection.y

	elif state == States.DASHING:
		if dashTimer ==0:
			state = States.JUMPING
		velocity = dashDirection*DASH_SPEED 


	dashTimer = max(dashTimer - delta,0)
	print(state)
	print("Timer ", dashTimer, " Velocity: ", velocity, " CoyoteTimer ", floorTouchTimer )
	
	if not is_on_floor():
		#coyote jump timer
		floorTouchTimer = max(floorTouchTimer - delta,0)

		# Add the gravity.
		velocity.y += currentGravity * delta
		# control jump height
		if Input.is_action_just_released("ui_accept") and velocity.y<=0:
			velocity.y = move_toward(velocity.y,0,JUMP_RELEASE_FRICTION)


	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and floorTouchTimer>0:
		velocity.y = JUMP_VELOCITY
		floorTouchTimer = 0;

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	if state in [States.IDLE, States.RUNNING, States.JUMPING, States.FALLING, States.GLIDING]:
		if direction:
			if is_on_floor():
				intendedVelocity.x = clamp(velocity.x + direction*GROUND_ACCELETATION,-GROUND_MAX_SPEED,GROUND_MAX_SPEED)
			else:
				intendedVelocity.x = clamp(velocity.x + direction*AIR_ACCELERATION,-AIR_MAX_SPEED,AIR_MAX_SPEED)
		else:
			if  is_on_floor():
				intendedVelocity.x = 0
			else:
				intendedVelocity.x = 0

	#handle friction
	if is_on_floor():
		velocity.x = move_toward(velocity.x,intendedVelocity.x,GROUND_FRICTION)
	else:
		velocity.x = move_toward(velocity.x,intendedVelocity.x, AIR_FRICTION)


	#handle dashing
	
		



	move_and_slide()
