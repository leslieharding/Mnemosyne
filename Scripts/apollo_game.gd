# res://Scripts/apollo_game.gd
extends Node2D

# Player's deck (received from deck selection)
var player_deck: Array[CardResource] = []
var selected_deck_index: int = -1
var selected_card_index: int = -1

# Grid navigation variables
var current_grid_index: int = -1  # Current selected grid position
var grid_size: int = 3  # 3x3 grid
var grid_slots: Array = []  # References to grid slot panels
var grid_occupied: Array = []  # Track which slots have cards

# Selected card visuals
var selected_grid_style: StyleBoxFlat
var default_grid_style: StyleBoxFlat
var hover_grid_style: StyleBoxFlat

# Reference to the card hand
@onready var hand_container = $VBoxContainer/HBoxContainer
@onready var board_container = $VBoxContainer/GameGrid

func _ready():
	# Initialize game board
	setup_empty_board()
	
	# Create styles for grid selection
	create_grid_styles()
	
	# Get the selected deck from Apollo scene
	var params = get_scene_params()
	if params.has("deck_index"):
		selected_deck_index = params.deck_index
		load_player_deck(selected_deck_index)
	else:
		push_error("No deck was selected!")
	
	# Set up input handling
	set_process_input(true)

# Set up input processing for keyboard navigation
func _input(event):
	# Only process input if a card is selected
	if selected_card_index == -1 or current_grid_index == -1:
		return
	
	# Arrow key / WASD navigation
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_w"):
		move_grid_selection(0, -1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_s"):
		move_grid_selection(0, 1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_a"):
		move_grid_selection(-1, 0)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_d"):
		move_grid_selection(1, 0)
	
	# Confirm placement with Enter/Space
	if event.is_action_pressed("ui_accept"):
		place_card_on_grid()

# Helper to move grid selection based on direction
func move_grid_selection(dx: int, dy: int):
	# Calculate new position
	var current_x = current_grid_index % grid_size
	var current_y = current_grid_index / grid_size
	
	var new_x = clamp(current_x + dx, 0, grid_size - 1)
	var new_y = clamp(current_y + dy, 0, grid_size - 1)
	
	var new_index = new_y * grid_size + new_x
	
	# Check if the new position is different and not already occupied
	if new_index != current_grid_index and not grid_occupied[new_index]:
		# Deselect current grid
		if current_grid_index != -1:
			grid_slots[current_grid_index].add_theme_stylebox_override("panel", default_grid_style)
		
		# Select new grid
		current_grid_index = new_index
		grid_slots[current_grid_index].add_theme_stylebox_override("panel", selected_grid_style)

# Create the different styles for grid slots
func create_grid_styles():
	# Default style (empty slot)
	default_grid_style = StyleBoxFlat.new()
	default_grid_style.bg_color = Color("#444444")
	default_grid_style.border_width_left = 1
	default_grid_style.border_width_top = 1
	default_grid_style.border_width_right = 1
	default_grid_style.border_width_bottom = 1
	default_grid_style.border_color = Color("#666666")
	
	# Selected style (currently highlighted slot)
	selected_grid_style = StyleBoxFlat.new()
	selected_grid_style.bg_color = Color("#444444")
	selected_grid_style.border_width_left = 2
	selected_grid_style.border_width_top = 2
	selected_grid_style.border_width_right = 2
	selected_grid_style.border_width_bottom = 2
	selected_grid_style.border_color = Color("#44AAFF")  # Bright blue highlight
	
	# Hover style
	hover_grid_style = StyleBoxFlat.new()
	hover_grid_style.bg_color = Color("#555555")
	hover_grid_style.border_width_left = 1
	hover_grid_style.border_width_top = 1
	hover_grid_style.border_width_right = 1
	hover_grid_style.border_width_bottom = 1
	hover_grid_style.border_color = Color("#888888")

# Helper to get passed parameters from previous scene
func get_scene_params() -> Dictionary:
	# Check for parameters passed to this scene
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}

# Setup the empty 3x3 board
func setup_empty_board():
	# Find the GridContainer for the board
	board_container.columns = grid_size
	
	# Clear any existing children
	for child in board_container.get_children():
		child.queue_free()
	
	# Clear tracking arrays
	grid_slots.clear()
	grid_occupied.clear()
	
	# Add 9 empty slots
	for i in range(grid_size * grid_size):
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(100, 100)
		slot.name = "Slot" + str(i)
		
		# Connect mouse signals for hover and click
		slot.mouse_entered.connect(_on_grid_mouse_entered.bind(i))
		slot.mouse_exited.connect(_on_grid_mouse_exited.bind(i))
		slot.gui_input.connect(_on_grid_gui_input.bind(i))
		
		# Add to board and tracking
		board_container.add_child(slot)
		grid_slots.append(slot)
		grid_occupied.append(false)
		
		# Apply default style
		slot.add_theme_stylebox_override("panel", default_grid_style)

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
			
			# Initialize grid selection if not already set
			if current_grid_index == -1:
				# Find the first unoccupied grid slot
				for i in range(grid_slots.size()):
					if not grid_occupied[i]:
						current_grid_index = i
						grid_slots[i].add_theme_stylebox_override("panel", selected_grid_style)
						break

# Grid hover handlers
func _on_grid_mouse_entered(grid_index):
	# Only apply hover effect if not selected and not occupied
	if grid_index != current_grid_index and not grid_occupied[grid_index]:
		grid_slots[grid_index].add_theme_stylebox_override("panel", hover_grid_style)

func _on_grid_mouse_exited(grid_index):
	# Restore default style if not the currently selected one
	if grid_index != current_grid_index and not grid_occupied[grid_index]:
		grid_slots[grid_index].add_theme_stylebox_override("panel", default_grid_style)

# Grid click handler
func _on_grid_gui_input(event, grid_index):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Only select if a card is selected and grid is not occupied
			if selected_card_index != -1 and not grid_occupied[grid_index]:
				# Deselect current selection
				if current_grid_index != -1:
					grid_slots[current_grid_index].add_theme_stylebox_override("panel", default_grid_style)
				
				# Select new grid
				current_grid_index = grid_index
				grid_slots[grid_index].add_theme_stylebox_override("panel", selected_grid_style)
			
			# Double-click to place
			if event.double_click and selected_card_index != -1 and current_grid_index == grid_index:
				place_card_on_grid()

# Place the selected card on the selected grid
func place_card_on_grid():
	if selected_card_index == -1 or current_grid_index == -1:
		return
	
	if grid_occupied[current_grid_index]:
		print("Grid slot is already occupied!")
		return
	
	# Mark the grid as occupied
	grid_occupied[current_grid_index] = true
	
	# Create a card display for the grid
	var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	
	# Remove the current panel
	grid_slots[current_grid_index].queue_free()
	
	# Replace with card display
	card_display.setup(player_deck[selected_card_index])
	board_container.add_child(card_display)
	board_container.move_child(card_display, current_grid_index)
	
	# Update grid slot reference
	grid_slots[current_grid_index] = card_display
	
	# Reset selection
	selected_card_index = -1
	current_grid_index = -1
	
	# Find the next available grid slot
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:
			current_grid_index = i
			grid_slots[i].add_theme_stylebox_override("panel", selected_grid_style)
			break
	
	# Deselect card in hand
	var cards_container = hand_container.get_node("CardsContainer")
	for child in cards_container.get_children():
		if child is CardDisplay and child.is_selected:
			child.deselect()
	
	print("Card placed on grid at position", current_grid_index)
