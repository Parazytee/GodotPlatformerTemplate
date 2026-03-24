extends CharacterBody2D

# this all assumes gravity is 1960 px/s2
const SPEED = 500.0
const JUMP_VELOCITY = -1400.0
const GROUND_ACCELETATION = 200.0
const AIR_ACCELERATION = 40.0
const GROUND_FRICTION = 80.0
const AIR_FRICTION = 40.0
const ICE_FRICTION = 10.0
const GROUND_MAX_SPEED = 700.0
const AIR_MAX_SPEED = 700.0
const JUMP_RELEASE_FRICTION = 450.0
const DASH_SPEED = 1800
const DASH_TIME = 0.8 # in seconds


@export var CoyoteJumpTime:float = .166 # in seconds
var floorTouchTimer = CoyoteJumpTime
var isDashAvailable:bool = true
var intendedVelocity = Vector2()
var dashTimer = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		floorTouchTimer = max(floorTouchTimer - delta,0)

	if is_on_floor():
		floorTouchTimer = CoyoteJumpTime
		isDashAvailable = true

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		# control jump height
		if Input.is_action_just_released("ui_accept") and velocity.y<=0:
			velocity.y = move_toward(velocity.y,0,JUMP_RELEASE_FRICTION)


	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and floorTouchTimer>0:
		velocity.y = JUMP_VELOCITY
		floorTouchTimer = 0;

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
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
	var omnidirection = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	dashTimer = max(dashTimer - delta,0)
	if Input.is_action_just_pressed("PlayerDash") and isDashAvailable and omnidirection.length()>0 and dashTimer == 0:
		isDashAvailable = false
		dashTimer = DASH_TIME
		velocity = omnidirection*DASH_SPEED 
		



	move_and_slide()
