extends Node2D

class_name PickupPopup2D

@onready var icon: Sprite2D = $Icon
@onready var label: Label = $Label

@export var rise: float = 24.0
@export var duration: float = 0.8
@export var start_offset: Vector2 = Vector2(0, -12)

func show_popup(tex: Texture2D, text: String) -> void:
	if tex:
		icon.texture = tex
	label.text = text
	
	position += start_offset
	modulate.a = 1.0
	
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - rise, duration)
	tw.parallel().tween_property(self, "modulate:a", 0.0, duration)
	await tw.finished
	queue_free()
