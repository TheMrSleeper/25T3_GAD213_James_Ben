extends TextureProgressBar

@export var player: Player
@export var tween_duration: float = 0.35
@export var ease_trans := Tween.TRANS_QUAD
@export var ease_type  := Tween.EASE_OUT
@export var animate_on_ready: bool = false

var _tween

func _ready() -> void:
	min_value = 0
	max_value = 100

	player.healthChanged.connect(_on_player_health_changed)

	if animate_on_ready:
		_on_player_health_changed()
	else:
		_snap_to_player()

func _snap_to_player() -> void:
	value = _pct_from_player()

func _on_player_health_changed() -> void:
	var target := _pct_from_player()
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "value", target, tween_duration)\
		.set_trans(ease_trans)\
		.set_ease(ease_type)

func _pct_from_player() -> float:
	return (player.currentHealth * 100.0) / max(player.maxHealth, 0.001)
