extends CharacterBody2D

const ACCELERATION = 1500
const MAX_SPEED = 12000
const LIMIT_SPEED_Y = 1200
const JUMP_HEIGHT = 20000
const MIN_JUMP_HEIGHT = 12000
const MAX_COYOTE_TIME = 6
const JUMP_BUFFER_TIME = 10
const WALL_JUMP_AMOUNT = 18000
const WALL_JUMP_TIME = 10
const WALL_SLIDE_FACTOR = 0.8
const WALL_HORIZONTAL_TIME = 30
const GRAVITY = 2100
const DASH_SPEED = 36000
#const JUMP_HEIGHT = 64
#const JUMP_TIME_TO_PEAK = .4
#const JUMP_TIME_TO_DESCENT = .3

#@onready var JUMP_VELOCITY : float = ((2.0 * JUMP_HEIGHT) / JUMP_TIME_TO_PEAK) * -1.0
#@onready var JUMP_GRAVITY : float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK * JUMP_TIME_TO_PEAK)) * -1.0
#@onready var FALL_GRAVITY : float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0

var axis = Vector2()

var coyote_timer = 0
var jump_buffer_timer = 0
var wall_jump_timer = 0
var wall_horizontal_timer = 0
var dashTime = 0

# Global variables
var is_dashing = false
var has_dashed = false
var dash_time = 0
var friction = false
var canJump = false
var wall_sliding = false
var trail = false
var is_grabbing = false

# Nodes
@onready var anim = get_node("AnimatedSprite2D")

func _physics_process(delta):
	if velocity.y <= LIMIT_SPEED_Y:
		if !is_dashing:
			velocity.y += GRAVITY * delta

	friction = false
	
	get_input_axis()
	dash(delta)
	
	#wallSlide(delta)

	#basic vertical movement mechanics
	if wall_jump_timer > WALL_JUMP_TIME:
		wall_jump_timer = WALL_JUMP_AMOUNT
		if !is_dashing && !is_grabbing:
			horizontal_movement(delta)
	else:
		wall_jump_timer += 1
	
	#jumping mechanics and coyote time
	if is_on_floor():
		canJump = true
		coyote_timer = 0
	else:
		coyote_timer += 1
		if coyote_timer > MAX_COYOTE_TIME:
			canJump = false
			coyote_timer = 0
		friction = true
	
	jump_buffer(delta)

	if Input.is_action_pressed("jump"):
		if canJump:
			jump(delta)
			friction_on_air()
		else:
			friction_on_air()
			jump_buffer_timer = JUMP_BUFFER_TIME #amount of frame

	set_jump_height(delta)
	jump_buffer(delta)

	
	# Update animations and move
	handle_anim()
	move_and_slide()

# Handle horizontal movement
func horizontal_movement(delta):
	var input_direction = get_input_direction()
	
	# Air speed handling
	if !is_on_floor() or Input.is_action_pressed("jump"):
		if input_direction == -1:
			velocity.x = min(get_walk_speed(delta), velocity.x)
		elif input_direction == 1:
			velocity.x = max(get_walk_speed(delta), velocity.x)
	
	# Ground speed handling
	else:
		velocity.x = get_walk_speed(delta)

# Get input direction
func get_input_direction():
	var horizontal := 0.0
	if Input.is_action_pressed("left"):
		horizontal -= 1.0
	if Input.is_action_pressed("right"):
		horizontal += 1.0
	return horizontal
	
func get_input_axis():
	axis = Vector2.ZERO
	axis.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	axis.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	axis = axis.normalized()
	
# Get input walk speed
func get_walk_speed(delta):
	var input_direction = get_input_direction()
	if input_direction == -1:
		return max(velocity.x - ACCELERATION * delta, -MAX_SPEED * delta)
	elif input_direction == 1:
		return min(velocity.x + ACCELERATION * delta, MAX_SPEED * delta)
	else:
		return  lerp(velocity.x, 0.0, 0.3)

func friction_on_air():
	if friction:
		velocity.x = lerp(velocity.x, 0.0, 0.01)

# Handles jumping
func jump(delta):
	velocity.y = -JUMP_HEIGHT * delta

func jump_buffer(delta):
	if jump_buffer_timer > 0:
		if is_on_floor():
			jump(delta)
		jump_buffer_timer -= 1

func set_jump_height(delta):
	if Input.is_action_just_released("jump"):
		if velocity.y < -MIN_JUMP_HEIGHT * delta:
			velocity.y = -MIN_JUMP_HEIGHT * delta
	
# Handles dashing
func dash(delta):
	if !has_dashed:
		if Input.is_action_just_pressed("dash"):
			velocity = axis * DASH_SPEED * delta
			is_dashing = true
			has_dashed = true
	if is_dashing:
		dash_time += 2
		if dash_time >= int(0.25 * 1 / delta):
			is_dashing = false
			dash_time = 0

	if is_on_floor() && velocity.y >= 0:
		has_dashed = false

# Handles updating the animation
func handle_anim():
	# Flip sprites horizontally if needed
	var input_direction = get_input_direction()
	if input_direction < 0:
		get_node("AnimatedSprite2D").flip_h = true
	elif input_direction > 0:
		get_node("AnimatedSprite2D").flip_h = false
	
	# Select walk or idle if on the floor
	if is_on_floor():
		if input_direction != 0:
			anim.play("walk")
		else:
			anim.play("idle")
	
	# Select jump or fall if in the air
	else:
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
