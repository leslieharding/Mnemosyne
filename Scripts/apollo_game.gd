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

# Journal button reference  
var journal_button: JournalButton


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
var visual_effects_manager: VisualEffectsManager

# State management to prevent multiple opponent turns
var opponent_is_thinking: bool = false

# Notification system
var notification_manager: NotificationManager

# UI References
@onready var hand_container = $VBoxContainer/HBoxContainer
@onready var board_container = $VBoxContainer/GameGrid
@onready var game_status_label = $VBoxContainer/Title
@onready var deck_name_label = $VBoxContainer/DeckName
@onready var card_info_panel = $CardInfoPanel
@onready var card_name_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/LeftSection/CardNameLabel
@onready var card_description_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/LeftSection/CardDescriptionLabel
@onready var ability_name_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/LeftSection/AbilityNameLabel
@onready var ability_description_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/LeftSection/AbilityDescriptionLabel
@onready var north_power_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/RightSection/PowerGrid/TopRow/NorthPower
@onready var east_power_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/RightSection/PowerGrid/MiddleRow/EastPower
@onready var south_power_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/RightSection/PowerGrid/BottomRow/SouthPower
@onready var west_power_display = $CardInfoPanel/MarginContainer/VBoxContainer/HBoxContainer/RightSection/PowerGrid/MiddleRow/WestPower

var active_passive_abilities: Dictionary = {}  # position -> array of passive abilities

# Boss prediction system
var is_boss_battle: bool = false
var current_boss_prediction: Dictionary = {}

# Card info panel state management
enum PanelState {
	HIDDEN,
	FADING_IN,
	VISIBLE,
	GRACE_PERIOD,
	FADING_OUT
}

var panel_state: PanelState = PanelState.HIDDEN
var panel_fade_tween: Tween
var panel_grace_timer: Timer

# Panel timing configuration
const FADE_IN_DURATION: float = 0.2
const FADE_OUT_DURATION: float = 0.4
const GRACE_PERIOD_DURATION: float = 0.7

func _ready():
	# Initialize game managers
	setup_managers()
	
	# Initialize boss prediction tracker
	setup_boss_prediction_tracker()
	
	# Initialize game board
	setup_empty_board()
	
	# Create styles for grid selection
	create_grid_styles()
	
	# Add journal button
	setup_journal_button()
	
	# Set up card info panel for smooth fading
	setup_card_info_panel()
	
	# Set up notification system
	setup_notification_manager()
	
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

func setup_notification_manager():
	if not notification_manager:
		# Create a CanvasLayer to ensure proper positioning
		var notification_canvas = CanvasLayer.new()
		notification_canvas.layer = 99  # High layer to be on top
		notification_canvas.name = "NotificationCanvas"
		add_child(notification_canvas)
		
		notification_manager = preload("res://Scenes/NotificationManager.tscn").instantiate()
		notification_canvas.add_child(notification_manager)
		
		# Position it properly on screen
		notification_manager.position = Vector2(
			get_viewport().get_visible_rect().size.x - 320,  # 20px from right edge (300 width + 20)
			get_viewport().get_visible_rect().size.y / 2 - 40  # Centered vertically
		)
		
		print("NotificationManager created and positioned at: ", notification_manager.position)


# Set up the boss prediction tracker
func setup_boss_prediction_tracker():
	# Check if this is a boss battle
	var params = get_scene_params()
	if params.has("current_node"):
		var current_node = params["current_node"]
		is_boss_battle = (current_node.enemy_name == "?????")
		print("Boss battle detected: ", is_boss_battle)
	
	print("Boss prediction tracker initialized")

func setup_card_info_panel():
	if card_info_panel:
		# Keep panel visible but transparent initially
		card_info_panel.visible = true
		card_info_panel.modulate.a = 0.0
		
		# Create grace period timer
		panel_grace_timer = Timer.new()
		panel_grace_timer.wait_time = GRACE_PERIOD_DURATION
		panel_grace_timer.one_shot = true
		panel_grace_timer.timeout.connect(_on_grace_period_expired)
		add_child(panel_grace_timer)
		
		print("Card info panel fade system initialized")

func setup_journal_button():
	if not journal_button:
		# Create a CanvasLayer to ensure it's always on top, especially for Node2D scenes
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 10  # High layer value to be on top
		canvas_layer.name = "JournalLayer"
		add_child(canvas_layer)
		
		# Create the journal button
		journal_button = preload("res://Scenes/JournalButton.tscn").instantiate()
		canvas_layer.add_child(journal_button)
		
		journal_button.position = Vector2(20, get_viewport().get_visible_rect().size.y - 80)
		journal_button.size = Vector2(60, 60)
		
		print("Apollo Game: Journal button added with CanvasLayer")


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
	
	# Create visual effects manager
	visual_effects_manager = VisualEffectsManager.new()
	add_child(visual_effects_manager)
	
	# Connect opponent manager signals
	opponent_manager.opponent_card_placed.connect(_on_opponent_card_placed)
	
	# Set up opponent based on map node data
	setup_opponent_from_params()


# Set up opponent based on parameters from map
# Set up opponent based on parameters from map
func setup_opponent_from_params():
	var params = get_scene_params()
	
	# Check if we have current node data (enemy info)
	if params.has("current_node"):
		var current_node = params["current_node"]
		var enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
		var enemy_difficulty = current_node.enemy_difficulty
		
		print("Setting up opponent: ", enemy_name, " (difficulty ", enemy_difficulty, ")")
		opponent_manager.setup_opponent(enemy_name, enemy_difficulty)
	else:
		# Fallback for testing or if no node data available
		print("No enemy data found, using default Shadow Acolyte")
		opponent_manager.setup_opponent("Shadow Acolyte", 0)


func _on_card_hovered(card_data: CardResource):
	if not card_data:
		return
	
	# Cancel grace period timer if it's running
	if panel_grace_timer.time_left > 0:
		panel_grace_timer.stop()
	
	# Update panel content
	update_panel_content(card_data)
	
	# Handle fade in based on current state
	match panel_state:
		PanelState.HIDDEN, PanelState.FADING_OUT:
			start_fade_in()
		PanelState.FADING_IN, PanelState.VISIBLE, PanelState.GRACE_PERIOD:
			# Panel is already visible or becoming visible, just ensure it's in visible state
			panel_state = PanelState.VISIBLE
			# Content is already updated above

func _on_card_unhovered():
	# Start grace period unless we're already fading out or hidden
	match panel_state:
		PanelState.VISIBLE, PanelState.FADING_IN:
			start_grace_period()
		PanelState.GRACE_PERIOD:
			# Restart grace period timer
			start_grace_period()
		PanelState.FADING_OUT, PanelState.HIDDEN:
			# Do nothing, already handling or hidden
			pass

func update_panel_content(card_data: CardResource):
	"""Update the panel content without affecting visibility"""
	card_name_display.text = card_data.card_name
	card_description_display.text = card_data.description
	
	# Update power numbers in D-pad layout
	north_power_display.text = str(card_data.values[0])
	east_power_display.text = str(card_data.values[1])
	south_power_display.text = str(card_data.values[2])
	west_power_display.text = str(card_data.values[3])
	
	# Handle ability information
	if card_data.abilities.size() > 0:
		var ability = card_data.abilities[0]
		ability_name_display.text = ability.ability_name
		ability_description_display.text = ability.description
		ability_name_display.visible = true
		ability_description_display.visible = true
	else:
		ability_name_display.visible = false
		ability_description_display.visible = false

func start_fade_in():
	"""Begin fading the panel in"""
	# Kill any existing fade tween
	if panel_fade_tween:
		panel_fade_tween.kill()
	
	panel_state = PanelState.FADING_IN
	
	# Create and configure fade in tween
	panel_fade_tween = create_tween()
	panel_fade_tween.tween_property(
		card_info_panel, 
		"modulate:a", 
		1.0, 
		FADE_IN_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Set state to visible when fade completes
	panel_fade_tween.tween_callback(func(): panel_state = PanelState.VISIBLE)

func start_grace_period():
	"""Start the grace period timer"""
	panel_state = PanelState.GRACE_PERIOD
	
	# Start or restart the grace timer
	panel_grace_timer.start()

func start_fade_out():
	"""Begin fading the panel out"""
	# Kill any existing fade tween
	if panel_fade_tween:
		panel_fade_tween.kill()
	
	panel_state = PanelState.FADING_OUT
	
	# Create and configure fade out tween
	panel_fade_tween = create_tween()
	panel_fade_tween.tween_property(
		card_info_panel, 
		"modulate:a", 
		0.0, 
		FADE_OUT_DURATION
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# Set state to hidden when fade completes
	panel_fade_tween.tween_callback(func(): panel_state = PanelState.HIDDEN)

func _on_grace_period_expired():
	"""Called when the grace period timer expires"""
	if panel_state == PanelState.GRACE_PERIOD:
		start_fade_out()

# Optional: Add debug function to monitor panel state
func get_panel_state_name() -> String:
	match panel_state:
		PanelState.HIDDEN: return "HIDDEN"
		PanelState.FADING_IN: return "FADING_IN"
		PanelState.VISIBLE: return "VISIBLE"
		PanelState.GRACE_PERIOD: return "GRACE_PERIOD"
		PanelState.FADING_OUT: return "FADING_OUT"
		_: return "UNKNOWN"



# Start the game sequence
func start_game():
	game_status_label.text = "Flipping coin to determine who goes first..."
	disable_player_input()
	turn_manager.start_game()

# Handle coin flip result
func _on_coin_flip_result(player_goes_first: bool):
	if player_goes_first:
		game_status_label.text = "You won the coin flip! You go first."
		# Add this new section:
		if not is_boss_battle:
			get_node("/root/BossPredictionTrackerAutoload").start_recording_battle()
			# Show atmospheric notification
			if notification_manager:
				notification_manager.show_notification("You get the feeling you are being watched")
	else:
		game_status_label.text = "Opponent won the coin flip! They go first."
		# Add this new section:
		if is_boss_battle:
			game_status_label.text = "The boss allows you to go first... 'I know what you will do.'"
			turn_manager.current_player = TurnManager.Player.HUMAN
			player_goes_first = true
	
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
		if is_boss_battle:
			make_boss_prediction()
	else:
		disable_player_input()
		# Only start opponent turn if they're not already thinking
		if not opponent_is_thinking:
			print("Starting opponent turn via turn change")
			call_deferred("opponent_take_turn")  # Use call_deferred to avoid async issues
		else:
			print("Opponent already thinking, skipping turn start")

func get_card_display_at_position(grid_index: int) -> CardDisplay:
	if grid_index < 0 or grid_index >= grid_slots.size():
		return null
	
	var slot = grid_slots[grid_index]
	if slot.get_child_count() > 0:
		var child = slot.get_child(0)
		if child is CardDisplay:
			return child
	
	return null

# Make boss prediction for the current turn
func make_boss_prediction():
	if not is_boss_battle:
		return
	
	var tracker = get_node("/root/BossPredictionTrackerAutoload")
	if not tracker:
		return
	
	# Calculate current turn number (1-based)
	var cards_played = 5 - player_deck.size()
	var current_turn = cards_played + 1
	
	if current_turn > 5:
		return  # All cards played
	
	# Get available cards (indices of remaining cards in hand)
	var available_cards: Array[int] = []
	for i in range(player_deck.size()):
		var card_collection_index = deck_card_indices[i]
		available_cards.append(card_collection_index)
	
	# Get available positions (unoccupied grid slots)
	var available_positions: Array[int] = []
	for i in range(grid_occupied.size()):
		if not grid_occupied[i]:
			available_positions.append(i)
	
	# Get boss prediction
	current_boss_prediction = tracker.get_boss_prediction(
		current_turn, 
		available_cards, 
		available_positions
	)
	
	print("Boss prediction for turn ", current_turn, ": Card ", current_boss_prediction.get("card", -1), " at position ", current_boss_prediction.get("position", -1))



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

# Add this helper method to apollo_game.gd to set card ownership
func set_card_ownership(grid_index: int, new_owner: Owner):
	if grid_index >= 0 and grid_index < grid_ownership.size():
		grid_ownership[grid_index] = new_owner
		print("Card at slot ", grid_index, " ownership changed to ", "Player" if new_owner == Owner.PLAYER else "Opponent")

# This replaces the existing resolve_combat function in apollo_game.gd (around lines 210-280)
# This replaces the existing resolve_combat function in apollo_game.gd (around lines 210-280)

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
					
					# Safety check - ensure both cards exist
					if not attacking_card or not adjacent_card:
						print("Warning: Missing card data in combat resolution")
						continue
					
					var my_value = attacking_card.values[direction.my_value_index]
					var their_value = adjacent_card.values[direction.their_value_index]
					
					print("Combat ", direction.name, ": My ", my_value, " vs Their ", their_value)
					
					# Check for capture or successful defense
					if my_value > their_value:
						print("Captured card at slot ", adj_index, "!")
						captures.append(adj_index)
						
						# VISUAL EFFECT: Flash the attacking card's edge
						var attacking_card_display = get_card_display_at_position(grid_index)
						if attacking_card_display:
							var is_player_attack = (attacking_owner == Owner.PLAYER)
							visual_effects_manager.show_capture_flash(attacking_card_display, direction.my_value_index, is_player_attack)
						
						# Award capture experience if it's a player card attacking
						if attacking_owner == Owner.PLAYER:
							var card_collection_index = get_card_collection_index(grid_index)
							if card_collection_index != -1:
								get_node("/root/RunExperienceTrackerAutoload").add_capture_exp(card_collection_index, 10)
						
						# Execute ON_CAPTURE abilities on the card that was just captured
						var captured_card_level = get_card_level(get_card_collection_index(adj_index))
						if adjacent_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, captured_card_level):
							print("Executing ON_CAPTURE abilities for captured card: ", adjacent_card.card_name)
							
							var capture_context = {
								"capturing_card": attacking_card,
								"capturing_position": grid_index,
								"captured_card": adjacent_card,
								"captured_position": adj_index,
								"game_manager": self,
								"direction": direction.name,
								"card_level": captured_card_level
							}
							
							adjacent_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, captured_card_level)
					else:
						# Defense successful - check for ON_DEFEND abilities
						print("Defense successful at slot ", adj_index, "!")
						
						# Award defense experience if defending card is player's
						if attacking_owner == Owner.OPPONENT and grid_ownership[adj_index] == Owner.PLAYER:
							var defending_card_index = get_card_collection_index(adj_index)
							if defending_card_index != -1:
								get_node("/root/RunExperienceTrackerAutoload").add_defense_exp(defending_card_index, 5)
						
						# DEBUG: Check for ON_DEFEND abilities on the defending card
						print("DEBUG: Checking ON_DEFEND abilities for card: ", adjacent_card.card_name)
						print("DEBUG: Card abilities count: ", adjacent_card.abilities.size())
						for i in range(adjacent_card.abilities.size()):
							var ability = adjacent_card.abilities[i]
							print("DEBUG: Ability ", i, ": ", ability.ability_name, " trigger: ", ability.trigger_condition)
						
						var defending_card_collection_index = get_card_collection_index(adj_index)
						print("DEBUG: Defending card collection index: ", defending_card_collection_index)
						
						var defending_card_level = get_card_level(defending_card_collection_index)
						print("DEBUG: Defending card level: ", defending_card_level)
						
						var has_on_defend = adjacent_card.has_ability_type(CardAbility.TriggerType.ON_DEFEND, defending_card_level)
						print("DEBUG: Has ON_DEFEND ability: ", has_on_defend)
						print("DEBUG: TriggerType.ON_DEFEND value: ", CardAbility.TriggerType.ON_DEFEND)
						
						if has_on_defend:
							print("Executing ON_DEFEND abilities for defending card: ", adjacent_card.card_name)
							
							var defend_context = {
								"defending_card": adjacent_card,
								"defending_position": adj_index,
								"attacking_card": attacking_card,
								"attacking_position": grid_index,
								"game_manager": self,
								"direction": direction.name,
								"card_level": defending_card_level
							}
							
							# Execute all ON_DEFEND abilities
							adjacent_card.execute_abilities(CardAbility.TriggerType.ON_DEFEND, defend_context, defending_card_level)
						else:
							print("DEBUG: No ON_DEFEND abilities found or level requirement not met")
	
	# Apply all captures and handle passive abilities
	for captured_index in captures:
		# Store the card data before changing ownership (for passive ability removal)
		var captured_card_data = grid_card_data[captured_index]
		
		# Remove passive abilities of the captured card BEFORE changing ownership
		handle_passive_abilities_on_capture(captured_index, captured_card_data)
		
		# Change ownership
		grid_ownership[captured_index] = attacking_owner
		print("Card at slot ", captured_index, " is now owned by ", "Player" if attacking_owner == Owner.PLAYER else "Opponent")
		
		# Check if the newly captured card has passive abilities and restart pulse effect
		var card_level = get_card_level(get_card_collection_index(captured_index))
		if captured_card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			print("Restarting passive abilities for captured card at position ", captured_index)
			
			# Re-add to passive abilities tracking
			if not captured_index in active_passive_abilities:
				active_passive_abilities[captured_index] = []
			
			var available_abilities = captured_card_data.get_available_abilities(card_level)
			for ability in available_abilities:
				if ability.trigger_condition == CardAbility.TriggerType.PASSIVE:
					active_passive_abilities[captured_index].append(ability)
			
			# Restart visual pulse effect for the captured card
			var card_display = get_card_display_at_position(captured_index)
			if card_display and visual_effects_manager:
				visual_effects_manager.start_passive_pulse(card_display)
	
	# Refresh all passive abilities to account for ownership changes
	if captures.size() > 0:
		refresh_all_passive_abilities()
	
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
	
	# DEBUG: Check the opponent card data
	print("=== OPPONENT CARD DEBUG ===")
	print("Card name: ", opponent_card_data.card_name)
	print("Card abilities count: ", opponent_card_data.abilities.size())
	if opponent_card_data.abilities.size() > 0:
		for i in range(opponent_card_data.abilities.size()):
			var ability = opponent_card_data.abilities[i]
			print("  Ability ", i, ": ", ability.ability_name, " - ", ability.description)
	print("===========================")
	
	# Mark the slot as occupied and set ownership
	grid_occupied[grid_index] = true
	grid_ownership[grid_index] = Owner.OPPONENT
	grid_card_data[grid_index] = opponent_card_data
	
	# Get the slot
	var slot = grid_slots[grid_index]
	
	# Create a card display for the opponent's card
	var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	
	# Add the card as a child of the slot panel FIRST
	slot.add_child(card_display)
	
	# Wait one frame to ensure _ready() is called and @onready variables are initialized
	await get_tree().process_frame
	
	# NOW setup the card display with the actual card data
	card_display.setup(opponent_card_data)
	
	# DEBUG: Verify the card display has the data
	print("=== CARD DISPLAY DEBUG ===")
	print("Card display card_data: ", card_display.card_data)
	if card_display.card_data:
		print("Card display abilities: ", card_display.card_data.abilities.size())
	else:
		print("ERROR: Card display card_data is null!")
	print("===========================")
	
	# Center the card within the slot (same as player cards)
	card_display.position = Vector2(
		(slot.custom_minimum_size.x - 100) / 2,  # Assuming card width is 100
		(slot.custom_minimum_size.y - 140) / 2   # Assuming card height is 140
	)
	
	# Set higher z-index so the card appears on top
	card_display.z_index = 1
	
	# Apply opponent styling
	card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
	
	# Connect hover signals AFTER setup - THIS IS THE KEY FIX
	# This ensures the card_data is properly set before hover events can fire
	card_display.card_hovered.connect(_on_card_hovered)
	card_display.card_unhovered.connect(_on_card_unhovered)
	
	# Check for passive abilities on opponent cards and start pulse effect
	var opponent_card_level = get_card_level(0)  # Opponent cards use level 0 for now
	if opponent_card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, opponent_card_level):
		print("Opponent card has passive abilities - starting pulse effect")
		
		# Store passive abilities for opponent card
		if not grid_index in active_passive_abilities:
			active_passive_abilities[grid_index] = []
		
		var available_abilities = opponent_card_data.get_available_abilities(opponent_card_level)
		for ability in available_abilities:
			if ability.trigger_condition == CardAbility.TriggerType.PASSIVE:
				active_passive_abilities[grid_index].append(ability)
		
		# Start visual pulse effect
		visual_effects_manager.start_passive_pulse(card_display)
	
	print("Opponent placed card: ", opponent_card_data.card_name, " at slot ", grid_index)
	print("Card abilities: ", opponent_card_data.abilities.size())
	for i in range(opponent_card_data.abilities.size()):
		var ability = opponent_card_data.abilities[i]
		print("  Ability ", i, ": ", ability.ability_name, " - ", ability.description)
	
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

func end_game():
	
	var tracker = get_node("/root/BossPredictionTrackerAutoload")
	if tracker:
		tracker.stop_recording()
	
	await get_tree().process_frame
	
	var scores = get_current_scores()
	var winner = ""
	var victory = false
	
	if scores.player > scores.opponent:
		winner = "You win!"
		victory = true
	elif scores.opponent > scores.player:
		winner = "You lose!"
		victory = false
	else:
		winner = "It's a tie!"
		victory = true  # Treat ties as victories for experience purposes
	
	# Record the enemy encounter in memory journal
	record_enemy_encounter(victory)
	
	# Record god experience (you used this god in battle)
	record_god_experience()
	
	if not victory:
		# If player loses, show run summary before ending
		game_status_label.text = "Defeat! " + winner
		disable_player_input()
		opponent_is_thinking = false
		turn_manager.end_game()
		
		# Add a delay then go to run summary
		await get_tree().create_timer(3.0).timeout
		
		# Pass data to summary screen
		var params = get_scene_params()
		get_tree().set_meta("scene_params", {
			"god": params.get("god", "Apollo"),
			"deck_index": params.get("deck_index", 0),
			"victory": false
		})
		get_tree().change_scene_to_file("res://Scenes/RunSummary.tscn")
		return
	
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
		
		# The experience tracker should already be initialized from the god selection screen
		print("Loading deck for battle - experience tracker should already be initialized")
		
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


# Helper method to get card at a specific grid position
func get_card_at_position(position: int) -> CardResource:
	if position >= 0 and position < grid_card_data.size():
		return grid_card_data[position]
	return null

# Helper method to get owner at a specific grid position  
func get_owner_at_position(position: int) -> Owner:
	if position >= 0 and position < grid_ownership.size():
		return grid_ownership[position]
	return Owner.NONE

# Helper method to get card level from experience system
func get_card_level(card_index: int) -> int:
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var exp_data = progress_tracker.get_card_total_experience("Apollo", card_index)
		var total_exp = exp_data.get("capture_exp", 0) + exp_data.get("defense_exp", 0)
		return ExperienceHelpers.calculate_level(total_exp)
	return 0


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
		
		# Connect hover signals for info panel
		card_display.card_hovered.connect(_on_card_hovered)
		card_display.card_unhovered.connect(_on_card_unhovered)


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

# Update the visual display of a card after its stats change
func update_card_display(grid_index: int, card_data: CardResource):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	var card_display = slot.get_child(0) if slot.get_child_count() > 0 else null
	
	if card_display and card_display.has_method("setup"):
		# Re-setup the card display with updated values
		card_display.setup(card_data)
		print("Updated card display for ", card_data.card_name, " with new values: ", card_data.values)



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
	var card_collection_index = deck_card_indices[selected_card_index]
	
	# Record this play for pattern tracking (if not boss battle)
	if not is_boss_battle:
		var tracker = get_node("/root/BossPredictionTrackerAutoload")
		if tracker:
			tracker.record_card_play(card_collection_index, current_grid_index)
	
	# Check boss prediction if this is a boss battle
	var boss_prediction_hit = false
	if is_boss_battle and current_boss_prediction.has("card") and current_boss_prediction.has("position"):
		if current_boss_prediction["card"] == card_collection_index and current_boss_prediction["position"] == current_grid_index:
			boss_prediction_hit = true
			print("BOSS PREDICTION HIT! The boss anticipated your move!")
			# Apply the stat reduction - weakens the card but doesn't change ownership
			card_data.values[0] = 1  # North
			card_data.values[1] = 1  # East
			card_data.values[2] = 1  # South
			card_data.values[3] = 1  # West
			
			# Show feedback to player
			game_status_label.text = "The boss anticipated your move! Your card's power is weakened!"
			
			# Show notification
			if notification_manager:
				notification_manager.show_notification("I knew you would go there")
	
	# Get card level for ability checks
	var card_level = get_card_level(card_collection_index)
	
	# Mark the slot as occupied and set ownership (always PLAYER - prediction hits don't change ownership)
	grid_occupied[current_grid_index] = true
	grid_ownership[current_grid_index] = Owner.PLAYER
	grid_card_data[current_grid_index] = card_data
	
	# Track which collection index this card is from
	grid_to_collection_index[current_grid_index] = card_collection_index
	
	# Get the current slot
	var slot = grid_slots[current_grid_index]
	
	# Create a card display for the grid
	var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	
	# Add the card as a child of the slot panel
	slot.add_child(card_display)
	
	# Center the card within the slot
	card_display.position = Vector2(
		(slot.custom_minimum_size.x - 100) / 2,  # Assuming card width is 100
		(slot.custom_minimum_size.y - 140) / 2   # Assuming card height is 140
	)
	
	# Set higher z-index so the card appears on top
	card_display.z_index = 1
	
	# Setup the card display with the card resource data (including potentially weakened stats)
	card_display.setup(card_data)
	
	# Apply player styling initially, but make prediction hits more visible
	if boss_prediction_hit:
		# Create a special style for predicted cards
		var prediction_hit_style = player_card_style.duplicate()
		prediction_hit_style.border_color = Color("#FF6B6B")  # Red border for prediction hits
		prediction_hit_style.border_width_left = 4
		prediction_hit_style.border_width_top = 4
		prediction_hit_style.border_width_right = 4
		prediction_hit_style.border_width_bottom = 4
		card_display.panel.add_theme_stylebox_override("panel", prediction_hit_style)
	else:
		card_display.panel.add_theme_stylebox_override("panel", player_card_style)
	
	# Connect hover signals for grid cards too
	card_display.card_hovered.connect(_on_card_hovered)
	card_display.card_unhovered.connect(_on_card_unhovered)
	
	print("Card placed on grid at position", current_grid_index)
	
	# EXECUTE ON-PLAY ABILITIES BEFORE COMBAT (but after potential stat reduction)
	if card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level):
		print("Executing on-play abilities for ", card_data.card_name)
		var ability_context = {
			"placed_card": card_data,
			"grid_position": current_grid_index,
			"game_manager": self,
			"card_level": card_level
		}
		card_data.execute_abilities(CardAbility.TriggerType.ON_PLAY, ability_context, card_level)
		
		# Update the visual display after abilities execute
		update_card_display(current_grid_index, card_data)
	
	# HANDLE PASSIVE ABILITIES
	handle_passive_abilities_on_place(current_grid_index, card_data, card_level)
	
	# Resolve combat (abilities may have modified stats, and boss prediction may have weakened the card)
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


# Handle passive abilities when a card is placed
func handle_passive_abilities_on_place(grid_position: int, card_data: CardResource, card_level: int):
	# Check if this card has passive abilities
	if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
		print("Handling passive abilities for ", card_data.card_name, " at position ", grid_position)
		
		# Store reference to this card's passive abilities
		if not grid_position in active_passive_abilities:
			active_passive_abilities[grid_position] = []
		
		var available_abilities = card_data.get_available_abilities(card_level)
		for ability in available_abilities:
			if ability.trigger_condition == CardAbility.TriggerType.PASSIVE:
				active_passive_abilities[grid_position].append(ability)
				
				# Execute the passive ability with "apply" action
				var passive_context = {
					"passive_action": "apply",
					"boosting_card": card_data,
					"boosting_position": grid_position,
					"game_manager": self,
					"card_level": card_level
				}
				
				ability.execute(passive_context)
		
		# Start visual pulse effect for passive abilities
		var card_display = get_card_display_at_position(grid_position)
		if card_display and visual_effects_manager:
			visual_effects_manager.start_passive_pulse(card_display)
	
	# Also trigger passive abilities of existing cards (in case they need to affect the new card)
	refresh_all_passive_abilities()

# Handle passive abilities when a card is captured/removed
func handle_passive_abilities_on_capture(grid_position: int, card_data: CardResource):
	if grid_position in active_passive_abilities:
		print("Removing passive abilities for captured card at position ", grid_position)
		
		# Stop visual pulse effect first
		var card_display = get_card_display_at_position(grid_position)
		if card_display and visual_effects_manager:
			visual_effects_manager.stop_passive_pulse(card_display)
		
		# Execute each passive ability with "remove" action
		for ability in active_passive_abilities[grid_position]:
			var passive_context = {
				"passive_action": "remove",
				"boosting_card": card_data,
				"boosting_position": grid_position,
				"game_manager": self
			}
			
			ability.execute(passive_context)
		
		# Remove from tracking
		active_passive_abilities.erase(grid_position)
	
	# Refresh remaining passive abilities
	refresh_all_passive_abilities()

# Refresh all passive abilities (useful when ownership changes)
func refresh_all_passive_abilities():
	print("Refreshing all passive abilities")
	
	# First remove all existing boosts
	for position in active_passive_abilities:
		var card_data = get_card_at_position(position)
		if card_data:
			for ability in active_passive_abilities[position]:
				var passive_context = {
					"passive_action": "remove",
					"boosting_card": card_data,
					"boosting_position": position,
					"game_manager": self
				}
				ability.execute(passive_context)
	
	# Then re-apply all boosts
	for position in active_passive_abilities:
		var card_data = get_card_at_position(position)
		if card_data:
			for ability in active_passive_abilities[position]:
				var passive_context = {
					"passive_action": "apply",
					"boosting_card": card_data,
					"boosting_position": position,
					"game_manager": self
				}
				ability.execute(passive_context)




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


# Lines 650-680 of apollo_game.gd - Updated memory recording functions

func record_enemy_encounter(victory: bool):
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var params = get_scene_params()
	
	# Get enemy info from current node
	var enemy_name = "Shadow Acolyte"  # Default
	var enemy_difficulty = 0
	
	if params.has("current_node"):
		var current_node = params["current_node"]
		enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
		enemy_difficulty = current_node.enemy_difficulty
	
	# Record the encounter with the simplified experience system
	memory_manager.record_enemy_encounter(enemy_name, victory, enemy_difficulty)
	print("Recorded enemy encounter: ", enemy_name, " (victory: ", victory, ", difficulty: ", enemy_difficulty, ")")

func record_god_experience():
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var params = get_scene_params()
	
	var god_name = params.get("god", "Apollo")
	var deck_index = params.get("deck_index", 0)
	
	# Get deck name for tracking
	var apollo_collection = load("res://Resources/Collections/Apollo.tres")
	var deck_name = ""
	if apollo_collection and deck_index < apollo_collection.decks.size():
		deck_name = apollo_collection.decks[deck_index].deck_name
	
	# Record the god experience
	memory_manager.record_god_experience(god_name, 1, deck_name)
	print("Recorded god experience: ", god_name, " with deck ", deck_name)
