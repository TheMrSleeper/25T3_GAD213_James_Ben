extends Control

@export var speaker_path: NodePath
@export var dialogue_path: NodePath
@export var continue_path: NodePath

@onready var _speaker: Label = get_node_or_null(speaker_path)
@onready var _dialogue: RichTextLabel = get_node_or_null(dialogue_path)
@onready var _continue: Button = get_node_or_null(continue_path)

func _ready() -> void:
	assert(_speaker and _dialogue and _continue, "Dialogue children not found. Check unique names.")

func display_line(line: String, speaker: String = "") -> void:
	_speaker.visible = (speaker != "")
	_speaker.text = speaker
	_dialogue.clear()
	_dialogue.parse_bbcode(line)
	open()

func open() -> void:
	get_tree().paused = true
	visible = true

func close() -> void:
	get_tree().paused = false
	visible = false

func _on_continue_pressed() -> void:
	close()
