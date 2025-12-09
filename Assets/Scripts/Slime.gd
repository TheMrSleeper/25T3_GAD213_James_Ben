extends CharacterBody2D

enum State { IDLE, ROAM, CHASE, RETURN, ATTACK }

@export var move_speed: float = 40.0
@export var roam_radius: float = 64.0
@export var idle_time_range: Vector2 = Vector2(0.5, 1.5)

@export var max_health: float = 50.0
@export var hurt_duration: float = 0.15
@export var potion_drop_chance: float = 0.25
@export var potion_drop_scene: PackedScene

var state: State = State.IDLE
var spawn_position: Vector2
var roam_target: Vector2
var state_timer: float = 0.0

var player: Player

var last_move_dir: Vector2 = Vector2.DOWN

var stuck_check_position: Vector2
var stuck_check_timer: float = 0.0

var health: float
var hurt_timer: float = 0.0
var is_dead: bool = false

@export var stuck_check_interval: float = 0.5
@export var stuck_min_distance: float = 8.0
@export var min_roam_distance: float = 24.0

var is_stopping: bool = false
var stop_timer: float = 0.0
@export var stop_duration: float = 0.25

#DETECTION
@export var detection_radius: float = 120.0
@export var lose_interest_radius: float = 160.0

# ATTACK
@export var attack_range: float = 20.0
@export var attack_duration: float = 0.4
@export var attack_cooldown: float = 0.8
@export var attack_damage: float = 10.0

@export var attack_hitbox_radius: float = 12.0
@export var attack_hitbox_offset: float = 10.0

var attack_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

func _ready() -> void:
	randomize()
	spawn_position = global_position
	stuck_check_position = global_position
	health = max_health
	add_to_group("enemy")
	
	if attack_shape and attack_shape.shape is CircleShape2D:
		var circle := attack_shape.shape as CircleShape2D
		circle.radius = attack_hitbox_radius
	
	anim_tree.active = true
	_set_idle()
	
	player = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return
	
	if hurt_timer > 0.0:
		hurt_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	
	match state:
		State.IDLE:
			state_timer -= delta
			if state_timer <= 0.0:
				_pick_new_roam_target()
				state = State.ROAM
		
		State.ROAM:
			if not is_stopping:
				_move_towards(roam_target)
				if global_position.distance_to(roam_target) < 4.0:
					_begin_smooth_stop()
			else:
				_apply_smooth_stop(delta)
		
		State.CHASE:
			if not is_stopping:
				if player == null:
					state = State.RETURN
				else:
					var to_player := player.global_position - global_position
					var dist := to_player.length()
					
					if dist <= attack_range and attack_cooldown_timer <= 0.0:
						# begin attack
						state = State.ATTACK
						attack_timer = attack_duration
						velocity = Vector2.ZERO
						if dist > 0.01:
							last_move_dir = to_player.normalized()
						_update_attack_hitbox_position()
					else:
						_move_towards(player.global_position)
			else:
				_apply_smooth_stop(delta)
		
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
			
			attack_timer -= delta
			
			if attack_timer <= 0.0:
				attack_cooldown_timer = attack_cooldown
				
				if player != null:
					var dist_after := global_position.distance_to(player.global_position)
					if dist_after <= detection_radius:
						state = State.CHASE
					elif dist_after <= roam_radius:
						state = State.RETURN
					else:
						state = State.ROAM
				else:
					state = State.RETURN
		
		State.RETURN:
			if not is_stopping:
				_move_towards(spawn_position)
				if global_position.distance_to(spawn_position) < 4.0:
					_begin_smooth_stop()
			else:
				_apply_smooth_stop(delta)
	
	if state == State.ROAM and not is_stopping and velocity.length() > 0.1:
		stuck_check_timer += delta
		if stuck_check_timer >= stuck_check_interval:
			var moved_distance := global_position.distance_to(stuck_check_position)
			
			if moved_distance < stuck_min_distance:
				_pick_new_roam_target()
			
			# Reset sample window
			stuck_check_timer = 0.0
			stuck_check_position = global_position
	
	_check_player_detection()
	_update_animation()

func _begin_smooth_stop() -> void:
	if is_stopping:
		return
	is_stopping = true
	stop_timer = stop_duration

func _set_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	state_timer = randf_range(idle_time_range.x, idle_time_range.y)


func _pick_new_roam_target() -> void:
	var distance: float = 0.0
	
	# ensure the roam target is not too close
	while distance < min_roam_distance:
		var angle := randf() * TAU
		distance = randf() * roam_radius
		roam_target = spawn_position + Vector2(cos(angle), sin(angle)) * distance


func _move_towards(target: Vector2) -> void:
	var dir := target - global_position
	if dir.length() > 0.01:
		dir = dir.normalized()
		velocity = dir * move_speed
		last_move_dir = dir
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _apply_smooth_stop(delta: float) -> void:
	# Gradually reduce speed towards zero over stop_duration
	stop_timer -= delta
	
	# Lerp velocity towards 0 so movement & animation naturally slow
	velocity = velocity.lerp(Vector2.ZERO, delta / stop_duration)
	move_and_slide()
	
	if stop_timer <= 0.0:
		is_stopping = false
		_set_idle()

func _check_player_detection() -> void:
	if player == null:
		return
		
	var dist := global_position.distance_to(player.global_position)
	
	if state == State.ROAM or state == State.IDLE:
		if dist <= detection_radius:
			state = State.CHASE
			is_stopping = false
		
	elif state == State.CHASE:
		if dist >= lose_interest_radius:
			state = State.RETURN
			is_stopping = false

func _update_animation() -> void:
	if is_dead:
		anim_state.travel("Death")
		anim_tree.set("parameters/Death/death_bs2d/blend_position", last_move_dir)
		return
	
	if hurt_timer > 0.0:
		anim_state.travel("Hurt")
		anim_tree.set("parameters/Hurt/hurt_bs2d/blend_position", last_move_dir)
		return
	
	if state == State.ATTACK:
		anim_state.travel("Attack")
		anim_tree.set("parameters/Attack/attack_bs2d/blend_position", last_move_dir)
		return
	
	var moving := velocity.length() > 0.1
	
	if moving:
		anim_state.travel("Run")
	else:
		anim_state.travel("Idle")
	
	anim_tree.set("parameters/Idle/idle_bs2d/blend_position", last_move_dir)
	anim_tree.set("parameters/Run/run_bs2d/blend_position", last_move_dir)

func apply_player_hit(player: Node, damage: float) -> void:
	if is_dead:
		return
	
	health -= damage
	hurt_timer = hurt_duration
	
	if health <= 0.0:
		_die()

func _die() -> void:
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	
	collision_layer = 0
	collision_mask = 0
	
	_maybe_drop_potion()
	
	await get_tree().create_timer(0.7).timeout
	queue_free()

func _maybe_drop_potion() -> void:
	if potion_drop_scene == null:
		return
	
	if randf() <= potion_drop_chance:
		var drop := potion_drop_scene.instantiate()
		get_parent().add_child(drop)
		drop.global_position = global_position

func attack_anim_hit_notify() -> void:
	if state != State.ATTACK:
		return
	
	_update_attack_hitbox_position()
	_attempt_attack_hit()

func _update_attack_hitbox_position() -> void:
	if attack_area == null:
		return
	
	var dir := last_move_dir
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	
	attack_area.position = dir.normalized() * attack_hitbox_offset

func _attempt_attack_hit() -> void:
	if player == null or attack_area == null:
		return
	
	# Respect player's i-frames/dodge
	if not player.can_take_damage:
		return
	
	# Check who is inside the hitbox
	for body in attack_area.get_overlapping_bodies():
		if body == player:
			player.change_health(-attack_damage)
			break
