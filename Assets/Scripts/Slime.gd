extends CharacterBody2D

@export var move_speed: float = 40.0
@export var wander_radius: float = 64.0
@export var chase_speed: float = 60.0
@export var lose_sight_distance: float = 200.0

@export var max_health: int = 3
var health: int
var is_hurt: bool = false
var is_dead: bool = false

var spawn_position: Vector2
var wander_target: Vector2
var player: Node2D = null

enum State { IDLE, WANDER, CHASE, RETURN }
var state: State = State.IDLE

var facing_dir: Vector2 = Vector2.DOWN

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

func _ready() -> void:
	spawn_position = global_position
	randomize()
	_pick_new_wander_target()
	health = max_health
	
	# Connect detection signals in the editor OR here:
	$DetectionArea.body_entered.connect(_on_detection_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.RETURN:
			_process_return(delta)
	
	_update_animation()
	move_and_slide()

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	# Occasionally start wandering
	if randf() < 0.01:
		state = State.WANDER
		_pick_new_wander_target()

func _process_wander(delta: float) -> void:
	var to_target = wander_target - global_position
	if to_target.length() < 8.0:
		_pick_new_wander_target()
		velocity = Vector2.ZERO
		state = State.IDLE
		return
	
	velocity = to_target.normalized() * move_speed

func _process_chase(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		state = State.RETURN
		return
	
	var to_player = player.global_position - global_position
	
	# Lose sight and go home
	if to_player.length() > lose_sight_distance:
		player = null
		state = State.RETURN
		return
	
	velocity = to_player.normalized() * chase_speed

func _process_return(delta: float) -> void:
	var to_spawn = spawn_position - global_position
	if to_spawn.length() < 8.0:
		global_position = spawn_position
		velocity = Vector2.ZERO
		state = State.IDLE
		return
	
	velocity = to_spawn.normalized() * move_speed

func _pick_new_wander_target() -> void:
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * wander_radius
	wander_target = spawn_position + offset

func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player": # or use a group "player"
		player = body
		state = State.CHASE

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		pass

func _update_animation() -> void:
	if is_dead:
		anim_state.travel("Death")
	elif is_hurt:
		anim_state.travel("Hurt")
	else:
		var dir := velocity
		if dir.length() > 0.1:
			facing_dir = dir.normalized()
			anim_state.travel("Run")
		else:
			anim_state.travel("Idle")
	
	anim_tree.set("parameters/Idle/idle_bs2d/blend_position", facing_dir)
	anim_tree.set("parameters/Run/run_bs2d/blend_position", facing_dir)
	anim_tree.set("parameters/Hurt/hurt_bs2d/blend_position", facing_dir)
	anim_tree.set("parameters/Death/death_bs2d/blend_position", facing_dir)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	health -= amount
	if health <= 0:
		_die()
	else:
		_play_hurt()

func _play_hurt() -> void:
	is_hurt = true
	anim_state.travel("Hurt")
	$HurtTimer.start()

func _on_HurtTimer_timeout() -> void:
	is_hurt = false

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	state = State.IDLE
	$CollisionShape2D.disabled = true
	$DetectionArea.monitoring = false
	
	var attack_area := get_node_or_null("AttackArea")
	if attack_area:
		attack_area.monitoring = false
	
	anim_state.travel("Death")

func _on_death_animation_finished() -> void:
	queue_free()
