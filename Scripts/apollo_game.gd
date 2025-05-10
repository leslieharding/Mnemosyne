extends Node2D

# Player's deck (received from deck selection)
var player_deck: Array[CardResource] = []
var selected_deck_index: int = -1

func _ready():
	# Initialize game board
	setup_empty_board()
	
	# Get the selected deck from Apollo scene
	var params = get_scene_params()
	if params.has("deck_index"):
		selected_deck_index = params.deck_index
		load_player_deck(selected_deck_index)
	else:
		push_error("No deck was selected!")

# Helper to get passed parameters from previous scene
func get_scene_params() -> Dictionary:
	# Check for parameters passed to this scene
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}

# Setup the empty 3x3 board
func setup_empty_board():
	# Find the GridContainer for the board
	var board_container = $VBoxContainer/GameGrid
	
	# Make sure it's configured as 3x3
	board_container.columns = 3
	
	# Clear any existing children
	for child in board_container.get_children():
		child.queue_free()
	
	# Add 9 empty slots
	for i in range(9):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(100, 100)
		slot.name = "Slot" + str(i)
		board_container.add_child(slot)

# Load player's selected deck
func load_player_deck(deck_index: int):
	# Load Apollo collection
	var apollo_collection: GodCardCollection = load("res://Resources/Collections/apollo.tres")
	if apollo_collection:
		# Get the deck based on index
		player_deck = apollo_collection.get_deck(deck_index)
		
		# Update deck info display - Add a label for displaying deck info if not already present
		var deck_info = $VBoxContainer/DeckName
		if not deck_info:
			# Create a deck info label if it doesn't exist
			deck_info = Label.new()
			deck_info.name = "DeckInfoLabel"
			deck_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			# Insert it at the top of the VBoxContainer, before the GameGrid
			$VBoxContainer.add_child(deck_info)
			$VBoxContainer.move_child(deck_info, 0)  # Move to top position
		
		# Now set the text
		deck_info.text = "Selected Deck: " + apollo_collection.decks[deck_index].deck_name
		
		# Display cards in hand
		display_player_hand()
	else:
		push_error("Failed to load Apollo collection!")

# Display player's hand of cards
func display_player_hand():
	var hand_container = $VBoxContainer/HBoxContainer
	
	# Clear existing cards
	for child in hand_container.get_children():
		child.queue_free()
	
	# Add each card from the deck
	for i in range(player_deck.size()):
		var card = player_deck[i]
		
		# Create a simple card display
		var card_display = VBoxContainer.new()
		card_display.name = "Card" + str(i)
		
		# Card name
		var name_label = Label.new()
		name_label.text = card.card_name
		card_display.add_child(name_label)
		
		# Card values (Up, Right, Down, Left)
		var values_label = Label.new()
		values_label.text = str(card.values[0]) + "|" + str(card.values[1]) + "|" + str(card.values[2]) + "|" + str(card.values[3])
		card_display.add_child(values_label)
		
		# Add to hand container
		hand_container.add_child(card_display)
