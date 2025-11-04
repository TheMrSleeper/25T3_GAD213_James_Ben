extends CharacterBody2D

class_name Player

signal healthChanged
signal staminaChanged

const MOVEMENT_SPEED: float = 200.0

const DASH_SPEED: float = 400.0
const DASH_DURATION: float = 0.3

var dash_dir: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var is_dashing: bool = false

var can_take_damage: bool = true

enum {IDLE, RUN, DASH}
var state = IDLE

@onready var animationTree = $AnimationTree
@onready var state_machine = animationTree["parameters/playback"]
var facing_dir: Vector2 = Vector2.LEFT

@export var maxHealth: float = 100.0
@onready var currentHealth: float = maxHealth


@export var maxStamina: float = 100.0
@onready var currentStamina: float = maxStamina
var staminaRegen: float = 20.0

@export var staminaRegenDelay: float = 0.5
var _regen_cooldown: float = 0.0


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

func _ready() -> void:
	add_to_group("player")
	healthChanged.emit()
	staminaChanged.emit()

func _physics_process(delta: float) -> void:
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	if dash_timer > 0.0:
		_dash_logic(delta)
	else:
		_movement(delta)
	animate()
	move_and_slide()

func _process(delta: float) -> void:
	if currentStamina < maxStamina and not is_dashing and _regen_cooldown <= 0.0:
		var before := currentStamina
		currentStamina = minf(maxStamina, currentStamina + staminaRegen * delta)
		if currentStamina != before:
			staminaChanged.emit()

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
		facing_dir = input_vector
	
	if not is_dashing:
		velocity = lerp(velocity, input_vector * MOVEMENT_SPEED, 22.0 * delta)
	
	if Input.is_action_just_pressed("dash") and currentStamina >= 40 and not is_dashing:
		var dir = input_vector if input_vector != Vector2.ZERO else facing_dir
		if dir != Vector2.ZERO:
			dash(dir.normalized())

func dash(dir: Vector2) -> void:
	is_dashing = true
	dash_dir = dir
	dash_timer = DASH_DURATION
	blend_position = dir
	currentStamina = maxf(0.0, currentStamina -40.0)
	staminaChanged.emit()
	can_take_damage = false
	_regen_cooldown = staminaRegenDelay
	state = DASH

func _dash_logic(delta: float) -> void:
	var elapsed_percent = clamp(1.0 - (dash_timer / DASH_DURATION), 0.0, 1.0)
	var current_speed = lerp(DASH_SPEED, DASH_SPEED * 0.5, elapsed_percent)
	
	velocity = dash_dir * current_speed
	dash_timer -= delta
	
	if dash_timer <= 0.0:
		dash_dir + Vector2.ZERO
		can_take_damage = true
		is_dashing = false

#func dash_old(direction: Vector2) -> void:
	#_regen_cooldown = staminaRegenDelay
	#dash_dir = direction
	#dash_timer = DASH_DURATION
	#currentStam = max(0, currentStam - 40)
	#stamChanged.emit()
	#is_dashing = true
	#can_take_damage = false
	#state = DASH

#func _dash_logic_old(delta: float) -> void:
	#var elapsed_percent = 1.0 - (dash_timer / DASH_DURATION)
	#var current_speed = lerp(DASH_SPEED, DASH_SPEED * 0.5, elapsed_percent)
	#
	#velocity = dash_dir * current_speed
	#
	#dash_timer -= delta
	#
	#if dash_timer <= 0.0:
		#dash_dir = Vector2.ZERO
		#can_take_damage = true
		#is_dashing = false

func change_health(delta: float) -> void:
	currentHealth = clampf(currentHealth + delta, 0.0, maxHealth)
	healthChanged.emit()
	print("HP change: %+d -> %.1f/%.1f" % [int(delta), currentHealth, maxHealth])

func animate() -> void:
	state_machine.travel(animTree_state_keys[state])
	animationTree.set(blend_pos_paths[state], blend_position)
