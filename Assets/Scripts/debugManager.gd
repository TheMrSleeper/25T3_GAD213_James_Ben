extends Node
class_name Debug

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_damage"):
		_apply_to_players(func(p): p.change_health(-10), "change_health")
	
	if event.is_action_pressed("debug_heal"):
		_apply_to_players(func(p): p.change_health(10), "change_health")

func _apply_to_players(action: Callable, required_method: String) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node and node.has_method(required_method):
			action.call(node)
