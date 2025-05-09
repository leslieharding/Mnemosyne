# res://Resources/god_card_collection.gd
class_name GodCardCollection
extends Resource

@export var god_name: String
@export var cards: Array[CardResource]  # All cards for this god (15 cards)
@export var decks: Array[DeckDefinition]  # All deck definitions (3 decks)

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

# Get deck by name
func get_deck_by_name(deck_name: String) -> Array[CardResource]:
	for i in range(decks.size()):
		if decks[i].deck_name == deck_name:
			return get_deck(i)
	return []
