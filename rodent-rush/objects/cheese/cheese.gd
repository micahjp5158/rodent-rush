extends Area2D

const FLOAT_AMP = 2
const FLOAT_FREQ = 5

var time = 0

@onready var default_pos = get_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time += delta * FLOAT_FREQ
	self.set_position(default_pos + Vector2(0, sin(time) * FLOAT_AMP))
