# res://Scripts/card_battle_manager.gd
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
var deck_card_indices: Array[int] = []  # Original indices in god's collection
var exp_panel: ExpPanel  # Reference to experience panel
var grid_to_collection_index: Dictionary = {}  # grid_index -> collection_index

# Journal button reference  
var journal_button: JournalButton

# Current god and game state
var current_god: String = "Apollo"  # Default fallback

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

# Tutorial mode variables
var is_tutorial_mode: bool = false
var tutorial_god: String = ""
var tutorial_step: int = 0
var tutorial_overlay: Control
var tutorial_modal: AcceptDialog
var tutorial_panel: PanelContainer

var consecutive_draws: int = 0

# Deck power system
var active_deck_power: DeckDefinition.DeckPowerType = DeckDefinition.DeckPowerType.NONE
var sunlit_positions: Array[int] = []


func _ready():
	print("=== BATTLE SCENE STARTING ===")
	
	# Get the current god from scene parameters first
	var params = get_scene_params()
	print("Raw scene params: ", params)
	
	current_god = params.get("god", "Apollo")
	is_tutorial_mode = params.get("is_tutorial", false)
	tutorial_god = params.get("god", "Apollo") if is_tutorial_mode else current_god
	
	print("Battle scene starting with god: ", current_god, " (tutorial mode: ", is_tutorial_mode, ")")
	print("Tutorial god set to: ", tutorial_god)
	
	# IMPORTANT: For tutorial mode, ensure we're using the right variables
	if is_tutorial_mode and tutorial_god != current_god:
		print("Tutorial mode detected - adjusting current_god from ", current_god, " to ", tutorial_god)
		current_god = tutorial_god
	
	# Initialize game managers
	setup_managers()
	
	# Initialize boss prediction tracker
	setup_boss_prediction_tracker()
	
	# Initialize game board
	setup_empty_board()
	
	# Create styles for grid selection
	create_grid_styles()
	
	# Set up card info panel for smooth fading
	setup_card_info_panel()
	
	# Set up notification system
	setup_notification_manager()
	
	setup_tutorial_panel()
	
	if is_tutorial_mode:
		print("Starting tutorial mode with god: ", tutorial_god, " vs opponent: ", params.get("opponent", "Chronos"))
		# No special UI setup needed - just play normally
	
	# Add journal button (unless tutorial mode)
	setup_journal_button()
	
	if params.has("deck_index"):
		selected_deck_index = params.deck_index
		load_player_deck(selected_deck_index)
	else:
		push_error("No deck was selected!")
	
	# Start a new run for conversation tracking (if not tutorial)
	if not is_tutorial_mode and has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		conv_manager.start_new_run()
		print("CardBattle: Started new run for conversations")
	
	# Set up input handling (only when it's player's turn)
	set_process_input(false)  # Start disabled
	
	# Start the game
	start_game()

func setup_tutorial_ui():
	# Simplified - no modal dialogs, just play normally
	print("Tutorial mode: Simplified setup complete")

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

func setup_tutorial_panel():
	if not is_tutorial_mode:
		return  # Only show in tutorial mode
	
	# Create the tutorial panel
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	
	# Position in top-left corner with some margin
	tutorial_panel.position = Vector2(20, 20)
	tutorial_panel.custom_minimum_size = Vector2(300, 120)  # Same width as card info panel
	
	# Create panel style similar to card info panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A2A2A")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#555555")
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	tutorial_panel.add_theme_stylebox_override("panel", style)
	
	# Create margin container for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	tutorial_panel.add_child(margin)
	
	# Create content container
	var content = VBoxContainer.new()
	margin.add_child(content)
	
	# Tutorial title
	var title_label = Label.new()
	title_label.text = "Tutorial"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#FFD700"))  # Gold color
	content.add_child(title_label)
	
	# Tutorial text
	var text_label = Label.new()
	text_label.text = "Click a card to select it
	Click to place the card on the grid 
	Adjacent cards will fight each other
	Hover over cards to see more details
	"
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(text_label)
	
	# Add to the main scene
	add_child(tutorial_panel)
	
	print("Tutorial panel created and positioned")

# Add this call in _ready() function after setup_notification_manager():
# setup_tutorial_panel()

# Function to update tutorial text (you can call this to change the text)
func update_tutorial_text(new_text: String):
	if not tutorial_panel:
		return
	
	# Find the text label (it's the second child in the VBoxContainer)
	var margin = tutorial_panel.get_child(0)
	var content = margin.get_child(0)
	var text_label = content.get_child(1)  # Second child is the text label
	
	if text_label is Label:
		text_label.text = new_text


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
	if is_tutorial_mode:
		# Don't show journal button in tutorial
		print("Tutorial mode: Skipping journal button setup")
		return
	
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
		
		print("Battle Scene: Journal button added with CanvasLayer")

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
func setup_opponent_from_params():
	var params = get_scene_params()
	
	print("=== SETTING UP OPPONENT ===")
	print("Tutorial mode: ", is_tutorial_mode)
	print("Scene params: ", params)
	
	if is_tutorial_mode:
		# Tutorial mode - use specified opponent
		var opponent_name = params.get("opponent", "Chronos")
		print("Setting up tutorial opponent: ", opponent_name)
		
		# For tutorial, we'll manually set up Chronos since it might not be in the enemies collection properly
		if opponent_name == "Chronos":
			setup_chronos_opponent()
		else:
			print("Unknown tutorial opponent, using Shadow Acolyte")
			opponent_manager.setup_opponent("Shadow Acolyte", 0)  # Fallback
	else:
		# Normal mode setup...
		if params.has("current_node"):
			var current_node = params["current_node"]
			var enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
			var enemy_difficulty = current_node.enemy_difficulty
			
			print("Setting up opponent: ", enemy_name, " (difficulty ", enemy_difficulty, ")")
			opponent_manager.setup_opponent(enemy_name, enemy_difficulty)
		else:
			print("No enemy data found, using default Shadow Acolyte")
			opponent_manager.setup_opponent("Shadow Acolyte", 0)

func setup_chronos_opponent():
	print("Setting up Chronos as tutorial opponent")
	
	# Try to get Chronos from the enemies collection first
	var enemies_collection: EnemiesCollection = load("res://Resources/Collections/Enemies.tres")
	if enemies_collection:
		var chronos_enemy = enemies_collection.get_enemy("Chronos")
		if chronos_enemy and chronos_enemy.cards.size() > 0:
			print("Found Chronos in enemies collection with ", chronos_enemy.cards.size(), " cards")
			# Get the first deck (difficulty 0) for tutorial
			var chronos_deck = chronos_enemy.get_deck_by_difficulty(0)
			if chronos_deck.size() > 0:
				opponent_manager.opponent_deck = chronos_deck
				opponent_manager.opponent_name = "Chronos (Tutorial)"
				opponent_manager.opponent_description = "The Titan of Time teaches you the ways of battle"
				print("Successfully loaded Chronos deck with ", chronos_deck.size(), " cards")
				
				# Debug: Print card names
				for i in range(chronos_deck.size()):
					print("Chronos card ", i, ": ", chronos_deck[i].card_name)
				return
			else:
				print("Chronos deck is empty")
		else:
			print("Chronos enemy not found or has no cards")
	
	# Fallback: Use Shadow Acolyte if Chronos isn't working
	print("Chronos not found, falling back to Shadow Acolyte")
	if enemies_collection and enemies_collection.enemies.size() > 0:
		var fallback_enemy = enemies_collection.enemies[0]  # Should be Shadow Acolyte
		var fallback_deck = fallback_enemy.get_deck_by_difficulty(0)
		if fallback_deck.size() > 0:
			opponent_manager.opponent_deck = fallback_deck
			opponent_manager.opponent_name = "Chronos (using Shadow Acolyte cards)"
			opponent_manager.opponent_description = "Tutorial opponent"
			print("Using fallback deck with ", fallback_deck.size(), " cards")
		else:
			print("ERROR: Even fallback enemy has no cards!")

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

func start_game():
	if is_tutorial_mode:
		game_status_label.text = "Tutorial: Learning the Basics"
		# Simple tutorial setup - just start the game normally
		turn_manager.is_game_active = true
		turn_manager.current_player = TurnManager.Player.HUMAN
		enable_player_input()
		update_game_status()
		print("Tutorial started as normal game - player can immediately play cards")
	else:
		game_status_label.text = "Flipping coin to determine who goes first..."
		disable_player_input()
		turn_manager.start_game()

# Remove all the tutorial step functions and replace with simple status messages
func get_tutorial_status_message() -> String:
	return "Select a card and place it on the grid"






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
	
	# Special handling for tutorial mode
	if is_tutorial_mode:
		print("Tutorial mode: Game started, waiting for tutorial flow")
		# Don't enable input here - let tutorial flow handle it
		return
	
	# Normal game mode: If it's opponent's turn, let them play
	if turn_manager.is_opponent_turn():
		print("Starting opponent's first turn")
		call_deferred("opponent_take_turn")

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
	
	# Debug output for tutorial
	if is_tutorial_mode:
		print("UPDATE_GAME_STATUS - Tutorial mode:")
		print("  is_game_active: ", turn_manager.is_game_active)
		print("  current_player: ", turn_manager.current_player)
		print("  is_player_turn(): ", turn_manager.is_player_turn())
		print("  tutorial_step: ", tutorial_step)
	
	if is_tutorial_mode:
		# Special tutorial status messages
		if turn_manager.is_player_turn():
			game_status_label.text = "Tutorial: Your Turn - " + get_tutorial_status_message()
		else:
			game_status_label.text = "Tutorial: Chronos is thinking..."
			print("ERROR: Tutorial thinks it's opponent's turn!")
	elif turn_manager.is_player_turn():
		game_status_label.text = "Your Turn - Select a card and place it"
	else:
		var opponent_info = opponent_manager.get_opponent_info()
		game_status_label.text = "Opponent's Turn - " + opponent_info.name + " is thinking..."
	
	# Update to show scores instead of card counts
	deck_name_label.text = "Score - Player: " + str(scores.player) + " | Opponent: " + str(scores.opponent)



func enable_player_input():
	set_process_input(true)
	print("Tutorial: Player input ENABLED")

func disable_player_input():
	set_process_input(false)
	print("Tutorial: Player input DISABLED")
	
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

# Add this helper method to set card ownership
func set_card_ownership(grid_index: int, new_owner: Owner):
	if grid_index >= 0 and grid_index < grid_ownership.size():
		grid_ownership[grid_index] = new_owner
		print("Card at slot ", grid_index, " ownership changed to ", "Player" if new_owner == Owner.PLAYER else "Opponent")

# This replaces the existing resolve_combat function
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
	
	# Hide sun icon if opponent places card on sunlit slot (blocks the power)
	hide_sun_icon_at_slot(slot)
	
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
	# Tutorial ending - different flow
	if is_tutorial_mode:
		game_status_label.text = "Tutorial Complete!"
		disable_player_input()
		opponent_is_thinking = false
		turn_manager.end_game()
		
		# Create and show tutorial completion dialog
		var tutorial_dialog = AcceptDialog.new()
		tutorial_dialog.dialog_text = "Chronos crushes you"
		tutorial_dialog.title = "Tutorial Complete"
		add_child(tutorial_dialog)
		tutorial_dialog.popup_centered()
		tutorial_dialog.confirmed.connect(_on_tutorial_finished, CONNECT_ONE_SHOT)
		return
	
	var tracker = get_node("/root/BossPredictionTrackerAutoload")
	if tracker:
		tracker.stop_recording()
	
	await get_tree().process_frame
	
	var scores = get_current_scores()
	var winner = ""
	var victory = false
	
	if scores.player > scores.opponent:
		# Check for perfect victory - player owns all 9 cards on the board
		var total_board_cards = 0
		var player_owned_cards = 0
		
		for i in range(grid_ownership.size()):
			if grid_occupied[i]:  # If there's a card in this slot
				total_board_cards += 1
				if grid_ownership[i] == Owner.PLAYER:
					player_owned_cards += 1
		
		print("=== PERFECT VICTORY CHECK ===")
		print("Total cards on board: ", total_board_cards)
		print("Player owned cards: ", player_owned_cards)
		print("Grid occupied: ", grid_occupied)
		print("Grid ownership: ", grid_ownership)
		print("============================")
		
		# Perfect victory = board is full (9 cards) and player owns ALL of them
		var is_perfect_victory = (total_board_cards == 9 and player_owned_cards == 9)
		
		print("Perfect victory achieved: ", is_perfect_victory)
		
		if is_perfect_victory:
			winner = "🏆 Perfect Victory! 🏆"
			# Show special notification for perfect victory
			if notification_manager:
				notification_manager.show_notification("🏆 PERFECT VICTORY ACHIEVED! 🏆")
			# Make the text gold colored
			game_status_label.add_theme_color_override("font_color", Color("#FFD700"))
		else:
			winner = "You win!"
		
		victory = true
		consecutive_draws = 0  # Reset draw counter on victory
	elif scores.opponent > scores.player:
		winner = "You lose!"
		victory = false
		consecutive_draws = 0  # Reset draw counter on loss
	else:
		# Handle draw
		consecutive_draws += 1
		
		if consecutive_draws >= 2:
			# Second consecutive draw counts as a loss
			winner = "Second draw in a row - You lose!"
			victory = false
			consecutive_draws = 0  # Reset for next encounter
			
			# Record the enemy encounter as a loss
			record_enemy_encounter(false)
			
			# Record god experience (you used this god in battle)
			record_god_experience()
			
			# Trigger conversation flags based on battle outcome
			if has_node("/root/ConversationManagerAutoload"):
				var conv_manager = get_node("/root/ConversationManagerAutoload")
				
				# Check if this was a boss battle
				if is_boss_battle:
					print("Triggering first_boss_loss conversation")
					conv_manager.trigger_conversation("first_boss_loss")
				else:
					print("Triggering first_run_defeat conversation")
					conv_manager.trigger_conversation("first_run_defeat")
			
			# Show defeat message and go to summary
			game_status_label.text = "Defeat! " + winner
			disable_player_input()
			opponent_is_thinking = false
			turn_manager.end_game()
			
			# Add a delay then go to run summary
			await get_tree().create_timer(3.0).timeout
			
			# Pass data to summary screen
			var params = get_scene_params()
			get_tree().set_meta("scene_params", {
				"god": params.get("god", current_god),
				"deck_index": params.get("deck_index", 0),
				"victory": false
			})
			get_tree().change_scene_to_file("res://Scenes/RunSummary.tscn")
			return
		else:
			# First draw - restart the round
			winner = "It's a draw! Restarting round... (Warning: Second draw will count as defeat)"
			game_status_label.text = winner
			
			# Reset the game state for a new round
			restart_round()
			return  # Exit early, don't proceed with normal end game logic
	
	# Record the enemy encounter in memory journal
	record_enemy_encounter(victory)
	
	# Record god experience (you used this god in battle)
	record_god_experience()
	
	# Trigger conversation flags based on battle outcome
	if has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		
		if not victory:
			# Check if this was a boss battle
			if is_boss_battle:
				print("Triggering first_boss_loss conversation")
				conv_manager.trigger_conversation("first_boss_loss")
			else:
				print("Triggering first_run_defeat conversation")
				conv_manager.trigger_conversation("first_run_defeat")
	
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
			"god": params.get("god", current_god),
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


# Add this new function to Scripts/card_battle_manager.gd
func restart_round():
	print("Restarting round due to draw")
	
	# Clear the grid
	for i in range(grid_slots.size()):
		if grid_occupied[i]:
			var slot = grid_slots[i]  # Get the slot reference
			# Remove card display if present
			for child in slot.get_children():
				child.queue_free()
		
		# Reset grid state
		grid_occupied[i] = false
		grid_ownership[i] = Owner.NONE
		grid_card_data[i] = null
		
		# Reset slot styling - get slot reference again
		var slot = grid_slots[i]
		slot.add_theme_stylebox_override("panel", default_grid_style)
	
	# Clear grid to collection index mapping
	grid_to_collection_index.clear()
	
	# Reset passive abilities tracking
	active_passive_abilities.clear()
	
	# Reset card selection
	selected_card_index = -1
	current_grid_index = -1
	
	# Reset opponent thinking state
	opponent_is_thinking = false
	
	# Restore original decks (you'll need to reload them)
	restore_original_decks()
	
	# Redisplay player hand
	display_player_hand()
	
	# Start a new coin flip
	await get_tree().create_timer(2.0).timeout  # Brief pause
	turn_manager.start_game()

func restore_original_decks():
	# Reload player deck
	var params = get_scene_params()
	var god_name = params.get("god", current_god)
	var deck_index = params.get("deck_index", 0)
	
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	if collection:
		var deck_def = collection.decks[deck_index]
		deck_card_indices = deck_def.card_indices.duplicate()
		player_deck = collection.get_deck(deck_index)
	
	# Reload opponent deck
	setup_opponent_from_params()  # This will reload their deck




func _on_tutorial_finished():
	print("Tutorial battle completed, transitioning to post-battle cutscene")
	
	# Trigger the post-battle cutscene (which is the existing "opening_awakening")
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").play_cutscene("opening_awakening")
	else:
		# Fallback if cutscene manager isn't available
		get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# Return to the map after completing an encounter
func return_to_map():
	# Get the current map data and node info
	var params = get_scene_params()
	if params.has("map_data"):
		# Pass the updated map data back to the map scene
		get_tree().set_meta("scene_params", {
			"god": params.get("god", current_god),
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
	selected_grid_style.bg_color = Color("#444444")  # Same background
	selected_grid_style.border_width_left = 2
	selected_grid_style.border_width_top = 2
	selected_grid_style.border_width_right = 2
	selected_grid_style.border_width_bottom = 2
	selected_grid_style.border_color = Color("#44AAFF")  # Bright blue highlight
	
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

func load_player_deck(deck_index: int):
	print("=== LOADING PLAYER DECK ===")
	print("Tutorial mode: ", is_tutorial_mode)
	print("Tutorial god: ", tutorial_god)
	print("Current god: ", current_god)
	print("Deck index: ", deck_index)
	
	var collection_path: String
	var collection: GodCardCollection
	
	if is_tutorial_mode:
		# Tutorial mode - use tutorial god, but ensure it's set correctly
		var god_to_use = tutorial_god if tutorial_god != "" else current_god
		if god_to_use == "":
			god_to_use = "Mnemosyne"  # Force default for tutorial
		
		print("Tutorial mode detected - using god: ", god_to_use)
		collection_path = "res://Resources/Collections/" + god_to_use + ".tres"
		print("Loading tutorial collection from: ", collection_path)
		
		collection = load(collection_path)
		if collection:
			print(god_to_use, " collection loaded successfully")
			print(god_to_use, " has ", collection.cards.size(), " cards")
			print(god_to_use, " has ", collection.decks.size(), " deck definitions")
			
			# Check if the god has deck definitions
			if collection.decks.size() > 0:
				# Use the first deck definition for tutorial
				var deck_def = collection.decks[0]
				player_deck = collection.get_deck(0)
				deck_card_indices = deck_def.card_indices.duplicate()
				
				# NEW: Initialize deck power (even in tutorial mode)
				initialize_deck_power(deck_def)
				
				print("Using deck definition: ", deck_def.deck_name)
				print("Card indices: ", deck_card_indices)
			else:
				# Fallback: use first 5 cards if no deck definitions
				player_deck = []
				deck_card_indices = []
				var cards_to_use = min(5, collection.cards.size())
				for i in range(cards_to_use):
					player_deck.append(collection.cards[i])
					deck_card_indices.append(i)
				print("No deck definitions found, using first ", cards_to_use, " cards")
			
			print("Final player deck size: ", player_deck.size())
			
			# Debug: Print card names
			for i in range(player_deck.size()):
				if player_deck[i]:
					print("Player card ", i, ": ", player_deck[i].card_name)
				else:
					print("Player card ", i, ": NULL")
			
			display_player_hand()
			return
		else:
			print("ERROR: Failed to load ", god_to_use, " collection from ", collection_path)
			# Fallback to Apollo if the specified god fails
			print("Trying fallback to Apollo collection...")
			collection_path = "res://Resources/Collections/Apollo.tres"
			collection = load(collection_path)
			if collection:
				player_deck = collection.get_deck(0)
				deck_card_indices = collection.decks[0].card_indices.duplicate()
				
				# NEW: Initialize deck power for fallback
				initialize_deck_power(collection.decks[0])
				
				print("Fallback successful - using Apollo deck")
				display_player_hand()
				return
			else:
				print("CRITICAL ERROR: Even Apollo fallback failed!")
				return
	else:
		# Normal mode - load the specified god collection
		collection_path = "res://Resources/Collections/" + current_god + ".tres"
	
	print("Loading collection from: ", collection_path)
	collection = load(collection_path)
	if collection:
		print("Collection loaded successfully with ", collection.cards.size(), " cards")
		# Continue with normal loading...
		var deck_def = collection.decks[deck_index]
		deck_card_indices = deck_def.card_indices.duplicate()
		player_deck = collection.get_deck(deck_index)
		
		# NEW: Initialize deck power
		initialize_deck_power(deck_def)
		
		setup_experience_panel()
		display_player_hand()
	else:
		push_error("Failed to load collection: " + collection_path)


func initialize_deck_power(deck_def: DeckDefinition):
	active_deck_power = deck_def.deck_power_type
	
	print("Initializing deck power: ", active_deck_power)
	
	match active_deck_power:
		DeckDefinition.DeckPowerType.SUN_POWER:
			setup_sun_power()
		DeckDefinition.DeckPowerType.NONE:
			print("No deck power for this deck")
		_:
			print("Unknown deck power type: ", active_deck_power)

func setup_sun_power():
	print("=== SETTING UP SUN POWER ===")
	
	# Randomly select 3 grid positions for sunlight
	var available_positions: Array[int] = []
	for i in range(9):  # 0-8 for 3x3 grid
		available_positions.append(i)
	available_positions.shuffle()
	
	# Take first 3 positions
	sunlit_positions = available_positions.slice(0, 3)
	
	print("Sunlit positions: ", sunlit_positions)
	
	# Apply visual styling to sunlit grid slots
	for position in sunlit_positions:
		apply_sunlit_styling(position)
	
	# Show notification about the power
	if notification_manager:
		notification_manager.show_notification("☀️ Solar Blessing Active: 3 grid spaces are bathed in sunlight!")

func apply_sunlit_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	
	# Create sunlit style - golden/yellow border
	var sunlit_style = StyleBoxFlat.new()
	sunlit_style.bg_color = Color("#444444")  # Same as default
	sunlit_style.border_width_left = 3
	sunlit_style.border_width_top = 3
	sunlit_style.border_width_right = 3
	sunlit_style.border_width_bottom = 3
	sunlit_style.border_color = Color("#FFD700")  # Gold border
	
	# Apply the sunlit styling
	slot.add_theme_stylebox_override("panel", sunlit_style)
	
	# Add sun icon overlay
	add_sun_icon_to_slot(slot)

func apply_deck_power_effects(card_data: CardResource, grid_position: int) -> bool:
	match active_deck_power:
		DeckDefinition.DeckPowerType.SUN_POWER:
			return apply_sun_power_boost(card_data, grid_position)
		DeckDefinition.DeckPowerType.NONE:
			return false
		_:
			return false

func apply_sun_boosted_card_styling(card_display: CardDisplay):
	# Safety check to ensure we have a valid CardDisplay with a panel
	if not card_display or not is_instance_valid(card_display):
		print("ERROR: Invalid card_display in apply_sun_boosted_card_styling")
		return
	
	if not card_display.panel:
		print("ERROR: CardDisplay has no panel in apply_sun_boosted_card_styling")
		return
	
	# Create special golden styling for sun-boosted cards
	var sun_boosted_style = player_card_style.duplicate()
	sun_boosted_style.border_color = Color("#FFD700")  # Gold border
	sun_boosted_style.border_width_left = 4
	sun_boosted_style.border_width_top = 4
	sun_boosted_style.border_width_right = 4
	sun_boosted_style.border_width_bottom = 4
	
	# Add a slight golden background tint
	sun_boosted_style.bg_color = Color("#555533")  # Slightly golden background
	
	card_display.panel.add_theme_stylebox_override("panel", sun_boosted_style)

func hide_sun_icon_at_slot(slot: Panel):
	var sun_icon = slot.get_node_or_null("SunIcon")
	if sun_icon:
		sun_icon.visible = false


func apply_sun_power_boost(card_data: CardResource, grid_position: int) -> bool:
	if grid_position in sunlit_positions:
		print("☀️ SUN POWER ACTIVATED! Boosting card stats by +1")
		
		# Apply +1 to all stats
		card_data.values[0] += 1  # North
		card_data.values[1] += 1  # East
		card_data.values[2] += 1  # South
		card_data.values[3] += 1  # West
		
		print("Card stats boosted to: ", card_data.values)
		
		# Show notification
		if notification_manager:
			notification_manager.show_notification("☀️ Solar Blessing: +1 to all stats!")
		
		return true
	
	return false


func add_sun_icon_to_slot(slot: Panel):
	# Create a label with sun emoji
	var sun_label = Label.new()
	sun_label.text = "☀️"
	sun_label.add_theme_font_size_override("font_size", 20)
	sun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sun_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sun_label.name = "SunIcon"
	sun_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't interfere with clicks
	
	# Position it in the center of the slot
	sun_label.set_anchors_preset(Control.PRESET_CENTER)
	sun_label.position = Vector2(slot.size.x/2 - 15, slot.size.y/2 - 15)
	sun_label.size = Vector2(30, 30)
	
	# Add with lower z-index so cards appear on top
	slot.add_child(sun_label)
	sun_label.z_index = -1


# Add new function to set up experience panel
func setup_experience_panel():
	# Don't create experience panel in tutorial mode
	if is_tutorial_mode:
		print("Tutorial mode: Skipping experience panel setup")
		return
		
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
		var exp_data = progress_tracker.get_card_total_experience(current_god, card_index)
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
		
		# Wait one frame to ensure the card display is fully ready
		await get_tree().process_frame
		
		# Position the card explicitly with the new spacing
		card_display.position.x = start_x + i * total_spacing
		
		# Setup the card with its data
		card_display.setup(card)
		
		# ALWAYS connect hover signals for info panel (regardless of tutorial mode)
		card_display.card_hovered.connect(_on_card_hovered)
		card_display.card_unhovered.connect(_on_card_unhovered)
		print("Tutorial: Connected hover signals for card ", i, ": ", card.card_name)
		
		# DEBUG: Check if panel exists and is ready
		if not card_display.panel:
			print("ERROR: Card display panel is null for card ", i)
			continue
		
		print("Card ", i, " panel mouse filter: ", card_display.panel.mouse_filter)
		print("Card ", i, " panel size: ", card_display.panel.size)
		print("Card ", i, " panel position: ", card_display.panel.position)
		
		# Make sure the panel can receive input
		card_display.panel.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Connect to detect clicks on the card - try multiple approaches
		
		
		card_display.panel.gui_input.connect(_on_card_gui_input.bind(card_display, i))
		print("Tutorial: Connected panel gui_input for card ", i)
		
		# Approach 3: Test if the CardDisplay itself has input handling
		if card_display.has_signal("input_event"):
			card_display.input_event.connect(_on_card_input_event.bind(card_display, i))
			print("Tutorial: Connected CardDisplay input_event for card ", i)


func _on_card_input_event(viewport, event, shape_idx, card_display, card_index):
	print("=== CARD INPUT EVENT ===")
	print("Event: ", event)
	print("Card index: ", card_index)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_card_selection(card_display, card_index)

# Extract the card selection logic into a separate function

# Replace the handle_card_selection function in Scripts/card_battle_manager.gd (around lines 275-315)

func handle_card_selection(card_display, card_index):
	print("=== HANDLING CARD SELECTION ===")
	print("Card index: ", card_index)
	print("Tutorial mode: ", is_tutorial_mode)
	print("Is player turn: ", turn_manager.is_player_turn())
	print("Current selected_card_index: ", selected_card_index)
	
	# In tutorial mode, FORCE allow card selection regardless of turn state
	if is_tutorial_mode:
		print("Tutorial mode: Allowing card selection")
	elif not turn_manager.is_player_turn():
		print("Not tutorial and not player turn - blocking selection")
		return
	
	# Validate that we have a valid card index
	if card_index >= player_deck.size():
		print("Invalid card index: ", card_index)
		return
	
	# FIRST: Deselect ALL cards before selecting the new one
	var cards_container = hand_container.get_node_or_null("CardsContainer")
	if cards_container:
		print("Deselecting all cards in hand...")
		for child in cards_container.get_children():
			if child is CardDisplay:
				if child.is_selected:
					print("  Deselecting card: ", child.get_card_data().card_name if child.get_card_data() else "Unknown")
					child.deselect()
	
	# SECOND: Select the new card
	print("Selecting new card: ", player_deck[card_index].card_name)
	card_display.select()
	selected_card_index = card_index
	
	# Initialize grid selection if not already set
	if current_grid_index == -1:
		# Find the first unoccupied grid slot
		for i in range(grid_slots.size()):
			if not grid_occupied[i]:
				current_grid_index = i
				grid_slots[i].add_theme_stylebox_override("panel", selected_grid_style)
				print("Auto-selected grid slot ", i)
				break
	
	print("Card selection complete - selected_card_index is now: ", selected_card_index)

# Handle card input events
func _on_card_gui_input(event, card_display, card_index):
	print("=== CARD INPUT RECEIVED ===")
	print("Event: ", event)
	print("Card index: ", card_index)
	print("Input processing enabled: ", is_processing_input())
	print("Tutorial mode: ", is_tutorial_mode)
	print("Turn manager active: ", turn_manager.is_game_active)
	print("Is player turn: ", turn_manager.is_player_turn())
	
	# In tutorial mode, FORCE allow card selection regardless of turn state
	if is_tutorial_mode:
		print("Tutorial mode: Allowing card input")
	elif not turn_manager.is_player_turn():
		print("Not tutorial and not player turn - blocking input")
		return
		
	if event is InputEventMouseButton:
		print("Mouse button event - button:", event.button_index, " pressed:", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Left click confirmed on card ", card_index)
			
			# Validate that we have a valid card index
			if card_index >= player_deck.size():
				print("Invalid card index: ", card_index)
				return
			
			# Use the improved handle_card_selection function
			handle_card_selection(card_display, card_index)
	else:
		print("Non-mouse event received: ", event.get_class())

func _on_grid_mouse_entered(grid_index):
	if not turn_manager.is_player_turn():
		return
	
	# Only apply selection highlight if a card is selected and slot is not occupied
	if selected_card_index != -1 and not grid_occupied[grid_index]:
		# Clear the previous selection highlight
		if current_grid_index != -1:
			grid_slots[current_grid_index].add_theme_stylebox_override("panel", default_grid_style)
		
		# Update the current selection to the hovered slot
		current_grid_index = grid_index
		grid_slots[grid_index].add_theme_stylebox_override("panel", selected_grid_style)
	

func _on_grid_mouse_exited(grid_index):
	if not turn_manager.is_player_turn():
		return
	
	# If this slot is not the currently selected one, make sure it has default style
	if current_grid_index != grid_index and not grid_occupied[grid_index]:
		grid_slots[grid_index].add_theme_stylebox_override("panel", default_grid_style)

# Grid click handler (only during player's turn)
func _on_grid_gui_input(event, grid_index):
	if not turn_manager.is_player_turn():
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Only place card if a card is selected and grid is not occupied
			if selected_card_index != -1 and not grid_occupied[grid_index]:
				# The grid selection is already handled by mouse_entered
				# Just place the card
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
	
	# NEW: Apply deck power effects before combat
	var sun_boosted = apply_deck_power_effects(card_data, current_grid_index)
	
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
	
	# Hide sun icon if present (card is now covering it)
	hide_sun_icon_at_slot(slot)
	
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
	
	# Setup the card display with the card resource data (including potentially boosted stats)
	card_display.setup(card_data)
	
	# Apply special styling for sun-boosted cards
	if sun_boosted:
		apply_sun_boosted_card_styling(card_display)
	elif boss_prediction_hit:
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
	
	# EXECUTE ON-PLAY ABILITIES BEFORE COMBAT (but after potential stat changes)
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
	
	# Resolve combat (abilities may have modified stats, and deck powers may have boosted the card)
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
	
	# Check for perfect victory using board ownership
	var total_board_cards = 0
	var player_owned_cards = 0
	
	for i in range(grid_ownership.size()):
		if grid_occupied[i]:  # If there's a card in this slot
			total_board_cards += 1
			if grid_ownership[i] == Owner.PLAYER:
				player_owned_cards += 1
	
	var is_perfect_victory = (total_board_cards == 9 and player_owned_cards == 9)
	
	print("=== REWARD SCREEN PERFECT VICTORY CHECK ===")
	print("Total board cards: ", total_board_cards)
	print("Player owned cards: ", player_owned_cards)
	print("Perfect victory: ", is_perfect_victory)
	print("=========================================")
	
	get_tree().set_meta("scene_params", {
		"god": params.get("god", current_god),
		"deck_index": params.get("deck_index", 0),
		"map_data": params.get("map_data"),
		"current_node": params.get("current_node"),
		"perfect_victory": is_perfect_victory
	})
	get_tree().change_scene_to_file("res://Scenes/RewardScreen.tscn")

# Record memory functions - updated to use current god
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
	
	var god_name = params.get("god", current_god)
	var deck_index = params.get("deck_index", 0)
	
	# Get deck name for tracking
	var god_collection = load("res://Resources/Collections/" + god_name + ".tres")
	var deck_name = ""
	if god_collection and deck_index < god_collection.decks.size():
		deck_name = god_collection.decks[deck_index].deck_name
	
	# Record the god experience
	memory_manager.record_god_experience(god_name, 1, deck_name)
	print("Recorded god experience: ", god_name, " with deck ", deck_name)
