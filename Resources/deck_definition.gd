# res://Resources/deck_definition.gd
class_name DeckDefinition
extends Resource

@export var deck_name: String
@export var deck_description: String
# Store indices into the cards array instead of references
@export var card_indices: Array[int]  # 5 indices pointing to cards in the god's card collection
