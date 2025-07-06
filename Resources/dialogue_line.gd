# res://Resources/dialogue_line.gd
class_name DialogueLine
extends Resource

@export var speaker_id: String = ""  # Which character is speaking
@export var text: String = ""
@export var speaker_position: String = "auto"  # "left", "right", or "auto" (use character default)

func _init(speaker: String = "", dialogue_text: String = "", position: String = "auto"):
	speaker_id = speaker
	text = dialogue_text
	speaker_position = position
