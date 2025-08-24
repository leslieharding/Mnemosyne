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

var active_enemy_deck_power: EnemyDeckDefinition.EnemyDeckPowerType = EnemyDeckDefinition.EnemyDeckPowerType.NONE
var darkness_shroud_active: bool = false

# Tremor tracking system
var active_tremors: Dictionary = {}  # tremor_id -> tremor_data
var tremor_id_counter: int = 0

var couple_definitions = {
	"Phaeton": "Cygnus",
	"Cygnus": "Phaeton", 
	"Orpheus": "Euridyce",
	"Euridyce": "Orpheus"
}
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
var hunt_target_style: StyleBoxFlat


# Game managers
var turn_manager: TurnManager
var opponent_manager: OpponentManager
var visual_effects_manager: VisualEffectsManager

# State management to prevent multiple opponent turns
var opponent_is_thinking: bool = false

# Notification system
var notification_manager: NotificationManager

# Hunt tracking system
var hunt_mode_active: bool = false
var current_hunter_position: int = -1
var current_hunter_owner: Owner = Owner.NONE
var current_hunter_card: CardResource = null
var active_hunts: Dictionary = {}  # target_position -> hunt_data
var hunt_id_counter: int = 0

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
	
	# Create styles for grid selection
	create_grid_styles()
	
	
	# Initialize game managers
	setup_managers()
	
	# Initialize boss prediction tracker
	setup_boss_prediction_tracker()
	
	# Initialize game board
	setup_empty_board()
	
	
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
			
			# REMOVED: Enemy deck power initialization moved to start_game()
		else:
			print("No enemy data found, using default Shadow Acolyte")
			opponent_manager.setup_opponent("Shadow Acolyte", 0)


func initialize_enemy_deck_power(deck_def: EnemyDeckDefinition):
	active_enemy_deck_power = deck_def.deck_power_type
	
	print("Initializing enemy deck power: ", active_enemy_deck_power)
	
	match active_enemy_deck_power:
		EnemyDeckDefinition.EnemyDeckPowerType.DARKNESS_SHROUD:
			setup_darkness_shroud()
		
		EnemyDeckDefinition.EnemyDeckPowerType.NONE:
			print("No enemy deck power for this deck")
		_:
			print("Unknown enemy deck power type: ", active_enemy_deck_power)

func setup_darkness_shroud():
	print("=== SETTING UP DARKNESS SHROUD ===")
	darkness_shroud_active = true
	
	# Check if player has sun power active
	if active_deck_power == DeckDefinition.DeckPowerType.SUN_POWER:
		print("🌑 Darkness Shroud activated! The cultists' shadows nullify the sun's blessing.")
		
		# IMPORTANT: Clear sunlit positions FIRST, then restore styling
		var positions_to_restore = sunlit_positions.duplicate()  # Save the positions
		sunlit_positions.clear()  # Clear the array so restore_slot_original_styling works properly
		
		# Now remove sun styling from all formerly sunlit positions
		for position in positions_to_restore:
			restore_slot_original_styling(position)
		
		# Show notification
		if notification_manager:
			notification_manager.show_notification("🌑 The shadows swallow the light...")
		
		# Update game status to show the power clash
		game_status_label.text = "🌑 Darkness Shroud nullifies Solar Blessing! No sun bonuses this battle."
	else:
		print("🌑 Darkness Shroud activated! No sun power to counter, but shadows linger.")
		
		# Show notification even if no sun power to counter
		if notification_manager:
			notification_manager.show_notification("🌑 Shadows gather on the battlefield...")



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
	
	# Check if timer is still valid and in tree before starting
	if panel_grace_timer and is_instance_valid(panel_grace_timer) and panel_grace_timer.is_inside_tree():
		panel_grace_timer.start()
	else:
		# If timer is invalid, skip grace period and go straight to fade out
		_on_grace_period_expired()

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
	
	# Reset consecutive draws counter for new battle
	consecutive_draws = 0
	
	# MOVE enemy deck power initialization HERE - before player deck power effects
	var params = get_scene_params()
	if not is_tutorial_mode and params.has("current_node"):
		var current_node = params["current_node"]
		var enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
		var enemy_difficulty = current_node.enemy_difficulty
		
		# Initialize enemy deck power EARLY
		var deck_def = opponent_manager.get_current_deck_definition()
		if deck_def and deck_def.deck_power_type != EnemyDeckDefinition.EnemyDeckPowerType.NONE:
			print("Early enemy deck power initialization: ", deck_def.get_power_description())
			initialize_enemy_deck_power(deck_def)
	
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
	# Override coin flip result if prophecy power is active
	if active_deck_power == DeckDefinition.DeckPowerType.PROPHECY_POWER:
		player_goes_first = true
		game_status_label.text = "🔮 Divine Prophecy reveals the path! You go first."
		# Force the turn manager to recognize player goes first
		turn_manager.current_player = TurnManager.Player.HUMAN
		
		# Still activate boss prediction tracking if not a boss battle
		if not is_boss_battle:
			get_node("/root/BossPredictionTrackerAutoload").start_recording_battle()
			# Show atmospheric notification
			if notification_manager:
				notification_manager.show_notification("You know you are being watched")
	elif player_goes_first:
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

func _on_turn_changed(is_player_turn: bool):
	print("Turn changed - is_player_turn: ", is_player_turn, " | opponent_is_thinking: ", opponent_is_thinking)
	update_game_status()
	
	# Process adaptive defense abilities on turn change
	handle_adaptive_defense_turn_change(is_player_turn)
	
	# Process tremors at the start of each player's turn
	if is_player_turn:
		process_tremors_for_player(Owner.PLAYER)
		enable_player_input()
		if is_boss_battle:
			make_boss_prediction()
	else:
		process_tremors_for_player(Owner.OPPONENT)
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
		# Look through all children to find the CardDisplay (ignore hunt icons and other UI elements)
		for child in slot.get_children():
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

func update_game_status():
	var scores = get_current_scores()
	
	# Debug output for tutorial
	if is_tutorial_mode:
		print("UPDATE_GAME_STATUS - Tutorial mode:")
		print("  is_game_active: ", turn_manager.is_game_active)
		print("  current_player: ", turn_manager.current_player)
		print("  is_player_turn(): ", turn_manager.is_player_turn())
		print("  tutorial_step: ", tutorial_step)
	
	# Check for special power status messages
	var special_status = ""
	
	# Check if darkness shroud countered sun power
	if darkness_shroud_active and active_deck_power == DeckDefinition.DeckPowerType.SUN_POWER:
		special_status = "🌑 Darkness Shroud vs ☀️ Solar Blessing - Shadows prevail! "
	elif darkness_shroud_active:
		special_status = "🌑 Darkness Shroud active - Shadows gather... "
	elif active_enemy_deck_power != EnemyDeckDefinition.EnemyDeckPowerType.NONE:
		# Show other enemy power status
		match active_enemy_deck_power:
			EnemyDeckDefinition.EnemyDeckPowerType.TITAN_STRENGTH:
				special_status = "⚡ Titan Strength empowers your enemies! "
			EnemyDeckDefinition.EnemyDeckPowerType.PLAGUE_CURSE:
				special_status = "☠️ Plague Curse spreads corruption! "
	
	if is_tutorial_mode:
		# Special tutorial status messages
		if turn_manager.is_player_turn():
			game_status_label.text = special_status + "Tutorial: Your Turn - " + get_tutorial_status_message()
		else:
			game_status_label.text = special_status + "Tutorial: Chronos is thinking..."
			print("ERROR: Tutorial thinks it's opponent's turn!")
	elif turn_manager.is_player_turn():
		game_status_label.text = special_status + "Your Turn - Select a card and place it"
	else:
		var opponent_info = opponent_manager.get_opponent_info()
		game_status_label.text = special_status + "Opponent's Turn - " + opponent_info.name + " is thinking..."
	
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

# helper method to set card ownership
func set_card_ownership(grid_index: int, new_owner: Owner):
	if grid_index >= 0 and grid_index < grid_ownership.size():
		grid_ownership[grid_index] = new_owner
		print("Card at slot ", grid_index, " ownership changed to ", "Player" if new_owner == Owner.PLAYER else "Opponent")
		
		# Handle adaptive defense when ownership changes
		handle_adaptive_defense_ownership_change(grid_index)

func resolve_combat(grid_index: int, attacking_owner: Owner, attacking_card: CardResource):
	print("Resolving combat for card at slot ", grid_index)
	
	var captures = []
	
	# Check if attacking card has extended range ability
	var has_extended_range = attacking_card.has_meta("has_extended_range") and attacking_card.get_meta("has_extended_range")
	
	if has_extended_range:
		print("Extended Range combat detected!")
		captures = resolve_extended_range_combat(grid_index, attacking_owner, attacking_card)
	else:
		print("Standard combat")
		captures = resolve_standard_combat(grid_index, attacking_owner, attacking_card)
	
	# NEW: Execute Bolster Confidence on the attacking card if it made any captures
	if captures.size() > 0:
		var attacking_card_level = 0  # Enemy cards typically use level 0
		if attacking_owner == Owner.PLAYER:
			var attacking_card_index = get_card_collection_index(grid_index)
			attacking_card_level = get_card_level(attacking_card_index)
		
		# Check specifically for Bolster Confidence ability on the attacking card
		var available_abilities = attacking_card.get_available_abilities(attacking_card_level)
		for ability in available_abilities:
			if ability.ability_name == "Bolster Confidence":
				print("DEBUG: Attacking card ", attacking_card.card_name, " has Bolster Confidence - checking captures")
				
				# Execute Bolster Confidence for each player card captured
				for captured_index in captures:
					var captured_card_data = grid_card_data[captured_index]
					
					var bolster_context = {
						"capturing_card": attacking_card,
						"capturing_position": grid_index,
						"captured_card": captured_card_data,
						"captured_position": captured_index,
						"game_manager": self,
						"direction": "combat_capture",
						"card_level": attacking_card_level
					}
					
					ability.execute(bolster_context)
				break  # Only execute Bolster Confidence once per attacking card
	
	# Apply all captures and handle passive abilities (existing code)
	for captured_index in captures:
		print("=== PROCESSING CAPTURE AT POSITION ", captured_index, " ===")
		
		# Store the card data before changing ownership (for passive ability removal)
		var captured_card_data = grid_card_data[captured_index]
		
		print("DEBUG: Captured card is: ", captured_card_data.card_name if captured_card_data else "NULL")
		
		# Remove passive abilities of the captured card BEFORE changing ownership
		handle_passive_abilities_on_capture(captured_index, captured_card_data)
		
		# Change ownership
		grid_ownership[captured_index] = attacking_owner
		print("Card at slot ", captured_index, " is now owned by ", "Player" if attacking_owner == Owner.PLAYER else "Opponent")
		
		# DEBUG: Check for ON_CAPTURE abilities
		var card_collection_index = get_card_collection_index(captured_index)
		var card_level = get_card_level(card_collection_index)
		
		print("DEBUG: Card collection index: ", card_collection_index, ", level: ", card_level)
		print("DEBUG: About to check ON_CAPTURE abilities for ", captured_card_data.card_name, " at position ", captured_index)
		
		if captured_card_data.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, card_level):
			print("DEBUG: Card ", captured_card_data.card_name, " HAS ON_CAPTURE abilities at level ", card_level)
			
			# EXECUTE ON_CAPTURE abilities on the captured card (like Infighting)
			print("DEBUG: Executing ON_CAPTURE abilities for captured card: ", captured_card_data.card_name)
			
			var capture_context = {
				"capturing_card": attacking_card,
				"capturing_position": grid_index,  # The attacking position
				"captured_card": captured_card_data,
				"captured_position": captured_index,
				"game_manager": self,
				"direction": "standard_combat",
				"card_level": card_level
			}
			
			captured_card_data.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, card_level)
		else:
			print("DEBUG: Card ", captured_card_data.card_name, " has NO ON_CAPTURE abilities at level ", card_level)
			if captured_card_data.abilities.size() > 0:
				print("DEBUG: But it does have ", captured_card_data.abilities.size(), " abilities:")
				for i in range(captured_card_data.abilities.size()):
					var ability = captured_card_data.abilities[i]
					print("  Ability ", i, ": ", ability.ability_name, " (trigger: ", ability.trigger_condition, ")")
		
		# Check if the newly captured card has passive abilities and restart pulse effect
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
	
	return captures.size()

func resolve_standard_combat(grid_index: int, attacking_owner: Owner, attacking_card: CardResource) -> Array[int]:
	var captures: Array[int] = []
	var grid_x = grid_index % grid_size
	var grid_y = grid_index / grid_size
	
	# Check all 4 adjacent positions (existing directions)
	var directions = [
		{"dx": 0, "dy": -1, "my_value_index": 0, "their_value_index": 2, "name": "North"},
		{"dx": 1, "dy": 0, "my_value_index": 1, "their_value_index": 3, "name": "East"},
		{"dx": 0, "dy": 1, "my_value_index": 2, "their_value_index": 0, "name": "South"},
		{"dx": -1, "dy": 0, "my_value_index": 3, "their_value_index": 1, "name": "West"}
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if grid_occupied[adj_index]:
				var adjacent_owner = grid_ownership[adj_index]
				
				if adjacent_owner != Owner.NONE and adjacent_owner != attacking_owner:
					var adjacent_card = grid_card_data[adj_index]
					
					if not attacking_card or not adjacent_card:
						print("Warning: Missing card data in combat resolution")
						continue
					
					var my_value = attacking_card.values[direction.my_value_index]
					var their_value: int
					
					# Check for critical strike
					if should_apply_critical_strike(attacking_card, grid_index):
						# Use the defending card's weakest stat instead of directional stat
						their_value = get_weakest_stat_value(adjacent_card.values)
						print("CRITICAL STRIKE! Using enemy's weakest stat: ", their_value, " instead of directional stat: ", adjacent_card.values[direction.their_value_index])
						
						# Mark critical strike as used
						CriticalStrikeAbility.mark_critical_strike_used(attacking_card)
					else:
						# Normal combat - use directional stat
						their_value = adjacent_card.values[direction.their_value_index]
					
					print("Combat ", direction.name, ": My ", my_value, " vs Their ", their_value)
					
					if my_value > their_value:
						print("Captured card at slot ", adj_index, "!")
						captures.append(adj_index)
						
						# Execute abilities and award experience (existing logic)
						handle_standard_combat_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, direction)
					else:
						# Defense successful
						handle_standard_defense_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, direction)
	
	return captures

func resolve_extended_range_combat(grid_index: int, attacking_owner: Owner, attacking_card: CardResource) -> Array[int]:
	var captures: Array[int] = []
	
	# Get all 8 adjacent positions using the helper function
	var adjacent_positions = ExtendedRangeAbility.get_extended_adjacent_positions(grid_index, grid_size)
	
	print("Extended range attacking ", adjacent_positions.size(), " positions")
	
	for pos_info in adjacent_positions:
		var adj_index = pos_info.position
		var direction = pos_info.direction
		var direction_name = pos_info.name
		var is_diagonal = pos_info.is_diagonal
		
		if grid_occupied[adj_index]:
			var adjacent_owner = grid_ownership[adj_index]
			
			if adjacent_owner != Owner.NONE and adjacent_owner != attacking_owner:
				var adjacent_card = grid_card_data[adj_index]
				
				if not attacking_card or not adjacent_card:
					print("Warning: Missing card data in extended combat resolution")
					continue
				
				# Calculate attack value based on direction
				var my_attack_value = ExtendedRangeAbility.get_attack_value_for_direction(attacking_card.values, direction)
				var their_defense_value: int
				
				# Check for critical strike
				if should_apply_critical_strike(attacking_card, grid_index):
					# Use the defending card's weakest stat instead of calculated defense
					their_defense_value = get_weakest_stat_value(adjacent_card.values)
					print("CRITICAL STRIKE (Extended)! Using enemy's weakest stat: ", their_defense_value, " instead of calculated defense: ", ExtendedRangeAbility.get_defense_value_for_direction(adjacent_card.values, direction))
					
					# Mark critical strike as used
					CriticalStrikeAbility.mark_critical_strike_used(attacking_card)
				else:
					# Normal extended combat - use calculated defense value
					their_defense_value = ExtendedRangeAbility.get_defense_value_for_direction(adjacent_card.values, direction)
				
				print("Extended Combat ", direction_name, " (", "diagonal" if is_diagonal else "orthogonal", "): My ", my_attack_value, " vs Their ", their_defense_value)
				
				if my_attack_value > their_defense_value:
					print("Extended range captured card at slot ", adj_index, "!")
					captures.append(adj_index)
					
					# Handle combat effects
					handle_extended_combat_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, pos_info)
				else:
					# Defense successful
					handle_extended_defense_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, pos_info)
	
	return captures



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
	
	# Check for hunt traps when opponent places cards
	check_hunt_trap_trigger(grid_index, opponent_card_data, Owner.OPPONENT)
	
	# NEW: EXECUTE ON-PLAY ABILITIES FOR OPPONENT CARDS
	if opponent_card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, opponent_card_level):
		print("Opponent card has on-play abilities - executing")
		
		var ability_context = {
			"placed_card": opponent_card_data,
			"grid_position": grid_index,
			"game_manager": self,
			"card_level": opponent_card_level
		}
		opponent_card_data.execute_abilities(CardAbility.TriggerType.ON_PLAY, ability_context, opponent_card_level)
		
		# Update the visual display after abilities execute
		update_card_display(grid_index, opponent_card_data)
	
	# Handle passive abilities when opponent places card
	handle_passive_abilities_on_place(grid_index, opponent_card_data, opponent_card_level)
	
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
	# Clean up all tremor visual effects first
	if visual_effects_manager:
		visual_effects_manager.clear_all_tremor_shake_effects(grid_slots)
		visual_effects_manager.clear_all_hunt_effects(grid_slots)
	
	clear_all_hunt_traps()
	
	var tracker = get_node("/root/BossPredictionTrackerAutoload")
	if tracker:
		tracker.stop_recording()
	
	await get_tree().process_frame
	
	# TUTORIAL MODE CHECK - Handle tutorial completion first
	if is_tutorial_mode:
		print("Tutorial battle completed!")
		
		var scores = get_current_scores()
		if scores.opponent > scores.player:
			game_status_label.text = "Chronos crushes you! But you're learning..."
		else:
			game_status_label.text = "You did well! Time to learn more..."
		
		disable_player_input()
		opponent_is_thinking = false
		turn_manager.end_game()
		
		# Wait a moment to show the result
		await get_tree().create_timer(2.0).timeout
		
		# Trigger the post-tutorial cutscene (opening_awakening)
		if has_node("/root/CutsceneManagerAutoload"):
			get_node("/root/CutsceneManagerAutoload").play_cutscene("opening_awakening")
		else:
			# Fallback if cutscene manager isn't available
			TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")
		
		return  # Exit early for tutorial mode
	
	# NORMAL GAME MODE - Continue with regular end game logic
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
					print("Recording defeat (from consecutive draws) for conversation tracking")
					conv_manager.increment_defeat_count()
			
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
			TransitionManagerAutoload.change_scene_to("res://Scenes/RunSummary.tscn")
			return
		else:
			# First draw - restart the round with improved error handling
			winner = "It's a draw! Restarting round... (Warning: Second draw will count as defeat)"
			game_status_label.text = winner
			
			print("=== DRAW DETECTED - RESTARTING ROUND ===")
			print("Consecutive draws: ", consecutive_draws)
			
			# Disable input during restart
			disable_player_input()
			opponent_is_thinking = false
			turn_manager.end_game()
			
			# Reset the game state for a new round
			restart_round()
			return  # Exit early, don't proceed with normal end game logic
	
	# Record the enemy encounter in memory journal
	record_enemy_encounter(victory)
	
	# Record god experience (you used this god in battle)
	record_god_experience()
	
	# Check for god unlocks after recording the encounter
	check_god_unlocks()
	
	# Trigger conversation flags based on battle outcome
	if has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		
		if not victory:
			# Check if this was a boss battle
			if is_boss_battle:
				print("Triggering first_boss_loss conversation")
				conv_manager.trigger_conversation("first_boss_loss")
			else:
				print("Recording defeat for conversation tracking")
				conv_manager.increment_defeat_count()
	
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
		TransitionManagerAutoload.change_scene_to("res://Scenes/RunSummary.tscn")
		return
	
	# Player won - check if this completes the run
	game_status_label.text = "Victory! " + winner
	disable_player_input()
	opponent_is_thinking = false
	turn_manager.end_game()
	
	print("Battle ended - Final score: Player ", scores.player, " | Opponent ", scores.opponent)
	
	# Add a brief celebration delay
	await get_tree().create_timer(2.0).timeout
	
	# NEW: Check if this was the final boss battle (run complete)
	var params = get_scene_params()
	if params.has("current_node"):
		var current_node = params["current_node"]
		# If this was a boss battle, the run is complete
		if current_node.node_type == MapNode.NodeType.BOSS:
			print("Boss defeated! Run is complete - going directly to run summary")
			
			# Pass data to summary screen with victory
			get_tree().set_meta("scene_params", {
				"god": params.get("god", current_god),
				"deck_index": params.get("deck_index", 0),
				"victory": true
			})
			TransitionManagerAutoload.change_scene_to("res://Scenes/RunSummary.tscn")
			return
	
	# Not the final boss - continue with reward screen
	show_reward_screen()

func restart_round():
	print("=== RESTARTING ROUND DUE TO DRAW ===")
	
	# Store original game parameters for restoration
	var params = get_scene_params()
	var god_name = params.get("god", current_god)
	var deck_index = params.get("deck_index", 0)
	
	print("Restoring: God=", god_name, " DeckIndex=", deck_index)
	
	# Clear all visual effects first
	if visual_effects_manager:
		visual_effects_manager.clear_all_tremor_shake_effects(grid_slots)
		visual_effects_manager.clear_all_hunt_effects(grid_slots)
	
	# Clear all special game state
	clear_all_hunt_traps()
	active_passive_abilities.clear()
	active_tremors.clear()
	grid_to_collection_index.clear()
	
	# Clear the grid completely
	for i in range(grid_slots.size()):
		if grid_occupied[i]:
			var slot = grid_slots[i]
			# Remove all children (cards, effects, etc.)
			for child in slot.get_children():
				child.queue_free()
		
		# Reset grid state
		grid_occupied[i] = false
		grid_ownership[i] = Owner.NONE
		grid_card_data[i] = null
		
		# Reset slot styling
		var slot = grid_slots[i]
		restore_slot_original_styling(i)
	
	# Wait for cleanup to complete
	await get_tree().process_frame
	
	# Reset card selection state
	selected_card_index = -1
	current_grid_index = -1
	
	# Reset game state flags
	opponent_is_thinking = false
	hunt_mode_active = false
	
	# CRITICAL: Properly restore original decks
	var restoration_success = restore_original_decks_properly(god_name, deck_index)
	if not restoration_success:
		print("ERROR: Failed to restore decks properly!")
		# Fallback to end game as loss
		end_game()
		return
	
	# Validate deck restoration
	if player_deck.is_empty() or deck_card_indices.is_empty():
		print("ERROR: Player deck is empty after restoration!")
		end_game()
		return
	
	if not opponent_manager.has_cards():
		print("ERROR: Opponent deck is empty after restoration!")
		end_game()
		return
	
	# Re-apply deck power effects (sun positions, etc.)
	reapply_deck_powers()
	
	# Redisplay player hand with proper card data
	display_player_hand()
	
	# Verify hand display worked
	await get_tree().process_frame
	var hand_container_cards = hand_container.get_node_or_null("CardsContainer")
	if not hand_container_cards or hand_container_cards.get_child_count() == 0:
		print("ERROR: Failed to display player hand after restart!")
		end_game()
		return
	
	print("Round restart successful - starting new coin flip")
	
	# Brief pause to show result, then start new game
	await get_tree().create_timer(2.0).timeout
	turn_manager.start_game()


func restore_original_decks_properly(god_name: String, deck_index: int) -> bool:
	print("=== RESTORING ORIGINAL DECKS ===")
	
	# Restore player deck with full validation
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	
	if not collection:
		print("ERROR: Failed to load collection: ", collection_path)
		return false
	
	if deck_index >= collection.decks.size():
		print("ERROR: Invalid deck index ", deck_index, " for ", god_name)
		return false
	
	# Get the original deck definition
	var deck_def = collection.decks[deck_index]
	
	# Restore deck card indices (this is critical!)
	deck_card_indices = deck_def.card_indices.duplicate()
	
	# Restore the actual cards
	player_deck = collection.get_deck(deck_index)
	
	print("Restored player deck: ", player_deck.size(), " cards")
	print("Restored deck indices: ", deck_card_indices)
	
	# Validate restoration
	if player_deck.size() != deck_card_indices.size():
		print("ERROR: Deck size mismatch after restoration!")
		return false
	
	if player_deck.size() == 0:
		print("ERROR: Empty deck after restoration!")
		return false
	
	# Restore opponent deck
	var opponent_restoration = restore_opponent_deck()
	if not opponent_restoration:
		print("ERROR: Failed to restore opponent deck!")
		return false
	
	print("=== DECK RESTORATION SUCCESSFUL ===")
	return true

func restore_opponent_deck() -> bool:
	print("Restoring opponent deck...")
	
	# Re-setup opponent based on current parameters
	var params = get_scene_params()
	
	if is_tutorial_mode:
		setup_chronos_opponent()
	else:
		if params.has("current_node"):
			var current_node = params["current_node"]
			var enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
			var enemy_difficulty = current_node.enemy_difficulty
			
			print("Restoring opponent: ", enemy_name, " (difficulty ", enemy_difficulty, ")")
			opponent_manager.setup_opponent(enemy_name, enemy_difficulty)
		else:
			print("No enemy data found, using default Shadow Acolyte")
			opponent_manager.setup_opponent("Shadow Acolyte", 0)
	
	# Validate opponent restoration
	if not opponent_manager.has_cards():
		print("ERROR: Opponent manager has no cards after restoration!")
		return false
	
	print("Opponent deck restored: ", opponent_manager.get_remaining_cards(), " cards")
	return true

func reapply_deck_powers():
	print("=== REAPPLYING DECK POWERS ===")
	
	# Re-initialize deck power effects
	var params = get_scene_params()
	var god_name = params.get("god", current_god)
	var deck_index = params.get("deck_index", 0)
	
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	
	if collection and deck_index < collection.decks.size():
		var deck_def = collection.decks[deck_index]
		initialize_deck_power(deck_def)
	
	# Re-initialize enemy deck power
	if not is_tutorial_mode and params.has("current_node"):
		var current_node = params["current_node"]
		var enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
		var enemy_difficulty = current_node.enemy_difficulty
		
		var deck_def = opponent_manager.get_current_deck_definition()
		if deck_def and deck_def.deck_power_type != EnemyDeckDefinition.EnemyDeckPowerType.NONE:
			initialize_enemy_deck_power(deck_def)
	
	print("Deck powers reapplied successfully")

func _on_tutorial_finished():
	print("Tutorial battle completed, transitioning to post-battle cutscene")
	
	# Trigger the post-battle cutscene (which is the existing "opening_awakening")
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").play_cutscene("opening_awakening")
	else:
		# Fallback if cutscene manager isn't available
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

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
		TransitionManagerAutoload.change_scene_to("res://Scenes/RunMap.tscn")
	else:
		# Fallback if no map data
		print("Warning: No map data found, returning to god selection")
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

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
	
	# Hunt target style (orange border for hunting targets)
	hunt_target_style = StyleBoxFlat.new()
	hunt_target_style.bg_color = Color("#444444")
	hunt_target_style.border_width_left = 3
	hunt_target_style.border_width_top = 3
	hunt_target_style.border_width_right = 3
	hunt_target_style.border_width_bottom = 3
	hunt_target_style.border_color = Color("#FF8800")  # Orange for hunt targets

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
				
				# Initialize deck power (even in tutorial mode)
				initialize_deck_power(deck_def)
				
				print("Using deck definition: ", deck_def.deck_name)
				print("Card indices: ", deck_card_indices)
				
				# Debug: Print card names and their expected levels
				for i in range(player_deck.size()):
					if player_deck[i]:
						var card_level = get_card_level(deck_card_indices[i])
						print("Player card ", i, ": ", player_deck[i].card_name, " (level ", card_level, ")")
					else:
						print("Player card ", i, ": NULL")
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
				
				# Initialize deck power for fallback
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
		var deck_def = collection.decks[deck_index]
		deck_card_indices = deck_def.card_indices.duplicate()
		player_deck = collection.get_deck(deck_index)
		
		# Initialize deck power
		initialize_deck_power(deck_def)
		
		# Debug: Print card names and their expected levels
		for i in range(player_deck.size()):
			if player_deck[i]:
				var card_level = get_card_level(deck_card_indices[i])
				print("Player card ", i, ": ", player_deck[i].card_name, " (level ", card_level, ", collection index ", deck_card_indices[i], ")")
			else:
				print("Player card ", i, ": NULL")
		
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
		DeckDefinition.DeckPowerType.PROPHECY_POWER:
			setup_prophecy_power()
		DeckDefinition.DeckPowerType.NONE:
			print("No deck power for this deck")
		_:
			print("Unknown deck power type: ", active_deck_power)

func setup_prophecy_power():
	print("=== SETTING UP PROPHECY POWER ===")
	print("Divine Prophecy activated - player will go first")


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
	
	# No sun icon - just the golden border
	print("Applied sunlit golden border to slot ", grid_index)

func apply_deck_power_effects(card_data: CardResource, grid_position: int) -> bool:
	print("DEBUG: apply_deck_power_effects called for position ", grid_position)
	match active_deck_power:
		DeckDefinition.DeckPowerType.SUN_POWER:
			print("DEBUG: Applying sun power boost")
			return apply_sun_power_boost(card_data, grid_position)
		DeckDefinition.DeckPowerType.NONE:
			print("DEBUG: No deck power active")
			return false
		_:
			print("DEBUG: Unknown deck power type: ", active_deck_power)
			return false

func apply_sun_boosted_card_styling(card_display: CardDisplay) -> void:
	print("=== APPLY SUN BOOSTED STYLING DEBUG ===")
	print("Received object type: ", type_string(typeof(card_display)))
	print("Object class: ", card_display.get_class() if card_display else "null")
	print("Is CardDisplay: ", card_display is CardDisplay if card_display else "null object")
	print("Object name: ", card_display.name if card_display else "null object")
	
	# Safety checks to ensure we have a valid CardDisplay
	if not card_display:
		print("ERROR: card_display is null in apply_sun_boosted_card_styling")
		return
	
	if not is_instance_valid(card_display):
		print("ERROR: card_display is not valid in apply_sun_boosted_card_styling")
		return
	
	# Check if this is actually a CardDisplay
	if not card_display is CardDisplay:
		print("ERROR: Object is not a CardDisplay, it's a: ", card_display.get_class())
		return
	
	# Wait for the card display to be fully ready
	if not card_display.panel:
		print("CardDisplay panel not ready yet, waiting...")
		await get_tree().process_frame
		if not card_display.panel:
			print("ERROR: CardDisplay panel still null after waiting")
			return
	
	# Safety check for player_card_style
	if not player_card_style:
		print("ERROR: player_card_style not initialized yet")
		create_grid_styles()  # Force creation if somehow missing
	
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
	print("Successfully applied sun boosted styling")




func apply_sun_power_boost(card_data: CardResource, grid_position: int) -> bool:
	print("DEBUG: apply_sun_power_boost called for position ", grid_position)
	print("DEBUG: sunlit_positions are: ", sunlit_positions)
	print("DEBUG: darkness_shroud_active: ", darkness_shroud_active)
	
	# Check if darkness shroud is active - it nullifies sun power
	if darkness_shroud_active:
		print("🌑 Darkness Shroud blocks sun power - no boost applied")
		return false
	
	if grid_position in sunlit_positions:
		print("☀️ SUN POWER ACTIVATED! Boosting card stats by +1")
		
		# Apply +1 to all stats
		card_data.values[0] += 1  # North
		card_data.values[1] += 1  # East
		card_data.values[2] += 1  # South
		card_data.values[3] += 1  # West
		
		print("Card stats boosted to: ", card_data.values)
		return true
	
	print("DEBUG: Position ", grid_position, " is not sunlit")
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
	
	# Set anchors to center and use relative positioning
	sun_label.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	sun_label.anchor_left = 0.5
	sun_label.anchor_right = 0.5
	sun_label.anchor_top = 0.5
	sun_label.anchor_bottom = 0.5
	sun_label.offset_left = -15
	sun_label.offset_right = 15
	sun_label.offset_top = -15
	sun_label.offset_bottom = 15
	
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
		return progress_tracker.get_card_level(current_god, card_index)
	return 0  

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
	
	# Add each card from the deck with explicit positioning and proper leveling
	for i in range(player_deck.size()):
		var card = player_deck[i]
		var card_collection_index = deck_card_indices[i]
		
		# Create a card display instance
		var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
		cards_container.add_child(card_display)
		
		# Wait one frame to ensure the card display is fully ready
		await get_tree().process_frame
		
		# Position the card explicitly with the new spacing
		card_display.position.x = start_x + i * total_spacing
		
		# Get the current level for this card - UNIFIED VERSION
		var current_level = get_card_level(card_collection_index)
		
		print("Setting up hand card ", i, ": ", card.card_name, " at level ", current_level, " (collection index: ", card_collection_index, ")")
		
		# FOR HAND DISPLAY: Create a copy of the card with level-appropriate values
		var hand_card_data = card.duplicate()
		var effective_values = card.get_effective_values(current_level)
		var effective_abilities = card.get_effective_abilities(current_level)
		
		# Apply the level-appropriate values to the hand display copy
		hand_card_data.values = effective_values.duplicate()
		hand_card_data.abilities = effective_abilities.duplicate()
		
		print("Hand card effective values: ", effective_values)
		print("Hand card effective abilities count: ", effective_abilities.size())
		
		# Setup the card with the level-appropriate data for hand display
		card_display.setup(hand_card_data, current_level, current_god, card_collection_index)
		
		# ALWAYS connect hover signals for info panel (regardless of tutorial mode)
		card_display.card_hovered.connect(_on_card_hovered)
		card_display.card_unhovered.connect(_on_card_unhovered)
		print("Connected hover signals for card ", i, ": ", card.card_name)
		
		# DEBUG: Check if panel exists and is ready
		if not card_display.panel:
			print("ERROR: Card display panel is null for card ", i)
			continue
		
		print("Card ", i, " panel mouse filter: ", card_display.panel.mouse_filter)
		print("Card ", i, " panel size: ", card_display.panel.size)
		print("Card ", i, " panel position: ", card_display.panel.position)
		
		# Make sure the panel can receive input
		card_display.panel.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Connect to detect clicks on the card
		card_display.panel.gui_input.connect(_on_card_gui_input.bind(card_display, i))
		print("Connected panel gui_input for card ", i)
		
		# Test if the CardDisplay itself has input handling
		if card_display.has_signal("input_event"):
			card_display.input_event.connect(_on_card_input_event.bind(card_display, i))
			print("Connected CardDisplay input_event for card ", i)


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
			# Restore the previous slot's original styling
			restore_slot_original_styling(current_grid_index)
		
		current_grid_index = grid_index
		
		if grid_index in active_hunts:
			print("Mouse entered hunt trap slot - preserving hunt styling but allowing selection")
			# Don't change the visual styling, but the slot is now selected for placement
			return
		
		# Apply selection highlight with awareness of sun spots (for non-hunt slots)
		apply_selection_highlight(grid_index)
	

func _on_grid_mouse_exited(grid_index):
	if not turn_manager.is_player_turn():
		return
	
	# If this slot is not the currently selected one, restore its original styling
	if current_grid_index != grid_index and not grid_occupied[grid_index]:
		restore_slot_original_styling(grid_index)
	# FIXED: If this IS the currently selected slot but has a hunt trap, restore hunt styling
	elif current_grid_index == grid_index and grid_index in active_hunts:
		apply_hunt_target_styling(grid_index)


func restore_slot_original_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	
	# FIXED: Check for hunt trap first, then sunlit position
	if grid_index in active_hunts:
		# Restore hunt trap styling
		apply_hunt_target_styling(grid_index)
	elif grid_index in sunlit_positions:
		# Restore sunlit styling
		apply_sunlit_styling(grid_index)
	else:
		# Restore default styling
		slot.add_theme_stylebox_override("panel", default_grid_style)

func apply_selection_highlight(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	
	# FIXED: Check for hunt trap first, then sunlit position
	if grid_index in active_hunts:
		# Don't override hunt trap styling with selection highlight
		return
	elif grid_index in sunlit_positions:
		# Create a combined sunlit + selected style
		var sunlit_selected_style = StyleBoxFlat.new()
		sunlit_selected_style.bg_color = Color("#444444")
		sunlit_selected_style.border_width_left = 4  # Thicker border for selection
		sunlit_selected_style.border_width_top = 4
		sunlit_selected_style.border_width_right = 4
		sunlit_selected_style.border_width_bottom = 4
		sunlit_selected_style.border_color = Color("#44AAFF")  # Blue selection border
		
		# Add a golden inner glow effect by using a background color
		sunlit_selected_style.bg_color = Color("#554422")  # Golden tinted background
		
		slot.add_theme_stylebox_override("panel", sunlit_selected_style)
	else:
		# Regular selection styling for non-special slots
		slot.add_theme_stylebox_override("panel", selected_grid_style)


# Grid click handler (only during player's turn)
func _on_grid_gui_input(event, grid_index):
	# Handle hunt target selection FIRST (but only during hunt mode setup)
	if hunt_mode_active and current_hunter_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow trap setup on empty slots for now (disable direct combat)
				if not grid_occupied[grid_index]:
					select_hunt_target(grid_index)
				else:
					print("Direct hunt combat disabled - can only set traps on empty slots")
				return  # Don't process normal card placement during hunt mode
	
	if not turn_manager.is_player_turn():
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# SIMPLIFIED: Just check if card selected and slot not occupied
			# Hunt trap handling moved to place_card_on_grid()
			if selected_card_index != -1 and not grid_occupied[grid_index]:
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

func place_card_on_grid():
	if selected_card_index == -1 or current_grid_index == -1:
		return
	
	# FIXED: Handle hunt trap removal BEFORE checking if slot is occupied
	if current_grid_index in active_hunts:
		var hunt_data = active_hunts[current_grid_index]
		# Only remove if it's our own hunt trap
		if hunt_data.hunter_owner == Owner.PLAYER:
			print("Removing player's own hunt trap from slot ", current_grid_index)
			remove_hunt_trap(current_grid_index)
		else:
			print("Cannot place on enemy hunt trap!")
			return
	
	if grid_occupied[current_grid_index]:
		print("Grid slot is already occupied!")
		return
		
	# Make sure the selected card index is valid
	if selected_card_index >= player_deck.size():
		print("Invalid card index: ", selected_card_index)
		selected_card_index = -1
		return
	
	# Store a reference to the original card data
	var original_card_data = player_deck[selected_card_index]
	var card_collection_index = deck_card_indices[selected_card_index]
	
	# Get card level for ability checks - UNIFIED VERSION
	var card_level = get_card_level(card_collection_index)
	print("Card level for ", original_card_data.card_name, " (index ", card_collection_index, "): ", card_level)
	
	# IMPORTANT: Create effective card data for the current level for grid placement
	var card_data = original_card_data.duplicate()
	var effective_values = original_card_data.get_effective_values(card_level)
	var effective_abilities = original_card_data.get_effective_abilities(card_level)
	
	# Apply the level-appropriate values and abilities to the grid copy
	card_data.values = effective_values.duplicate()
	card_data.abilities = effective_abilities.duplicate()
	
	print("Grid placement effective values: ", card_data.values)
	print("Grid placement effective abilities count: ", card_data.abilities.size())
	
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
			
			# NEW: Record trap encounter
			get_node("/root/GlobalProgressTrackerAutoload").record_trap_fallen_for("boss_prediction", "Fell into boss's prediction trap")
			if notification_manager:
				notification_manager.show_notification("Artemis observes your trap encounter")
			
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
	
	# Wait one frame to ensure _ready() is called and @onready variables are initialized
	await get_tree().process_frame
	
	# NOW setup the card display with the actual card data and level
	card_display.setup(card_data, card_level, current_god, card_collection_index)
	
	# Wait another frame to ensure setup is complete
	await get_tree().process_frame
	
	# Apply special styling for sun-boosted cards
	if sun_boosted:
		# Wait to ensure the card display is fully ready before applying styling
		await get_tree().process_frame
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
	
	# Check for hunt traps before normal combat (this will only affect enemy hunt traps now)
	check_hunt_trap_trigger(current_grid_index, card_data, Owner.PLAYER)
	
	# EXECUTE ON-PLAY ABILITIES BEFORE COMBAT (but after potential stat changes)
	if card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level):
		print("Executing on-play abilities for ", card_data.card_name, " at level ", card_level)
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
	
	check_for_couple_union(card_data, current_grid_index)
	
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

	# Reset grid selection and restore any remaining selection styling
	if current_grid_index != -1:
		restore_slot_original_styling(current_grid_index)
	current_grid_index = -1

	# Check if game should end
	if should_game_end():
		end_game()
		return

	# HUNT FIX: DON'T switch turns if hunt mode is active - player needs to select hunt target first
	if hunt_mode_active:
		print("Hunt mode active - staying on player turn for target selection")
		return
	
	# Switch turns only if hunt mode is not active
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
	
	# Check if captured card had any active hunts and remove them
	for target_pos in active_hunts.keys():
		var hunt_data = active_hunts[target_pos]
		if hunt_data.hunter_position == grid_position:
			print("Removing hunt trap due to hunter capture")
			remove_hunt_trap(target_pos)
	
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
	TransitionManagerAutoload.change_scene_to("res://Scenes/RewardScreen.tscn")

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

# Check for god unlocks after battle completion
func check_god_unlocks():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
	
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var newly_unlocked = progress_tracker.check_god_unlocks()
	
	for god_name in newly_unlocked:
		print("New god unlocked: ", god_name)
		
		# Show notification
		if notification_manager:
			notification_manager.show_notification("🎉 " + god_name + " unlocked! 🎉")
		
		# Could trigger a conversation here too
		if has_node("/root/ConversationManagerAutoload"):
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			# This conversation would need to be defined in conversation_manager.gd
			conv_manager.trigger_conversation("hermes_unlocked")


# Replace the check_for_couple_union function in Scripts/card_battle_manager.gd
func check_for_couple_union(placed_card: CardResource, grid_position: int):
	var placed_card_name = placed_card.card_name
	
	# Get global progress tracker
	var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not progress_tracker:
		return
	
	# Check if this card is part of a couple
	if not placed_card_name in couple_definitions:
		return
	
	var partner_name = couple_definitions[placed_card_name]
	
	# Create couple ID to check if already united (same logic as in progress tracker)
	var couple_names = [placed_card_name, partner_name]
	couple_names.sort()
	var couple_id = couple_names[0] + " & " + couple_names[1]
	
	# Check if this couple has already been united
	if couple_id in progress_tracker.couples_united:
		print("Couple ", couple_id, " has already been united - skipping")
		return
	
	# Check all 4 adjacent positions for the partner
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	var adjacent_positions = [
		{"dx": 0, "dy": -1},  # North
		{"dx": 1, "dy": 0},   # East
		{"dx": 0, "dy": 1},   # South
		{"dx": -1, "dy": 0}   # West
	]
	
	for adj in adjacent_positions:
		var adj_x = grid_x + adj.dx
		var adj_y = grid_y + adj.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if grid_occupied[adj_index]:
				var adjacent_card = get_card_at_position(adj_index)
				if adjacent_card and adjacent_card.card_name == partner_name:
					# Couple found! Record the union
					progress_tracker.record_couple_union(placed_card_name, partner_name)
					
					# Show notification if available
					if notification_manager:
						notification_manager.show_notification("💕 " + couple_id + " united! 💕")
					
					return

func get_adjacent_position(grid_position: int, direction: int) -> int:
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	match direction:
		0: # North
			if grid_y > 0:
				return (grid_y - 1) * grid_size + grid_x
		1: # East
			if grid_x < grid_size - 1:
				return grid_y * grid_size + (grid_x + 1)
		2: # South
			if grid_y < grid_size - 1:
				return (grid_y + 1) * grid_size + grid_x
		3: # West
			if grid_x > 0:
				return grid_y * grid_size + (grid_x - 1)
	
	return -1

func record_couple_union(card1_name: String, card2_name: String):
	# Get global progress tracker
	var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not progress_tracker:
		return
	
	progress_tracker.record_couple_union(card1_name, card2_name)




# Handle combat effects for standard combat
func handle_standard_combat_effects(attacker_pos: int, defender_pos: int, attacking_owner: Owner, attacking_card: CardResource, defending_card: CardResource, direction: Dictionary):
	# VISUAL EFFECT: Flash the attacking card's edge
	var attacking_card_display = get_card_display_at_position(attacker_pos)
	if attacking_card_display:
		var is_player_attack = (attacking_owner == Owner.PLAYER)
		visual_effects_manager.show_capture_flash(attacking_card_display, direction.my_value_index, is_player_attack)
	
	# Award capture experience if it's a player card attacking - UNIFIED VERSION
	if attacking_owner == Owner.PLAYER:
		var card_collection_index = get_card_collection_index(attacker_pos)
		if card_collection_index != -1:
			# Use the unified experience system
			var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(card_collection_index, 10)
				print("Player card at position ", attacker_pos, " (collection index ", card_collection_index, ") gained 10 capture exp")
			else:
				print("Warning: RunExperienceTrackerAutoload not found for capture exp")
	
	# Execute ON_CAPTURE abilities on the captured card (existing logic)
	execute_capture_abilities(defender_pos, defending_card, attacker_pos, attacking_card, direction.name)

# Handle defense effects for standard combat
func handle_standard_defense_effects(attacker_pos: int, defender_pos: int, attacking_owner: Owner, attacking_card: CardResource, defending_card: CardResource, direction: Dictionary):
	print("Defense successful at slot ", defender_pos, "!")
	
	# Award defense experience if defending card is player's - UNIFIED VERSION
	if attacking_owner == Owner.OPPONENT and grid_ownership[defender_pos] == Owner.PLAYER:
		var defending_card_index = get_card_collection_index(defender_pos)
		if defending_card_index != -1:
			# Use the unified experience system
			var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_defense_exp(defending_card_index, 5)
				print("Player card at position ", defender_pos, " (collection index ", defending_card_index, ") gained 5 defense exp")
			else:
				print("Warning: RunExperienceTrackerAutoload not found for defense exp")
	
	# Execute ON_DEFEND abilities
	execute_defend_abilities(defender_pos, defending_card, attacker_pos, attacking_card, direction.name)

# Handle combat effects for extended range combat
func handle_extended_combat_effects(attacker_pos: int, defender_pos: int, attacking_owner: Owner, attacking_card: CardResource, defending_card: CardResource, pos_info: Dictionary):
	# VISUAL EFFECT: Flash the attacking card's edge (modified for extended range)
	var attacking_card_display = get_card_display_at_position(attacker_pos)
	if attacking_card_display:
		var is_player_attack = (attacking_owner == Owner.PLAYER)
		# For extended range, we'll flash based on the actual direction
		var flash_direction = pos_info.direction if pos_info.direction < 4 else (pos_info.direction - 4)  # Map diagonals to orthogonals for flashing
		visual_effects_manager.show_capture_flash(attacking_card_display, flash_direction, is_player_attack)
	
	# Award capture experience - UNIFIED VERSION
	if attacking_owner == Owner.PLAYER:
		var card_collection_index = get_card_collection_index(attacker_pos)
		if card_collection_index != -1:
			# Use the unified experience system
			var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(card_collection_index, 10)
				print("Player card at position ", attacker_pos, " (collection index ", card_collection_index, ") gained 10 extended range capture exp")
			else:
				print("Warning: RunExperienceTrackerAutoload not found for extended capture exp")
	
	# Execute ON_CAPTURE abilities
	execute_capture_abilities(defender_pos, defending_card, attacker_pos, attacking_card, pos_info.name)

# Handle defense effects for extended range combat
func handle_extended_defense_effects(attacker_pos: int, defender_pos: int, attacking_owner: Owner, attacking_card: CardResource, defending_card: CardResource, pos_info: Dictionary):
	print("Extended defense successful at slot ", defender_pos, "!")
	
	# Award defense experience if defending card is player's - UNIFIED VERSION
	if attacking_owner == Owner.OPPONENT and grid_ownership[defender_pos] == Owner.PLAYER:
		var defending_card_index = get_card_collection_index(defender_pos)
		if defending_card_index != -1:
			# Use the unified experience system
			var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_defense_exp(defending_card_index, 5)
				print("Player card at position ", defender_pos, " (collection index ", defending_card_index, ") gained 5 extended range defense exp")
			else:
				print("Warning: RunExperienceTrackerAutoload not found for extended defense exp")
	
	# Execute ON_DEFEND abilities
	execute_defend_abilities(defender_pos, defending_card, attacker_pos, attacking_card, pos_info.name)
# Helper functions for ability execution
func execute_capture_abilities(defender_pos: int, defending_card: CardResource, attacker_pos: int, attacking_card: CardResource, direction_name: String):
	var defending_card_collection_index = get_card_collection_index(defender_pos)
	var defending_card_level = get_card_level(defending_card_collection_index)
	
	if defending_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, defending_card_level):
		print("Executing ON_CAPTURE abilities for captured card: ", defending_card.card_name)
		
		var capture_context = {
			"capturing_card": attacking_card,
			"capturing_position": attacker_pos,
			"captured_card": defending_card,
			"captured_position": defender_pos,
			"game_manager": self,
			"direction": direction_name,
			"card_level": defending_card_level
		}
		
		defending_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, defending_card_level)

func execute_defend_abilities(defender_pos: int, defending_card: CardResource, attacker_pos: int, attacking_card: CardResource, direction_name: String):
	var defending_card_collection_index = get_card_collection_index(defender_pos)
	var defending_card_level = get_card_level(defending_card_collection_index)
	
	if defending_card.has_ability_type(CardAbility.TriggerType.ON_DEFEND, defending_card_level):
		print("Executing ON_DEFEND abilities for defending card: ", defending_card.card_name)
		
		var defend_context = {
			"defending_card": defending_card,
			"defending_position": defender_pos,
			"attacking_card": attacking_card,
			"attacking_position": attacker_pos,
			"game_manager": self,
			"direction": direction_name,
			"card_level": defending_card_level
		}
		
		defending_card.execute_abilities(CardAbility.TriggerType.ON_DEFEND, defend_context, defending_card_level)


func register_tremors(source_position: int, tremor_zones: Array[int], owner: Owner, turns_remaining: int):
	var tremor_id = tremor_id_counter
	tremor_id_counter += 1
	
	active_tremors[tremor_id] = {
		"source_position": source_position,
		"tremor_zones": tremor_zones.duplicate(),
		"owner": owner,
		"turns_remaining": turns_remaining,
		"turn_placed": get_current_turn_number()
	}
	
	# Apply shake effects through VisualEffectsManager
	if visual_effects_manager:
		visual_effects_manager.apply_tremor_shake_effects(tremor_zones, grid_slots)
	
	print("Tremors registered: ID ", tremor_id, " from position ", source_position, " affecting zones ", tremor_zones)

func process_tremors_for_player(player_owner: Owner):
	print("Processing tremors for ", "Player" if player_owner == Owner.PLAYER else "Opponent")
	
	var tremors_to_remove = []
	
	for tremor_id in active_tremors:
		var tremor_data = active_tremors[tremor_id]
		
		# Only process tremors owned by the current player
		if tremor_data.owner != player_owner:
			continue
		
		# Check if source card still exists and is owned by the original owner
		var source_position = tremor_data.source_position
		if not grid_occupied[source_position] or grid_ownership[source_position] != tremor_data.owner:
			print("Tremor source card captured/removed - ending tremors for ID ", tremor_id)
			tremors_to_remove.append(tremor_id)
			continue
		
		# Process tremor attacks
		process_single_tremor(tremor_id, tremor_data)
		
		# Decrease turns remaining
		tremor_data.turns_remaining -= 1
		if tremor_data.turns_remaining <= 0:
			print("Tremor expired: ID ", tremor_id)
			tremors_to_remove.append(tremor_id)
	
	# Remove expired tremors and their visual effects
	for tremor_id in tremors_to_remove:
		var tremor_data = active_tremors[tremor_id]
		
		# Remove shake effects through VisualEffectsManager
		if visual_effects_manager:
			visual_effects_manager.remove_tremor_shake_effects(tremor_data.tremor_zones, grid_slots)
		
		active_tremors.erase(tremor_id)

# Process a single tremor's attacks
func process_single_tremor(tremor_id: int, tremor_data: Dictionary):
	var source_position = tremor_data.source_position
	var tremor_zones = tremor_data.tremor_zones
	var tremor_owner = tremor_data.owner
	
	# Get the source card's current stats
	var source_card = get_card_at_position(source_position)
	if not source_card:
		return
	
	print("Processing tremor attacks from ", source_card.card_name, " at position ", source_position)
	
	var captures = []
	
	# Check each tremor zone for enemies to attack
	for tremor_zone in tremor_zones:
		if not grid_occupied[tremor_zone]:
			continue  # Still empty, no tremor attack
		
		var target_owner = grid_ownership[tremor_zone]
		if target_owner == tremor_owner:
			continue  # Don't attack own cards
		
		var target_card = get_card_at_position(tremor_zone)
		if not target_card:
			continue
		
		# Determine attack direction from source to tremor zone
		var attack_direction = get_direction_between_positions(source_position, tremor_zone)
		if attack_direction == -1:
			continue
		
		# Perform tremor combat
		var tremor_attack_value = source_card.values[attack_direction]
		var target_defense_value = target_card.values[get_opposite_direction(attack_direction)]
		
		print("Tremor combat: ", source_card.card_name, " (", tremor_attack_value, ") vs ", target_card.card_name, " (", target_defense_value, ") at zone ", tremor_zone)
		
		if tremor_attack_value > target_defense_value:
			print("Tremor captured card at position ", tremor_zone, "!")
			captures.append(tremor_zone)
			
			# NEW: Record trap encounter if player card was captured
			if target_owner == Owner.PLAYER:
				get_node("/root/GlobalProgressTrackerAutoload").record_trap_fallen_for("tremor", "Card captured by earthquake tremors")
				if notification_manager:
					notification_manager.show_notification("Artemis observes your trap encounter")
			
			# Show tremor capture visual effect
			var target_card_display = get_card_display_at_position(tremor_zone)
			if target_card_display and visual_effects_manager:
				visual_effects_manager.show_tremor_capture_flash(target_card_display)
			
			# Execute capture
			grid_ownership[tremor_zone] = tremor_owner
			
			# Award experience for tremor capture
			if tremor_owner == Owner.PLAYER:
				var source_card_index = get_card_collection_index(source_position)
				if source_card_index != -1:
					var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
					if exp_tracker:
						exp_tracker.add_capture_exp(source_card_index, 8)  # Slightly less than normal capture
						print("Tremor capture awarded 8 exp to card at collection index ", source_card_index)
			
			# Execute ON_CAPTURE abilities on captured card
			execute_tremor_capture_abilities(tremor_zone, target_card, source_position, source_card)
	
	if captures.size() > 0:
		print("Tremors captured ", captures.size(), " cards!")
		update_board_visuals()
		update_game_status()

# Execute capture abilities for tremor captures
func execute_tremor_capture_abilities(defender_pos: int, defending_card: CardResource, attacker_pos: int, attacking_card: CardResource):
	var defending_card_collection_index = get_card_collection_index(defender_pos)
	var defending_card_level = get_card_level(defending_card_collection_index)
	
	if defending_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, defending_card_level):
		print("Executing ON_CAPTURE abilities for tremor-captured card: ", defending_card.card_name)
		
		var capture_context = {
			"capturing_card": attacking_card,
			"capturing_position": attacker_pos,
			"captured_card": defending_card,
			"captured_position": defender_pos,
			"game_manager": self,
			"direction": "tremor",
			"card_level": defending_card_level
		}
		
		defending_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, defending_card_level)

# Get direction between two positions
func get_direction_between_positions(from_pos: int, to_pos: int) -> int:
	var from_x = from_pos % grid_size
	var from_y = from_pos / grid_size
	var to_x = to_pos % grid_size
	var to_y = to_pos / grid_size
	
	var dx = to_x - from_x
	var dy = to_y - from_y
	
	# Only handle orthogonal directions
	if dx == 0 and dy == -1:  # North
		return 0
	elif dx == 1 and dy == 0:  # East
		return 1
	elif dx == 0 and dy == 1:  # South
		return 2
	elif dx == -1 and dy == 0:  # West
		return 3
	
	return -1  # Invalid direction

# Get opposite direction for defense calculation
func get_opposite_direction(direction: int) -> int:
	match direction:
		0: return 2  # North -> South
		1: return 3  # East -> West
		2: return 0  # South -> North
		3: return 1  # West -> East
		_: return 0

# Get current turn number for tracking
func get_current_turn_number() -> int:
	# This is a simple implementation - you might want to track this more accurately
	var cards_played_total = (5 - player_deck.size()) + (5 - opponent_manager.get_remaining_cards())
	return cards_played_total + 1



# Start hunt target selection mode
func start_hunt_mode(hunter_position: int, hunter_owner: Owner, hunter_card: CardResource):
	hunt_mode_active = true
	current_hunter_position = hunter_position
	current_hunter_owner = hunter_owner
	current_hunter_card = hunter_card
	
	# Update game status
	if hunter_owner == Owner.PLAYER:
		game_status_label.text = "🎯 HUNT MODE: Select a slot to hunt"
	else:
		game_status_label.text = "🎯 " + opponent_manager.get_opponent_info().name + " is hunting..."
		# Auto-select target for opponent
		call_deferred("opponent_select_hunt_target")
	
	print("Hunt mode activated for ", hunter_card.card_name, " at position ", hunter_position)

func select_hunt_target(target_position: int):
	if not hunt_mode_active:
		return
	
	print("Hunt target selected: position ", target_position)
	
	# Check if target slot is occupied
	if grid_occupied[target_position]:
		# Immediate hunt combat
		execute_immediate_hunt(target_position)
	else:
		# Set up hunt trap
		setup_hunt_trap(target_position)
	
	# Exit hunt mode
	hunt_mode_active = false
	current_hunter_position = -1
	current_hunter_owner = Owner.NONE
	current_hunter_card = null
	
	# Update game status
	update_game_status()
	
	# NOW switch turns after hunt target is selected
	if should_game_end():
		end_game()
		return
	
	turn_manager.next_turn()

# Execute immediate hunt combat
func execute_immediate_hunt(target_position: int):
	var hunted_card = get_card_at_position(target_position)
	var hunted_owner = get_owner_at_position(target_position)
	
	if not hunted_card or hunted_owner == current_hunter_owner:
		print("Invalid hunt target - no card or friendly card")
		return
	
	print("Executing immediate hunt: ", current_hunter_card.card_name, " hunts ", hunted_card.card_name)
	
	# Calculate combat values
	var hunter_stats = HuntAbility.get_highest_stat(current_hunter_card.values)
	var hunted_stats = HuntAbility.get_lowest_stat(hunted_card.values)
	
	print("Hunt combat: Hunter ", hunter_stats.value, " vs Hunted ", hunted_stats.value)
	
	# Show hunt combat visual effect
	if visual_effects_manager:
		var hunter_display = get_card_display_at_position(current_hunter_position)
		var hunted_display = get_card_display_at_position(target_position)
		if hunter_display and hunted_display:
			visual_effects_manager.show_hunt_combat_flash(hunter_display, hunted_display)
	
	# Resolve hunt combat
	if hunter_stats.value > hunted_stats.value:
		print("Hunt successful! Capturing hunted card")
		
		# Capture the hunted card
		set_card_ownership(target_position, current_hunter_owner)
		
		# Award experience for hunt capture
		if current_hunter_owner == Owner.PLAYER:
			var hunter_card_index = get_card_collection_index(current_hunter_position)
			if hunter_card_index != -1:
				var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
				if exp_tracker:
					exp_tracker.add_capture_exp(hunter_card_index, 12)  # Bonus exp for hunt
					print("Hunt capture awarded 12 exp to hunter")
		
		# Execute ON_CAPTURE abilities on the hunted card
		execute_hunt_capture_abilities(target_position, hunted_card, current_hunter_position, current_hunter_card)
		
		# Update visuals
		update_board_visuals()
	else:
		print("Hunt failed - hunted card resisted")
		
		# Award defense experience to hunted card if it's a player card
		if hunted_owner == Owner.PLAYER:
			var hunted_card_index = get_card_collection_index(target_position)
			if hunted_card_index != -1:
				var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
				if exp_tracker:
					exp_tracker.add_defense_exp(hunted_card_index, 7)  # Bonus exp for resisting hunt
					print("Hunt resistance awarded 7 defense exp")

# Set up hunt trap for empty slot
func setup_hunt_trap(target_position: int):
	print("Setting up hunt trap at position ", target_position)
	
	# Remove any existing hunt on this slot
	if target_position in active_hunts:
		remove_hunt_trap(target_position)
	
	var hunt_id = hunt_id_counter
	hunt_id_counter += 1
	
	active_hunts[target_position] = {
		"hunt_id": hunt_id,
		"hunter_position": current_hunter_position,
		"hunter_owner": current_hunter_owner,
		"hunter_card": current_hunter_card,
		"target_position": target_position
	}
	
	# Apply visual styling to show this slot is being hunted
	apply_hunt_target_styling(target_position)
	
	print("Hunt trap set up with ID ", hunt_id, " at position ", target_position)

func apply_hunt_target_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	slot.add_theme_stylebox_override("panel", hunt_target_style)
	
	print("Applied hunt target styling (orange border) to slot ", grid_index)



func remove_hunt_trap(target_position: int):
	if not target_position in active_hunts:
		return
	
	print("Removing hunt trap from position ", target_position)
	
	# Remove visual styling
	restore_slot_original_styling(target_position)
	
	# Remove from tracking
	active_hunts.erase(target_position)

func check_hunt_trap_trigger(grid_position: int, placed_card: CardResource, placing_owner: Owner):
	if not grid_position in active_hunts:
		return
	
	var hunt_data = active_hunts[grid_position]
	
	# Check if hunter card still exists and is owned by original owner
	if not grid_occupied[hunt_data.hunter_position] or grid_ownership[hunt_data.hunter_position] != hunt_data.hunter_owner:
		print("Hunt trap expired - hunter card captured/removed")
		remove_hunt_trap(grid_position)
		return
	
	# This function should only be called for enemy placements now
	# (friendly placements handle trap removal in place_card_on_grid)
	if placing_owner == hunt_data.hunter_owner:
		print("WARNING: check_hunt_trap_trigger called for friendly placement - this shouldn't happen")
		remove_hunt_trap(grid_position)
		return
	
	print("Hunt trap triggered! ", hunt_data.hunter_card.card_name, " hunts the newly placed ", placed_card.card_name)
	
	# Execute trap hunt combat
	execute_trap_hunt_combat(grid_position, placed_card, hunt_data)
	
	# Remove the trap (used up)
	remove_hunt_trap(grid_position)

func execute_trap_hunt_combat(target_position: int, hunted_card: CardResource, hunt_data: Dictionary):
	var hunter_card = hunt_data.hunter_card
	
	# Calculate combat values
	var hunter_stats = HuntAbility.get_highest_stat(hunter_card.values)
	var hunted_stats = HuntAbility.get_lowest_stat(hunted_card.values)
	
	print("Trap hunt combat: Hunter ", hunter_stats.value, " vs Hunted ", hunted_stats.value)
	
	# Show hunt combat visual effect
	if visual_effects_manager:
		var hunter_display = get_card_display_at_position(hunt_data.hunter_position)
		var hunted_display = get_card_display_at_position(target_position)
		if hunter_display and hunted_display:
			visual_effects_manager.show_hunt_trap_flash(hunter_display, hunted_display)
	
	# Resolve hunt combat
	if hunter_stats.value > hunted_stats.value:
		print("Hunt trap successful! Capturing hunted card")
		
		# NEW: Record trap encounter if player walked into enemy hunt trap
		var hunted_owner = get_owner_at_position(target_position)
		if hunted_owner == Owner.PLAYER:
			get_node("/root/GlobalProgressTrackerAutoload").record_trap_fallen_for("hunt_trap", "Caught in enemy hunting snare")
			if notification_manager:
				notification_manager.show_notification("Artemis observes your trap encounter")
		
		# Capture the hunted card
		set_card_ownership(target_position, hunt_data.hunter_owner)
		
		# Award experience for hunt capture
		if hunt_data.hunter_owner == Owner.PLAYER:
			var hunter_card_index = get_card_collection_index(hunt_data.hunter_position)
			if hunter_card_index != -1:
				var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
				if exp_tracker:
					exp_tracker.add_capture_exp(hunter_card_index, 10)  # Standard hunt exp
					print("Hunt trap capture awarded 10 exp to hunter")
		
		# Execute ON_CAPTURE abilities on the hunted card
		execute_hunt_capture_abilities(target_position, hunted_card, hunt_data.hunter_position, hunter_card)
		
		# Update visuals
		update_board_visuals()
	else:
		print("Hunt trap failed - hunted card resisted")

# Execute capture abilities for hunt captures
func execute_hunt_capture_abilities(defender_pos: int, defending_card: CardResource, attacker_pos: int, attacking_card: CardResource):
	var defending_card_collection_index = get_card_collection_index(defender_pos)
	var defending_card_level = get_card_level(defending_card_collection_index)
	
	if defending_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, defending_card_level):
		print("Executing ON_CAPTURE abilities for hunt-captured card: ", defending_card.card_name)
		
		var capture_context = {
			"capturing_card": attacking_card,
			"capturing_position": attacker_pos,
			"captured_card": defending_card,
			"captured_position": defender_pos,
			"game_manager": self,
			"direction": "hunt",
			"card_level": defending_card_level
		}
		
		defending_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, defending_card_level)

# Opponent AI hunt target selection
func opponent_select_hunt_target():
	if not hunt_mode_active:
		return
	
	# Simple AI: prefer occupied enemy slots, otherwise pick random empty slot
	var possible_targets = []
	var enemy_targets = []
	
	for i in range(grid_slots.size()):
		if grid_occupied[i]:
			var owner = get_owner_at_position(i)
			if owner != current_hunter_owner:
				enemy_targets.append(i)
		else:
			possible_targets.append(i)
	
	# Prefer enemy targets if available
	var target_position = -1
	if enemy_targets.size() > 0:
		target_position = enemy_targets[randi() % enemy_targets.size()]
	elif possible_targets.size() > 0:
		target_position = possible_targets[randi() % possible_targets.size()]
	
	if target_position != -1:
		select_hunt_target(target_position)

# Clear all hunt traps (for game end or reset)
func clear_all_hunt_traps():
	for target_position in active_hunts.keys():
		remove_hunt_trap(target_position)
	active_hunts.clear()
	hunt_mode_active = false
	current_hunter_position = -1
	current_hunter_owner = Owner.NONE
	current_hunter_card = null
	print("All hunt traps cleared")

func handle_adaptive_defense_turn_change(is_player_turn: bool):
	print("Processing adaptive defense for turn change - is_player_turn: ", is_player_turn)
	
	# Check all cards on the board
	for position in range(grid_slots.size()):
		if not grid_occupied[position]:
			continue
			
		var card_data = get_card_at_position(position)
		var card_owner = get_owner_at_position(position)
		var card_level = get_card_level(get_card_collection_index(position))
		
		if not card_data:
			continue
		
		# Check if this card has adaptive defense ability
		var has_adaptive_defense = false
		var adaptive_defense_ability = null
		
		if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			for ability in card_data.get_available_abilities(card_level):
				if ability.ability_name == "Adaptive Defense":
					has_adaptive_defense = true
					adaptive_defense_ability = ability
					break
		
		if not has_adaptive_defense:
			continue
		
		# Determine if adaptive defense should be active
		# Active when it's NOT the controlling player's turn
		var should_be_active = (card_owner == Owner.PLAYER and not is_player_turn) or (card_owner == Owner.OPPONENT and is_player_turn)
		
		print("Card ", card_data.card_name, " at position ", position, " owned by ", "Player" if card_owner == Owner.PLAYER else "Opponent", " - should be active: ", should_be_active)
		
		# Apply or remove adaptive defense
		var context = {
			"passive_action": "apply" if should_be_active else "remove",
			"boosting_card": card_data,
			"boosting_position": position,
			"game_manager": self,
			"card_level": card_level
		}
		
		adaptive_defense_ability.execute(context)

func handle_adaptive_defense_ownership_change(grid_index: int):
	"""Handle adaptive defense when card ownership changes"""
	if not grid_occupied[grid_index]:
		return
	
	var card_data = get_card_at_position(grid_index)
	var card_level = get_card_level(get_card_collection_index(grid_index))
	
	if not card_data or not card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
		return
	
	# Check if this card has adaptive defense
	var adaptive_defense_ability = null
	for ability in card_data.get_available_abilities(card_level):
		if ability.ability_name == "Adaptive Defense":
			adaptive_defense_ability = ability
			break
	
	if not adaptive_defense_ability:
		return
	
	print("Handling adaptive defense ownership change for ", card_data.card_name, " at position ", grid_index)
	
	# Get new owner after capture
	var new_owner = get_owner_at_position(grid_index)
	var is_player_turn = turn_manager.is_player_turn()
	
	# Determine if adaptive defense should be active under new ownership
	var should_be_active = (new_owner == Owner.PLAYER and not is_player_turn) or (new_owner == Owner.OPPONENT and is_player_turn)
	
	print("New owner: ", "Player" if new_owner == Owner.PLAYER else "Opponent", " - should be active: ", should_be_active)
	
	# Apply or remove adaptive defense based on new ownership
	var context = {
		"passive_action": "apply" if should_be_active else "remove",
		"boosting_card": card_data,
		"boosting_position": grid_index,
		"game_manager": self,
		"card_level": card_level
	}
	
	adaptive_defense_ability.execute(context)


func should_apply_critical_strike(attacking_card: CardResource, attacker_position: int) -> bool:
	if not attacking_card:
		return false
	
	# Get the card level for ability checks
	var card_collection_index = get_card_collection_index(attacker_position)
	var card_level = get_card_level(card_collection_index)
	
	# Check if the card has critical strike ability and can still use it
	if attacking_card.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
		var abilities = attacking_card.get_available_abilities(card_level)
		for ability in abilities:
			if ability.ability_name == "Critical Strike":
				return CriticalStrikeAbility.can_use_critical_strike(attacking_card)
	
	return false

# Add this helper function to get the weakest stat
func get_weakest_stat_value(card_values: Array[int]) -> int:
	var weakest = card_values[0]
	for i in range(1, card_values.size()):
		if card_values[i] < weakest:
			weakest = card_values[i]
	return weakest
