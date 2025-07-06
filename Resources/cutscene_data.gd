# res://Resources/cutscene_data.gd
class_name CutsceneData
extends Resource

@export var cutscene_id: String = ""
@export var participants: Array[Character] = []
@export var dialogue_lines: Array[DialogueLine] = []
@export var background_color: Color = Color.BLACK  # Simple background for now

func _init(id: String = "", chars: Array[Character] = [], lines: Array[DialogueLine] = []):
	cutscene_id = id
	participants = chars
	dialogue_lines = lines

# Helper to get character by ID
func get_character(character_id: String) -> Character:
	for character in participants:
		if character.character_name == character_id:
			return character
	return null

# Helper to get character position for a dialogue line
func get_speaker_position(line: DialogueLine) -> String:
	if line.speaker_position != "auto":
		return line.speaker_position
	
	var character = get_character(line.speaker_id)
	if character:
		return character.default_position
	
	return "left"  # fallback
