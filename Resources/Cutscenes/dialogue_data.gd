# res://Resources/Cutscenes/dialogue_data.gd
extends Resource
class_name DialogueData

@export var speaker_id: String  # "narrator", "mnemosyne", "voice", etc.
@export var text: String
@export var speaker_name: String = ""  # Display name (can be different from ID)
