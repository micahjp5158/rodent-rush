extends CharacterBody2D

# Character speed consts
const MAX_SPEED = 13000
const ACCELERATION = 1700

# Jump consts
const JUMP_HEIGHT = 64
const JUMP_TIME_TO_PEAK = .4
const JUMP_TIME_TO_DESCENT = .3

@onready var JUMP_VELOCITY : float = ((2.0 * JUMP_HEIGHT) / JUMP_TIME_TO_PEAK) * -1.0
@onready var JUMP_GRAVITY : float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK)) * -1.0
@onready var FALL_GRAVITY : float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0

# Nodes
@onready var anim = get_node("AnimatedSprite2D")

func _physics_process(delta):
	# Handle horizontal velocity
	horizontal_movement(delta)
	
	# Handle veritcal velocty and jump
	velocity.y += get_gravity() * delta
	if Input.is_action_pressed("jump") and is_on_floor():
		jump()
	
	# Update animations and move
	handle_anim()
	move_and_slide()

# Handle horizontal movement
func horizontal_movement(delta):
	var input_velocity = get_input_velocity()
	if input_velocity == -1:
		velocity.x = max(velocity.x - ACCELERATION * delta, -MAX_SPEED * delta)
	elif input_velocity == 1:
		velocity.x = min(velocity.x + ACCELERATION * delta, MAX_SPEED * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.3)

# Get input velocity / walk direction
func get_input_velocity():
	var horizontal := 0.0
	if Input.is_action_pressed("left"):
		horizontal -= 1.0
	if Input.is_action_pressed("right"):
		horizontal += 1.0
	return horizontal
	
# Get current gravity based on jumping / falling state
func get_gravity():
	if velocity.y < 0.0:
		return JUMP_GRAVITY
	else:
		return FALL_GRAVITY

# Handles jumping
func jump():
	velocity.y = JUMP_VELOCITY

# Handles updating the animation
func handle_anim():
	# Flip sprites horizontally if needed
	var input_velocity = get_input_velocity()
	if input_velocity < 0:
		get_node("AnimatedSprite2D").flip_h = true
	elif input_velocity > 0:
		get_node("AnimatedSprite2D").flip_h = false
	
	# Select walk or idle if on the floor
	if is_on_floor():
		if input_velocity != 0:
			anim.play("walk")
		else:
			anim.play("idle")
	
	# Select jump or fall if in the air
	else:
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
