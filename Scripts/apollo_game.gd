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
var grid_ownership: Array = []  # Track who owns each card (can change via combat)
var grid_card_data: Array = []  # Track the actual card data for each slot

# Experience tracking
var deck_card_indices: Array[int] = []  # Original indices in Apollo's collection
var exp_panel: ExpPanel  # Reference to experience panel
var grid_to_collection_index: Dictionary = {}  # grid_index -> collection_index

# Player types for ownership tracking
enum Owner {
	NONE,
	PLAYER,
	OPPONENT
}

# Selected card visuals
var selected_grid_style: StyleBoxFlat
var default_grid_style: StyleBoxFlat
var hover_grid_style: StyleBoxFlat
var player_card_style: StyleBoxFlat
var opponent_card_style: StyleBoxFlat

# Game managers
var turn_manager: TurnManager
var opponent_manager: OpponentManager

# State management to prevent multiple opponent turns
var opponent_is_thinking: bool = false

# UI References
@onready var hand_container = $VBoxContainer/HBoxContainer
@onready var board_container = $VBoxContainer/GameGrid
@onready var game_status_label = $VBoxContainer/Title
@onready var deck_name_label = $VBoxContainer/DeckName

func _ready():
	# Initialize game managers
	setup_managers()
	
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
	
	# Set up input handling (only when it's player's turn)
	set_process_input(false)  # Start disabled
	
	# Start the game
	start_game()

# Set up the game managers
func setup_managers():
	# Create turn manager
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	# Connect turn manager signals
	turn_manager.coin_flip_result.connect(_on_coin_flip_result)
	turn_manager.game_started.connect(_on_game_started)
	turn_manager.turn_changed.connect(_on_turn_changed)
	
	# Create opponent manager
	opponent_manager = OpponentManager.new()
	add_child(opponent_manager)
	
	# Connect opponent manager signals
	opponent_manager.opponent_card_placed.connect(_on_opponent_card_placed)

# Start the game sequence
func start_game():
	game_status_label.text = "Flipping coin to determine who goes first..."
	disable_player_input()
	turn_manager.start_game()

# Handle coin flip result
func _on_coin_flip_result(player_goes_first: bool):
	if player_goes_first:
		game_status_label.text = "You won the coin flip! You go first."
	else:
		game_status_label.text = "Opponent won the coin flip! They go first."
	
	# Brief pause to show result
	await get_tree().create_timer(2.0).timeout

# Handle game start after coin flip
func _on_game_started():
	print("Game started - current player is: ", "Player" if turn_manager.is_player_turn() else "Opponent")
	update_game_status()
	
	# If it's opponent's turn, let them play - but only once!
	if turn_manager.is_opponent_turn():
		print("Starting opponent's first turn")
		call_deferred("opponent_take_turn")  # Use call_deferred to avoid async issues

# Handle turn changes
func _on_turn_changed(is_player_turn: bool):
	print("Turn changed - is_player_turn: ", is_player_turn, " | opponent_is_thinking: ", opponent_is_thinking)
	update_game_status()
	
	if is_player_turn:
		enable_player_input()
	else:
		disable_player_input()
		# Only start opponent turn if they're not already thinking
		if not opponent_is_thinking:
			print("Starting opponent turn via turn change")
			call_deferred("opponent_take_turn")  # Use call_deferred to avoid async issues
		else:
			print("Opponent already thinking, skipping turn start")

# Calculate and return current scores (Triple Triad style)
func get_current_scores() -> Dictionary:
	# Count cards owned on the board
	var player_board_cards = 0
	var opponent_board_cards = 0
	
	for owner in grid_ownership:
		if owner == Owner.PLAYER:
			player_board_cards += 1
		elif owner == Owner.OPPONENT:
			opponent_board_cards += 1
	
	# Total score = cards in hand + cards owned on board
	var player_score = player_deck.size() + player_board_cards
	var opponent_score = opponent_manager.get_remaining_cards() + opponent_board_cards
	
	return {"player": player_score, "opponent": opponent_score}

# Update the game status display
func update_game_status():
	var scores = get_current_scores()
	
	if turn_manager.is_player_turn():
		game_status_label.text = "Your Turn - Select a card and place it"
	else:
		var opponent_info = opponent_manager.get_opponent_info()
		game_status_label.text = "Opponent's Turn - " + opponent_info.name + " is thinking..."
	
	# Update to show scores instead of card counts
	deck_name_label.text = "Score - Player: " + str(scores.player) + " | Opponent: " + str(scores.opponent)

# Enable player input controls
func enable_player_input():
	set_process_input(true)

# Disable player input controls
func disable_player_input():
	set_process_input(false)
	
	# Clear any current selection
	if current_grid_index != -1:
		grid_slots[current_grid_index].add_theme_stylebox_override("panel", default_grid_style)
		current_grid_index = -1

# Let opponent take their turn
func opponent_take_turn():
	# Double-check that it's actually the opponent's turn to prevent multiple calls
	if not turn_manager.is_opponent_turn():
		print("Warning: opponent_take_turn called when it's not opponent's turn!")
		return
	
	# Check if opponent is already thinking to prevent concurrent turns
	if opponent_is_thinking:
		print("Warning: opponent_take_turn called while opponent is already thinking!")
		return
	
	# Set the thinking flag
	opponent_is_thinking = true
	print("Opponent starting turn - setting thinking flag to true")
	
	# Get list of available slots
	var available_slots: Array[int] = []
	for i in range(grid_occupied.size()):
		if not grid_occupied[i]:
			available_slots.append(i)
	
	# Check if game should end
	if available_slots.is_empty() or not opponent_manager.has_cards():
		opponent_is_thinking = false
		end_game()
		return
	
	print("Opponent taking turn - available slots: ", available_slots.size())
	
	# Let opponent make their move
	opponent_manager.take_turn(available_slots)

# Resolve combat when a card is placed
func resolve_combat(grid_index: int, attacking_owner: Owner, attacking_card: CardResource):
	print("Resolving combat for card at slot ", grid_index)
	
	var captures = []
	var grid_x = grid_index % grid_size
	var grid_y = grid_index / grid_size
	
	# Check all 4 adjacent positions
	var directions = [
		{"dx": 0, "dy": -1, "my_value_index": 0, "their_value_index": 2, "name": "North"},  # North: my North vs their South
		{"dx": 1, "dy": 0, "my_value_index": 1, "their_value_index": 3, "name": "East"},   # East: my East vs their West
		{"dx": 0, "dy": 1, "my_value_index": 2, "their_value_index": 0, "name": "South"},  # South: my South vs their North
		{"dx": -1, "dy": 0, "my_value_index": 3, "their_value_index": 1, "name": "West"}   # West: my West vs their East
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if grid_occupied[adj_index]:
				var adjacent_owner = grid_ownership[adj_index]
				
				# Only battle if the adjacent card is owned by the opponent
				if adjacent_owner != Owner.NONE and adjacent_owner != attacking_owner:
					var adjacent_card = grid_card_data[adj_index]
					
					var my_value = attacking_card.values[direction.my_value_index]
					var their_value = adjacent_card.values[direction.their_value_index]
					
					print("Combat ", direction.name, ": My ", my_value, " vs Their ", their_value)
					
					# If my value is greater, I capture their card
					if my_value > their_value:
						print("Captured card at slot ", adj_index, "!")
						captures.append(adj_index)
						
						# Award capture experience if it's a player card
						if attacking_owner == Owner.PLAYER:
							var card_collection_index = get_card_collection_index(grid_index)
							if card_collection_index != -1:
								get_node("/root/RunExperienceTrackerAutoload").add_capture_exp(card_collection_index, 10)
					else:
						# Defense successful - award defense exp if defending card is player's
						if attacking_owner == Owner.OPPONENT and grid_ownership[adj_index] == Owner.PLAYER:
							var defending_card_index = get_card_collection_index(adj_index)
							if defending_card_index != -1:
								get_node("/root/RunExperienceTrackerAutoload").add_defense_exp(defending_card_index, 5)
	
	# Apply all captures
	for captured_index in captures:
		grid_ownership[captured_index] = attacking_owner
		print("Card at slot ", captured_index, " is now owned by ", "Player" if attacking_owner == Owner.PLAYER else "Opponent")
	
	# Update visuals for all affected cards
	update_board_visuals()
	
	return captures.size()  # Return number of captures for potential future use

# Add helper function to get collection index from grid position
func get_card_collection_index(grid_index: int) -> int:
	if grid_index in grid_to_collection_index:
		return grid_to_collection_index[grid_index]
	return -1

# Update all card visuals based on current ownership
func update_board_visuals():
	for i in range(grid_slots.size()):
		if grid_occupied[i]:
			var slot = grid_slots[i]
			var card_display = slot.get_child(0)  # The card display should be the first child
			
			# Apply styling based on current ownership
			if grid_ownership[i] == Owner.PLAYER:
				card_display.panel.add_theme_stylebox_override("panel", player_card_style)
			elif grid_ownership[i] == Owner.OPPONENT:
				card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)

# Handle opponent card placement
func _on_opponent_card_placed(grid_index: int):
	print("Opponent card placed signal received for slot: ", grid_index)
	
	if grid_index < 0 or grid_index >= grid_slots.size():
		print("Invalid grid index from opponent: ", grid_index)
		opponent_is_thinking = false  # Reset thinking flag on error
		return
	
	if grid_occupied[grid_index]:
		print("Opponent tried to place card on occupied slot!")
		opponent_is_thinking = false  # Reset thinking flag on error
		return
	
	# Get the card data that the opponent just played
	var opponent_card_data = opponent_manager.get_last_played_card()
	if not opponent_card_data:
		print("Warning: Could not get opponent card data!")
		opponent_is_thinking = false
		return
	
	# Mark the slot as occupied and set ownership
	grid_occupied[grid_index] = true
	grid_ownership[grid_index] = Owner.OPPONENT
	grid_card_data[grid_index] = opponent_card_data
	
	# Get the slot
	var slot = grid_slots[grid_index]
	
	# Create a card display for the opponent's card
	var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	
	# Add the card as a child of the slot panel
	slot.add_child(card_display)
	
	# Center the card within the slot (same as player cards)
	card_display.position = Vector2(
		(slot.custom_minimum_size.x - 100) / 2,  # Assuming card width is 100
		(slot.custom_minimum_size.y - 140) / 2   # Assuming card height is 140
	)
	
	# Set higher z-index so the card appears on top
	card_display.z_index = 1
	
	# Setup the card display with the actual card data
	card_display.setup(opponent_card_data)
	
	# Apply opponent styling
	card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
	
	print("Opponent placed card: ", opponent_card_data.card_name, " at slot ", grid_index)
	
	# Resolve combat
	var captures = resolve_combat(grid_index, Owner.OPPONENT, opponent_card_data)
	if captures > 0:
		print("Opponent captured ", captures, " cards!")
		
	# Update the score display immediately after combat
	update_game_status()
	
	# Clear the thinking flag since opponent finished their turn
	opponent_is_thinking = false
	print("Opponent finished turn - setting thinking flag to false")
	
	# Check if game should end
	if should_game_end():
		end_game()
		return
	
	print("Switching turns after opponent move")
	
	# Switch turns - this should make it the player's turn
	turn_manager.next_turn()

# Check if the game should end
func should_game_end() -> bool:
	# Game ends if board is full or both players are out of cards
	var available_slots = 0
	for occupied in grid_occupied:
		if not occupied:
			available_slots += 1
	
	return available_slots == 0 or (player_deck.is_empty() and not opponent_manager.has_cards())

# End the game
func end_game():
	await get_tree().process_frame
	
	var scores = get_current_scores()
	var winner = ""
	
	if scores.player > scores.opponent:
		winner = "You win!"
	elif scores.opponent > scores.player:
		winner = "You lose!"
		# If player loses, end the entire run
		game_status_label.text = "Defeat! " + winner
		disable_player_input()
		opponent_is_thinking = false
		turn_manager.end_game()
		
		# Add a delay then return to god selection
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")
		return
	else:
		winner = "It's a tie!"
	
	# Player won or tied - continue the run
	game_status_label.text = "Victory! " + winner
	disable_player_input()
	opponent_is_thinking = false
	turn_manager.end_game()
	
	print("Battle ended - Final score: Player ", scores.player, " | Opponent ", scores.opponent)
	
	# Add a brief celebration delay
	await get_tree().create_timer(2.0).timeout
	
	# Return to map with updated progress
	show_reward_screen()

# Return to the map after completing an encounter
func return_to_map():
	# Get the current map data and node info
	var params = get_scene_params()
	if params.has("map_data"):
		# Pass the updated map data back to the map scene
		get_tree().set_meta("scene_params", {
			"god": params.get("god", "Apollo"),
			"deck_index": params.get("deck_index", 0),
			"map_data": params.get("map_data"),
			"returning_from_battle": true
		})
		
		# Return to the map scene
		get_tree().change_scene_to_file("res://Scenes/RunMap.tscn")
	else:
		# Fallback if no map data
		print("Warning: No map data found, returning to god selection")
		get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# Set up input processing for keyboard navigation (only when player's turn)
func _input(event):
	# Only process input if it's the player's turn and a card is selected
	if not turn_manager.is_player_turn() or selected_card_index == -1 or current_grid_index == -1:
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
	# Calculate current position
	var current_x = current_grid_index % grid_size
	var current_y = current_grid_index / grid_size
	
	var new_index = current_grid_index
	
	# Rule 1: Check if there's a free adjacent space in the direction pressed
	if dx != 0:  # Horizontal movement
		var target_x = current_x + dx
		var target_y = current_y
		
		# Check if target is within bounds and free
		if target_x >= 0 and target_x < grid_size:
			var adjacent_index = target_y * grid_size + target_x
			if not grid_occupied[adjacent_index]:
				new_index = adjacent_index
			else:
				# Rule 2: No free adjacent space, apply horizontal overflow rules
				new_index = handle_horizontal_overflow(current_x, current_y, dx)
		else:
			# Rule 2: Moving outside bounds, apply horizontal overflow rules
			new_index = handle_horizontal_overflow(current_x, current_y, dx)
	
	elif dy != 0:  # Vertical movement
		var target_x = current_x
		var target_y = current_y + dy
		
		# Check if target is within bounds and free
		if target_y >= 0 and target_y < grid_size:
			var adjacent_index = target_y * grid_size + target_x
			if not grid_occupied[adjacent_index]:
				new_index = adjacent_index
			else:
				# Rule 4: No free adjacent space, apply vertical overflow rules
				new_index = handle_vertical_overflow(current_x, current_y, dy)
		else:
			# Rule 4: Moving outside bounds, apply vertical overflow rules
			new_index = handle_vertical_overflow(current_x, current_y, dy)
	
	# Apply the movement if we found a valid new position
	if new_index != current_grid_index and new_index != -1:
		# Deselect current grid
		if current_grid_index != -1:
			grid_slots[current_grid_index].add_theme_stylebox_override("panel", default_grid_style)
		
		# Select new grid
		current_grid_index = new_index
		grid_slots[current_grid_index].add_theme_stylebox_override("panel", selected_grid_style)

# Handle horizontal overflow when moving left/right
func handle_horizontal_overflow(current_x: int, current_y: int, dx: int) -> int:
	# First, try to wrap within the same row
	if dx > 0:  # Moving right, wrap to leftmost of same row
		for x in range(grid_size):
			var check_index = current_y * grid_size + x
			if not grid_occupied[check_index] and check_index != current_grid_index:
				return check_index
	else:  # Moving left, wrap to rightmost of same row
		for x in range(grid_size - 1, -1, -1):  # Start from rightmost
			var check_index = current_y * grid_size + x
			if not grid_occupied[check_index] and check_index != current_grid_index:
				return check_index
	
	# No free slot in current row, move to next row
	if dx > 0:  # Moving right, overflow to leftmost of next row
		return find_slot_in_direction(current_y, 1, 0)  # Start from leftmost
	else:  # Moving left, overflow to rightmost of next row
		return find_slot_in_direction(current_y, 1, grid_size - 1)  # Start from rightmost

# Handle vertical overflow when moving up/down
func handle_vertical_overflow(current_x: int, current_y: int, dy: int) -> int:
	# First, try to wrap within the same column
	if dy > 0:  # Moving down, wrap to topmost of same column
		for y in range(grid_size):
			var check_index = y * grid_size + current_x
			if not grid_occupied[check_index] and check_index != current_grid_index:
				return check_index
	else:  # Moving up, wrap to bottommost of same column
		for y in range(grid_size - 1, -1, -1):  # Start from bottommost
			var check_index = y * grid_size + current_x
			if not grid_occupied[check_index] and check_index != current_grid_index:
				return check_index
	
	# No free slot in current column, move to next column
	if dy > 0:  # Moving down, overflow to topmost of next column
		return find_slot_in_direction_vertical(current_x, 1, 0)  # Start from topmost
	else:  # Moving up, overflow to bottommost of next column
		return find_slot_in_direction_vertical(current_x, 1, grid_size - 1)  # Start from bottommost

# Find a free slot starting from a specific row, moving in a direction
func find_slot_in_direction(start_row: int, row_step: int, preferred_x: int) -> int:
	# Try rows in order: start_row + row_step, start_row + 2*row_step, etc.
	for row_offset in range(1, grid_size):
		var target_row = (start_row + row_offset * row_step) % grid_size
		
		# Check preferred position first
		var preferred_index = target_row * grid_size + preferred_x
		if not grid_occupied[preferred_index]:
			return preferred_index
		
		# If preferred position is occupied, check other positions in this row
		for x in range(grid_size):
			var check_index = target_row * grid_size + x
			if not grid_occupied[check_index]:
				return check_index
	
	return -1  # No free slot found

# Find a free slot starting from a specific column, moving in a direction
func find_slot_in_direction_vertical(start_col: int, col_step: int, preferred_y: int) -> int:
	# Try columns in order: start_col + col_step, start_col + 2*col_step, etc.
	for col_offset in range(1, grid_size):
		var target_col = (start_col + col_offset * col_step) % grid_size
		
		# Check preferred position first
		var preferred_index = preferred_y * grid_size + target_col
		if not grid_occupied[preferred_index]:
			return preferred_index
		
		# If preferred position is occupied, check other positions in this column
		for y in range(grid_size):
			var check_index = y * grid_size + target_col
			if not grid_occupied[check_index]:
				return check_index
	
	return -1  # No free slot found

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
	
	# Player card style (blue border)
	player_card_style = StyleBoxFlat.new()
	player_card_style.bg_color = Color("#444444")
	player_card_style.border_width_left = 2
	player_card_style.border_width_top = 2
	player_card_style.border_width_right = 2
	player_card_style.border_width_bottom = 2
	player_card_style.border_color = Color("#4444FF")  # Blue for player
	
	# Opponent card style (red border)
	opponent_card_style = StyleBoxFlat.new()
	opponent_card_style.bg_color = Color("#444444")
	opponent_card_style.border_width_left = 2
	opponent_card_style.border_width_top = 2
	opponent_card_style.border_width_right = 2
	opponent_card_style.border_width_bottom = 2
	opponent_card_style.border_color = Color("#FF4444")  # Red for opponent

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
	grid_ownership.clear()
	grid_card_data.clear()
	
	# Add 9 empty slots
	for i in range(grid_size * grid_size):
		var slot = Panel.new()
		# Increase the slot size to better fit cards
		slot.custom_minimum_size = Vector2(100, 140)  # Larger size to accommodate cards
		slot.name = "Slot" + str(i)
		
		# Add some margin to the grid container
		board_container.add_theme_constant_override("h_separation", 10)  # Horizontal space between slots
		board_container.add_theme_constant_override("v_separation", 10)  # Vertical space between slots
		
		# Connect mouse signals for hover and click (only for player turns)
		slot.mouse_entered.connect(_on_grid_mouse_entered.bind(i))
		slot.mouse_exited.connect(_on_grid_mouse_exited.bind(i))
		slot.gui_input.connect(_on_grid_gui_input.bind(i))
		
		# Add to board and tracking
		board_container.add_child(slot)
		grid_slots.append(slot)
		grid_occupied.append(false)
		grid_ownership.append(Owner.NONE)
		grid_card_data.append(null)
		
		# Apply default style
		slot.add_theme_stylebox_override("panel", default_grid_style)

# Load player's selected deck
func load_player_deck(deck_index: int):
	# Load Apollo collection
	var apollo_collection: GodCardCollection = load("res://Resources/Collections/Apollo.tres")
	if apollo_collection:
		# Get the deck definition
		var deck_def = apollo_collection.decks[deck_index]
		
		# Store the original indices
		deck_card_indices = deck_def.card_indices.duplicate()
		
		# Get the deck based on index
		player_deck = apollo_collection.get_deck(deck_index)
		
		# Only initialize the experience tracker if this is a new run (not returning from battle)
		var params = get_scene_params()
		if not params.has("returning_from_battle"):
			# This is a new run - initialize the tracker
			get_node("/root/RunExperienceTrackerAutoload").start_new_run(deck_card_indices)
		# If returning from battle, the tracker already has the experience data
		
		# Set up experience panel
		setup_experience_panel()
		
		# Display cards in hand
		display_player_hand()
	else:
		push_error("Failed to load Apollo collection!")

# Add new function to set up experience panel
func setup_experience_panel():
	# Create and add the experience panel
	exp_panel = preload("res://Scenes/ExpPanel.tscn").instantiate()
	
	# Position it in the top-right corner
	exp_panel.position = Vector2(900, 10)
	
	# Add to the scene
	add_child(exp_panel)
	
	# Set up with current deck
	exp_panel.setup_deck(player_deck, deck_card_indices)

# Display player's hand of cards using manual positioning
# Display player's hand of cards using manual positioning
func display_player_hand():
	# First, clear existing cards
	for child in hand_container.get_children():
		child.queue_free()
	
	# If the deck is empty, nothing to display
	if player_deck.size() == 0:
		print("No cards left in hand")
		return
		
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
		
		# Connect to detect clicks on the card (only when it's player's turn)
		card_display.panel.gui_input.connect(_on_card_gui_input.bind(card_display, i))

# Handle card input events
func _on_card_gui_input(event, card_display, card_index):
	# Only allow card selection during player's turn
	if not turn_manager.is_player_turn():
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Validate that we have a valid card index
			if card_index >= player_deck.size():
				print("Invalid card index: ", card_index)
				return
				
			# Deselect previous card if any
			var cards_container = hand_container.get_node_or_null("CardsContainer")
			if cards_container:
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

# Grid hover handlers (only during player's turn)
func _on_grid_mouse_entered(grid_index):
	if not turn_manager.is_player_turn():
		return
		
	# Only apply hover effect if not selected and not occupied
	if grid_index != current_grid_index and not grid_occupied[grid_index]:
		grid_slots[grid_index].add_theme_stylebox_override("panel", hover_grid_style)

func _on_grid_mouse_exited(grid_index):
	if not turn_manager.is_player_turn():
		return
		
	# Restore default style if not the currently selected one
	if grid_index != current_grid_index and not grid_occupied[grid_index]:
		grid_slots[grid_index].add_theme_stylebox_override("panel", default_grid_style)

# Grid click handler (only during player's turn)
func _on_grid_gui_input(event, grid_index):
	if not turn_manager.is_player_turn():
		return
		
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
		
	# Make sure the selected card index is valid
	if selected_card_index >= player_deck.size():
		print("Invalid card index: ", selected_card_index)
		selected_card_index = -1
		return
	
	# Store a reference to the card data before removing it
	var card_data = player_deck[selected_card_index]
	
	# Mark the slot as occupied and set ownership
	grid_occupied[current_grid_index] = true
	grid_ownership[current_grid_index] = Owner.PLAYER
	grid_card_data[current_grid_index] = card_data
	
	# Track which collection index this card is from
	grid_to_collection_index[current_grid_index] = deck_card_indices[selected_card_index]
	
	# Get the current slot
	var slot = grid_slots[current_grid_index]
	
	# Create a card display for the grid
	var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	
	# Add the card as a child of the slot panel
	# This ensures proper positioning within the grid
	slot.add_child(card_display)
	
	# Center the card within the slot
	card_display.position = Vector2(
		(slot.custom_minimum_size.x - 100) / 2,  # Assuming card width is 100
		(slot.custom_minimum_size.y - 140) / 2   # Assuming card height is 140
	)
	
	# Set higher z-index so the card appears on top
	card_display.z_index = 1
	
	# Setup the card with the card resource data (using our stored reference)
	card_display.setup(card_data)
	
	# Apply player styling initially
	card_display.panel.add_theme_stylebox_override("panel", player_card_style)
	
	print("Card placed on grid at position", current_grid_index)
	
	# Resolve combat
	var captures = resolve_combat(current_grid_index, Owner.PLAYER, card_data)
	if captures > 0:
		print("Player captured ", captures, " cards!")

	# Update the score display immediately after combat
	update_game_status()

	# Remove the card from the hand
	var temp_index = selected_card_index
	selected_card_index = -1  # Reset before removing to avoid issues with callbacks
	remove_card_from_hand(temp_index)

	# Reset grid selection
	current_grid_index = -1

	# Check if game should end
	if should_game_end():
		end_game()
		return

	# Switch turns
	turn_manager.next_turn()

# Remove a card from the player's hand after it's played
func remove_card_from_hand(card_index: int):
	# Check if the index is valid
	if card_index < 0 or card_index >= player_deck.size():
		print("Invalid card index to remove:", card_index)
		return
		
	# Store the card we're removing for reference
	var played_card = player_deck[card_index]
	print("Removing card from hand: ", played_card.card_name)
	
	# Remove the card from the deck array
	player_deck.remove_at(card_index)
	
	# Also remove from the deck indices tracking
	deck_card_indices.remove_at(card_index)
	
	# Reset the selected card index
	selected_card_index = -1
	
	# Redisplay the hand to update visuals
	display_player_hand()

func show_reward_screen():
	var params = get_scene_params()
	
	get_tree().set_meta("scene_params", {
		"god": params.get("god", "Apollo"),
		"deck_index": params.get("deck_index", 0),
		"map_data": params.get("map_data"),
		"current_node": params.get("current_node")
	})
	get_tree().change_scene_to_file("res://Scenes/RewardScreen.tscn")
