extends InventoryItem
class_name HealthPotion

@export var heal_amount: float = 35.0
@export var duration: float = 2.0

func can_apply(user: Node) -> bool:
	if user is Player:
		var p := user as Player
		return p.currentHealth < p.maxHealth
	return false

func apply(user: Node) -> void:
	if user is Player:
		(user as Player).start_heal_over_time_continuous(heal_amount, duration)

func describe_effect() -> String:
	return "Restores %s HP over %ss." % [str(int(heal_amount)), str(duration)]
