# res://Resources/enemy_card_collection.gd
class_name EnemyCardCollection
extends Resource

@export var enemy_name: String
@export var enemy_description: String
@export var cards: Array[CardResource]  # All cards for this enemy type
@export var decks: Array[EnemyDeckDefinition]  # All deck variations

# Helper function to get a complete deck by index
func get_deck(index: int) -> Array[CardResource]:
	if index < 0 or index >= decks.size():
		return []
		
	var deck_def = decks[index]
	var result: Array[CardResource] = []
	
	for card_index in deck_def.card_indices:
		if card_index >= 0 and card_index < cards.size():
			result.append(cards[card_index])
			
	return result

# Get deck by difficulty level
func get_deck_by_difficulty(difficulty: int) -> Array[CardResource]:
	for i in range(decks.size()):
		if decks[i].difficulty_level == difficulty:
			return get_deck(i)
	
	# Fallback to first deck if difficulty not found
	return get_deck(0)

# Get deck definition by difficulty level
func get_deck_definition_by_difficulty(difficulty: int) -> EnemyDeckDefinition:
	for deck_def in decks:
		if deck_def.difficulty_level == difficulty:
			return deck_def
	
	# Fallback to first deck
	return decks[0] if decks.size() > 0 else null

# Get available difficulty levels for this enemy
func get_available_difficulties() -> Array[int]:
	var difficulties: Array[int] = []
	for deck_def in decks:
		if not deck_def.difficulty_level in difficulties:
			difficulties.append(deck_def.difficulty_level)
	difficulties.sort()
	return difficulties
