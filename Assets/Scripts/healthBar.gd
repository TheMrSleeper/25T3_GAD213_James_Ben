extends TextureProgressBar

@export var player: Player
@export var lerp_speed: float = 6.0

var target_value: float = 100.0

func _ready() -> void:
	min_value = 0
	max_value = 100
	player.healthChanged.connect(_on_player_health_changed)
	player.healthUpdated.connect(_on_player_health_changed)
	_snap_to_player()

func _process(delta: float) -> void:
	value = lerp(value, target_value, delta * lerp_speed)

func _on_player_health_changed() -> void:
	target_value = _pct_from_player()

func _pct_from_player() -> float:
	return (player.currentHealth * 100.0) / max(player.maxHealth, 0.001)

func _snap_to_player() -> void:
	value = _pct_from_player()
	target_value = value
