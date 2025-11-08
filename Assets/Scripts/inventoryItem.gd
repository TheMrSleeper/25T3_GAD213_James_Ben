extends Resource

class_name InventoryItem

@export var id: String
@export var display_name: String
@export var max_stack: int = 99
@export var texture: Texture2D
@export_enum("potion") var item_type: String

func can_apply(user: Node) -> bool:
	return true

func apply(user: Node) -> void:
	pass

func describe_effect() -> String:
	return ""
