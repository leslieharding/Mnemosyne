# res://Resources/enemy_deck_definition.gd
class_name EnemyDeckDefinition
extends Resource

@export var deck_name: String
@export var deck_description: String
@export var difficulty_level: int = 0  # 0 = easy, 1 = medium, 2 = hard/boss
@export var card_indices: Array[int]  # 5 indices pointing to cards in the enemy collection

# Get difficulty description for UI
func get_difficulty_description() -> String:
	match difficulty_level:
		0:
			return "Novice"
		1:
			return "Adept" 
		2:
			return "Master"
		_:
			return "Unknown"
