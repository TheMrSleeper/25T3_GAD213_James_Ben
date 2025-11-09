extends Node

@onready var _dialogue_box: Control = %DialogueBox
@export var player: Player

func _ready() -> void:
	player.	healthChanged.emit()
	player.staminaChanged.emit()
	print("[GM] ready; dialogue=", _dialogue_box)
	await _dialogue_box.ready
	call_deferred("_show_intro")

func _show_intro() -> void:
	print("[GM] _show_intro")
	_dialogue_box.display_line("[font_size={32}][b]W/A/S/D[/b] - Move				[b]SPACE[/b] - Dash[br][b]Q[/b] - Use Potion				[b]E[/b] - Interact[br][b]F1[/b] - Damage Player			[b]F2[/b] - Heal Player[br][b]F3[/b] - Give Health Potion to Player[/font_size]", "Controls")
