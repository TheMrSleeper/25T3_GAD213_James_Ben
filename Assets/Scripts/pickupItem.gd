extends Area2D

class_name PickupItem

@export var item: InventoryItem
@export var amount: int = 1
@export var auto_register: bool = true
@export var destroy_on_pick: bool = true
@export var popup_scene: PackedScene = preload("res://Assets/UI/pickup_popup.tscn")

var _consumed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true

func _on_body_entered(body: Node) -> void:
	if _consumed or item == null:
		return
	if not body.is_in_group("player"):
		return

	var pouch := (body as Player).potion_pouch if body is Player else null
	if pouch == null:
		pouch = get_tree().get_first_node_in_group("potion_pouch") as PotionPouch
	if pouch == null:
		return

	if auto_register:
		pouch.register_item(item)

	var added: int = pouch.add_capped(item.id, amount)
	if added <= 0:
		return

	_consumed = true
	_spawn_popup_above(body, added)
	_consume_and_despawn()

func _spawn_popup_above(player: Node, added: int) -> void:
	if popup_scene == null or added <= 0:
		return
	var popup := popup_scene.instantiate() as Node2D
	var world_parent := (player as Node).get_parent()
	if world_parent:
		world_parent.add_child(popup)
	else:
		add_child(popup)
	var head_pos := (player as Player).get_head_position()
	popup.global_position = head_pos
	popup.z_as_relative = false
	popup.z_index = 1000
	for c in popup.get_children():
		if c is CanvasItem:
			(c as CanvasItem).z_as_relative = false
			(c as CanvasItem).z_index = 1000
	var txt := "+%d" % added
	var tex := item.texture
	if popup.has_method("show_popup"):
		popup.call("show_popup", tex, txt)

func _consume_and_despawn() -> void:
	set_deferred("monitoring", false)
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
	visible = false

	if destroy_on_pick:
		call_deferred("queue_free")
