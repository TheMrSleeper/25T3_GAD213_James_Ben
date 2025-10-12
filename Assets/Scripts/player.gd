extends CharacterBody2D

const MOVEMENT_SPEED: float = 200.0

const DASH_SPEED: float = 400.0
const DASH_DURATION: float = 0.3

var dash_dir: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

var can_take_damage: bool = true

enum {IDLE, RUN, DASH}
var state = IDLE

@onready var animationTree = $AnimationTree
@onready var state_machine = animationTree["parameters/playback"]

var blend_position : Vector2 = Vector2.ZERO
var blend_pos_paths = [
	"parameters/idle/idle_bs2d/blend_position",
	"parameters/run/run_bs2d/blend_position",
	"parameters/dash/dash_bs2d/blend_position"
]
var animTree_state_keys = [
	"idle",
	"run",
	"dash"
]

func _physics_process(delta: float) -> void:
	if dash_timer > 0.0:
		_dash_logic(delta)
	else:
		_movement(delta)
	animate()
	move_and_slide()

func _movement(delta: float) -> void:
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	if input_vector == Vector2.ZERO:
		state = IDLE
	else:
		state = RUN
		blend_position = input_vector
	
	velocity = lerp(velocity, input_vector * MOVEMENT_SPEED, 22.0 * delta)
	
	if Input.is_action_just_pressed("dash"):
		if input_vector != Vector2.ZERO:
			dash(input_vector)
		elif velocity.length() > 0.1:
			dash(velocity.normalized())

func dash(direction: Vector2) -> void:
	dash_dir = direction
	dash_timer = DASH_DURATION
	can_take_damage = false
	state = DASH

func _dash_logic(delta: float) -> void:
	var elapsed_percent = 1.0 - (dash_timer / DASH_DURATION)
	var current_speed = lerp(DASH_SPEED, DASH_SPEED * 0.5, elapsed_percent)
	
	velocity = dash_dir * current_speed
	
	dash_timer -= delta
	
	if dash_timer <= 0.0:
		dash_dir = Vector2.ZERO
		can_take_damage = true

func animate() -> void:
	state_machine.travel(animTree_state_keys[state])
	animationTree.set(blend_pos_paths[state], blend_position)
