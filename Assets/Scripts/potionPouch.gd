extends Node

class_name PotionPouch

signal pouch_changed(item_id: String, new_count: int)
signal pouch_bulk_changed()
signal selected_changed(selected_id: String)

var _counts: Dictionary[String, int] = {}
var _registry: Dictionary[String, InventoryItem] = {}

var _order: Array[String] = []
var _selected_index: int = 0

func _ready() -> void:
	add_to_group("potion_pouch")

func register_item(item: InventoryItem) -> void:
	if item == null or item.id.is_empty():
		push_warning("Attempted to register a null/invalid InventoryItem.")
		return
	_registry[item.id] = item

func get_count(item_id: String) -> int:
	return _counts.get(item_id, 0)

func _sync_order_for(item_id: String, new_count: int) -> void:
	var had := _order.has(item_id)
	if new_count > 0 and not had:
		_order.append(item_id)
	elif new_count <= 0 and had:
		var idx := _order.find(item_id)
		_order.remove_at(idx)
		if _order.is_empty():
			_selected_index = 0
			selected_changed.emit("")
		else:
			_selected_index = clampi(_selected_index, 0, _order.size() - 1)
			selected_changed.emit(get_selected_id())

func add_capped(item_id: String, amount: int = 1) -> int:
	if amount <= 0:
		return 0
	var max_stack: int = get_max_stack(item_id)
	var cur: int = get_count(item_id)
	if cur >= max_stack:
		return 0
	var room: int = max_stack - cur
	var to_add: int = min(amount, room)
	set_count(item_id, cur + to_add)
	return to_add

func set_count(item_id: String, new_count: int) -> void:
	new_count = clamp(new_count, 0, get_max_stack(item_id))
	_counts[item_id] = new_count
	_sync_order_for(item_id, new_count)
	pouch_changed.emit(item_id, new_count)

func add(item_id: String, amount: int = 1) -> void:
	if amount == 0:
		return
	set_count(item_id, get_count(item_id) + amount)

func can_use(item_id: String, amount: int = 1) -> bool:
	return get_count(item_id) >= amount

func use(item_id: String, amount: int = 1) -> bool:
	if not can_use(item_id, amount):
		return false
	set_count(item_id, get_count(item_id) - amount)
	return true

func get_selected_id() -> String:
	if _order.is_empty():
		return ""
	return _order[_selected_index]

func select_next() -> void:
	if _order.is_empty():
		return
	_selected_index = (_selected_index + 1) % _order.size()
	selected_changed.emit(get_selected_id())

func select_prev() -> void:
	if _order.is_empty():
		return
	_selected_index = (_selected_index - 1 + _order.size()) % _order.size()
	selected_changed.emit(get_selected_id())

func use_selected(amount: int = 1) -> bool:
	var id := get_selected_id()
	if id == "":
		return false
	var ok := use(id, amount)
	return ok

func clear() -> void:
	_counts.clear()
	_order.clear()
	_selected_index = 0
	selected_changed.emit("")
	pouch_bulk_changed.emit()

func to_dict() -> Dictionary:
	return {"counts": _counts.duplicate(true)}

func from_dict(data: Dictionary) -> void:
	var incoming := data.get("counts", {}) as Dictionary
	_counts.clear()
	_order.clear()
	for k in incoming.keys():
		var id := str(k)
		var n := int(incoming[k])
		_counts[id] = n
		if n > 0:
			_order.append(id)
	if _order.is_empty():
		_selected_index = 0
		selected_changed.emit("")
	else:
		_selected_index = clampi(_selected_index, 0, _order.size() - 1)
		selected_changed.emit(get_selected_id())
	pouch_bulk_changed.emit()

func get_item(item_id: String) -> InventoryItem:
	return _registry.get(item_id, null)

func get_max_stack(item_id: String) -> int:
	var item: InventoryItem = _registry.get(item_id, null)
	return item.max_stack if item else 99

func is_at_max(item_id: String) -> bool:
	return get_count(item_id) >= get_max_stack(item_id)

func can_add(item_id: String, amount: int = 1) -> bool:
	return get_count(item_id) + amount <= get_max_stack(item_id)
