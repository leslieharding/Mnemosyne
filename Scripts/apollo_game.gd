# res://Scripts/apollo_game.gd
extends Node2D

# Player's deck (received from deck selection)
var player_deck: Array[CardResource] = []
var selected_deck_index: int = -1
var selected_card_index: int = -1

# Reference to the card hand
@onready var hand_container = $VBoxContainer/HBoxContainer

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
	var apollo_collection: GodCardCollection = load("res://Resources/Collections/Apollo.tres")
	if apollo_collection:
		# Get the deck based on index
		player_deck = apollo_collection.get_deck(deck_index)
		
		# Update deck info display
		var deck_info = $VBoxContainer/DeckName
		deck_info.text = "Selected Deck: " + apollo_collection.decks[deck_index].deck_name
		
		# Display cards in hand
		display_player_hand()
	else:
		push_error("Failed to load Apollo collection!")

# Display player's hand of cards using manual positioning
func display_player_hand():
	# First, clear existing cards
	for child in hand_container.get_children():
		child.queue_free()
	
	# Card width and spacing parameters
	var card_width = 110  # Base card width
	var card_spacing = 30  # Adjust this value to increase/decrease spacing between cards
	var total_spacing = card_width + card_spacing  # Total space each card takes horizontally
	
	# Calculate the total width needed
	var total_width = player_deck.size() * total_spacing
	var start_x = -total_width / 2 + card_width / 2  # Center the cards
	
	# Create a Node2D as a container for all cards
	var cards_container = Node2D.new()
	cards_container.name = "CardsContainer"
	hand_container.add_child(cards_container)
	
	# Add each card from the deck with explicit positioning
	for i in range(player_deck.size()):
		var card = player_deck[i]
		
		# Create a card display instance
		var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
		cards_container.add_child(card_display)
		
		# Position the card explicitly with the new spacing
		card_display.position.x = start_x + i * total_spacing
		
		# Setup the card with its data
		card_display.setup(card)
		
		# Connect to detect clicks on the card
		card_display.panel.gui_input.connect(_on_card_gui_input.bind(card_display, i))

# Handle card input events
func _on_card_gui_input(event, card_display, card_index):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Deselect previous card if any
			var cards_container = hand_container.get_node("CardsContainer")
			for child in cards_container.get_children():
				if child is CardDisplay and child.is_selected:
					child.deselect()
			
			# Select this card
			card_display.select()
			selected_card_index = card_index
			print("Selected card: ", player_deck[card_index].card_name)
