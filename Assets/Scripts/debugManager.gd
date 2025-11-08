extends Node

class_name Debug

@export var health_potion_res: Resource = preload("res://Inventory/Items/HealthPotion/health_potion.tres")
@export var spawn_amount: int = 1

var _pouch: PotionPouch = null

func _ready() -> void:
	call_deferred("_late_bind")

func _late_bind() -> void:
	_pouch = get_tree().get_first_node_in_group("potion_pouch") as PotionPouch
	if _pouch == null:
		push_warning("Debug: No PotionPouch found in group 'potion_pouch'.")
		return
	if health_potion_res:
		_pouch.register_item(health_potion_res)
	else:
		push_warning("Debug: health_potion_res is null or not an InventoryItem.")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	if event.is_action_pressed("debug_damage"):
		_apply_to_players(func(p): p.change_health(-20), "change_health")

	if event.is_action_pressed("debug_heal"):
		_apply_to_players(func(p): p.change_health(10), "change_health")

	if event.is_action_pressed("debug_add_health_potion"):
		_spawn_health_potion()

func _spawn_health_potion() -> void:
	if _pouch == null:
		_late_bind()
	if _pouch == null:
		return

	if health_potion_res:
		_pouch.register_item(health_potion_res)
	var id: String = health_potion_res.id if health_potion_res else ""
	if id == "":
		push_warning("Debug: health_potion_res has empty id; cannot add.")
		return
	var added: int = _pouch.add_capped(id, spawn_amount)
	if added > 0:
		print("Spawned %d %s. New count: %d / %d" % [
			added, id, _pouch.get_count(id), _pouch.get_max_stack(id)
		])
	else:
		if not _pouch.can_add(id, spawn_amount):
			print("%s already at max (%d). No spawn." % [id, _pouch.get_max_stack(id)])
		else:
			print("Nothing added (spawn_amount=%d?)" % spawn_amount)

func _apply_to_players(action: Callable, required_method: String) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node and node.has_method(required_method):
			action.call(node)
