extends CharacterBody2D

class_name Player

signal healthChanged
signal healthUpdated
signal staminaChanged

#MOVEMENT
const MOVEMENT_SPEED: float = 200.0
const DASH_SPEED: float = 400.0
const DASH_DURATION: float = 0.3
const POTION_DURATION: float = 1.2

#DASHing
var dash_dir: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var is_dashing: bool = false
var can_take_damage: bool = true

#POTIONS
@onready var potion_pouch: PotionPouch = $PotionPouch

var queued_potion: bool = false
var is_drinking: bool = false
var potion_timer: float = 0.0
var potion_dir: Vector2 = Vector2.ZERO

#HEALTH
@export var maxHealth: float = 100.0
@onready var currentHealth: float = maxHealth

#STAMINA
@export var maxStamina: float = 100.0
@onready var currentStamina: float = maxStamina
var staminaRegen: float = 20.0
@export var staminaRegenDelay: float = 0.5
var _regen_cooldown: float = 0.0

@export var Inventory: Inv

#ANIMATIONS
enum {IDLE, RUN, DASH, POTION}
var state = IDLE

@onready var animationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine = animationTree["parameters/playback"]
var facing_dir: Vector2 = Vector2.LEFT

var blend_position : Vector2 = Vector2.ZERO
var blend_pos_paths = [
	"parameters/idle/idle_bs2d/blend_position",
	"parameters/run/run_bs2d/blend_position",
	"parameters/dash/dash_bs2d/blend_position",
	"parameters/potion/potion_bs2d/blend_position"
]

var animTree_state_keys = [
	"idle",
	"run",
	"dash",
	"potion"
]

func _ready() -> void:
	add_to_group("player")
	var health_potion: InventoryItem = load("res://Inventory/Items/HealthPotion/health_potion.tres")
	potion_pouch.register_item(health_potion)
	healthChanged.emit()
	staminaChanged.emit()
	animationTree.active = true

func _physics_process(delta: float) -> void:
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	
	if is_drinking or potion_timer > 0.0:
		_potion_logic(delta)
		state = POTION
		velocity = Vector2.ZERO
		animate()
		move_and_slide()
		return
	
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
	if is_drinking or potion_timer > 0.0:
		state = POTION
		return
	
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
	
	if Input.is_action_just_pressed("dash") and currentStamina >= 40 and not is_dashing and not is_drinking:
		var dir = input_vector if input_vector != Vector2.ZERO else facing_dir
		if dir != Vector2.ZERO:
			dash(dir.normalized())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_potion"):
		_try_use_potion()
	#elif event.is_action_pressed("next_potion"):
		#potion_pouch.select_next()
	#elif event.is_action_pressed("prev_potion"):
		#potion_pouch.select_prev()

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
		can_take_damage = true
		is_dashing = false
		var end_dir := dash_dir
		dash_dir = Vector2.ZERO
		if queued_potion:
			queued_potion = false
			_drink_potion(end_dir.normalized())

func _try_use_potion() -> void:
	if is_drinking:
		return
	if is_dashing:
		queued_potion = true
		return
	_drink_potion(facing_dir)

func _drink_potion(dir: Vector2 = Vector2.ZERO) -> void:
	if dir == Vector2.ZERO:
		dir = facing_dir
		if dir == Vector2.ZERO:
			dir = Vector2.DOWN
	
	if potion_pouch:
		var selected_id := potion_pouch.get_selected_id()
		if selected_id == "":
			return
		
		if potion_pouch.can_use(selected_id, 1):
			is_drinking = true
			potion_dir = dir
			potion_timer = POTION_DURATION
			blend_position = dir
			state = POTION
			
			var used := potion_pouch.use_selected(1)
			if used:
				var item := potion_pouch.get_item(selected_id)
				if item and item.can_apply(self):
					item.apply(self)
			return

func _potion_logic(delta: float) -> void:
	var elapsed_percent = clamp(1.0 - (potion_timer / POTION_DURATION), 0.0, 1.0)
	velocity = Vector2.ZERO
	potion_timer -= delta
	
	if potion_timer <= 0.0:
		is_drinking = false
		potion_dir = Vector2.ZERO

func change_health(delta: float) -> void:
	currentHealth = clampf(currentHealth + delta, 0.0, maxHealth)
	healthChanged.emit()
	healthUpdated.emit()
	print("HP change: %+d -> %.1f/%.1f" % [int(delta), currentHealth, maxHealth])

func start_heal_over_time_continuous(total_heal: float, duration: float, ease_curve: Curve = null) -> void:
	if duration <= 0.0 or total_heal == 0.0:
		return
	_heal_over_time_continuous(total_heal, duration, ease_curve)

func _heal_over_time_continuous(total_heal: float, duration: float, ease_curve: Curve = null) -> void:
	var t: float = 0.0
	var last_frac: float = 0.0
	var healed: float = 0.0
	
	while t < duration:
		await get_tree().process_frame
		var dt: float = get_process_delta_time()
		t += dt
		
		var x: float = clampf(t / duration, 0.0, 1.0)
		
		var frac: float
		if ease_curve != null:
			frac = float(ease_curve.sample(x))
		else:
			frac = x
			
		var dfrac: float = maxf(frac - last_frac, 0.0)
		last_frac = frac
		
		var step: float = total_heal * dfrac
		healed += step
		change_health(step)
		
	var remainder: float = total_heal - healed
	if absf(remainder) > 0.001:
		change_health(remainder)

func animate() -> void:
	state_machine.travel(animTree_state_keys[state])
	animationTree.set(blend_pos_paths[state], blend_position)

func get_head_position(offset: Vector2 = Vector2(0, -4)) -> Vector2:
	var a := get_node_or_null("HeadAnchor") as Node2D
	if a:
		return a.global_position + offset
	var s := get_node_or_null("Sprite2D") as Sprite2D
	if s and s.texture:
		var h := s.texture.get_size().y * s.scale.y
		return global_position + Vector2(0, -h * 0.5) + offset
	return global_position + Vector2(0, -16) + offset
