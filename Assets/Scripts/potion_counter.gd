extends HBoxContainer

@export var player_path: NodePath
@export var item_id: String = "health_potion"
@export var follow_selected: bool = true

@onready var label: Label = $PotionNumber
var _pouch: PotionPouch = null

func _ready() -> void:
	var player: Node = get_node_or_null(player_path)
	if player and player.has_node("PotionPouch"):
		_pouch = player.get_node("PotionPouch") as PotionPouch
		_pouch.pouch_changed.connect(_on_pouch_changed)
		_pouch.pouch_bulk_changed.connect(_refresh_all)
		_pouch.selected_changed.connect(_on_selected_changed)
		if follow_selected:
			var selected := _pouch.get_selected_id()
			item_id = selected if selected != "" else item_id

		_refresh_single()
	else:
		push_warning("PotionCounter: player_path invalid or PotionPouch not found.")

func _on_selected_changed(selected_id: String) -> void:
	if not follow_selected:
		return
	item_id = selected_id
	_refresh_single()

func _on_pouch_changed(changed_id: String, new_count: int) -> void:
	if changed_id == item_id:
		label.text = str(new_count)

func _refresh_all() -> void:
	_refresh_single()

func _refresh_single() -> void:
	if _pouch == null:
		return
	var id := item_id
	if follow_selected:
		var selected := _pouch.get_selected_id()
		id = selected if selected != "" else item_id
	label.text = str(_pouch.get_count(id))
