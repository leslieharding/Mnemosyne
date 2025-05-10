# res://Scripts/card_hand.gd
extends HBoxContainer
class_name CardHand

signal card_selected(card_index: int)

var cards: Array[CardDisplay] = []
var selected_card: CardDisplay = null
var selected_index: int = -1

# Configure the hand with cards
func setup_hand(card_resources: Array[CardResource]):
	# Clear any existing cards
	for child in get_children():
		child.queue_free()
	
	cards.clear()
	selected_card = null
	selected_index = -1
	
	# Add a card display for each card resource
	for i in range(card_resources.size()):
		var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
		add_child(card_display)
		card_display.setup(card_resources[i])
		cards.append(card_display)

# Handle card selection
func select_card(card: CardDisplay):
	# Deselect previous card if any
	if selected_card != null:
		selected_card.deselect()
	
	# Select the new card
	selected_card = card
	selected_card.select()
	
	# Find the index of the selected card
	selected_index = cards.find(card)
	
	# Emit signal with selected card index
	emit_signal("card_selected", selected_index)

# Get currently selected card index
func get_selected_card_index() -> int:
	return selected_index
