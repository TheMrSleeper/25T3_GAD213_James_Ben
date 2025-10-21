extends TextureProgressBar

@export var player: Player

func _ready():
	player.staminaChanged.connect(update)
	update()

func update():
	value = player.currentStamina * 100 / player.maxStamina
