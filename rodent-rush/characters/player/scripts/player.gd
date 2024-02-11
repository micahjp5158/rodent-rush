extends CharacterBody2D

const ACCELERATION = 1000
const MAX_SPEED = 8000
const LIMIT_SPEED_Y = 1200
const JUMP_HEIGHT = 20000
const MIN_JUMP_HEIGHT = 12000
const MAX_COYOTE_TIME = 6
const JUMP_BUFFER_TIME = 10
const WALL_JUMP_KICKBACK = 230
const WALL_SLIDE_SPEED = 50
const GRAVITY = 2100
const DASH_SPEED = 36000
const WALL_JUMP_TIMEOUT = 10

var axis = Vector2()

var coyote_timer = 0
var jump_buffer_timer = 0
var wall_jump_timer = 0
var wall_jump_timeout_timer = 0
var wall_horizontal_timer = 0
var dashTime = 0

# Global variables
var is_dashing = false
var has_dashed = false
var dash_time = 0
var friction = false
var canJump = false
var is_wall_sliding = false
var trail = false
var is_grabbing = false

var cheese_count = 0

# Nodes
@onready var anim = get_node("AnimatedSprite2D")
@onready var jumpsound = get_node("AudioStreamPlayer2D")

func _physics_process(delta):
	if velocity.y <= LIMIT_SPEED_Y:
		if !is_dashing:
			velocity.y += GRAVITY * delta

	friction = false
	
	get_input_axis()
	dash(delta)
	
	wallslide(delta)

	#basic vertical movement mechanics

	horizontal_movement(delta)
	
	#jumping mechanics and coyote time
	if (wall_jump_timer > 0):
		wall_jump_timer -= 1
	if is_on_floor() or (is_on_wall() and get_input_direction() != 0 and Input.is_action_just_pressed("jump")):
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
		return  lerp(velocity.x, 0.0, 0.4)

func friction_on_air():
	if friction:
		velocity.x = lerp(velocity.x, 0.0, 0.01)

# Handles jumping
func jump(delta):
	if is_on_wall():
		if wall_jump_timer == 0:
			if Input.is_action_pressed("left"):
				velocity.x = WALL_JUMP_KICKBACK
				wall_jump_timer = WALL_JUMP_TIMEOUT
				jumpsound.play()
			elif Input.is_action_pressed("right"):
				wall_jump_timer = WALL_JUMP_TIMEOUT
				velocity.x = -WALL_JUMP_KICKBACK
				jumpsound.play()
	else:
		velocity.y = -JUMP_HEIGHT * delta
		if is_on_floor():
			jumpsound.play()

func jump_buffer(delta):
	if jump_buffer_timer > 0:
		if is_on_floor():
			jump(delta)
		jump_buffer_timer -= 1

func set_jump_height(delta):
	if Input.is_action_just_released("jump"):
		if velocity.y < -MIN_JUMP_HEIGHT * delta:
			velocity.y = -MIN_JUMP_HEIGHT * delta

func wallslide(delta):
	if is_on_wall() and !is_on_floor():
		if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			if velocity.y > 0:
				velocity.y += WALL_SLIDE_SPEED + delta
				velocity.y = max(velocity.y, WALL_SLIDE_SPEED)
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false
	
	if is_wall_sliding:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

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
			if !is_on_floor() and has_dashed:
				# Limit velocity if a dash was started and finished in the air
				if velocity.x > 0:
					velocity.x = min(200, velocity.x)
				else:
					velocity.x = max(-200, velocity.x)
				velocity.y = max(velocity.y, -200)

	if is_on_floor() && velocity.y >= 0:
		has_dashed = false

# Handles updating the animation and playing sounds
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
			
	elif is_wall_sliding:
		anim.play("wallslide")
	
	# Select jump or fall if in the air
	else:
		if velocity.y < 0:
			anim.play("jump")
			
		else:
			anim.play("fall")

func add_cheese():
	cheese_count += 1
	print(cheese_count)
