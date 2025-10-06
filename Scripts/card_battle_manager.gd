# res://Scripts/card_battle_manager.gd
extends Node2D

# Player's deck (received from deck selection)
var player_deck: Array[CardResource] = []
var selected_deck_index: int = -1
var selected_card_index: int = -1

var battle_snapshot: Dictionary = {}

# Grid navigation variables
var current_grid_index: int = -1  # Current selected grid position
var grid_size: int = 3  # 3x3 grid
var grid_slots: Array = []  # References to grid slot panels
var grid_occupied: Array = []  # Track which slots have cards
var grid_ownership: Array = []  # Track who owns each card (can change via combat)
var grid_card_data: Array = []  # Track the actual card data for each slot

var discordant_active: bool = false

# Track Second Chance cards and their info for returning to hand
var second_chance_cards: Dictionary = {}  # Format: {grid_position: {card: CardResource, owner: Owner, collection_index: int}}

var aristeia_mode_active: bool = false
var current_aristeia_position: int = -1
var current_aristeia_owner: Owner = Owner.NONE
var current_aristeia_card: CardResource = null

var is_artemis_boss_battle: bool = false
var artemis_boss_counter_triggered: bool = false

# Cloak of Night ability tracking 
var cloak_of_night_active: bool = false
var cloak_of_night_turns_remaining: int = 0
var hidden_opponent_cards = [] # Positions of hidden opponent cards

# Rhythm power variables
var rhythm_slot: int = -1  # Current rhythm slot position (-1 means none)
var rhythm_boost_value: int = 1  # Current boost value (doubles on use)

# Experience tracking
var deck_card_indices: Array[int] = []  # Original indices in god's collection
var exp_panel: ExpPanel  # Reference to experience panel
var grid_to_collection_index: Dictionary = {}  # grid_index -> collection_index

var active_enemy_deck_power: EnemyDeckDefinition.EnemyDeckPowerType = EnemyDeckDefinition.EnemyDeckPowerType.NONE
var darkness_shroud_active: bool = false

var misdirection_used: bool = false

var disarray_active: bool = false

# Hermes boss visual inversion system
var is_hermes_boss_battle: bool = false
var visual_stat_inversion_active: bool = false

var fimbulwinter_boss_active: bool = false

# Tremor tracking system
var active_tremors: Dictionary = {}  # tremor_id -> tremor_data
var tremor_id_counter: int = 0

var soothe_active: bool = false

# Prophetic ability modal system
var opponent_hand_modal: OpponentHandModal = null
var game_paused_for_modal: bool = false

var active_volleys: Dictionary = {}  # volley_id -> volley_data
var volley_id_counter: int = 0
var volley_direction_modal: VolleyDirectionModal = null

# Enrich mode variables
var enrich_mode_active = false
var current_enricher_position = -1
var current_enricher_owner = Owner.NONE
var current_enricher_card: CardResource = null
var pending_enrichment_amount = 1

# Enrich visual style
var enrich_highlight_style: StyleBoxFlat

# Coerce tracking system
var coerce_mode_active: bool = false
var current_coercer_position: int = -1
var current_coercer_owner: Owner = Owner.NONE
var current_coercer_card: CardResource = null
var active_coerced_card_index: int = -1  # Index of card in player's hand that must be played
var coerced_card_style: StyleBoxFlat

# Camouflage tracking system
var active_camouflage_slots: Dictionary = {}  # slot_position -> camouflage_data
var camouflage_data = {
	"card": null,            # The camouflaged card
	"owner": Owner.NONE,     # Who owns the camouflaged card
	"turns_remaining": 0     # How many turns until it's revealed (1 turn duration)
}

# Compel tracking system
var compel_mode_active: bool = false
var current_compeller_position: int = -1
var current_compeller_owner: Owner = Owner.NONE
var current_compeller_card: CardResource = null
var active_compel_slot: int = -1  # The slot that opponent must play in
var compel_target_style: StyleBoxFlat

var dance_mode_active: bool = false
var current_dancer_position: int = -1
var current_dancer_owner: Owner = Owner.NONE
var current_dancer_card: CardResource = null

# Race mode tracking system
var race_mode_active: bool = false
var current_racer_position: int = -1
var current_racer_owner: Owner = Owner.NONE
var current_racer_card: CardResource = null

var ordain_mode_active: bool = false
var current_ordainer_position: int = -1
var current_ordainer_owner: Owner = Owner.NONE
var current_ordainer_card: CardResource = null
var active_ordain_slot: int = -1
var ordain_target_style: StyleBoxFlat
var active_ordain_owner: Owner = Owner.NONE  # Track who created the ordain effect
var active_ordain_turns_remaining: int = 0  # Track how many turns until ordain expires

# Coordinate power system
var coordinate_used: bool = false
var is_coordination_active: bool = false
var coordinate_button: Button = null


# Seasons power system
enum Season {
	SUMMER,
	WINTER
}

var current_season: Season = Season.SUMMER
var seasons_status_label: Label = null  # For displaying current season

# Sanctuary tracking system
var sanctuary_mode_active: bool = false
var current_sanctuary_position: int = -1
var current_sanctuary_owner: Owner = Owner.NONE
var current_sanctuary_card: CardResource = null
var active_sanctuary_slot: int = -1  # The slot that will grant cheat death to next friendly card
var sanctuary_target_style: StyleBoxFlat

# Trojan horse mode tracking
var trojan_horse_mode_active: bool = false
var current_trojan_summoner_position: int = -1
var current_trojan_summoner_owner: Owner = Owner.NONE
var current_trojan_summoner_card: CardResource = null
var active_trojan_horses: Array[int] = []  # Track positions of active trojan horses

var couple_definitions = {
	"Phaeton": "Cygnus",
	"Cygnus": "Phaeton", 
	"Orpheus": "Eurydice",
	"Eurydice": "Orpheus"
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
	
	# Add to battle manager group for cross-script communication
	add_to_group("battle_manager")
	
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


func setup_boss_prediction_tracker():
	# Check if this is a boss battle
	var params = get_scene_params()
	if params.has("current_node"):
		var current_node = params["current_node"]
		is_boss_battle = current_node.node_type == MapNode.NodeType.BOSS
		
		# Check for specific boss types using centralized config
		if is_boss_battle:
			if current_node.enemy_name == BossConfig.APOLLO_BOSS_NAME:
				print("Apollo boss battle detected - prediction system activated!")
				game_status_label.text = "The oracle's gaze pierces through time..."
			elif current_node.enemy_name == BossConfig.HERMES_BOSS_NAME:
				is_hermes_boss_battle = true
				visual_stat_inversion_active = true
				print("Hermes boss battle detected - visual stat inversion activated!")
				game_status_label.text = "The trickster's illusions warp your perception..."
			elif current_node.enemy_name == BossConfig.DEMETER_BOSS_NAME:
				print("Demeter boss battle detected!")
				game_status_label.text = "Winter will follow winter which follows winter"
			elif current_node.enemy_name == BossConfig.ARTEMIS_BOSS_NAME:
				is_artemis_boss_battle = true
				artemis_boss_counter_triggered = false
				print("Artemis boss battle detected - Coordinate counter activated!")
				game_status_label.text = "The hunter's prey becomes the predator..."
		
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
	
	# Pass game manager reference to opponent for AI decision making
	opponent_manager.set_game_manager(self)
	
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
		
		EnemyDeckDefinition.EnemyDeckPowerType.DISCORDANT:
			setup_discordant()
		
		EnemyDeckDefinition.EnemyDeckPowerType.NONE:
			print("No enemy deck power for this deck")
		_:
			print("Unknown enemy deck power type: ", active_enemy_deck_power)

func setup_discordant():
	print("=== SETTING UP DISCORDANT ===")
	discordant_active = true
	
	# Check if player has rhythm power active
	if active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER:
		print("🎭 Discordant activated! Wrong Note corrupts the rhythm's harmony.")
		
		# Clear any existing rhythm slot visuals
		if rhythm_slot >= 0:
			clear_rhythm_slot_visual(rhythm_slot)
		
		# Show notification
		if notification_manager:
			notification_manager.show_notification("🎭 The rhythm turns discordant - beware the wrong note!")
	else:
		print("Discordant ready, but no rhythm power detected")

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
	
	# Don't show hover info for cloaked cards
	var all_displays = get_tree().get_nodes_in_group("battle_manager")
	for node in all_displays:
		if node == self:
			for i in range(grid_slots.size()):
				var card_display = get_card_display_at_position(i)
				if card_display and card_display.card_data == card_data:
					if card_display.get_meta("cloaked", false):
						return
	
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
	
	create_battle_snapshot()
	
	# DO NOT clear run stat growth tracker - we want to preserve growth across battles
	# Only ensure the tracker knows about the current deck indices
	if has_node("/root/RunStatGrowthTrackerAutoload"):
		var growth_tracker = get_node("/root/RunStatGrowthTrackerAutoload")
		# Update current deck indices but preserve existing growth data
		growth_tracker.update_deck_indices(deck_card_indices)
		print("Updated run stat growth tracker with current deck indices (preserving growth)")
	
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

func _on_coin_flip_result(player_goes_first: bool):
	# Override coin flip result if prophecy power is active
	if active_deck_power == DeckDefinition.DeckPowerType.PROPHECY_POWER:
		player_goes_first = true
		game_status_label.text = "🔮 Divine Prophecy reveals the path! You go first."
		# Force the turn manager to recognize player goes first
		turn_manager.current_player = TurnManager.Player.HUMAN
		
		# Activate boss prediction tracking for Apollo decks (but not during boss battles)
		if current_god == "Apollo" and not is_boss_battle:
			get_node("/root/BossPredictionTrackerAutoload").start_recording_battle()
			# Show atmospheric notification
			if notification_manager:
				notification_manager.show_notification("You know you are being watched")
	elif player_goes_first:
		game_status_label.text = "You won the coin flip! You go first."
		# Only start boss prediction tracking when player is using Apollo deck (but not during boss battles)
		if current_god == "Apollo" and not is_boss_battle:
			get_node("/root/BossPredictionTrackerAutoload").start_recording_battle()
			# Show atmospheric notification
			if notification_manager:
				notification_manager.show_notification("You get the feeling you are being watched")
	else:
		game_status_label.text = "Opponent won the coin flip! They go first."
		# Handle boss-specific dialogue
		if is_boss_battle:
			var params = get_scene_params()
			if params.has("current_node"):
				var current_node = params["current_node"]
				if current_node.enemy_name == BossConfig.APOLLO_BOSS_NAME:
					game_status_label.text = "The boss allows you to go first... 'I know what you will do.'"
				elif current_node.enemy_name == BossConfig.HERMES_BOSS_NAME:
					game_status_label.text = "The trickster grins... 'After you, mortal.'"
				else:
					game_status_label.text = "The boss allows you to go first..."
			else:
				game_status_label.text = "The boss allows you to go first..."
			turn_manager.current_player = TurnManager.Player.HUMAN
			player_goes_first = true
	
	# Brief pause to show result
	await get_tree().create_timer(2.0).timeout
	
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
	# Process cloak of night turn tracking
	process_cloak_of_night_turn()
	
	print("*** TURN CHANGED EVENT FIRED: is_player_turn=", is_player_turn, " ***")
	print("Turn changed - is_player_turn: ", is_player_turn, " | opponent_is_thinking: ", opponent_is_thinking)
	update_game_status()
	
	# Handle ordain effect expiration - expires after one turn
	handle_ordain_turn_expiration()
	
	# Process adaptive defense abilities on turn change
	handle_adaptive_defense_turn_change(is_player_turn)
	
	# Process morph abilities at the start of every turn (both owners)
	process_morph_turn_start()
	process_camouflage_turn_end()
	# Process cultivation abilities at the start of player's turn
	if is_player_turn:
		process_cultivation_turn_start()
	else:
		# Process corruption abilities at the start of opponent's turn
		process_corruption_turn_start()
		# Process greedy abilities at the start of opponent's turn
		process_greedy_turn_start()
	
	# Process charge abilities at the start of each turn
	await process_charge_turn_start(is_player_turn)
	
	# Process tremors at the start of each player's turn
	if is_player_turn:
		# Reassign rhythm slot at the start of Apollo player's turn
		if active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER:
			# Clear previous rhythm slot visual if it exists
			if rhythm_slot >= 0:
				clear_rhythm_slot_visual(rhythm_slot)
			# Assign new rhythm slot
			assign_new_rhythm_slot()
		process_tremors_for_player(Owner.PLAYER)
		process_volleys_for_player(Owner.PLAYER)
		enable_player_input()
		if is_boss_battle:
			make_boss_prediction()
	else:
		process_tremors_for_player(Owner.OPPONENT)
		process_volleys_for_player(Owner.OPPONENT)
		disable_player_input()
		# Only start opponent turn if not already thinking
		if not opponent_is_thinking and not is_tutorial_mode and not game_paused_for_modal:
			call_deferred("opponent_take_turn")
		elif game_paused_for_modal:
			print("Game paused for modal - deferring opponent turn until modal closes")

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
	if discordant_active and active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER:
		special_status = "🎭 Discordant vs 🎵 Rhythm - Wrong notes corrupt the harmony! "
	elif discordant_active:
		special_status = "🎭 Discordant active - Wrong notes await... "
	
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

func opponent_take_turn():
	# Check if game is paused for modal - if so, defer the turn
	if game_paused_for_modal:
		print("Game paused for modal - opponent turn deferred")
		return
		
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
	
	# Get available slots considering compel constraints - FIXED: Use new helper function
	var available_slots: Array[int] = get_available_slots_for_opponent()
	
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
	
	# Execute Bolster Confidence on the attacking card if it made any captures
	if captures.size() > 0:
		var attacking_card_level = 0
		if attacking_owner == Owner.PLAYER:
			var attacking_card_index = get_card_collection_index(grid_index)
			attacking_card_level = get_card_level(attacking_card_index)
		
		var available_abilities = attacking_card.get_available_abilities(attacking_card_level)
		for ability in available_abilities:
			if ability.ability_name == "Bolster Confidence":
				print("DEBUG: Attacking card ", attacking_card.card_name, " has Bolster Confidence - checking captures")
				
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
				break
	
	# Apply all captures and handle passive abilities - WITH SECOND CHANCE CHECKS
	var successful_captures = []
	
	for captured_index in captures:
		print("=== PROCESSING POTENTIAL CAPTURE AT POSITION ", captured_index, " ===")
		
		var captured_card_data = grid_card_data[captured_index]
		var captured_owner = grid_ownership[captured_index]
		print("DEBUG: Potential capture of: ", captured_card_data.card_name if captured_card_data else "NULL")
		
		# Check for null card data
		if captured_card_data == null:
			print("ERROR: captured_card_data is null at position ", captured_index, " - skipping")
			continue
		
		# DISARRAY: Check if this is a confused friendly attacking friendly
		var is_confused = attacking_card.has_meta("disarray_confused") and attacking_card.get_meta("disarray_confused")
		var is_friendly_fire = (attacking_owner == captured_owner)
		
		if is_confused and is_friendly_fire:
			print("DISARRAY FRIENDLY FIRE: Confused card captured friendly - giving to opponent!")
			var new_owner = Owner.OPPONENT if attacking_owner == Owner.PLAYER else Owner.PLAYER
			attacking_owner = new_owner
		
		# ===== NEW: Check for Second Chance BEFORE processing capture =====
		var second_chance_prevented = try_second_chance_rescue(captured_index, captured_card_data, grid_index, attacking_card, attacking_owner)
		
		if second_chance_prevented:
			print("SECOND CHANCE! ", captured_card_data.card_name, " returned to hand instead of being captured!")
			continue  # Skip the actual capture for this card
		
		# ===== NEW: Check for Cheat Death BEFORE processing capture =====
		var cheat_death_prevented = check_for_cheat_death(captured_index, captured_card_data, grid_index, attacking_card)
		
		if cheat_death_prevented:
			print("CHEAT DEATH! Capture of ", captured_card_data.card_name, " at position ", captured_index, " was prevented!")
			
			if attacking_owner == Owner.PLAYER:
				var card_collection_index = get_card_collection_index(grid_index)
				if card_collection_index != -1:
					var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
					if exp_tracker:
						exp_tracker.add_capture_exp(card_collection_index, 5)
						print("Player gained 5 exp for attack (capture prevented by cheat death)")
			
			continue  # Skip the actual capture for this card
		
		# CAPTURE SUCCESSFUL - Show visual effects
		var attacking_card_display = get_card_display_at_position(grid_index)
		if attacking_card_display and visual_effects_manager:
			var is_player_attack = (attacking_owner == Owner.PLAYER)
			var attack_direction = get_direction_between_positions(grid_index, captured_index)
			if attack_direction != -1:
				visual_effects_manager.show_capture_flash(attacking_card_display, attack_direction, is_player_attack)
		
		# Normal capture processing - Remove passive abilities BEFORE changing ownership
		handle_passive_abilities_on_capture(captured_index, captured_card_data)
		
		# Change ownership
		grid_ownership[captured_index] = attacking_owner
		print("Card at slot ", captured_index, " is now owned by ", "Player" if attacking_owner == Owner.PLAYER else "Opponent")
		
		# Award capture experience
		if attacking_owner == Owner.PLAYER:
			var card_collection_index = get_card_collection_index(grid_index)
			if card_collection_index != -1:
				var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
				if exp_tracker:
					exp_tracker.add_capture_exp(card_collection_index, 10)
					print("Player card at position ", grid_index, " gained 10 capture exp")
		
		# Track successful capture
		successful_captures.append(captured_index)
		
		# Execute ON_CAPTURE abilities on the captured card
		var card_collection_index = get_card_collection_index(captured_index)
		var card_level = get_card_level(card_collection_index)
		
		if captured_card_data.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, card_level):
			print("DEBUG: Executing ON_CAPTURE abilities for captured card: ", captured_card_data.card_name)
			
			var capture_context = {
				"capturing_card": attacking_card,
				"capturing_position": grid_index,
				"captured_card": captured_card_data,
				"captured_position": captured_index,
				"game_manager": self,
				"direction": "standard_combat",
				"card_level": card_level
			}
			
			captured_card_data.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, card_level)
		
		# Check if newly captured card has passive abilities for new owner
		if captured_card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			print("Checking if passive abilities should restart for captured card at position ", captured_index)
			
			var new_owner = attacking_owner
			var available_abilities = captured_card_data.get_available_abilities(card_level)
			var active_abilities_for_new_owner = []
			
			for ability in available_abilities:
				if ability.trigger_condition == CardAbility.TriggerType.PASSIVE:
					active_abilities_for_new_owner.append(ability)
					print("Passive ability ", ability.ability_name, " will be active for new owner")
			
			print("Restarted ", active_abilities_for_new_owner.size(), " passive abilities for captured card")
	
	# Update visuals for all ownership changes
	update_board_visuals()
	
	return successful_captures.size()

func resolve_standard_combat(grid_index: int, attacking_owner: Owner, attacking_card: CardResource) -> Array[int]:
	
	print("=== RESOLVE_STANDARD_COMBAT DEBUG ===")
	print("Attacking card: ", attacking_card.card_name)
	print("Has disarray_confused meta: ", attacking_card.has_meta("disarray_confused"))
	if attacking_card.has_meta("disarray_confused"):
		print("Disarray value: ", attacking_card.get_meta("disarray_confused"))
	
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
				
				# Check if card is confused by disarray (attacks both friendlies and enemies)
				var is_confused = attacking_card.has_meta("disarray_confused") and attacking_card.get_meta("disarray_confused")
				
				print("DEBUG DISARRAY CHECK: Direction ", direction.name, " - adjacent_owner: ", adjacent_owner, " attacking_owner: ", attacking_owner, " is_confused: ", is_confused)
				
				# Check if there's a card to fight: enemy OR (friendly if confused)
				if adjacent_owner != Owner.NONE and (adjacent_owner != attacking_owner or is_confused):
					var adjacent_card = grid_card_data[adj_index]
					
					if not attacking_card or not adjacent_card:
						print("Warning: Missing card data in combat resolution")
						continue
					
					# Check for Perfect Aim ability first
					var my_value: int
					if PerfectAimAbility.has_perfect_aim(attacking_card):
						my_value = PerfectAimAbility.get_perfect_aim_value(attacking_card)
						print("PERFECT AIM! Using highest stat: ", my_value, " instead of directional stat: ", attacking_card.values[direction.my_value_index])
					else:
						my_value = attacking_card.values[direction.my_value_index]
					
					var their_value: int

					# Check for critical strike first
					if should_apply_critical_strike(attacking_card, grid_index):
						# Use the defending card's weakest stat instead of directional stat
						their_value = get_weakest_stat_value(adjacent_card.values)
						print("CRITICAL STRIKE! Using enemy's weakest stat: ", their_value, " instead of directional stat: ", adjacent_card.values[direction.their_value_index])
						
						# Mark critical strike as used
						CriticalStrikeAbility.mark_critical_strike_used(attacking_card)
					elif should_apply_backstab(attacking_card, grid_index):
						# Use the backstab defense value (opposing stat instead of adjacent)
						their_value = BackstabAbility.get_backstab_defense_value(adjacent_card, direction.their_value_index)
						
						# Mark backstab as used
						BackstabAbility.mark_backstab_used(attacking_card)
					else:
						# Normal combat - use directional stat
						their_value = adjacent_card.values[direction.their_value_index]
					
					print("Combat ", direction.name, ": My ", my_value, " vs Their ", their_value)
					
					# Check for Exploit ability - doubles attack if attacking weakest stat
					if should_apply_exploit(attacking_card, grid_index):
						if ExploitAbility.is_attacking_weakest_stat(attacking_card, adjacent_card, direction.my_value_index):
							my_value = my_value * 2
							print("EXPLOIT! Doubled attack value from ", my_value / 2, " to ", my_value)
							
							# Update the visual display to show doubled attack
							var slot = grid_slots[grid_index]
							for child in slot.get_children():
								if child is CardDisplay:
									# Temporarily boost the card's displayed value for visual feedback
									attacking_card.values[direction.my_value_index] = my_value
									child.card_data = attacking_card
									child.update_display()
									print("ExploitAbility: Updated CardDisplay visual for doubled attack")
									break
							
							# Mark exploit as used
							ExploitAbility.mark_exploit_used(attacking_card)
					
					if my_value > their_value:
						print("Captured card at slot ", adj_index, "!")
						captures.append(adj_index)
						handle_standard_combat_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, direction)
					else:
						handle_standard_defense_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, direction)
	
	return captures

func check_for_cheat_death(defender_pos: int, defending_card: CardResource, attacker_pos: int, attacking_card: CardResource) -> bool:
	print("=== CHECK_FOR_CHEAT_DEATH DEBUG ===")
	print("Defender position: ", defender_pos)
	print("Defending card: ", defending_card.card_name if defending_card else "NULL")
	print("Attacker position: ", attacker_pos)
	print("Attacking card: ", attacking_card.card_name if attacking_card else "NULL")
	
	# Clear any previous cheat death flags for this position
	remove_meta("cheat_death_prevented_" + str(defender_pos))
	
	# Check for sanctuary-granted cheat death first
	var has_sanctuary_cheat_death = defending_card.has_meta("sanctuary_cheat_death") and defending_card.get_meta("sanctuary_cheat_death")
	print("Has sanctuary cheat death metadata: ", has_sanctuary_cheat_death)
	
	if has_sanctuary_cheat_death:
		print("SANCTUARY CHEAT DEATH! ", defending_card.card_name, " has sanctuary protection!")
		
		# Remove the sanctuary cheat death after use (one-time use)
		defending_card.set_meta("sanctuary_cheat_death", false)
		
		# Set the prevention flag
		set_meta("cheat_death_prevented_" + str(defender_pos), true)
		
		print("Sanctuary cheat death activated for ", defending_card.card_name, "!")
		print("=== SANCTUARY CHEAT DEATH SUCCESS ===")
		return true
	
	# Execute normal defend abilities to see if any prevent capture
	print("Checking normal defend abilities for cheat death...")
	execute_defend_abilities(defender_pos, defending_card, attacker_pos, attacking_card, "capture_attempt")
	
	# Check if normal cheat death was triggered
	var was_prevented = has_meta("cheat_death_prevented_" + str(defender_pos)) and get_meta("cheat_death_prevented_" + str(defender_pos))
	print("Normal cheat death prevented: ", was_prevented)
	
	# Clean up the flag
	if was_prevented:
		remove_meta("cheat_death_prevented_" + str(defender_pos))
	
	print("=== CHECK_FOR_CHEAT_DEATH RESULT: ", was_prevented or has_sanctuary_cheat_death, " ===")
	return was_prevented

# NEW FUNCTION - Award experience for successful attack even when capture is prevented
func award_attack_experience(attacker_pos: int, attacking_owner: Owner, attacking_card: CardResource):
	if attacking_owner == Owner.PLAYER:
		var card_collection_index = get_card_collection_index(attacker_pos)
		if card_collection_index != -1:
			var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(card_collection_index, 5)  # Reduced exp since capture was prevented
				print("Player card at position ", attacker_pos, " gained 5 exp for successful attack (capture prevented)")

func resolve_extended_range_combat(grid_index: int, attacking_owner: Owner, attacking_card: CardResource) -> Array[int]:
	print("=== RESOLVE_EXTENDED_RANGE_combat DEBUG ===")
	print("Attacking card: ", attacking_card.card_name)
	print("Has disarray_confused meta: ", attacking_card.has_meta("disarray_confused"))
	if attacking_card.has_meta("disarray_confused"):
		print("Disarray value: ", attacking_card.get_meta("disarray_confused"))
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
			
			# Check if card is confused by disarray (attacks both friendlies and enemies)
			var is_confused = attacking_card.has_meta("disarray_confused") and attacking_card.get_meta("disarray_confused")
			
			print("DEBUG DISARRAY CHECK (Extended): Direction ", direction_name, " - adjacent_owner: ", adjacent_owner, " attacking_owner: ", attacking_owner, " is_confused: ", is_confused)
			
			# Check if there's a card to fight: enemy OR (friendly if confused)
			if adjacent_owner != Owner.NONE and (adjacent_owner != attacking_owner or is_confused):
				var adjacent_card = grid_card_data[adj_index]
				
				if not attacking_card or not adjacent_card:
					print("Warning: Missing card data in extended combat resolution")
					continue
				
				# Check for Perfect Aim ability first (overrides Extended Range calculations)
				var my_attack_value: int
				if PerfectAimAbility.has_perfect_aim(attacking_card):
					my_attack_value = PerfectAimAbility.get_perfect_aim_value(attacking_card)
					print("PERFECT AIM (Extended)! Using highest stat: ", my_attack_value)
				else:
					my_attack_value = ExtendedRangeAbility.get_attack_value_for_direction(attacking_card.values, direction)
				
				var their_defense_value: int
				
				## Check for critical strike first
				if should_apply_critical_strike(attacking_card, grid_index):
					# Use the defending card's weakest stat instead of calculated defense
					their_defense_value = get_weakest_stat_value(adjacent_card.values)
					print("CRITICAL STRIKE (Extended)! Using enemy's weakest stat: ", their_defense_value, " instead of calculated defense: ", ExtendedRangeAbility.get_defense_value_for_direction(adjacent_card.values, direction))
					
					# Mark critical strike as used
					CriticalStrikeAbility.mark_critical_strike_used(attacking_card)
				elif should_apply_backstab(attacking_card, grid_index):
					# Use the extended backstab calculation which handles both orthogonal and diagonal attacks
					their_defense_value = BackstabAbility.get_extended_backstab_defense_value(adjacent_card, direction)
					print("BACKSTAB (Extended)! Using backstab defense instead of normal extended defense")
					
					# Mark backstab as used
					BackstabAbility.mark_backstab_used(attacking_card)
				else:
					# Normal extended combat - use calculated defense value
					their_defense_value = ExtendedRangeAbility.get_defense_value_for_direction(adjacent_card.values, direction)
				
				print("Extended Combat ", direction_name, " (", "diagonal" if is_diagonal else "orthogonal", "): My ", my_attack_value, " vs Their ", their_defense_value)
				
				if my_attack_value > their_defense_value:
					print("Extended range captured card at slot ", adj_index, "!")
					captures.append(adj_index)
					handle_extended_combat_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, direction_name)
				else:
					handle_extended_defense_effects(grid_index, adj_index, attacking_owner, attacking_card, adjacent_card, direction_name)
	
	return captures
# Add helper function to get collection index from grid position
func get_card_collection_index(grid_index: int) -> int:
	if grid_index in grid_to_collection_index:
		return grid_to_collection_index[grid_index]
	return -1

func update_board_visuals():
	for i in range(grid_slots.size()):
		if grid_occupied[i]:
			var slot = grid_slots[i]
			var card_display = get_card_display_at_position(i)
			
			if card_display and card_display.panel:
				# DON'T override styling for camouflaged cards
				if is_slot_camouflaged(i):
					print("Skipping board visual update for camouflaged card at position ", i)
					continue
				
				# Force apply the correct ownership styling
				if grid_ownership[i] == Owner.PLAYER:
					card_display.panel.add_theme_stylebox_override("panel", player_card_style)
					print("Applied PLAYER styling to card at position ", i)
				elif grid_ownership[i] == Owner.OPPONENT:
					card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
					print("Applied OPPONENT styling to card at position ", i)
				else:
					print("Warning: Card at position ", i, " has no clear owner")
			else:
				print("Warning: No valid card display at position ", i)

func _on_opponent_card_placed(grid_index: int):
	print("Opponent card placed signal received for slot: ", grid_index)
	
	if grid_index < 0 or grid_index >= grid_slots.size():
		print("Invalid grid index from opponent: ", grid_index)
		opponent_is_thinking = false  # Reset thinking flag on error
		return
	
	# CAMOUFLAGE CHECK: Before processing placement, check if this triggers camouflage capture
	if check_camouflage_capture(grid_index, Owner.OPPONENT):
		# Camouflage was triggered - the capture sequence has been executed
		# The opponent's card is captured and cannot be placed
		print("Opponent's card was captured by camouflage!")
		opponent_is_thinking = false
		
		# Switch turns back to player after camouflage capture
		turn_manager.next_turn()
		return
	
	if grid_occupied[grid_index]:
		print("Opponent tried to place card on occupied slot!")
		opponent_is_thinking = false  # Reset thinking flag on error
		return
	
	# Check if opponent is respecting compel constraint
	if active_compel_slot != -1:
		if grid_index == active_compel_slot:
			print("Opponent correctly placed card in compelled slot ", grid_index)
			remove_compel_constraint()  # Remove the constraint after it's fulfilled
		else:
			print("ERROR: Opponent should have been forced to play in slot ", active_compel_slot, " but played in ", grid_index)
			# For now, just log the error and continue
	
	# Get the card data that the opponent just played
	var opponent_card_data = opponent_manager.get_last_played_card()
	if not opponent_card_data:
		print("Warning: Could not get opponent card data!")
		opponent_is_thinking = false
		return
	
	# : Create a deep copy of the card data to avoid modifying the original
	opponent_card_data = opponent_card_data.duplicate(true)
	
	# Apply Soothe effect if active - MUST be done BEFORE other modifications
	if soothe_active:
		print("Applying Soothe effect to opponent card: ", opponent_card_data.card_name)
		print("Original stats: ", opponent_card_data.values)
		
		# Reduce all stats by 1, minimum 0
		for i in range(opponent_card_data.values.size()):
			opponent_card_data.values[i] = max(0, opponent_card_data.values[i] - 1)
		
		print("Soothed stats: ", opponent_card_data.values)
		
		# Deactivate soothe after use
		soothe_active = false
		print("Soothe effect has been consumed")
		
		# Apply Disarray effect if active - mark the card as confused
	if disarray_active:
		print("Applying Disarray effect to opponent card: ", opponent_card_data.card_name)
		
		# Mark this card as confused (will attack both friendlies and enemies)
		opponent_card_data.set_meta("disarray_confused", true)
		
		print("Disarray effect applied - card will attack both friendly and enemy cards")
		
		# Deactivate disarray after use
		disarray_active = false
		print("Disarray effect has been consumed")
		
	if not opponent_card_data:
		print("Warning: Could not get opponent card data!")
		opponent_is_thinking = false
		return
	
	# Check if opponent card should trigger ordain effect removal (no bonus for opponent)
	apply_ordain_bonus_if_applicable(grid_index, opponent_card_data, Owner.OPPONENT)
	
	# Get opponent card level using existing pattern
	var opponent_card_level = get_card_level(0)  # Follow existing implementation pattern
	
	# DEBUG: Check the opponent card data
	print("=== OPPONENT CARD DEBUG ===")
	print("Card name: ", opponent_card_data.card_name)
	print("Card level: ", opponent_card_level)
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
	card_display.setup(opponent_card_data, opponent_card_level, current_god, 0, true)  # true = is_opponent_card
	
	# EXECUTE ON-PLAY ABILITIES AFTER display setup is complete
	if opponent_card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, opponent_card_level):
		print("Opponent card has on-play abilities - executing AFTER display setup")
		
		var ability_context = {
			"placed_card": opponent_card_data,
			"grid_position": grid_index,
			"game_manager": self,
			"card_level": opponent_card_level
		}
		opponent_card_data.execute_abilities(CardAbility.TriggerType.ON_PLAY, ability_context, opponent_card_level)
	
	# Connect hover signals for opponent cards too
	card_display.card_hovered.connect(_on_card_hovered)
	card_display.card_unhovered.connect(_on_card_unhovered)
	print("Connected hover signals for opponent card: ", opponent_card_data.card_name)
	
	if card_display and card_display.panel:
		card_display.panel.gui_input.connect(_on_grid_card_right_click.bind(grid_index))
		print("Connected right-click handler for opponent card at grid position ", grid_index)
	
	# Apply opponent card styling to the slot (not the card display) - BUT NOT if camouflaged  
	if not is_slot_camouflaged(grid_index):
		slot.add_theme_stylebox_override("panel", opponent_card_style)
	
	print("Opponent card abilities: ", opponent_card_data.abilities.size())
	for i in range(opponent_card_data.abilities.size()):
		var ability = opponent_card_data.abilities[i]
		print("  Ability ", i, ": ", ability.ability_name, " - ", ability.description)
	
	# Check for hunt traps when opponent places cards
	check_hunt_trap_trigger(grid_index, opponent_card_data, Owner.OPPONENT)
	
	# Handle passive abilities when opponent places card
	handle_passive_abilities_on_place(grid_index, opponent_card_data, opponent_card_level)
	
	# Register if this card has Second Chance
	register_second_chance_if_needed(grid_index, opponent_card_data, Owner.OPPONENT)
	
	# Resolve combat
	var captures = resolve_combat(grid_index, Owner.OPPONENT, opponent_card_data)
	if captures > 0:
		print("Opponent captured ", captures, " cards!")
		
	# Update the score display immediately after combat
	update_game_status()
	
	# NEW: CHECK FOR PURSUIT TRIGGERS AFTER OPPONENT'S TURN IS COMPLETE
	print("Checking for Pursuit ability triggers...")
	check_pursuit_triggers(grid_index, opponent_card_data)
	
	# If cloak of night is active, hide the newly placed card
	if cloak_of_night_active:
		hide_opponent_card_at_position(grid_index)
	
	# Clear the thinking flag since opponent finished their turn
	opponent_is_thinking = false
	print("Opponent finished turn - setting thinking flag to false")
	
	# Check if game should end
	if should_game_end():
		end_game()
		return
	
	# ARTEMIS BOSS MECHANIC: Check if we need a second turn after counter
	if is_artemis_boss_battle and artemis_boss_counter_triggered:
		# We're in the Artemis counter sequence
		# Check if this was the FIRST opponent turn after the counter
		# We can track this by checking if we're still on opponent turn and counter is triggered
		
		# Brief visual pause
		await get_tree().create_timer(0.5).timeout
		
		# Check if opponent can take another turn
		var available_slots_second: Array[int] = get_available_slots_for_opponent()
		if not available_slots_second.is_empty() and opponent_manager.has_cards():
			# Take second turn - don't switch players yet
			call_deferred("opponent_take_turn")
			# After this second turn completes, we'll check artemis_second_turn_complete
			set_meta("artemis_second_turn", true)  # Mark that next opponent turn is the second one
			return
		elif has_meta("artemis_second_turn"):
			# This WAS the second turn, now switch to player
			remove_meta("artemis_second_turn")
			print("Artemis boss second turn complete - switching to player")
	
	
	print("Switching turns after opponent move")
	
	# Switch turns - this should make it the player's turn
	turn_manager.next_turn()

func should_game_end() -> bool:
	# Check board fullness
	var available_slots = 0
	for occupied in grid_occupied:
		if not occupied:
			available_slots += 1
	
	# If board is full, clean up trojan horses first
	if available_slots == 0:
		check_trojan_horse_cleanup()
		# Re-check after cleanup
		available_slots = 0
		for occupied in grid_occupied:
			if not occupied:
				available_slots += 1
	
	# Game ends if board is full or both players are out of cards
	return available_slots == 0 or (player_deck.is_empty() and not opponent_manager.has_cards())

# REPLACE the entire end_game() function in Scripts/card_battle_manager.gd

func end_game():
	# Clean up all tremor visual effects first
	if visual_effects_manager:
		visual_effects_manager.clear_all_tremor_shake_effects(grid_slots)
		visual_effects_manager.clear_all_hunt_effects(grid_slots)
	
	clear_all_hunt_traps()
	clear_all_compel_constraints()
	clear_all_coerce_constraints()
	clear_all_ordain_effects()
	clear_all_sanctuary_effects()
	clear_all_trojan_horses()
	clear_all_camouflage_effects()
	misdirection_used = false
	
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
			game_status_label.text = "You did well! The basics are yours."
		
		# Show tutorial completion message for a moment
		await get_tree().create_timer(3.0).timeout
		
		# Mark tutorial as completed and go to god selection
		if has_node("/root/TutorialManagerAutoload"):
			get_node("/root/TutorialManagerAutoload").mark_tutorial_completed()
		
		_on_tutorial_finished()
		return
	
	# Calculate final scores for normal games
	var scores = get_current_scores()
	var winner = ""
	
	if scores.player > scores.opponent:
		winner = "Player Wins!"
	elif scores.opponent > scores.player:
		winner = "Opponent Wins!"
	else:
		winner = "It's a Draw!"
	
	print("=== GAME ENDED ===")
	print("Final Score - Player: ", scores.player, " | Opponent: ", scores.opponent)
	print("Result: ", winner)
	print("==================")
	
	# SIMPLIFIED DRAW HANDLING - No more consecutive draw tracking
	if scores.player == scores.opponent:
		print("Draw detected - restarting battle from snapshot")
		game_status_label.text = "Draw! Restarting battle..."
		disable_player_input()
		opponent_is_thinking = false
		turn_manager.end_game()
		
		# Show draw message briefly then restart
		await get_tree().create_timer(2.0).timeout
		restart_round()
		return
	
	# Check for loss condition
	if scores.opponent > scores.player:
		# Player lost
		game_status_label.text = "Defeat! " + winner
		disable_player_input()
		opponent_is_thinking = false
		turn_manager.end_game()
		
		record_enemy_encounter(false)  
		record_god_experience()
		check_god_unlocks()
		
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
		
		# Clear the battle snapshot since the battle is over
		clear_battle_snapshot()
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
			
			# IMPORTANT: Record the boss encounter BEFORE going to run summary
			record_enemy_encounter(true)  # true = victory
			record_god_experience()
			check_god_unlocks()
			
			# Pass data to summary screen with victory
			get_tree().set_meta("scene_params", {
				"god": params.get("god", current_god),
				"deck_index": params.get("deck_index", 0),
				"victory": true
			})
			TransitionManagerAutoload.change_scene_to("res://Scenes/RunSummary.tscn")
			
			# Clear the battle snapshot since the battle is over
			clear_battle_snapshot()
			return
	
	# Not the final boss - continue with reward screen
	show_reward_screen()
	
	# Clear the battle snapshot since the battle is over
	clear_battle_snapshot()

func restart_round():
	print("=== RESTARTING ROUND DUE TO DRAW ===")
	
	# Use snapshot restoration instead of manual deck restoration
	var restoration_success = restore_battle_from_snapshot()
	if not restoration_success:
		print("ERROR: Failed to restore from battle snapshot!")
		# Fallback to end game as loss
		end_game()
		return
	
	# Reset card selection state
	selected_card_index = -1
	current_grid_index = -1
	
	# Reset game state flags
	opponent_is_thinking = false
	hunt_mode_active = false
	
	# Redisplay player hand with restored card data
	display_player_hand()
	
	# Verify hand display worked
	await get_tree().process_frame
	var hand_container_cards = hand_container.get_node_or_null("CardsContainer")
	if not hand_container_cards or hand_container_cards.get_child_count() == 0:
		print("ERROR: Failed to display player hand after snapshot restore!")
		end_game()
		return
	
	print("Round restart from snapshot successful - starting new coin flip")
	
	# Brief pause to show result, then start new game
	await get_tree().create_timer(2.0).timeout
	turn_manager.start_game()



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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		print("DEBUG: Right-click detected in _input(), allowing it to pass through")
		return  # Don't consume right-clicks, let them reach the grid slots
	
	# Only process keyboard input if it's the player's turn and a card is selected
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
	
	# Compel target style (purple border for compelled slots)
	compel_target_style = StyleBoxFlat.new()
	compel_target_style.bg_color = Color("#444444")
	compel_target_style.border_width_left = 3
	compel_target_style.border_width_top = 3
	compel_target_style.border_width_right = 3
	compel_target_style.border_width_bottom = 3
	compel_target_style.border_color = Color("#AA44FF")  # Purple border for compel
	
	# Ordain target style (golden border for ordained slots)
	ordain_target_style = StyleBoxFlat.new()
	ordain_target_style.bg_color = Color("#444444")
	ordain_target_style.border_width_left = 3
	ordain_target_style.border_width_top = 3
	ordain_target_style.border_width_right = 3
	ordain_target_style.border_width_bottom = 3
	ordain_target_style.border_color = Color("#FFD700")  # Golden border for ordain

	# Sanctuary target style (cyan/teal border to distinguish from other effects)
	sanctuary_target_style = StyleBoxFlat.new()
	sanctuary_target_style.bg_color = Color("#444444")
	sanctuary_target_style.border_width_left = 3
	sanctuary_target_style.border_width_top = 3
	sanctuary_target_style.border_width_right = 3
	sanctuary_target_style.border_width_bottom = 3
	sanctuary_target_style.border_color = Color("#00FFAA")  # Cyan/teal border
	
	# Enrich highlight style (green border for slot selection)
	enrich_highlight_style = StyleBoxFlat.new()
	enrich_highlight_style.bg_color = Color("#444444")
	enrich_highlight_style.border_width_left = 3
	enrich_highlight_style.border_width_top = 3
	enrich_highlight_style.border_width_right = 3
	enrich_highlight_style.border_width_bottom = 3
	enrich_highlight_style.border_color = Color("#00FF44")  # Green border for enrich selection
	
	create_coerced_card_style()

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
		
		slot.mouse_filter = Control.MOUSE_FILTER_PASS
		
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
		# Initialize enrichment displays
		call_deferred("initialize_enrichment_displays")

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
		DeckDefinition.DeckPowerType.MISDIRECTION_POWER:
			setup_misdirection_power()
		DeckDefinition.DeckPowerType.SEASONS_POWER:
			setup_seasons_power()
		DeckDefinition.DeckPowerType.COORDINATE_POWER:
			setup_coordinate_power()	
		DeckDefinition.DeckPowerType.RHYTHM_POWER:
			setup_rhythm_power()	
		DeckDefinition.DeckPowerType.NONE:
			print("No deck power for this deck")
		_:
			print("Unknown deck power type: ", active_deck_power)

func setup_misdirection_power():
	print("=== SETTING UP MISDIRECTION POWER ===")
	misdirection_used = false
	print("Misdirection power ready - right-click enemy cards to invert their stats")

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
		DeckDefinition.DeckPowerType.RHYTHM_POWER:
			print("DEBUG: Checking rhythm power at position ", grid_position)
			if grid_position == rhythm_slot:
				return apply_rhythm_boost(card_data)
			return false	
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

func get_card_level(card_collection_index: int) -> int:
	# Check if this is Persephone (index 0 in Demeter collection)
	if current_god == "Demeter" and card_collection_index == 0:
		return get_persephone_level()
	
	# For all other cards, use the normal system
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		return progress_tracker.get_card_level(current_god, card_collection_index)
	
	return 1  # Default level

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
		
		# FOR HAND DISPLAY: Create a copy of the card with level-appropriate values AND growth
		var hand_card_data = card.duplicate()
		var effective_values = card.get_effective_values(current_level)
		var effective_abilities = card.get_effective_abilities(current_level)
		
		# Apply stat growth from the run tracker
		if has_node("/root/RunStatGrowthTrackerAutoload"):
			var growth_tracker = get_node("/root/RunStatGrowthTrackerAutoload")
			effective_values = growth_tracker.apply_growth_to_card_values(effective_values, card_collection_index)
		
		# Apply the level-appropriate values AND growth to the hand display copy
		hand_card_data.values = effective_values.duplicate()
		hand_card_data.abilities = effective_abilities.duplicate()
		
		print("Hand card effective values (with growth): ", effective_values)
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
		
		if active_coerced_card_index != -1:
			apply_coerced_card_styling(active_coerced_card_index)


func _on_card_input_event(viewport, event, shape_idx, card_display, card_index):
	print("=== CARD INPUT EVENT ===")
	print("Event: ", event)
	print("Card index: ", card_index)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_card_selection(card_display, card_index)

func handle_card_selection(card_display, card_index):
	print("=== HANDLING CARD SELECTION ===")
	print("Card index: ", card_index)
	print("Tutorial mode: ", is_tutorial_mode)
	print("Is player turn: ", turn_manager.is_player_turn())
	print("Current selected_card_index: ", selected_card_index)
	print("Active coerced card index: ", active_coerced_card_index)
	print("Game paused for modal: ", game_paused_for_modal)
	
	# Block input if modal is open
	if game_paused_for_modal:
		print("Game paused for modal - blocking card selection")
		return
	
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
	
	# NEW: Check coerce constraint - but DON'T remove it here
	if not is_card_selectable(card_index):
		print("Card selection blocked by coerce constraint - must select card index: ", active_coerced_card_index)
		var coerced_card_name = player_deck[active_coerced_card_index].card_name if active_coerced_card_index < player_deck.size() else "Unknown"
		game_status_label.text = "Coerce Effect: You must play " + coerced_card_name + "!"
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
	
	# Handle enrich mode - ALL slots should be highlightable during enrich selection
	if enrich_mode_active and current_enricher_owner == Owner.PLAYER:
		# Clear the previous selection highlight
		if current_grid_index != -1:
			# Restore the previous slot's original styling
			restore_slot_original_styling(current_grid_index)
		
		current_grid_index = grid_index
		
		# Apply enrich highlight to ANY slot (occupied or empty)
		apply_enrich_selection_highlight(grid_index)
		return
	
	# Only apply selection highlight if a card is selected and slot is not occupied
	if selected_card_index != -1 and (not grid_occupied[grid_index] or is_slot_camouflaged(grid_index)):
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
	
	# Handle enrich mode - restore styling for ANY slot
	if enrich_mode_active and current_enricher_owner == Owner.PLAYER:
		# Always restore original styling when exiting during enrich mode
		# FIXED: Always restore styling regardless of current_grid_index
		restore_slot_original_styling(grid_index)
		# FIXED: Also remove enrich overlay for occupied slots
		if grid_occupied[grid_index]:
			var slot = grid_slots[grid_index]
			remove_enrich_card_overlay(slot)
		return
	
	# If this slot is not the currently selected one, restore its original styling
	if current_grid_index != grid_index and not grid_occupied[grid_index]:
		restore_slot_original_styling(grid_index)
	# FIXED: If this IS the currently selected slot but has a hunt trap, restore hunt styling
	elif current_grid_index == grid_index and grid_index in active_hunts:
		apply_hunt_target_styling(grid_index)

func apply_enrich_selection_highlight(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	
	# Always apply enrich highlight style to the slot itself
	slot.add_theme_stylebox_override("panel", enrich_highlight_style)
	
	# ISSUE #2 FIX: For occupied slots, also add a bright overlay on the card to show it's selectable
	if grid_occupied[grid_index]:
		add_enrich_card_overlay(slot)


func restore_slot_original_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	
	# Check for rhythm slot first (before other effects)
	if active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER and grid_index == rhythm_slot and not grid_occupied[grid_index]:
		# Restore rhythm styling
		apply_rhythm_slot_visual(grid_index)
		return
	# Check for ordain effect
	elif grid_index == active_ordain_slot:
		# Restore ordain styling
		apply_ordain_target_styling(grid_index)
	# Check for sanctuary effect 
	elif grid_index == active_sanctuary_slot:
		# Restore sanctuary styling
		apply_sanctuary_target_styling(grid_index)	
	# Check for compel constraint
	elif grid_index == active_compel_slot:
		# Restore compel styling
		apply_compel_target_styling(grid_index)
	# Then check for hunt trap
	elif grid_index in active_hunts:
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
	
	# Don't override rhythm styling with selection highlight
	if active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER and grid_index == rhythm_slot:
		return
	# Don't override ordain styling with selection highlight
	elif grid_index == active_ordain_slot:
		return
	# Don't override compel styling with selection highlight
	elif grid_index == active_compel_slot:
		return
	# Don't override hunt trap styling with selection highlight
	elif grid_index in active_hunts:
		return
	elif grid_index in sunlit_positions:
		# Create a combined sunlit + selected style
		var sunlit_selected_style = StyleBoxFlat.new()
		sunlit_selected_style.bg_color = Color("#444444")
		sunlit_selected_style.border_width_left = 4
		sunlit_selected_style.border_width_top = 4
		sunlit_selected_style.border_width_right = 4
		sunlit_selected_style.border_width_bottom = 4
		sunlit_selected_style.border_color = Color("#44AAFF")
		sunlit_selected_style.bg_color = Color("#554422")
		
		slot.add_theme_stylebox_override("panel", sunlit_selected_style)
	else:
		# Regular selection styling for non-special slots
		slot.add_theme_stylebox_override("panel", selected_grid_style)

func _on_grid_gui_input(event, grid_index):
	
	# Block input if modal is open
	if game_paused_for_modal:
		print("Game paused for modal - blocking grid input")
		return
	
	
	# Handle dance target selection FIRST (but only during dance mode setup)
	if dance_mode_active and current_dancer_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow dance to empty slots
				if not grid_occupied[grid_index]:
					select_dance_target(grid_index)
				else:
					print("Cannot dance to occupied slot - can only dance to empty slots")
				return  # Don't process normal card placement during dance mode
	
	# Handle aristeia target selection (during aristeia mode)
	if aristeia_mode_active and current_aristeia_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow aristeia move to empty slots
				if not grid_occupied[grid_index]:
					select_aristeia_target(grid_index)
				else:
					print("Cannot move to occupied slot - can only move to empty slots")
				return  # Don't process normal card placement during aristeia mode
	
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
	
	# Handle compel target selection (only during compel mode setup)
	if compel_mode_active and current_compeller_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow compel on empty slots
				if not grid_occupied[grid_index]:
					select_compel_target(grid_index)
				else:
					print("Cannot compel occupied slot - can only compel empty slots")
				return  # Don't process normal card placement during compel mode
	
	# Handle ordain target selection (only during ordain mode setup)
	if ordain_mode_active and current_ordainer_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow ordain on empty slots
				if not grid_occupied[grid_index]:
					select_ordain_target(grid_index)
				else:
					print("Cannot ordain occupied slot - can only ordain empty slots")
				return  # Don't process normal card placement during ordain mode
	
	# Handle sanctuary target selection (only during sanctuary mode setup)
	if sanctuary_mode_active and current_sanctuary_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow sanctuary on empty slots
				if not grid_occupied[grid_index]:
					select_sanctuary_target(grid_index)
				else:
					print("Cannot sanctuary occupied slot - can only sanctuary empty slots")
				return  # Don't process normal card placement during sanctuary mode
	
	# Handle enrich target selection (only during enrich mode setup)
	if enrich_mode_active and current_enricher_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Enrich can target any slot (occupied or empty)
				select_enrich_target(grid_index)
				return  # Don't process normal card placement during enrich mode
	
	
	# Handle trojan horse target selection (only during trojan horse mode setup)
	if trojan_horse_mode_active and current_trojan_summoner_owner == Owner.PLAYER:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				# Only allow trojan horse on empty slots
				if not grid_occupied[grid_index]:
					select_trojan_horse_target(grid_index)
				else:
					print("Cannot deploy trojan horse on occupied slot - can only deploy on empty slots")
				return  # Don't process normal card placement during trojan horse mode
	
	# Check if it's the player's turn before processing any further input
	if not turn_manager.is_player_turn():
		return
	
	# Handle misdirection right-click AFTER turn validation
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		handle_misdirection_activation(grid_index)
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			
			if selected_card_index != -1 and (not grid_occupied[grid_index] or is_slot_camouflaged(grid_index)):
				place_card_on_grid()

func update_card_display(grid_index: int, card_data: CardResource):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	# Don't update display for camouflaged cards - they should remain hidden
	if is_slot_camouflaged(grid_index):
		print("Skipping display update for camouflaged card at slot ", grid_index)
		return
	
	var slot = grid_slots[grid_index]
	var card_display = slot.get_child(0) if slot.get_child_count() > 0 else null
	
	if card_display and card_display.has_method("update_display"):
		# Just update the display without losing the existing setup
		card_display.card_data = card_data  # Update the card data reference
		card_display.update_display()       # Refresh the visual display
		print("Updated card display for ", card_data.card_name, " with new values: ", card_data.values)

func place_card_on_grid():
	if selected_card_index == -1 or current_grid_index == -1:
		return
	
	check_and_remove_coerce_constraint(selected_card_index)
	
	# Handle dance target selection FIRST (but only during dance mode setup)
	if dance_mode_active and current_dancer_owner == Owner.PLAYER:
		select_dance_target(current_grid_index)
		return
	
	# Handle aristeia target selection (during aristeia mode setup)
	if aristeia_mode_active and current_aristeia_owner == Owner.PLAYER:
		select_aristeia_target(current_grid_index)
		return
	
	# Handle hunt trap removal BEFORE checking if slot is occupied
	if current_grid_index in active_hunts:
		var hunt_data = active_hunts[current_grid_index]
		# Only remove if it's our own hunt trap
		if hunt_data.hunter_owner == Owner.PLAYER:
			print("Removing player's own hunt trap from slot ", current_grid_index)
			remove_hunt_trap(current_grid_index)
		else:
			print("Cannot place on enemy hunt trap!")
			return
			
	# Handle compel constraint removal when player places card in compelled slot
	if current_grid_index == active_compel_slot:
		print("Player placing card in compelled slot - removing compel constraint")
		remove_compel_constraint()
	
	if check_camouflage_capture(current_grid_index, Owner.PLAYER):
		# Camouflage was triggered - the capture sequence has been executed
		# The player's card is captured and cannot be placed
		print("Player's card was captured by camouflage!")
		
		# Remove the card from hand since it was captured
		remove_card_from_hand(selected_card_index)
		
		# Reset selection
		selected_card_index = -1
		current_grid_index = -1
		
		# Switch turns after camouflage capture
		turn_manager.next_turn()
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
	var card_data = original_card_data.duplicate(true)  # DEEP COPY
	var effective_values = original_card_data.get_effective_values(card_level)
	var effective_abilities = original_card_data.get_effective_abilities(card_level)
	
	# Apply stat growth from the run tracker BEFORE other modifications
	if has_node("/root/RunStatGrowthTrackerAutoload"):
		var growth_tracker = get_node("/root/RunStatGrowthTrackerAutoload")
		effective_values = growth_tracker.apply_growth_to_card_values(effective_values, card_collection_index)
	
	# Apply the level-appropriate values and abilities AND growth to the grid copy
	card_data.values = effective_values.duplicate()
	card_data.abilities = effective_abilities.duplicate()
	
	# Apply Disarray effect if active - mark the card as confused
	if disarray_active:
		print("Applying Disarray effect to player card: ", card_data.card_name)
		
		# Mark this card as confused (will attack both friendlies and enemies)
		card_data.set_meta("disarray_confused", true)
		
		print("Disarray effect applied - card will attack both friendly and enemy cards")
		print("DEBUG DISARRAY: Player card metadata set - has_meta: ", card_data.has_meta("disarray_confused"), " value: ", card_data.get_meta("disarray_confused"))
		
		# Deactivate disarray after use
		disarray_active = false
		print("Disarray effect has been consumed")
	
	
	
	# FIXED: Apply ordain bonus to the card copy that will be placed on the grid
	var placing_owner = Owner.PLAYER
	apply_ordain_bonus_if_applicable(current_grid_index, card_data, placing_owner)
	# Apply enrichment bonus if applicable
	apply_enrichment_bonus_if_applicable(current_grid_index, card_data, placing_owner)
	apply_sanctuary_cheat_death_if_applicable(current_grid_index, card_data, placing_owner)
	
	if active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER and current_grid_index == rhythm_slot:
		print("🎵 RHYTHM POWER ACTIVATED! Card placed in rhythm slot")
		apply_rhythm_boost(card_data)
	
	print("Grid placement effective values (with growth and ordain): ", card_data.values)
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
			
			# BOSS EFFECT: Reduce card stats to 1,1,1,1
			print("Boss effect: Reducing card stats from ", card_data.values, " to [1,1,1,1]")
			card_data.values[0] = 1  # North
			card_data.values[1] = 1  # East  
			card_data.values[2] = 1  # South
			card_data.values[3] = 1  # West
			
			# Trigger the notification
			if notification_manager:
				notification_manager.show_notification("I knew you would go there")
	
	# Check for deck power boosts and apply them to the card
	var sun_boosted = false
	if active_deck_power == DeckDefinition.DeckPowerType.SUN_POWER and current_grid_index in sunlit_positions and not darkness_shroud_active:
		print("Sun Power boost activated for card in sunlit position!")
		for i in range(card_data.values.size()):
			card_data.values[i] += 1
		sun_boosted = true
		print("Card boosted to: ", card_data.values)
	
	# Check if this is a Hunt trap trigger (enemy trap)
	if current_grid_index in active_hunts:
		var hunt_data = active_hunts[current_grid_index]
		if hunt_data.hunter_owner != Owner.PLAYER:
			print("Player triggered enemy hunt trap!")
			check_hunt_trap_trigger(current_grid_index, card_data, Owner.PLAYER)
			return

	# Mark the slot as occupied and set ownership
	grid_occupied[current_grid_index] = true
	grid_ownership[current_grid_index] = Owner.PLAYER
	grid_card_data[current_grid_index] = card_data
	
	# Track this card's collection index for experience
	grid_to_collection_index[current_grid_index] = card_collection_index

	# Get the slot
	var slot = grid_slots[current_grid_index]
	
	# Create a card display for the player's card
	var card_display_scene = preload("res://Scenes/CardDisplay.tscn")
	var card_display = card_display_scene.instantiate()
	
	# Add the card as a child of the slot panel FIRST
	slot.add_child(card_display)
	
	# Wait one frame to ensure @onready variables are initialized
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
	elif not is_slot_camouflaged(current_grid_index):
		card_display.panel.add_theme_stylebox_override("panel", player_card_style)

	# Connect hover signals for player cards
	card_display.card_hovered.connect(_on_card_hovered)
	card_display.card_unhovered.connect(_on_card_unhovered)

	print("Player placed ", card_data.card_name, " at slot ", current_grid_index)
	# Connect right-click handling for cards placed on the grid
	if card_display and card_display.panel:
		card_display.panel.gui_input.connect(_on_grid_card_right_click.bind(current_grid_index))
		print("Connected right-click handler for player card at grid position ", current_grid_index)
	
	# Check if the card should get ordain bonus BEFORE executing abilities
	apply_ordain_bonus_if_applicable(current_grid_index, card_data, placing_owner)
	
	# SEASONS POWER: Check if Persephone is being played (triggers Winter)
	if is_seasons_power_active() and original_card_data.card_name == "Persephone":
		transition_to_winter()
	
	print("Final card values after all bonuses: ", card_data.values)
	
		# ADD THIS DEBUG CODE HERE:
	# Debug: Check Persephone specifically
	if card_data.card_name == "Persephone":
		print("=== PERSEPHONE DEBUG ===")
		print("Card level calculated: ", card_level)
		print("Collection index: ", card_collection_index)
		print("Has ON_PLAY ability: ", card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level))
		print("Available abilities: ")
		var abilities = card_data.get_available_abilities(card_level)
		for ability in abilities:
			print("  - ", ability.ability_name, " (trigger: ", ability.trigger_condition, ")")
		print("======================")
	
	
	# Execute ON_PLAY abilities
	if card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level):
		print("Executing on-play abilities for ", card_data.card_name)
		
		var ability_context = {
			"placed_card": card_data,
			"grid_position": current_grid_index,
			"game_manager": self,
			"placing_owner": Owner.PLAYER,
			"card_level": card_level
		}
		
		# Execute all ON_PLAY abilities EXCEPT Aristeia (which needs captures_made context)
		var abilities = card_data.get_available_abilities(card_level)
		for ability in abilities:
			if ability.trigger_condition == CardAbility.TriggerType.ON_PLAY:
				# Skip Aristeia during general ON_PLAY phase
				if ability.ability_name == "Aristeia":
					print("Skipping Aristeia during ON_PLAY - will check after combat")
					continue
				
				print("Executing ability: ", ability.ability_name, " (", ability.description, ")")
				ability.execute(ability_context)
		
		# Update the visual display after abilities execute (in case stats changed)
		update_card_display(current_grid_index, card_data)
	
	# Handle passive abilities when player places card
	handle_passive_abilities_on_place(current_grid_index, card_data, card_level)
	
	# Check for couple union
	check_for_couple_union(card_data, current_grid_index)
	
	# Register if this card has Second Chance
	register_second_chance_if_needed(current_grid_index, card_data, Owner.PLAYER)
	
	# Resolve combat
	var captures = resolve_combat(current_grid_index, Owner.PLAYER, card_data)
	if captures > 0:
		print("Player captured ", captures, " cards!")
		# NEW: Check if card has Aristeia ability and trigger it with captures_made
		if card_data.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level):
			var available_abilities = card_data.get_available_abilities(card_level)
			for ability in available_abilities:
				if ability.ability_name == "Aristeia":
					print("Checking Aristeia ability with ", captures, " captures")
					
					var aristeia_context = {
						"placed_card": card_data,
						"grid_position": current_grid_index,
						"game_manager": self,
						"placing_owner": Owner.PLAYER,
						"card_level": card_level,
						"captures_made": captures
					}
					
					var aristeia_activated = ability.execute(aristeia_context)
					if aristeia_activated:
						print("Aristeia successfully activated - mode is now active")
						
						# Remove the card from hand now that it's been placed and aristeia activated
						var temp_index = selected_card_index
						selected_card_index = -1
						remove_card_from_hand(temp_index)
						
						# Reset grid selection
						if current_grid_index != -1:
							restore_slot_original_styling(current_grid_index)
						current_grid_index = -1
						
						return
					else:
						print("Aristeia did not activate (no captures or ownership changed)")
					break  # Exit the ability loop
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

	# DON'T switch turns if any special modes are active
	if hunt_mode_active:
		print("Hunt mode active - staying on player turn for target selection")
		return
	
	if compel_mode_active:
		print("Compel mode active - staying on player turn for target selection")
		return
	
	if ordain_mode_active:
		print("Ordain mode active - staying on player turn for target selection")
		return
	
	if dance_mode_active:
		print("Dance mode active - staying on turn for target selection")
		return
	
	if aristeia_mode_active:
		print("Aristeia mode active - staying on turn for target selection")
		return
	
	if sanctuary_mode_active:
		print("Sanctuary mode active - staying on player turn for target selection")
		return
	
	if enrich_mode_active:
		print("Enrich mode active - staying on player turn for target selection")
		return
	
	if trojan_horse_mode_active:
		print("Trojan Horse mode active - staying on player turn for target selection")
		return
	
	if race_mode_active:
		print("Race mode active - staying on turn until race completes")
		return
	if is_coordination_active and turn_manager.current_player == TurnManager.Player.HUMAN:
		print("🎯 Coordination active - player gets another turn!")
		is_coordination_active = false  # Reset after giving the extra turn
		
		# CHECK IF GAME SHOULD END BEFORE ARTEMIS COUNTER
		if should_game_end():
			print("Game ending after Coordinate - board full or no cards left")
			end_game()
			return
		
		# ARTEMIS BOSS MECHANIC: Trigger counter after Coordinate ends (only if game not ending)
		if is_artemis_boss_battle and not artemis_boss_counter_triggered:
			print("=== ARTEMIS BOSS COUNTER ACTIVATED ===")
			artemis_boss_counter_triggered = true
			
			# Return 2 opponent cards to hand
			artemis_boss_return_cards_to_hand()
			
			# Brief pause for player to see what happened
			await get_tree().create_timer(1.0).timeout
			
			# Now opponent takes TWO turns
			# First turn
			turn_manager.next_turn()  # Switch to opponent
			# Turn change signal will trigger opponent_take_turn automatically
			return
		
		# Normal coordinate behavior (not Artemis boss)
		if notification_manager:
			notification_manager.show_notification("🎯 Coordination: You play again!")
		return
	
	# Switch turns only if no special modes are active
	turn_manager.next_turn()
	
	
func handle_passive_abilities_on_place(grid_position: int, card_data: CardResource, card_level: int):
	# Check if this card has passive abilities
	if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
		print("Handling passive abilities for ", card_data.card_name, " at position ", grid_position)
		
		# Get card owner
		var card_owner = get_owner_at_position(grid_position)
		
		# Store reference to this card's passive abilities (only if they should be active)
		if not grid_position in active_passive_abilities:
			active_passive_abilities[grid_position] = []
		
		var available_abilities = card_data.get_available_abilities(card_level)
		var active_abilities_for_card = []
		
		for ability in available_abilities:
			if ability.trigger_condition == CardAbility.TriggerType.PASSIVE:
				# Check if this ability should be active for the current owner
				if should_passive_ability_be_active(ability, card_owner, grid_position):
					print("Adding active passive ability: ", ability.ability_name)
					active_passive_abilities[grid_position].append(ability)
					active_abilities_for_card.append(ability)
					
					# Execute the passive ability with "apply" action
					var passive_context = {
						"passive_action": "apply",
						"boosting_card": card_data,
						"boosting_position": grid_position,
						"game_manager": self,
						"card_level": card_level
					}
					
					ability.execute(passive_context)
				else:
					print("Passive ability ", ability.ability_name, " not active for current owner")
		
		# Check if any of the active abilities should show visual pulse
		var should_show_pulse = false
		for ability in active_abilities_for_card:
			if should_passive_ability_show_pulse(ability, card_owner, grid_position):
				should_show_pulse = true
				break
		
		# Only start visual pulse if needed
		if should_show_pulse:
			var card_display = get_card_display_at_position(grid_position)
			if card_display and visual_effects_manager:
				visual_effects_manager.start_passive_pulse(card_display)
				print("Started visual pulse for ", card_data.card_name)
		else:
			print("No visual pulse needed for ", card_data.card_name, " (Cultivate has its own arrow effect)")
	
	# Also trigger passive abilities of existing cards (in case they need to affect the new card)
	refresh_all_passive_abilities()

func _on_grid_card_right_click(event, grid_index: int):
	
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		print("Right-click confirmed on grid card at position ", grid_index)
		handle_misdirection_activation(grid_index)

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
			
			# Special handling for cultivation - ensure it's marked as inactive
			if ability.ability_name == "Cultivate":
				card_data.set_meta("cultivation_active", false)
				print("CultivateAbility: Marked cultivation as inactive due to capture")
		
		# Remove from tracking
		active_passive_abilities.erase(grid_position)
	
	# Check if captured card had any active hunts and remove them
	for target_pos in active_hunts.keys():
		var hunt_data = active_hunts[target_pos]
		if hunt_data.hunter_position == grid_position:
			print("Removing hunt trap due to hunter capture")
			remove_hunt_trap(target_pos)

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
					"game_manager": self,
					"is_refresh": true  # Mark this as a refresh, not a real removal
				}
				ability.execute(passive_context)
	
	# Clear all tracking
	active_passive_abilities.clear()
	
	# Stop all visual pulse effects before re-applying
	if visual_effects_manager:
		for position in range(grid_slots.size()):
			if grid_occupied[position]:
				var card_display = get_card_display_at_position(position)
				if card_display:
					visual_effects_manager.stop_passive_pulse(card_display)
	
	# Then re-apply all boosts based on current ownership AND ability functionality
	for position in range(grid_slots.size()):
		if not grid_occupied[position]:
			continue
		
		var card_data = get_card_at_position(position)
		if not card_data:
			continue
		
		var card_collection_index = get_card_collection_index(position)
		var card_level = get_card_level(card_collection_index)
		var card_owner = get_owner_at_position(position)
		
		# Check if this card has passive abilities
		if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			print("Checking passive abilities for ", card_data.card_name, " at position ", position, " owned by ", "Player" if card_owner == Owner.PLAYER else "Opponent")
			
			var available_abilities = card_data.get_available_abilities(card_level)
			var active_abilities_for_card = []
			
			for ability in available_abilities:
				if ability.trigger_condition == CardAbility.TriggerType.PASSIVE:
					# Check if this ability should be active for the current owner
					var should_be_active = should_passive_ability_be_active(ability, card_owner, position)
					
					if should_be_active:
						print("Re-adding passive ability ", ability.ability_name, " for ", card_data.card_name)
						active_abilities_for_card.append(ability)
						
						# Execute "apply" action
						var passive_context = {
							"passive_action": "apply",
							"boosting_card": card_data,
							"boosting_position": position,
							"game_manager": self,
							"card_level": card_level
						}
						ability.execute(passive_context)
					else:
						print("Passive ability ", ability.ability_name, " not active for current owner")
			
			# Add to tracking if there are active abilities
			if active_abilities_for_card.size() > 0:
				active_passive_abilities[position] = active_abilities_for_card
			
			# Check if any of the active abilities should show visual pulse
			var should_show_pulse = false
			for ability in active_abilities_for_card:
				if should_passive_ability_show_pulse(ability, card_owner, position):
					should_show_pulse = true
					break
			
			# Only start visual pulse if needed
			if should_show_pulse:
				var card_display = get_card_display_at_position(position)
				if card_display and visual_effects_manager:
					visual_effects_manager.start_passive_pulse(card_display)
func should_passive_ability_be_active(ability: CardAbility, card_owner: Owner, position: int) -> bool:
	match ability.ability_name:
		"Cultivate":
			# Cultivation only works for player-owned cards
			return card_owner == Owner.PLAYER
		"Corruption":
			# Corruption only works for opponent-owned cards
			return card_owner == Owner.OPPONENT
		"Greedy":
			# Greedy only works for opponent-owned cards
			return card_owner == Owner.OPPONENT
		"Adaptive Defense":
			# Adaptive defense works for both owners
			return true
		"Fortify":
			# Fortify works for both owners, but only in corner positions
			return is_corner_position(position)
		"Divine Inspiration", "Passive Boost":
			# Boost abilities work for both owners (boost friendly cards)
			return true
		_:
			# Default: passive abilities work for both owners
			return true

# NEW: Helper function to determine if a passive ability should show visual pulse
func should_passive_ability_show_pulse(ability: CardAbility, card_owner: Owner, position: int) -> bool:
	match ability.ability_name:
		"Cultivate":
			# Cultivation has its own green arrow visual - no need for pulse
			return false
		"Adaptive Defense":
			# Show pulse for adaptive defense
			return true
		"Divine Inspiration", "Passive Boost":
			# Show pulse for boost abilities
			return true
		_:
			# Default: show pulse for most passive abilities
			return true

# Helper function to check if a position is a corner slot
func is_corner_position(position: int) -> bool:
	# In a 3x3 grid, corner positions are: 0, 2, 6, 8
	# Top-left: 0, Top-right: 2, Bottom-left: 6, Bottom-right: 8
	return position in [0, 2, 6, 8]

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
	# RECORD THE BATTLE RESULTS BEFORE GOING TO REWARDS
	record_enemy_encounter(true)  # true = victory since we only reach rewards on victory
	record_god_experience()
	check_god_unlocks()
	
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


func record_enemy_encounter(victory: bool):
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var params = get_scene_params()
	
	print("=== DEBUG ENEMY ENCOUNTER RECORDING ===")
	print("Victory: ", victory)
	print("Scene params: ", params)
	
	# Get enemy info from current node
	var enemy_name = "Shadow Acolyte"  # Default
	var enemy_difficulty = 0
	var is_boss = false
	
	if params.has("current_node"):
		var current_node = params["current_node"]
		print("Current node data:")
		print("  display_name: '", current_node.display_name, "'")
		print("  enemy_name: '", current_node.enemy_name, "'")
		print("  enemy_difficulty: ", current_node.enemy_difficulty)
		print("  node_type: ", current_node.node_type)
		print("  NodeType.BOSS constant: ", MapNode.NodeType.BOSS)
		
		enemy_name = current_node.enemy_name if current_node.enemy_name != "" else "Shadow Acolyte"
		enemy_difficulty = current_node.enemy_difficulty
		is_boss = current_node.node_type == MapNode.NodeType.BOSS
		
		print("Determined values:")
		print("  enemy_name: '", enemy_name, "'")
		print("  is_boss: ", is_boss)
	
	# Record the encounter in memory journal
	memory_manager.record_enemy_encounter(enemy_name, victory, enemy_difficulty)
	print("Recorded enemy encounter: '", enemy_name, "' (victory: ", victory, ")")
	
	# NEW: Check for boss victory and update BossVictoryTracker
	if victory and is_boss:
		print("Boss victory detected! Updating BossVictoryTracker...")
		
		var boss_tracker = get_node_or_null("/root/BossVictoryTrackerAutoload")
		if boss_tracker:
			# Map enemy names to boss names for the tracker
			var boss_name = map_enemy_name_to_boss(enemy_name)
			if boss_name != "":
				boss_tracker.mark_boss_defeated(boss_name)
				print("Boss victory recorded: ", boss_name)
				
				# Show special notification for boss ability unlocks
				show_boss_victory_notification(boss_name)
			else:
				print("Warning: Could not map enemy name '", enemy_name, "' to boss name")
		else:
			print("Warning: BossVictoryTrackerAutoload not found!")
	
	# Check current memory state
	var enemy_memories = memory_manager.get_all_enemy_memories()
	print("All enemy memories after recording: ", enemy_memories.keys())
	if enemy_name in enemy_memories:
		print("Data for '", enemy_name, "': ", enemy_memories[enemy_name])
	
	# Immediately check for god unlocks if this was a victory
	if victory and has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		
		print("Checking god unlocks...")
		print("Current unlocked gods: ", progress_tracker.get_unlocked_gods())

func map_enemy_name_to_boss(enemy_name: String) -> String:
	if enemy_name == null or enemy_name == "":
		return ""
	
	# Map the actual enemy names from BossConfig to boss names for the tracker
	var boss_mapping = {
		"?????": "Apollo",                    # BossConfig.APOLLO_BOSS_NAME
		"Hermes Boss": "Hermes",             # BossConfig.HERMES_BOSS_NAME  
		"Fimbulwinter": "Demeter",           # BossConfig.DEMETER_BOSS_NAME
		"Artemis Boss": "Artemis"            # BossConfig.ARTEMIS_BOSS_NAME
	}
	
	return boss_mapping.get(enemy_name, "")

# NEW: Show special notification when boss abilities are unlocked
func show_boss_victory_notification(boss_name: String):
	if notification_manager:
		var message = "Victory over " + boss_name + " awakens new memories within Mnemosyne!"
		notification_manager.show_notification(message)  # Show for 5 seconds


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
			
			# FIXED: Only record trap encounter if PLAYER card was captured by ENEMY tremor
			if target_owner == Owner.PLAYER and tremor_owner == Owner.OPPONENT:
				var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
				progress_tracker.record_trap_fallen_for("tremor", "Player's card captured by earthquake tremors")
				
				# FIXED: Only show notification if Artemis isn't unlocked yet
				if progress_tracker.should_show_artemis_notification() and notification_manager:
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
		
		# Get the owner of the hunted card
		var hunted_owner = get_owner_at_position(target_position)
		
		# FIXED: Only record trap encounter if PLAYER walked into ENEMY hunt trap
		if hunted_owner == Owner.PLAYER and hunt_data.hunter_owner == Owner.OPPONENT:
			var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
			progress_tracker.record_trap_fallen_for("hunt_trap", "Player's card caught in enemy hunting snare")
			
			# FIXED: Only show notification if Artemis isn't unlocked yet
			if progress_tracker.should_show_artemis_notification() and notification_manager:
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

func should_apply_backstab(attacking_card: CardResource, attacker_position: int) -> bool:
	if not attacking_card:
		return false
	
	# Get the card level for ability checks
	var card_collection_index = get_card_collection_index(attacker_position)
	var card_level = get_card_level(card_collection_index)
	
	# Check if the card has backstab ability and can still use it
	if attacking_card.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
		var abilities = attacking_card.get_available_abilities(card_level)
		for ability in abilities:
			if ability.ability_name == "Backstab":
				return BackstabAbility.can_use_backstab(attacking_card)
	
	return false

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


# Process cultivation abilities at the start of player's turn
func process_cultivation_turn_start():
	print("Processing cultivation abilities for player turn start")
	
	# Check all cards on the board for cultivation abilities
	for position in range(grid_slots.size()):
		if not grid_occupied[position]:
			continue
		
		# Only process player-owned cards
		var card_owner = get_owner_at_position(position)
		if card_owner != Owner.PLAYER:
			continue
		
		var card_data = get_card_at_position(position)
		if not card_data:
			continue
		
		# Get card level for ability checks
		var card_collection_index = get_card_collection_index(position)
		var card_level = get_card_level(card_collection_index)
		
		# Check if this card has cultivation ability
		var has_cultivation = false
		var cultivation_ability = null
		
		if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			for ability in card_data.get_available_abilities(card_level):
				if ability.ability_name == "Cultivate":
					has_cultivation = true
					cultivation_ability = ability
					break
		
		if not has_cultivation or not cultivation_ability:
			continue
		
		print("Found cultivation card at position ", position, ": ", card_data.card_name)
		
		# Execute cultivation turn processing
		var context = {
			"passive_action": "turn_start",
			"boosting_card": card_data,
			"boosting_position": position,
			"game_manager": self,
			"card_level": card_level
		}
		
		cultivation_ability.execute(context)

# Process corruption abilities at the start of opponent's turn
func process_corruption_turn_start():
	print("Processing corruption abilities for opponent turn start")
	
	# Check all cards on the board for corruption abilities
	for position in range(grid_slots.size()):
		if not grid_occupied[position]:
			continue
		
		# Only process opponent-owned cards
		var card_owner = get_owner_at_position(position)
		if card_owner != Owner.OPPONENT:
			continue
		
		var card_data = get_card_at_position(position)
		if not card_data:
			continue
		
		# Get card level for ability checks
		var card_collection_index = get_card_collection_index(position)
		var card_level = get_card_level(card_collection_index)
		
		# Check if this card has corruption ability
		var has_corruption = false
		var corruption_ability = null
		
		if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			for ability in card_data.get_available_abilities(card_level):
				if ability.ability_name == "Corruption":
					has_corruption = true
					corruption_ability = ability
					break
		
		if not has_corruption or not corruption_ability:
			continue
		
		print("Found corruption card at position ", position, ": ", card_data.card_name)
		
		# Execute corruption turn processing
		var context = {
			"passive_action": "turn_start",
			"boosting_card": card_data,
			"boosting_position": position,
			"game_manager": self,
			"card_level": card_level
		}
		
		corruption_ability.execute(context)



func start_compel_mode(compeller_position: int, compeller_owner: Owner, compeller_card: CardResource):
	compel_mode_active = true
	current_compeller_position = compeller_position
	current_compeller_owner = compeller_owner
	current_compeller_card = compeller_card
	
	# Update game status
	if compeller_owner == Owner.PLAYER:
		game_status_label.text = "🎯 COMPEL MODE: Select a slot to compel the opponent"
	else:
		game_status_label.text = "🎯 " + opponent_manager.get_opponent_info().name + " is compelling..."
		# Auto-select target for opponent
		call_deferred("opponent_select_compel_target")
	
	print("Compel mode activated for ", compeller_card.card_name, " at position ", compeller_position)

func select_compel_target(target_position: int):
	if not compel_mode_active:
		return
	
	print("Compel target selected: position ", target_position)
	
	# Set the compel constraint
	active_compel_slot = target_position
	
	# Apply visual styling to show this slot is compelled
	apply_compel_target_styling(target_position)
	
	# End compel mode
	compel_mode_active = false
	current_compeller_position = -1
	current_compeller_owner = Owner.NONE
	current_compeller_card = null
	
	# Update game status
	if current_compeller_owner == Owner.PLAYER:
		game_status_label.text = "Compel set! Opponent must play in the marked slot."
	
	# Switch turns - compel action completes the turn
	print("Compel target selected - switching turns")
	turn_manager.next_turn()

func apply_compel_target_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	slot.add_theme_stylebox_override("panel", compel_target_style)
	
	print("Applied compel target styling (purple border) to slot ", grid_index)

func remove_compel_constraint():
	if active_compel_slot == -1:
		return
	
	print("Removing compel constraint from position ", active_compel_slot)
	
	# Remove visual styling
	restore_slot_original_styling(active_compel_slot)
	
	# Clear tracking
	active_compel_slot = -1

# Modify the is_slot_available_for_opponent function to treat camouflaged slots as empty
func is_slot_available_for_opponent(slot_index: int) -> bool:
	# If slot is occupied AND not camouflaged, it's not available
	if grid_occupied[slot_index] and not is_slot_camouflaged(slot_index):
		return false
	
	# If there's an active compel constraint, only the compelled slot is available
	if active_compel_slot != -1:
		return slot_index == active_compel_slot
	
	# Otherwise, any empty slot OR camouflaged slot is available
	return true

# Opponent AI compel target selection
func opponent_select_compel_target():
	if not compel_mode_active:
		return
	
	# Simple AI: pick a random empty slot for now
	var possible_targets = []
	
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:  # Only empty slots
			possible_targets.append(i)
	
	var target_position = -1
	if possible_targets.size() > 0:
		target_position = possible_targets[randi() % possible_targets.size()]
	
	if target_position != -1:
		select_compel_target(target_position)

# Clear compel constraints (for game end or reset)
func clear_all_compel_constraints():
	if active_compel_slot != -1:
		remove_compel_constraint()
	compel_mode_active = false
	current_compeller_position = -1
	current_compeller_owner = Owner.NONE
	current_compeller_card = null
	print("All compel constraints cleared")

func get_available_slots_for_opponent() -> Array[int]:
	var available_slots: Array[int] = []
	for i in range(grid_slots.size()):
		if is_slot_available_for_opponent(i):
			available_slots.append(i)
	return available_slots


func start_ordain_mode(ordainer_position: int, ordainer_owner: Owner, ordainer_card: CardResource):
	ordain_mode_active = true
	current_ordainer_position = ordainer_position
	current_ordainer_owner = ordainer_owner
	current_ordainer_card = ordainer_card
	
	# Update game status
	if ordainer_owner == Owner.PLAYER:
		game_status_label.text = "✨ ORDAIN MODE: Select an empty slot to ordain"
	else:
		game_status_label.text = "✨ " + opponent_manager.get_opponent_info().name + " is ordaining..."
		# Auto-select target for opponent
		call_deferred("opponent_select_ordain_target")
	
	print("Ordain mode activated for ", ordainer_card.card_name, " at position ", ordainer_position)

# FIXED select_ordain_target function
# Replace your select_ordain_target function with this corrected version:

func select_ordain_target(target_position: int):
	if not ordain_mode_active:
		return
	
	print("Ordain target selected: position ", target_position)
	
	# Set the ordain effect
	active_ordain_slot = target_position
	
	# CRITICAL: Store the owner who created the ordain effect BEFORE resetting variables
	active_ordain_owner = current_ordainer_owner
	
	# Set turn counter - ordain lasts for 3 turns
	active_ordain_turns_remaining = 3
	
	# Apply visual styling to show this slot is ordained
	apply_ordain_target_styling(target_position)
	
	# End ordain mode
	ordain_mode_active = false
	current_ordainer_position = -1
	current_ordainer_owner = Owner.NONE
	current_ordainer_card = null
	
	# Update game status based on who ordained
	if active_ordain_owner == Owner.PLAYER:
		game_status_label.text = "Ordain set! Next card in that slot gets +2 to all stats."
	else:
		game_status_label.text = "Opponent ordained a slot."
	
	# Switch turns - ordain action completes the turn
	print("Ordain target selected - switching turns")
	turn_manager.next_turn()

func apply_ordain_target_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	slot.add_theme_stylebox_override("panel", ordain_target_style)
	
	print("Applied ordain target styling (golden border) to slot ", grid_index)

func remove_ordain_effect():
	if active_ordain_slot == -1:
		return
	
	print("Removing ordain effect from position ", active_ordain_slot)
	
	var slot_to_restore = active_ordain_slot
	active_ordain_slot = -1
	active_ordain_owner = Owner.NONE
	active_ordain_turns_remaining = 0
	
	# Now restore the visual styling to default (after clearing tracking)
	restore_slot_original_styling(slot_to_restore)

# Opponent AI ordain target selection
func opponent_select_ordain_target():
	if not ordain_mode_active:
		return
	
	# Simple AI: pick a random empty slot
	var possible_targets = []
	
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:  # Only empty slots
			possible_targets.append(i)
	
	var target_position = -1
	if possible_targets.size() > 0:
		target_position = possible_targets[randi() % possible_targets.size()]
	
	if target_position != -1:
		select_ordain_target(target_position)

func clear_all_ordain_effects():
	if active_ordain_slot != -1:
		remove_ordain_effect()
	ordain_mode_active = false
	current_ordainer_position = -1
	current_ordainer_owner = Owner.NONE
	current_ordainer_card = null
	active_ordain_owner = Owner.NONE
	active_ordain_turns_remaining = 0  # Reset turn counter
	print("All ordain effects cleared")

# Check if a card being placed should get the ordain bonus
func apply_ordain_bonus_if_applicable(grid_position: int, card_data: CardResource, placing_owner: Owner):
	print("=== ORDAIN BONUS CHECK ===")
	print("Active ordain slot: ", active_ordain_slot)
	print("Grid position: ", grid_position)
	print("Active ordain owner: ", active_ordain_owner)
	print("Placing owner: ", placing_owner)
	
	# Only apply bonus if:
	# 1. There's an active ordain slot
	# 2. The card is being placed in the ordained slot  
	# 3. The player who ordained the slot is the one placing the card
	if active_ordain_slot != -1 and grid_position == active_ordain_slot and placing_owner == active_ordain_owner:
		print("CONDITIONS MET - Applying ordain bonus (+2 to all stats) to ", card_data.card_name)
		print("Card stats BEFORE ordain bonus: ", card_data.values)
		
		# Apply +2 to all stats
		for i in range(card_data.values.size()):
			card_data.values[i] += 2
		
		print("Card stats AFTER ordain bonus: ", card_data.values)
		
		# Remove the ordain effect after use
		remove_ordain_effect()
		
		return true
	elif active_ordain_slot != -1 and grid_position == active_ordain_slot:
		# Enemy used ordained slot - just remove effect silently
		print("Enemy used ordained slot - removing effect without bonus")
		remove_ordain_effect()
	else:
		print("Ordain bonus conditions NOT met")
	
	return false

func handle_ordain_turn_expiration():
	# Count down ordain turns and expire when reaches 0
	if active_ordain_slot != -1 and active_ordain_turns_remaining > 0:
		active_ordain_turns_remaining -= 1
		print("Ordain turns remaining: ", active_ordain_turns_remaining)
		
		if active_ordain_turns_remaining <= 0:
			print("Ordain effect expired after 3 turns")
			remove_ordain_effect()


# Check for Pursuit ability triggers when opponent plays a card
func check_pursuit_triggers(opponent_position: int, opponent_card: CardResource):
	print("Checking for Pursuit triggers after opponent played at position ", opponent_position)
	
	var pursuit_candidates = []
	
	# Check all occupied positions for cards with Pursuit ability
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:
			continue
			
		var card = get_card_at_position(i)
		var owner = get_owner_at_position(i)
		
		# Only check player's cards (pursuit against opponent)
		if owner != Owner.PLAYER:
			continue
		
		var card_level = get_card_level_for_position(i)
		if not card.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			continue
		
		# Check if this card has Pursuit ability
		var has_pursuit = false
		for ability in card.get_available_abilities(card_level):
			if ability.ability_name == "Pursuit":
				has_pursuit = true
				break
		
		if not has_pursuit:
			continue
		
		print("Found Pursuit card: ", card.card_name, " at position ", i)
		
		# Check if this Pursuit card can target the opponent's new card
		var pursuit_data = check_pursuit_conditions(i, card, opponent_position, opponent_card)
		if pursuit_data != null:
			pursuit_candidates.append(pursuit_data)
	
	# If we have multiple candidates, only activate the lowest slot number
	if pursuit_candidates.size() > 1:
		print("Multiple Pursuit triggers found - selecting lowest slot number")
		pursuit_candidates.sort_custom(func(a, b): return a.pursuit_position < b.pursuit_position)
		
		# Only keep the first (lowest slot) candidate
		var selected_candidate = pursuit_candidates[0]
		print("Selected Pursuit candidate at position ", selected_candidate.pursuit_position)
		pursuit_candidates = [selected_candidate]
	
	# Execute Pursuit if we have a valid candidate
	if pursuit_candidates.size() == 1:
		execute_pursuit(pursuit_candidates[0])

func check_pursuit_conditions(pursuit_position: int, pursuit_card: CardResource, target_position: int, target_card: CardResource):
	"""Check if a Pursuit card can target the given opponent card. Returns pursuit data Dictionary if valid, null if not."""
	
	print("Checking Pursuit conditions: position ", pursuit_position, " targeting position ", target_position)
	
	# Check if pursuit and target are in same row or column
	var same_row_column = are_in_same_row_or_column(pursuit_position, target_position)
	if not same_row_column.is_valid:
		print("  Not in same row/column - Pursuit cannot trigger")
		return null
	
	print("  Same ", same_row_column.type, " - checking for empty slot between")
	
	# Check if there's exactly one empty slot between them
	var empty_slot = find_empty_slot_between(pursuit_position, target_position)
	if empty_slot == -1:
		print("  No empty slot between positions - Pursuit cannot trigger")
		return null
	
	print("  Found empty slot at position ", empty_slot)
	
	# Determine attack direction from pursuit to target
	var attack_direction = get_attack_direction(empty_slot, target_position)
	if attack_direction == -1:
		print("  Could not determine attack direction - Pursuit cannot trigger")
		return null
	
	print("  Attack direction: ", get_direction_name_from_index(attack_direction))
	
	# Simulate combat to see if Pursuit would win
	var pursuit_value = pursuit_card.values[attack_direction]
	var defense_direction = get_opposite_direction(attack_direction)
	var target_value = target_card.values[defense_direction]
	
	print("  Combat simulation: Pursuit ", pursuit_value, " vs Target ", target_value)
	
	if pursuit_value <= target_value:
		print("  Pursuit would not win combat - cannot trigger")
		return null
	
	print("  Pursuit would win combat - trigger valid!")
	
	return {
		"pursuit_position": pursuit_position,
		"pursuit_card": pursuit_card,
		"target_position": target_position,
		"target_card": target_card,
		"move_to_position": empty_slot,
		"attack_direction": attack_direction,
		"row_or_column": same_row_column.type
	}

func are_in_same_row_or_column(pos1: int, pos2: int) -> Dictionary:
	"""Check if two positions are in same row or column. Returns {is_valid: bool, type: String}"""
	
	var x1 = pos1 % grid_size
	var y1 = pos1 / grid_size
	var x2 = pos2 % grid_size
	var y2 = pos2 / grid_size
	
	if y1 == y2:
		return {"is_valid": true, "type": "row"}
	elif x1 == x2:
		return {"is_valid": true, "type": "column"}
	else:
		return {"is_valid": false, "type": ""}

func find_empty_slot_between(pos1: int, pos2: int) -> int:
	"""Find empty slot between two positions. Returns position index or -1 if none/multiple."""
	
	var x1 = pos1 % grid_size
	var y1 = pos1 / grid_size
	var x2 = pos2 % grid_size
	var y2 = pos2 / grid_size
	
	var empty_positions = []
	
	if y1 == y2:  # Same row
		var min_x = min(x1, x2)
		var max_x = max(x1, x2)
		
		for x in range(min_x + 1, max_x):
			var check_pos = y1 * grid_size + x
			if not grid_occupied[check_pos]:
				empty_positions.append(check_pos)
	
	elif x1 == x2:  # Same column
		var min_y = min(y1, y2)
		var max_y = max(y1, y2)
		
		for y in range(min_y + 1, max_y):
			var check_pos = y * grid_size + x1
			if not grid_occupied[check_pos]:
				empty_positions.append(check_pos)
	
	# Return position if exactly one empty slot, otherwise -1
	if empty_positions.size() == 1:
		return empty_positions[0]
	else:
		return -1

func get_attack_direction(attacker_pos: int, defender_pos: int) -> int:
	"""Get the direction from attacker to defender position"""
	
	var x1 = attacker_pos % grid_size
	var y1 = attacker_pos / grid_size
	var x2 = defender_pos % grid_size
	var y2 = defender_pos / grid_size
	
	# Determine direction
	if y2 < y1:  # Target is north
		return 0
	elif x2 > x1:  # Target is east
		return 1
	elif y2 > y1:  # Target is south
		return 2
	elif x2 < x1:  # Target is west
		return 3
	else:
		return -1  # Same position (shouldn't happen)



func get_direction_name_from_index(direction: int) -> String:
	"""Get direction name for debugging"""
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func execute_pursuit(pursuit_data: Dictionary):
	"""Execute a Pursuit ability with the given data"""
	
	print("EXECUTING PURSUIT ABILITY")
	print("  Pursuit card: ", pursuit_data.pursuit_card.card_name, " at position ", pursuit_data.pursuit_position)
	print("  Target card: ", pursuit_data.target_card.card_name, " at position ", pursuit_data.target_position)
	print("  Moving to position: ", pursuit_data.move_to_position)
	print("  Attack direction: ", get_direction_name_from_index(pursuit_data.attack_direction))
	
	# Find the Pursuit ability instance
	var pursuit_position = pursuit_data.pursuit_position
	var pursuit_card = pursuit_data.pursuit_card
	var card_level = get_card_level_for_position(pursuit_position)
	
	var pursuit_ability = null
	for ability in pursuit_card.get_available_abilities(card_level):
		if ability.ability_name == "Pursuit":
			pursuit_ability = ability
			break
	
	if not pursuit_ability:
		print("ERROR: Could not find Pursuit ability on card")
		return
	
	# Create context for the ability execution
	var context = {
		"pursuit_card": pursuit_data.pursuit_card,
		"pursuit_position": pursuit_data.pursuit_position,
		"target_card": pursuit_data.target_card,
		"target_position": pursuit_data.target_position,
		"move_to_position": pursuit_data.move_to_position,
		"direction": pursuit_data.attack_direction,
		"game_manager": self
	}
	
	# Execute the Pursuit ability
	pursuit_ability.execute(context)

func get_card_level_for_position(grid_index: int) -> int:
	"""Get the card level for a card at a specific grid position"""
	var collection_index = get_card_collection_index(grid_index)
	if collection_index != -1:
		return get_card_level(collection_index)
	else:
		return 1  # Default level for opponent cards or cards without collection mapping


func start_dance_mode(dancer_position: int, dancer_owner: Owner, dancer_card: CardResource):
	dance_mode_active = true
	current_dancer_position = dancer_position
	current_dancer_owner = dancer_owner
	current_dancer_card = dancer_card
	
	# Update game status
	if dancer_owner == Owner.PLAYER:
		game_status_label.text = "💃 DANCE MODE: Select an empty slot to dance to"
	else:
		game_status_label.text = "💃 " + opponent_manager.get_opponent_info().name + " is dancing..."
		# Auto-select target for opponent
		call_deferred("opponent_select_dance_target")
	
	print("Dance mode activated for ", dancer_card.card_name, " at position ", dancer_position)

func select_dance_target(target_position: int):
	if not dance_mode_active:
		return
	
	print("Dance target selected: position ", target_position)
	
	# Get the dancer card data from the original position
	var dancer_card = current_dancer_card
	var original_position = current_dancer_position
	var dancing_owner = current_dancer_owner
	
	# End dance mode first
	dance_mode_active = false
	current_dancer_position = -1
	current_dancer_owner = Owner.NONE
	current_dancer_card = null
	
	# Move the card from original position to target position
	execute_dance_move(original_position, target_position, dancer_card, dancing_owner)

func execute_dance_move(from_position: int, to_position: int, dancer_card: CardResource, dancing_owner: Owner):
	print("Executing dance move from position ", from_position, " to position ", to_position)
	
	# Get card collection info before clearing original position
	var card_collection_index = get_card_collection_index_for_dance(from_position)
	var card_level = get_card_level(card_collection_index)
	
	var existing_card_display = null
	var from_slot = grid_slots[from_position]
	for child in from_slot.get_children():
		if child is CardDisplay:
			existing_card_display = child
			break

	# FIXED: Clear the original position without using clear_grid_slot to avoid freeing the card display
	grid_occupied[from_position] = false
	grid_ownership[from_position] = Owner.NONE
	grid_card_data[from_position] = null

	# Clear passive abilities for this position
	if from_position in active_passive_abilities:
		active_passive_abilities.erase(from_position)

	# Place the card at the new position
	grid_occupied[to_position] = true
	grid_ownership[to_position] = dancing_owner
	grid_card_data[to_position] = dancer_card

	# Update grid to collection mapping for the new position
	if card_collection_index != -1:
		grid_to_collection_index[to_position] = card_collection_index
		grid_to_collection_index.erase(from_position)

	# FIXED: Move the existing card display instead of creating a new one
	if existing_card_display and is_instance_valid(existing_card_display):
		# Remove from old slot
		from_slot.remove_child(existing_card_display)
		
		# Add to new slot
		var to_slot = grid_slots[to_position]
		to_slot.add_child(existing_card_display)
		
		print("DancerAbility: Moved existing CardDisplay from position ", from_position, " to ", to_position)
	else:
		# Fallback: create new card display if the old one was somehow invalid
		var slot = grid_slots[to_position]
		var card_display_scene = preload("res://Scenes/CardDisplay.tscn")
		var card_display = card_display_scene.instantiate()
		card_display.setup(dancer_card, card_level, "", card_collection_index, dancing_owner == Owner.OPPONENT)
		slot.add_child(card_display)
		print("DancerAbility: Created new CardDisplay as fallback")
	
	# Execute placement effects at new location (like ordain bonus)
	if dancing_owner == Owner.PLAYER:
		apply_ordain_bonus_if_applicable(to_position, dancer_card, dancing_owner)
	
	# Handle passive abilities at new position
	handle_passive_abilities_on_place(to_position, dancer_card, card_level)
	
	# Check for couple union at new position
	check_for_couple_union(dancer_card, to_position)
	
	# Resolve combat at the new position
	var captures = resolve_combat(to_position, dancing_owner, dancer_card)
	if captures > 0:
		print("Dancer captured ", captures, " cards after dancing!")
	
	# Update displays
	update_card_display(to_position, dancer_card)
	update_game_status()
	
	# Check if game should end
	if should_game_end():
		end_game()
		return
	
	# Switch turns after dance is complete
	print("Dance complete - switching turns")
	turn_manager.next_turn()

func get_card_collection_index_for_dance(original_position: int) -> int:
	return grid_to_collection_index.get(original_position, -1)

func clear_grid_slot(position: int):
	grid_occupied[position] = false
	grid_ownership[position] = Owner.NONE
	grid_card_data[position] = null
	
	# Remove visual display
	var slot = grid_slots[position]
	for child in slot.get_children():
		child.queue_free()
	
	# Clear passive abilities
	if position in active_passive_abilities:
		active_passive_abilities.erase(position)

func opponent_select_dance_target():
	if not dance_mode_active:
		return
	
	# Simple AI: pick a random empty slot
	var possible_targets = []
	
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:  # Only empty slots
			possible_targets.append(i)
	
	var target_position = -1
	if possible_targets.size() > 0:
		target_position = possible_targets[randi() % possible_targets.size()]
	
	if target_position != -1:
		select_dance_target(target_position)

func clear_all_dance_constraints():
	if dance_mode_active:
		dance_mode_active = false
		current_dancer_position = -1
		current_dancer_owner = Owner.NONE
		current_dancer_card = null
		print("All dance constraints cleared")


# Start trojan horse deployment mode
func start_trojan_horse_mode(summoner_position: int, summoner_owner: Owner, summoner_card: CardResource):
	trojan_horse_mode_active = true
	current_trojan_summoner_position = summoner_position
	current_trojan_summoner_owner = summoner_owner
	current_trojan_summoner_card = summoner_card
	
	# Update game status
	if summoner_owner == Owner.PLAYER:
		game_status_label.text = "🐴 TROJAN HORSE: Select a slot to deploy the trojan horse"
	else:
		# This shouldn't happen since it's player-only, but just in case
		game_status_label.text = "🐴 " + opponent_manager.get_opponent_info().name + " is deploying a trojan horse..."
	
	print("Trojan Horse mode activated for ", summoner_card.card_name, " at position ", summoner_position)

# Select target slot for trojan horse deployment
func select_trojan_horse_target(target_position: int):
	if not trojan_horse_mode_active:
		return
	
	print("Trojan Horse target selected: position ", target_position)
	
	# Deploy the trojan horse card at the selected position
	deploy_trojan_horse(target_position)
	
	# End trojan horse mode
	trojan_horse_mode_active = false
	current_trojan_summoner_position = -1
	current_trojan_summoner_owner = Owner.NONE
	current_trojan_summoner_card = null
	
	# Update game status
	game_status_label.text = "Trojan Horse deployed! The trap is set..."
	
	# Switch turns - trojan horse deployment completes the turn
	print("Trojan Horse deployed - switching turns")
	turn_manager.next_turn()

# Deploy the actual trojan horse card
func deploy_trojan_horse(target_position: int):
	print("Deploying Trojan Horse at position ", target_position)
	
	# Get the Trojan Horse card from Hermes collection (index 5)
	var hermes_collection = load("res://Resources/Collections/Hermes.tres") as GodCardCollection
	if not hermes_collection:
		print("ERROR: Could not load Hermes collection")
		return
	
	print("Hermes collection loaded. Cards count: ", hermes_collection.cards.size())
	
	if hermes_collection.cards.size() <= 5:
		print("ERROR: Hermes collection doesn't have enough cards (needs at least 6 for index 5)")
		print("Available cards:")
		for i in range(hermes_collection.cards.size()):
			print("  Index ", i, ": ", hermes_collection.cards[i].card_name)
		return
	
	var trojan_horse_card = hermes_collection.cards[5]  # Trojan Horse at index 5
	
	print("Retrieved Trojan Horse card:")
	print("  Name: ", trojan_horse_card.card_name)
	print("  Values: ", trojan_horse_card.values)
	print("  Description: ", trojan_horse_card.description)
	
	# Validate the card data
	if trojan_horse_card.card_name != "Trojan Horse":
		print("WARNING: Expected 'Trojan Horse' but got '", trojan_horse_card.card_name, "'")
	
	if trojan_horse_card.values != [0, 0, 0, 0]:
		print("WARNING: Expected [0,0,0,0] values but got ", trojan_horse_card.values)
	
	# Set up the card data structures
	grid_card_data[target_position] = trojan_horse_card
	grid_occupied[target_position] = true
	grid_ownership[target_position] = Owner.PLAYER  # Always owned by player
	
	# Track this as an active trojan horse
	active_trojan_horses.append(target_position)
	
	# Create and display the card visually
	var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	
	var slot = grid_slots[target_position]
	# Clear any existing content
	for child in slot.get_children():
		child.queue_free()
	slot.add_child(card_display)
	
	# Wait one frame to ensure @onready variables are initialized
	await get_tree().process_frame
	
	# Setup the card display with proper parameters
	# Use level 1, current god name, and index 5 (trojan horse index)
	card_display.setup(trojan_horse_card, 1, current_god, 5)
	
	# Apply player card styling
	slot.add_theme_stylebox_override("panel", player_card_style)
	
	print("Trojan Horse successfully deployed at position ", target_position)

# Check if board is full for trojan horse cleanup
func check_trojan_horse_cleanup():
	if active_trojan_horses.is_empty():
		return
	
	# Check if board is full
	var empty_slots = 0
	for occupied in grid_occupied:
		if not occupied:
			empty_slots += 1
	
	if empty_slots == 0:
		print("Board is full - removing all trojan horses")
		for horse_position in active_trojan_horses:
			remove_trojan_horse(horse_position)
		active_trojan_horses.clear()

# Remove a trojan horse from the board
func remove_trojan_horse(horse_position: int):
	if horse_position < 0 or horse_position >= grid_slots.size():
		return
	
	print("Removing Trojan Horse from position ", horse_position)
	
	# Clear the card data
	grid_card_data[horse_position] = null
	grid_occupied[horse_position] = false
	grid_ownership[horse_position] = Owner.NONE
	
	# Clear the visual display
	var slot = grid_slots[horse_position]
	for child in slot.get_children():
		child.queue_free()
	
	# Restore default slot styling
	slot.add_theme_stylebox_override("panel", default_grid_style)
	
	# Remove from active trojan horses list
	active_trojan_horses.erase(horse_position)

# Clear all trojan horses (for game end or reset)
func clear_all_trojan_horses():
	for horse_position in active_trojan_horses:
		remove_trojan_horse(horse_position)
	active_trojan_horses.clear()
	trojan_horse_mode_active = false
	current_trojan_summoner_position = -1
	current_trojan_summoner_owner = Owner.NONE
	current_trojan_summoner_card = null
	print("All trojan horses cleared")

func check_trojan_horse_reversal(defender_pos: int, defending_card: CardResource, attacker_pos: int, attacking_card: CardResource, attacking_owner: Owner) -> bool:
	# Add null checks first to prevent crashes
	if not defending_card or not attacking_card:
		print("check_trojan_horse_reversal: Null card detected - defending_card: ", defending_card, ", attacking_card: ", attacking_card)
		return false
	
	# Check if the defending card is a Trojan Horse with reversal ability
	if defending_card.card_name != "Trojan Horse":
		return false
	
	# Check if it has the reversal ability and get the specific ability instance
	var reversal_ability = null
	for ability in defending_card.abilities:
		if ability.ability_name == "Its just a horse":  # Match the actual ability name in the collection
			reversal_ability = ability
			break
	
	if not reversal_ability:
		return false
	
	print("=== TROJAN HORSE TRAP ACTIVATED ===")
	print("  Attacking card: ", attacking_card.card_name, " at position ", attacker_pos)
	print("  Trojan Horse at position: ", defender_pos)
	print("  Reversing capture - attacking card will be captured instead!")
	
	# Create the proper context for the reversal ability
	var reversal_context = {
		"defending_card": defending_card,
		"attacking_card": attacking_card,
		"defending_position": defender_pos,
		"attacking_position": attacker_pos,
		"game_manager": self,
		"attacking_owner": attacking_owner,
		"would_be_captured": true  # This indicates the horse would normally be captured
	}
	
	# Execute the actual reversal ability instead of handling it manually
	var reversal_successful = reversal_ability.execute(reversal_context)
	
	if reversal_successful:
		print("=== TROJAN HORSE TRAP COMPLETED ===")
	else:
		print("=== TROJAN HORSE TRAP FAILED ===")
	
	return reversal_successful


func start_sanctuary_mode(sanctuary_position: int, sanctuary_owner: Owner, sanctuary_card: CardResource):
	sanctuary_mode_active = true
	current_sanctuary_position = sanctuary_position
	current_sanctuary_owner = sanctuary_owner
	current_sanctuary_card = sanctuary_card
	
	# Update game status
	if sanctuary_owner == Owner.PLAYER:
		game_status_label.text = "🛡️ SANCTUARY MODE: Select an empty slot to sanctuary"
	else:
		game_status_label.text = "🛡️ " + opponent_manager.get_opponent_info().name + " is sanctuaring..."
		# Auto-select target for opponent
		call_deferred("opponent_select_sanctuary_target")
	
	print("Sanctuary mode activated for ", sanctuary_card.card_name, " at position ", sanctuary_position)

# Add this function with the other target selection functions (around line 1000-1100)
func select_sanctuary_target(target_position: int):
	if not sanctuary_mode_active:
		return
	
	print("Sanctuary target selected: position ", target_position)
	
	# Set the sanctuary effect
	active_sanctuary_slot = target_position
	
	# Apply visual styling to show this slot is sanctuaried
	apply_sanctuary_target_styling(target_position)
	
	# End sanctuary mode
	sanctuary_mode_active = false
	current_sanctuary_position = -1
	current_sanctuary_owner = Owner.NONE
	current_sanctuary_card = null
	
	# Update game status
	if current_sanctuary_owner == Owner.PLAYER:
		game_status_label.text = "Sanctuary set! Next friendly card in that slot gets cheat death."
	else:
		game_status_label.text = "Opponent sanctuaried a slot."
	
	# Switch turns - sanctuary action completes the turn
	print("Sanctuary target selected - switching turns")
	turn_manager.next_turn()

# Add this styling function with the other styling functions (around line 1200-1300)
func apply_sanctuary_target_styling(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	slot.add_theme_stylebox_override("panel", sanctuary_target_style)
	
	print("Applied sanctuary target styling (cyan border) to slot ", grid_index)

# Add this function with the other removal functions (around line 1300-1400)
func remove_sanctuary_effect():
	if active_sanctuary_slot == -1:
		return
	
	print("Removing sanctuary effect from position ", active_sanctuary_slot)
	
	var slot_to_restore = active_sanctuary_slot
	active_sanctuary_slot = -1
	
	# Restore visual styling to default (after clearing tracking)
	restore_slot_original_styling(slot_to_restore)

# Add this AI function with the other opponent AI functions (around line 1400-1500)
func opponent_select_sanctuary_target():
	if not sanctuary_mode_active:
		return
	
	# Simple AI: pick a random empty slot
	var possible_targets = []
	
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:  # Only empty slots
			possible_targets.append(i)
	
	var target_position = -1
	if possible_targets.size() > 0:
		target_position = possible_targets[randi() % possible_targets.size()]
	
	if target_position != -1:
		select_sanctuary_target(target_position)

# Add this clear function with the other clear functions (around line 1500-1600)
func clear_all_sanctuary_effects():
	if active_sanctuary_slot != -1:
		remove_sanctuary_effect()
	sanctuary_mode_active = false
	current_sanctuary_position = -1
	current_sanctuary_owner = Owner.NONE
	current_sanctuary_card = null
	print("All sanctuary effects cleared")

func apply_sanctuary_cheat_death_if_applicable(grid_position: int, card_data: CardResource, placing_owner: Owner):
	print("=== SANCTUARY CHEAT DEATH CHECK ===")
	print("Active sanctuary slot: ", active_sanctuary_slot)
	print("Grid position: ", grid_position)
	print("Placing owner: ", placing_owner)
	print("Card being placed: ", card_data.card_name)
	
	# Only apply sanctuary cheat death if:
	# 1. There's an active sanctuary slot
	# 2. The card is being placed in the sanctuaried slot  
	# 3. The placing owner is the player (friendly card)
	if active_sanctuary_slot != -1 and grid_position == active_sanctuary_slot and placing_owner == Owner.PLAYER:
		print("CONDITIONS MET - Granting sanctuary cheat death to ", card_data.card_name)
		
		# Grant cheat death by setting metadata on the card
		card_data.set_meta("sanctuary_cheat_death", true)
		
		print("Sanctuary cheat death granted to ", card_data.card_name, "!")
		print("Metadata check: ", card_data.has_meta("sanctuary_cheat_death"), " = ", card_data.get_meta("sanctuary_cheat_death"))
		
		# Remove the sanctuary effect after use
		remove_sanctuary_effect()
		
		return true
	elif active_sanctuary_slot != -1 and grid_position == active_sanctuary_slot:
		# Enemy used sanctuaried slot - just remove effect silently
		print("Enemy used sanctuaried slot - removing effect without granting cheat death")
		remove_sanctuary_effect()
	else:
		print("Sanctuary cheat death conditions NOT met")
	
	return false


func handle_misdirection_activation(grid_index: int):
	print("=== MISDIRECTION ACTIVATION ATTEMPT ===")
	print("Grid index: ", grid_index)
	print("Misdirection power active: ", active_deck_power == DeckDefinition.DeckPowerType.MISDIRECTION_POWER)
	print("Misdirection already used: ", misdirection_used)
	print("Slot occupied: ", grid_occupied[grid_index])
	print("Slot owner: ", grid_ownership[grid_index] if grid_occupied[grid_index] else "NONE")
	
	# Check if misdirection power is available
	if active_deck_power != DeckDefinition.DeckPowerType.MISDIRECTION_POWER:
		print("Misdirection power not active for this deck")
		return
	
	if misdirection_used:
		print("Misdirection already used this battle")
		if notification_manager:
			notification_manager.show_notification("Misdirection already used this battle")
		return
	
	# Check if the target is an enemy card
	if not grid_occupied[grid_index]:
		print("No card at target position")
		if notification_manager:
			notification_manager.show_notification("No target found")
		return
	
	if grid_ownership[grid_index] != Owner.OPPONENT:
		print("Target is not an enemy card")
		if notification_manager:
			notification_manager.show_notification("Can only target enemy cards")
		return
	
	# Get the enemy card data
	var enemy_card = grid_card_data[grid_index]
	if not enemy_card:
		print("No card data found at position")
		return
	
	# Apply misdirection - invert N↔S and E↔W
	print("MISDIRECTION ACTIVATED! Inverting stats for: ", enemy_card.card_name)
	print("Original stats: ", enemy_card.values)
	
	# Store original values for logging
	var original_north = enemy_card.values[0]
	var original_east = enemy_card.values[1]
	var original_south = enemy_card.values[2]
	var original_west = enemy_card.values[3]
	
	# Perform the inversion: N↔S, E↔W
	enemy_card.values[0] = original_south  # North becomes South
	enemy_card.values[1] = original_west   # East becomes West
	enemy_card.values[2] = original_north  # South becomes North
	enemy_card.values[3] = original_east   # West becomes East
	
	print("Inverted stats: ", enemy_card.values)
	print("N:", original_north, "→", enemy_card.values[0], " | E:", original_east, "→", enemy_card.values[1])
	print("S:", original_south, "→", enemy_card.values[2], " | W:", original_west, "→", enemy_card.values[3])
	
	# Mark misdirection as used
	misdirection_used = true
	
	# Update the visual display
	update_card_display(grid_index, enemy_card)
	
	# Show notification
	if notification_manager:
		notification_manager.show_notification("🃏 Misdirection! " + enemy_card.card_name + "'s stats inverted!")
	
	print("Misdirection power used successfully!")

func process_charge_turn_start(is_player_turn: bool):
	if is_player_turn:
		print("Processing charge abilities for player turn start")
		# Check player-owned cards for charge against opponent targets
		check_charge_triggers_for_owner(Owner.PLAYER, Owner.OPPONENT)
	else:
		print("Processing charge abilities for opponent turn start")
		# Check opponent-owned cards for charge against player targets
		check_charge_triggers_for_owner(Owner.OPPONENT, Owner.PLAYER)

# Check for charge ability triggers for cards owned by charging_owner against target_owner
func check_charge_triggers_for_owner(charging_owner: Owner, target_owner: Owner):
	print("=== CHARGE CHECK DEBUG ===")
	print("Checking charge triggers for ", get_owner_name(charging_owner), " against ", get_owner_name(target_owner))
	
	var charge_candidates = []
	var current_turn = get_current_turn_number()
	print("Current turn number: ", current_turn)
	
	# Check all occupied positions for cards with Charge ability
	for i in range(grid_slots.size()):
		print("Checking position ", i, " - occupied: ", grid_occupied[i])
		if not grid_occupied[i]:
			continue
			
		var card = get_card_at_position(i)
		var owner = get_owner_at_position(i)
		
		print("  Position ", i, " has card: ", card.card_name if card else "none", " owned by: ", get_owner_name(owner))
		
		# Only check cards owned by the charging owner
		if owner != charging_owner:
			print("  Wrong owner - skipping")
			continue
		
		var card_level = get_card_level_for_position(i)
		if not card.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			print("  No passive abilities - skipping")
			continue
		
		# Check if this card has Charge ability
		var has_charge = false
		var available_abilities = card.get_available_abilities(card_level)
		print("  Card has ", available_abilities.size(), " available abilities:")
		for ability in available_abilities:
			print("    - ", ability.ability_name, " (trigger: ", ability.trigger_condition, ")")
			if ability.ability_name == "Charge":
				has_charge = true
		
		if not has_charge:
			print("  No Charge ability - skipping")
			continue
		
		print("  *** FOUND CHARGE CARD: ", card.card_name, " at position ", i, " ***")
		
		# NEW: Check if this card was placed this turn (if so, skip it)
		if card.has_meta("charge_placed_turn"):
			var placed_turn = card.get_meta("charge_placed_turn")
			print("  Charge card placed on turn: ", placed_turn, " (current turn: ", current_turn, ")")
			if placed_turn == current_turn:
				print("  *** CHARGE CARD PLACED THIS TURN - SKIPPING ***")
				continue
			else:
				print("  Charge card placed on previous turn - can charge")
		else:
			print("  No placement turn metadata - can charge")
		
		# Check all enemy cards as potential targets
		for j in range(grid_slots.size()):
			print("    Checking target position ", j, " - occupied: ", grid_occupied[j])
			if not grid_occupied[j]:
				continue
			
			var target_card = get_card_at_position(j)
			var target_owner_at_pos = get_owner_at_position(j)
			
			print("      Target position ", j, " has card: ", target_card.card_name if target_card else "none", " owned by: ", get_owner_name(target_owner_at_pos))
			
			# Only target cards owned by the target owner
			if target_owner_at_pos != target_owner:
				print("      Wrong target owner - skipping")
				continue
			
			print("      *** CHECKING CHARGE CONDITIONS: position ", i, " vs position ", j, " ***")
			# Check if this Charge card can target this enemy card
			var charge_data = check_charge_conditions(i, card, j, target_card)
			if charge_data != null:
				print("      *** CHARGE TRIGGER VALID! ***")
				charge_candidates.append(charge_data)
			else:
				print("      Charge conditions not met")
	
	print("Found ", charge_candidates.size(), " charge candidates")
	
	# If we have multiple candidates, only activate the lowest slot number
	if charge_candidates.size() > 1:
		print("Multiple Charge triggers found - selecting lowest slot number")
		charge_candidates.sort_custom(func(a, b): return a.charge_position < b.charge_position)
		
		# Only keep the first (lowest slot) candidate
		var selected_candidate = charge_candidates[0]
		print("Selected Charge candidate at position ", selected_candidate.charge_position)
		charge_candidates = [selected_candidate]
	
	# Execute Charge if we have a valid candidate
	if charge_candidates.size() == 1:
		print("*** EXECUTING CHARGE! ***")
		execute_charge(charge_candidates[0])
	else:
		print("*** NO VALID CHARGE TRIGGERS FOUND ***")
	
	print("=== END CHARGE CHECK ===")

func check_charge_conditions(charge_position: int, charge_card: CardResource, target_position: int, target_card: CardResource):
	"""Check if a Charge card can target the given enemy card. Returns charge data Dictionary if valid, null if not."""
	
	print("      Checking Charge conditions: position ", charge_position, " targeting position ", target_position)
	
	# Check if charge and target are in same row or column
	var same_row_column = are_in_same_row_or_column(charge_position, target_position)
	if not same_row_column.is_valid:
		print("        Not in same row/column - Charge cannot trigger")
		return null
	
	print("        Same ", same_row_column.type, " - checking for empty slot between")
	
	# Check if there's exactly one empty slot between them
	var empty_slot = find_empty_slot_between(charge_position, target_position)
	if empty_slot == -1:
		print("        No single empty slot between positions - Charge cannot trigger")
		# Let's also debug what slots are between them
		var x1 = charge_position % grid_size
		var y1 = charge_position / grid_size
		var x2 = target_position % grid_size
		var y2 = target_position / grid_size
		
		if y1 == y2:  # Same row
			print("        Same row debug - positions between ", charge_position, " and ", target_position, ":")
			var min_x = min(x1, x2)
			var max_x = max(x1, x2)
			for x in range(min_x + 1, max_x):
				var check_pos = y1 * grid_size + x
				print("          Position ", check_pos, " occupied: ", grid_occupied[check_pos])
		elif x1 == x2:  # Same column
			print("        Same column debug - positions between ", charge_position, " and ", target_position, ":")
			var min_y = min(y1, y2)
			var max_y = max(y1, y2)
			for y in range(min_y + 1, max_y):
				var check_pos = y * grid_size + x1
				print("          Position ", check_pos, " occupied: ", grid_occupied[check_pos])
		return null
	
	print("        Found empty slot at position ", empty_slot)
	
	# Determine attack direction from charge to target
	var attack_direction = get_attack_direction(empty_slot, target_position)
	if attack_direction == -1:
		print("        Could not determine attack direction - Charge cannot trigger")
		return null
	
	print("        Attack direction: ", get_direction_name_from_index(attack_direction))
	print("        Charge trigger valid - charge always captures!")
	
	# Return charge data
	return {
		"charge_card": charge_card,
		"charge_position": charge_position,
		"target_card": target_card,
		"target_position": target_position,
		"move_to_position": empty_slot,
		"attack_direction": attack_direction
	}
func execute_charge(charge_data: Dictionary):
	"""Execute a charge ability with the given data"""
	
	print("EXECUTING CHARGE ABILITY")
	print("  Charge card: ", charge_data.charge_card.card_name, " at position ", charge_data.charge_position)
	print("  Target card: ", charge_data.target_card.card_name, " at position ", charge_data.target_position)
	print("  Moving to position: ", charge_data.move_to_position)
	print("  Attack direction: ", get_direction_name_from_index(charge_data.attack_direction))
	
	# Find the Charge ability instance
	var charge_position = charge_data.charge_position
	var charge_card = charge_data.charge_card
	var card_level = get_card_level_for_position(charge_position)
	
	var charge_ability = null
	for ability in charge_card.get_available_abilities(card_level):
		if ability.ability_name == "Charge":
			charge_ability = ability
			break
	
	if not charge_ability:
		print("ERROR: Could not find Charge ability on card")
		return
	
	# Create context for the ability execution
	var context = {
		"charge_card": charge_data.charge_card,
		"charge_position": charge_data.charge_position,
		"target_card": charge_data.target_card,
		"target_position": charge_data.target_position,
		"move_to_position": charge_data.move_to_position,
		"direction": charge_data.attack_direction,
		"game_manager": self
	}
	
	# Execute the Charge ability
	charge_ability.execute(context)

func get_owner_name(owner: Owner) -> String:
	"""Get owner name for debugging"""
	match owner:
		Owner.PLAYER: return "Player"
		Owner.OPPONENT: return "Opponent"
		_: return "Neutral"

# Helper function for Hermes visual trickery - inverts OPPONENT card display values only
func get_display_value_for_opponent_card(actual_value: int) -> int:
	if not visual_stat_inversion_active:
		return actual_value
	
	# Invert values: 1<->9, 2<->8, 3<->7, 4<->6, 5 stays 5
	match actual_value:
		1: return 9
		2: return 8
		3: return 7
		4: return 6
		5: return 5
		6: return 4
		7: return 3
		8: return 2
		9: return 1
		_: return actual_value

func set_soothe_active(active: bool):
	soothe_active = active
	if active:
		print("Soothe effect activated - next opponent card will be weakened")
	else:
		print("Soothe effect deactivated")


# Method to let player choose from underworld allies (for tier 2 ability)
func let_player_choose_underworld_ally(underworld_allies: Array) -> CardResource:
	print("Player choosing underworld ally from ", underworld_allies.size(), " options")
	
	# For now, implement a simple text-based choice
	# TODO: Replace with proper UI later
	
	# Create choice text
	var choice_text = "Choose your underworld ally:\n"
	for i in range(underworld_allies.size()):
		var ally = underworld_allies[i]
		choice_text += str(i + 1) + ". " + ally.card_name + " (" + str(ally.values) + ")\n"
	
	# Show choice in game status (temporary implementation)
	game_status_label.text = choice_text + "Press 1, 2, or 3 to choose"
	
	# Wait for player input (simplified - would need proper input handling)
	# For now, just return random choice as placeholder
	var chosen_index = randi() % underworld_allies.size()
	print("Player chose: ", underworld_allies[chosen_index].card_name)
	return underworld_allies[chosen_index]

# Replace a card with a summoned ally
func replace_card_with_summon(grid_position: int, summoned_ally: CardResource):
	print("=== REPLACING CARD WITH SUMMON ===")
	print("Position: ", grid_position)
	print("Summoned ally: ", summoned_ally.card_name)
	
	if grid_position < 0 or grid_position >= grid_slots.size():
		print("ERROR: Invalid grid position for replacement")
		return
	
	if not grid_occupied[grid_position]:
		print("ERROR: No card at position to replace")
		return
	
	# Get the current owner (should be player since it's Persephone)
	var current_owner = grid_ownership[grid_position]
	
	# FIXED: Remove the old card display first
	var slot = grid_slots[grid_position]
	for child in slot.get_children():
		if child.has_method("setup"):  # This is a CardDisplay
			print("Removing old card display: ", child.card_data.card_name if child.card_data else "Unknown")
			child.queue_free()
	
	# Create a copy of the summoned ally for the grid
	var ally_copy = summoned_ally.duplicate(true)
	
	# Replace the card data
	grid_card_data[grid_position] = ally_copy
	
	# FIXED: Create new card display properly
	var card_display_scene = preload("res://Scenes/CardDisplay.tscn")
	var card_display = card_display_scene.instantiate()
	slot.add_child(card_display)
	
	# Wait one frame to ensure the card display is ready
	await get_tree().process_frame
	
	# Setup the new card display
	card_display.setup(ally_copy)
	
	# Connect hover signals for the summoned card
	card_display.card_hovered.connect(_on_card_hovered)
	card_display.card_unhovered.connect(_on_card_unhovered)
	print("Connected hover signals for summoned card: ", ally_copy.card_name)
	
	# Connect right-click handling for the summoned card
	if card_display and card_display.panel:
		card_display.panel.gui_input.connect(_on_grid_card_right_click.bind(grid_position))
		print("Connected right-click handler for summoned card at grid position ", grid_position)
	
	# Apply ownership styling
	if current_owner == Owner.PLAYER:
		if card_display and card_display.panel:
			card_display.panel.add_theme_stylebox_override("panel", player_card_style)
	
	print("Card replacement complete - ", ally_copy.card_name, " now visible")
	
	# Execute the summoned ally's ON_PLAY abilities
	var ally_level = 1  # Summoned allies are always base level
	if ally_copy.has_ability_type(CardAbility.TriggerType.ON_PLAY, ally_level):
		print("Executing ON_PLAY abilities for summoned ally: ", ally_copy.card_name)
		
		var ability_context = {
			"placed_card": ally_copy,
			"grid_position": grid_position,
			"game_manager": self,
			"card_level": ally_level
		}
		ally_copy.execute_abilities(CardAbility.TriggerType.ON_PLAY, ability_context, ally_level)
		
		# Update display after abilities execute
		update_card_display(grid_position, ally_copy)
	
	# Handle passive abilities for the summoned ally
	handle_passive_abilities_on_place(grid_position, ally_copy, ally_level)
	
	print("Resolving combat for summoned ally: ", ally_copy.card_name)
	var captures = resolve_combat(grid_position, current_owner, ally_copy)
	if captures > 0:
		print("Summoned ally captured ", captures, " cards!")
	else:
		print("No captures for summoned ally")

func get_persephone_level() -> int:
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return 1
	
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var god_progress = progress_tracker.get_god_progress("Demeter")
	
	# Sum experience from underworld allies (indices 5, 6, 7)
	var total_underworld_exp = 0
	var underworld_indices = [5, 6, 7]  # Cerberus, Hades, Hecate
	
	for index in underworld_indices:
		if index in god_progress:
			var card_exp = god_progress[index]
			total_underworld_exp += card_exp.get("total_exp", 0)
	
	print("Persephone level calculation: combined underworld exp = ", total_underworld_exp)
	
	# Use the same level thresholds as other cards
	# Standard progression: 50, 150, 300, 500, 750, etc.
	if total_underworld_exp >= 750:
		return 6
	elif total_underworld_exp >= 500:
		return 5
	elif total_underworld_exp >= 300:
		return 4
	elif total_underworld_exp >= 150:
		return 3
	elif total_underworld_exp >= 50:
		return 2
	else:
		return 1


func setup_seasons_power():
	print("=== SETTING UP SEASONS POWER ===")
	
	# Check if this is the Fimbulwinter boss battle
	var params = get_scene_params()
	var is_fimbulwinter_boss = false
	
	if params.has("current_node"):
		var current_node = params["current_node"]
		if current_node.node_type == MapNode.NodeType.BOSS and current_node.enemy_name == BossConfig.DEMETER_BOSS_NAME:
			is_fimbulwinter_boss = true
			print("FIMBULWINTER BOSS DETECTED - Eternal Winter mode activated!")
	
	# Set initial season
	if is_fimbulwinter_boss:
		current_season = Season.WINTER  # Force winter for Fimbulwinter boss
		fimbulwinter_boss_active = true  # Add this flag to prevent season changes
	else:
		current_season = Season.SUMMER  # Normal start in Summer
		fimbulwinter_boss_active = false
	
	# Create season status display
	create_seasons_status_label()
	update_seasons_display()
	
	if is_fimbulwinter_boss:
		print("The Seasons power activated - Eternal Winter enforced by Fimbulwinter!")
	else:
		print("The Seasons power activated - Summer begins with Persephone in hand")


func create_seasons_status_label():
	# Create a label to show current season
	seasons_status_label = Label.new()
	seasons_status_label.name = "SeasonsStatusLabel"
	seasons_status_label.add_theme_font_size_override("font_size", 18)
	seasons_status_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Position it near the game status label
	seasons_status_label.position = Vector2(10, 100)
	add_child(seasons_status_label)

func update_seasons_display():
	if not seasons_status_label:
		return
		
	match current_season:
		Season.SUMMER:
			seasons_status_label.text = "🌞 Summer - Growth Flourishes"
			seasons_status_label.add_theme_color_override("font_color", Color("#FFD700"))  # Gold
		Season.WINTER:
			if fimbulwinter_boss_active:
				seasons_status_label.text = "🌨️ Fimbulwinter - Eternal Freeze"
				seasons_status_label.add_theme_color_override("font_color", Color("#4169E1"))  # Royal blue for boss
			else:
				seasons_status_label.text = "❄️ Winter - Growth Withers" 
				seasons_status_label.add_theme_color_override("font_color", Color("#87CEEB"))  # Sky blue

func transition_to_winter():
	# Prevent season changes during Fimbulwinter boss fight
	if fimbulwinter_boss_active:
		print("Season transition blocked - Fimbulwinter maintains eternal winter!")
		return
	
	if current_season == Season.SUMMER:
		print("=== SEASON TRANSITION: SUMMER → WINTER ===")
		current_season = Season.WINTER
		update_seasons_display()
		
		# Show notification about the season change
		if notification_manager:
			notification_manager.show_notification("Persephone descends to the underworld. Winter falls upon the land.")

func get_current_season() -> Season:
	return current_season

func is_seasons_power_active() -> bool:
	return active_deck_power == DeckDefinition.DeckPowerType.SEASONS_POWER


func start_coerce_mode(coercer_position: int, coercer_owner: Owner, coercer_card: CardResource):
	coerce_mode_active = true
	current_coercer_position = coercer_position
	current_coercer_owner = coercer_owner
	current_coercer_card = coercer_card
	
	print("Starting coerce mode - coercer at position ", coercer_position)
	
	# Only opponent can use coerce, and it targets player's hand
	if coercer_owner == Owner.OPPONENT:
		# Automatically select a random card from player's hand
		opponent_select_coerce_target()
	else:
		print("ERROR: Only opponents should use coerce ability")
		coerce_mode_active = false

func opponent_select_coerce_target():
	if not coerce_mode_active:
		return
	
	# Simple AI: pick a random card from player's hand
	if player_deck.size() == 0:
		print("Player has no cards to coerce!")
		coerce_mode_active = false
		return
	
	var target_card_index = randi() % player_deck.size()
	select_coerce_target(target_card_index)

func select_coerce_target(card_index: int):
	if card_index < 0 or card_index >= player_deck.size():
		print("Invalid coerce target card index: ", card_index)
		return
	
	active_coerced_card_index = card_index
	var coerced_card = player_deck[card_index]
	
	print("Coerce target selected: ", coerced_card.card_name, " (index ", card_index, ")")
	
	# Apply visual styling to the coerced card
	apply_coerced_card_styling(card_index)
	
	# Update game status
	game_status_label.text = "Coerce Effect Active! You must play: " + coerced_card.card_name + " next turn."
	
	# End coerce selection phase
	coerce_mode_active = false
	
	print("Coerce effect applied - player must play card index ", card_index)

func apply_coerced_card_styling(card_index: int):
	if card_index < 0 or card_index >= player_deck.size():
		return
	
	# Find the card display in the hand
	var cards_container = hand_container.get_node_or_null("CardsContainer")
	if not cards_container:
		print("No cards container found for coerced styling")
		return
	
	# Apply styling to the specific card
	var children = cards_container.get_children()
	if card_index < children.size():
		var card_display = children[card_index]
		if card_display and card_display.has_method("apply_special_style"):
			card_display.apply_special_style(coerced_card_style)
		elif card_display and card_display.get_node_or_null("Panel"):
			card_display.get_node("Panel").add_theme_stylebox_override("panel", coerced_card_style)
		
		print("Applied coerced card styling (purple border) to card index ", card_index)

func remove_coerce_constraint():
	if active_coerced_card_index == -1:
		return
	
	print("Removing coerce constraint from card index ", active_coerced_card_index)
	
	# Remove visual styling from the previously coerced card
	restore_card_original_styling(active_coerced_card_index)
	
	# Clear tracking
	active_coerced_card_index = -1

func restore_card_original_styling(card_index: int):
	if card_index < 0:
		return
	
	var cards_container = hand_container.get_node_or_null("CardsContainer")
	if not cards_container:
		return
	
	var children = cards_container.get_children()
	if card_index < children.size():
		var card_display = children[card_index]
		if card_display and card_display.has_method("restore_default_style"):
			card_display.restore_default_style()
		elif card_display and card_display.get_node_or_null("Panel"):
			# Remove any style override to return to default
			card_display.get_node("Panel").remove_theme_stylebox_override("panel")

# Check if a card can be selected considering coerce constraint
func is_card_selectable(card_index: int) -> bool:
	# If there's an active coerce constraint, only the coerced card can be selected
	if active_coerced_card_index != -1:
		return card_index == active_coerced_card_index
	
	# Otherwise, any card is selectable
	return true

# Clear coerce constraints (for game end or reset)
func clear_all_coerce_constraints():
	if active_coerced_card_index != -1:
		remove_coerce_constraint()
	coerce_mode_active = false
	current_coercer_position = -1
	current_coercer_owner = Owner.NONE
	current_coercer_card = null
	print("All coerce constraints cleared")

func create_coerced_card_style():
	coerced_card_style = StyleBoxFlat.new()
	coerced_card_style.bg_color = Color("#2A1A4A", 0.8)
	coerced_card_style.border_color = Color("#9A4AFF")
	coerced_card_style.border_width_left = 4
	coerced_card_style.border_width_top = 4
	coerced_card_style.border_width_right = 4
	coerced_card_style.border_width_bottom = 4
	coerced_card_style.corner_radius_top_left = 8
	coerced_card_style.corner_radius_top_right = 8
	coerced_card_style.corner_radius_bottom_left = 8
	coerced_card_style.corner_radius_bottom_right = 8

func check_and_remove_coerce_constraint(played_card_index: int):
	if active_coerced_card_index == -1:
		return  # No active coerce constraint
	
	if played_card_index == active_coerced_card_index:
		print("Player played the coerced card - removing coerce constraint")
		remove_coerce_constraint()
		game_status_label.text = "Coerce constraint fulfilled!"
	else:
		print("ERROR: Player tried to play wrong card during coerce!")
		# This should never happen due to selection constraints, but just in case


func start_enrich_mode(enricher_position: int, enricher_owner: Owner, enricher_card: CardResource, enrichment_amount: int):
	enrich_mode_active = true
	current_enricher_position = enricher_position
	current_enricher_owner = enricher_owner
	current_enricher_card = enricher_card
	pending_enrichment_amount = enrichment_amount
	
	# CRITICAL: Allow mouse input to pass through cards on occupied slots during enrich mode
	if enricher_owner == Owner.PLAYER:
		set_cards_mouse_passthrough_for_enrich_mode(true)
	
	# Update game status
	if enricher_owner == Owner.PLAYER:
		if enrichment_amount > 0:
			game_status_label.text = "Choose a slot to enrich (+%d boost to friendly cards)" % enrichment_amount
		else:
			game_status_label.text = "Choose a slot to weaken (%d penalty to friendly cards)" % enrichment_amount
	else:
		game_status_label.text = "Opponent is enriching a slot."
	
	# AI selection for opponent
	if enricher_owner == Owner.OPPONENT:
		call_deferred("opponent_select_enrich_target")

func select_enrich_target(target_slot: int):
	if not enrich_mode_active:
		return
	
	print("Enrich target selected: slot ", target_slot)
	
	# CRITICAL: Restore normal mouse input handling for cards
	if current_enricher_owner == Owner.PLAYER:
		set_cards_mouse_passthrough_for_enrich_mode(false)
	
	# Remove all enrich overlays
	cleanup_enrich_overlays()
	
	# Get the run enrichment tracker
	var enrichment_tracker = get_node_or_null("/root/RunEnrichmentTrackerAutoload")
	if not enrichment_tracker:
		print("EnrichAbility: RunEnrichmentTrackerAutoload not found!")
		return
	
	# Apply enrichment to the selected slot
	enrichment_tracker.add_slot_enrichment(target_slot, pending_enrichment_amount)
	
	# Update slot visual to show enrichment level
	update_slot_enrichment_display(target_slot)
	
	# ISSUE #1 FIX: Apply enrichment bonus to any card already in the slot
	if grid_occupied[target_slot] and grid_ownership[target_slot] == Owner.PLAYER:
		var card_in_slot = grid_card_data[target_slot]
		if card_in_slot:
			print("Applying immediate enrichment bonus to existing card in slot ", target_slot)
			apply_enrichment_bonus_to_existing_card(target_slot, card_in_slot, pending_enrichment_amount)
	
	# Clear enrich mode
	enrich_mode_active = false
	current_enricher_position = -1
	current_enricher_owner = Owner.NONE
	current_enricher_card = null
	pending_enrichment_amount = 1
	
	# Update game status
	if pending_enrichment_amount > 0:
		game_status_label.text = "Slot enriched! Friendly cards in that slot get +%d to all stats." % pending_enrichment_amount
	else:
		game_status_label.text = "Slot weakened! Friendly cards in that slot get %d to all stats." % pending_enrichment_amount
	
	# Switch turns - enrich action completes the turn
	print("Enrich target selected - switching turns")
	turn_manager.next_turn()

func set_cards_mouse_passthrough_for_enrich_mode(enable_passthrough: bool):
	"""
	During enrich mode, we need to allow mouse input to pass through cards on occupied slots
	so that the underlying grid slots can receive mouse events for selection.
	"""
	print("Setting cards mouse passthrough for enrich mode: ", enable_passthrough)
	
	for i in range(grid_slots.size()):
		if grid_occupied[i]:
			var slot = grid_slots[i]
			# Find the card display in the slot
			for child in slot.get_children():
				if child is CardDisplay and child.panel:
					if enable_passthrough:
						# Allow mouse input to pass through the card to the slot underneath
						child.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
						print("Set card at slot ", i, " to MOUSE_FILTER_IGNORE for enrich mode")
					else:
						# Restore normal mouse input handling
						child.panel.mouse_filter = Control.MOUSE_FILTER_PASS
						print("Restored card at slot ", i, " to MOUSE_FILTER_PASS after enrich mode")

func opponent_select_enrich_target():
	if not enrich_mode_active:
		return
	
	# Simple AI: pick a random slot (enrichment can target any slot)
	var target_position = randi() % grid_slots.size()
	
	select_enrich_target(target_position)

func update_slot_enrichment_display(slot_index: int):
	if slot_index < 0 or slot_index >= grid_slots.size():
		return
	
	var enrichment_tracker = get_node_or_null("/root/RunEnrichmentTrackerAutoload")
	if not enrichment_tracker:
		return
	
	var enrichment_level = enrichment_tracker.get_slot_enrichment(slot_index)
	var slot = grid_slots[slot_index]
	
	# Find or create enrichment label
	var enrichment_label = slot.get_node_or_null("EnrichmentLabel")
	if not enrichment_label:
		enrichment_label = Label.new()
		enrichment_label.name = "EnrichmentLabel"
		enrichment_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		enrichment_label.anchor_left = 1.0
		enrichment_label.anchor_top = 0.0
		enrichment_label.anchor_right = 1.0
		enrichment_label.anchor_bottom = 0.0
		enrichment_label.offset_left = -30
		enrichment_label.offset_top = 5
		enrichment_label.offset_right = -5
		enrichment_label.offset_bottom = 25
		enrichment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enrichment_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		enrichment_label.add_theme_color_override("font_color", Color.WHITE)
		enrichment_label.add_theme_font_size_override("font_size", 12)
		slot.add_child(enrichment_label)
	
	# Update label text
	if enrichment_level > 0:
		enrichment_label.text = "x" + str(enrichment_level)
		enrichment_label.visible = true
	elif enrichment_level < 0:
		enrichment_label.text = "x" + str(enrichment_level)
		enrichment_label.visible = true
	else:
		enrichment_label.text = ""
		enrichment_label.visible = false

func apply_enrichment_bonus_if_applicable(grid_position: int, card_data: CardResource, placing_owner: Owner):
	print("=== ENRICHMENT BONUS CHECK ===")
	print("Grid position: ", grid_position)
	print("Placing owner: ", placing_owner)
	
	# Only apply enrichment bonus to player-owned cards
	if placing_owner != Owner.PLAYER:
		print("Enrichment bonus only applies to player cards")
		return
	
	# Get the run enrichment tracker
	var enrichment_tracker = get_node_or_null("/root/RunEnrichmentTrackerAutoload")
	if not enrichment_tracker:
		print("RunEnrichmentTrackerAutoload not found!")
		return
	
	var enrichment_level = enrichment_tracker.get_slot_enrichment(grid_position)
	
	if enrichment_level != 0:
		print("Applying enrichment bonus: +", enrichment_level, " to all stats")
		
		# Apply enrichment bonus to all directions
		card_data.values[0] += enrichment_level  # North
		card_data.values[1] += enrichment_level  # East
		card_data.values[2] += enrichment_level  # South
		card_data.values[3] += enrichment_level  # West
		
		print("Card stats after enrichment: ", card_data.values)
		
		# Update visual display
		update_card_display(grid_position, card_data)
	else:
		print("No enrichment on this slot")

func clear_all_enrich_effects():
	enrich_mode_active = false
	current_enricher_position = -1
	current_enricher_owner = Owner.NONE
	current_enricher_card = null
	pending_enrichment_amount = 1
	print("All enrich effects cleared")

func initialize_enrichment_displays():
	# Initialize enrichment displays for all slots at start of battle
	var enrichment_tracker = get_node_or_null("/root/RunEnrichmentTrackerAutoload")
	if not enrichment_tracker:
		return
	
	for i in range(grid_slots.size()):
		update_slot_enrichment_display(i)


func add_enrich_card_overlay(slot: Panel):
	# Remove any existing overlay first to prevent stacking
	remove_enrich_card_overlay(slot)
	
	# Create a bright overlay to show the card is selectable during enrich mode
	var overlay = ColorRect.new()
	overlay.name = "EnrichSelectionOverlay"
	overlay.color = Color("#00FF44", 0.3)  # Semi-transparent green
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100  # High z_index to appear above the card
	
	slot.add_child(overlay)

# NEW FUNCTION:
func remove_enrich_card_overlay(slot: Panel):
	var overlay = slot.get_node_or_null("EnrichSelectionOverlay")
	if overlay:
		overlay.queue_free()

func apply_enrichment_bonus_to_existing_card(grid_position: int, card_data: CardResource, enrichment_amount: int):
	"""
	Apply enrichment bonus to a card that's already placed in a slot when that slot gets enriched.
	This is different from the normal apply_enrichment_bonus_if_applicable which only works during placement.
	"""
	print("=== IMMEDIATE ENRICHMENT BONUS ===")
	print("Grid position: ", grid_position)
	print("Enrichment amount: ", enrichment_amount)
	print("Card stats before: ", card_data.values)
	
	# Apply enrichment bonus to all directions
	card_data.values[0] += enrichment_amount  # North
	card_data.values[1] += enrichment_amount  # East
	card_data.values[2] += enrichment_amount  # South
	card_data.values[3] += enrichment_amount  # West
	
	print("Card stats after enrichment: ", card_data.values)
	
	# CRITICAL: Update the grid_card_data array so the changes persist
	grid_card_data[grid_position] = card_data
	
	# FIXED: Find the CardDisplay and update it directly
	var slot = grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = card_data  # Update the card data reference
			child.update_display()       # Refresh the visual display
			print("Updated CardDisplay visual for enriched card")
			break


func cleanup_enrich_overlays():
	"""Remove all enrich selection overlays from the grid"""
	for slot in grid_slots:
		remove_enrich_card_overlay(slot)

# Process greedy abilities at the start of opponent's turn
func process_greedy_turn_start():
	print("Processing greedy abilities for opponent turn start")
	
	# Check all cards on the board for greedy abilities
	for position in range(grid_slots.size()):
		if not grid_occupied[position]:
			continue
		
		# Only process opponent-owned cards
		var card_owner = get_owner_at_position(position)
		if card_owner != Owner.OPPONENT:
			continue
		
		var card_data = get_card_at_position(position)
		if not card_data:
			continue
		
		# Get card level for ability checks
		var card_collection_index = get_card_collection_index(position)
		var card_level = get_card_level(card_collection_index)
		
		# Check if this card has greedy ability
		var has_greedy = false
		var greedy_ability = null
		
		if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			for ability in card_data.get_available_abilities(card_level):
				if ability.ability_name == "Greedy":
					has_greedy = true
					greedy_ability = ability
					break
		
		if not has_greedy or not greedy_ability:
			continue
		
		print("Found greedy card at position ", position, ": ", card_data.card_name)
		
		# Execute greedy turn processing
		var context = {
			"passive_action": "turn_start",
			"boosting_card": card_data,
			"boosting_position": position,
			"game_manager": self,
			"card_level": card_level
		}
		
		greedy_ability.execute(context)


# Process morph abilities at the start of every turn (both player and opponent)
func process_morph_turn_start():
	print("Processing morph abilities for turn start")
	
	# Check all cards on the board for morph abilities
	for position in range(grid_slots.size()):
		if not grid_occupied[position]:
			continue
		
		var card_data = get_card_at_position(position)
		if not card_data:
			continue
		
		# Get card level for ability checks
		var card_collection_index = get_card_collection_index(position)
		var card_level = get_card_level(card_collection_index)
		
		# Check if this card has morph ability
		var has_morph = false
		var morph_ability = null
		
		if card_data.has_ability_type(CardAbility.TriggerType.PASSIVE, card_level):
			for ability in card_data.get_available_abilities(card_level):
				if ability.ability_name == "Morph":
					has_morph = true
					morph_ability = ability
					break
		
		if not has_morph or not morph_ability:
			continue
		
		print("Found morph card at position ", position, ": ", card_data.card_name)
		
		# Execute morph turn processing
		var context = {
			"passive_action": "turn_start",
			"boosting_card": card_data,
			"boosting_position": position,
			"game_manager": self,
			"card_level": card_level
		}
		
		morph_ability.execute(context)


func show_opponent_hand_modal():
	"""Show the opponent's hand modal for the Prophetic ability"""
	if opponent_hand_modal:
		print("Opponent hand modal already open - skipping")
		return
	
	# Pause game interactions
	game_paused_for_modal = true
	disable_player_input()
	
	print("Creating opponent hand modal...")
	
	# Create the modal from the scene file (not the script!)
	var modal_scene = preload("res://Scenes/OpponentHandModal.tscn")
	opponent_hand_modal = modal_scene.instantiate()
	
	# Add it to the scene tree at a high layer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Very high layer to be on top of everything
	canvas_layer.name = "PropheticModalLayer"
	add_child(canvas_layer)
	canvas_layer.add_child(opponent_hand_modal)
	
	# Connect the modal closed signal
	opponent_hand_modal.modal_closed.connect(_on_opponent_hand_modal_closed)
	
	# Get the opponent's current hand
	var opponent_cards = opponent_manager.opponent_deck.duplicate()
	
	print("Showing ", opponent_cards.size(), " opponent cards in modal")
	
	# Display the opponent's hand
	opponent_hand_modal.display_opponent_hand(opponent_cards)

func _on_opponent_hand_modal_closed():
	"""Handle when the prophetic modal is closed"""
	print("Opponent hand modal closed - resuming game")
	
	# Clean up modal reference
	opponent_hand_modal = null
	
	# Remove the canvas layer
	var modal_layer = get_node_or_null("PropheticModalLayer")
	if modal_layer:
		modal_layer.queue_free()
	
	# Resume game
	game_paused_for_modal = false
	
	# Re-enable player input if it's still the player's turn
	if turn_manager.current_player == TurnManager.Player.HUMAN and turn_manager.is_game_active:
		enable_player_input()
	
	# If it's the opponent's turn and they haven't started thinking yet, let them take their turn
	if turn_manager.is_opponent_turn() and not opponent_is_thinking and not is_tutorial_mode:
		print("Modal closed - starting deferred opponent turn")
		call_deferred("opponent_take_turn")
	
	print("Game resumed after prophetic vision")


func start_race_mode(racer_position: int, racer_owner: Owner, racer_card: CardResource):
	race_mode_active = true
	current_racer_position = racer_position
	current_racer_owner = racer_owner
	current_racer_card = racer_card
	
	# Update game status
	if racer_owner == Owner.PLAYER:
		game_status_label.text = "🏃 RACING: " + racer_card.card_name + " is racing through empty slots..."
	else:
		game_status_label.text = "🏃 " + opponent_manager.get_opponent_info().name + "'s " + racer_card.card_name + " is racing..."
	
	print("Race mode activated for ", racer_card.card_name, " at position ", racer_position)
	
	# Execute the race sequence
	call_deferred("execute_race_sequence", racer_position, racer_card, racer_owner)

func execute_race_sequence(starting_position: int, racing_card: CardResource, racing_owner: Owner):
	"""Execute the race through all empty slots with movement and combat"""
	
	# Find all empty slots in numerical order
	var empty_slots = find_empty_slots_in_order()
	
	if empty_slots.is_empty():
		print("RaceAbility: No empty slots found to race to")
		complete_race()
		return
	
	var current_position = starting_position
	var movements_made = 0
	
	print("RaceAbility: Starting race sequence from position ", starting_position)
	print("RaceAbility: Found ", empty_slots.size(), " empty slots to race through")
	
	# Race through each empty slot that comes AFTER the starting position
	for target_slot in empty_slots:
		# Skip the starting position and any slots before it (no backtracking)
		if target_slot <= starting_position:
			continue
		
		print("RaceAbility: Moving from slot ", current_position, " to slot ", target_slot)
		
		# Reduce power by 1 for each movement
		reduce_card_power_for_race(racing_card, 1)
		movements_made += 1
		print("RaceAbility: Card power reduced by 1 after ", movements_made, " movements")
		
		# Move the card with proper visual updates
		execute_race_move(current_position, target_slot, racing_card, racing_owner)
		current_position = target_slot
		
		# Update the visual display with new stats
		update_card_display(current_position, racing_card)
		
		# Resolve combat at this position
		var captures = resolve_combat(current_position, racing_owner, racing_card)
		if captures > 0:
			print("RaceAbility: Captured ", captures, " cards at position ", current_position)
		
		# Add delay between movements
		await get_tree().create_timer(0.5).timeout
	
	print("RaceAbility: Race completed! Final position: ", current_position, " after ", movements_made, " movements")
	
	# Complete the race and switch turns
	complete_race()

# Replace the execute_race_move function (around lines 2890-2930)
func execute_race_move(from_position: int, to_position: int, racing_card: CardResource, racing_owner: Owner):
	"""Move the racing card from one position to another with proper visual updates"""
	
	print("Executing race move from position ", from_position, " to position ", to_position)
	
	# Get card collection info before clearing original position
	var card_collection_index = grid_to_collection_index.get(from_position, -1)
	var card_level = get_card_level(card_collection_index) if card_collection_index != -1 else 1
	
	# FIXED: Store reference to the existing card display before clearing
	var existing_card_display = null
	var from_slot = grid_slots[from_position]
	for child in from_slot.get_children():
		if child is CardDisplay:
			existing_card_display = child
			break
	
	# FIXED: Clear the original position without using clear_grid_slot to avoid freeing the card display
	grid_occupied[from_position] = false
	grid_ownership[from_position] = Owner.NONE
	grid_card_data[from_position] = null
	
	# Clear passive abilities for this position
	if from_position in active_passive_abilities:
		active_passive_abilities.erase(from_position)
	
	# FIXED: Move the existing card display instead of creating a new one
	if existing_card_display and is_instance_valid(existing_card_display):
		# Remove from old slot
		from_slot.remove_child(existing_card_display)
		
		# Add to new slot
		var to_slot = grid_slots[to_position]
		to_slot.add_child(existing_card_display)
		
		# Update the card display with current data (in case stats changed)
		existing_card_display.setup(racing_card, card_level, current_god, card_collection_index)
	else:
		# Fallback: create new card display if the old one was somehow invalid
		var slot = grid_slots[to_position]
		var card_display_scene = preload("res://Scenes/CardDisplay.tscn")
		var card_display = card_display_scene.instantiate()
		card_display.setup(racing_card, card_level, current_god, card_collection_index)
		slot.add_child(card_display)
	
	# Place the card at the new position
	grid_occupied[to_position] = true
	grid_ownership[to_position] = racing_owner
	grid_card_data[to_position] = racing_card
	
	# Update grid to collection mapping for the new position
	if card_collection_index != -1:
		grid_to_collection_index[to_position] = card_collection_index
		grid_to_collection_index.erase(from_position)
	
	# Apply styling to target slot
	var to_slot = grid_slots[to_position]
	if racing_owner == Owner.PLAYER:
		to_slot.add_theme_stylebox_override("panel", player_card_style)
	else:
		to_slot.add_theme_stylebox_override("panel", opponent_card_style)
	
	# Clear styling from source slot (reset to default)
	from_slot.add_theme_stylebox_override("panel", default_grid_style)
	
	# Execute placement effects at new location (like ordain bonus)
	if racing_owner == Owner.PLAYER:
		apply_ordain_bonus_if_applicable(to_position, racing_card, racing_owner)
	
	# Handle passive abilities at new position
	handle_passive_abilities_on_place(to_position, racing_card, card_level)
	
	# Check for couple union at new position
	check_for_couple_union(racing_card, to_position)
	
	print("Race move completed from slot ", from_position, " to slot ", to_position)

func find_empty_slots_in_order() -> Array[int]:
	"""Find all empty slots in numerical order (0, 1, 2, 3, 4, 5, 6, 7, 8)"""
	var empty_slots: Array[int] = []
	
	# Check all 9 grid positions in order
	for i in range(9):
		if not grid_occupied[i]:
			empty_slots.append(i)
	
	return empty_slots

func reduce_card_power_for_race(card_data: CardResource, reduction_amount: int):
	"""Reduce all directional stats by the specified amount"""
	for i in range(card_data.values.size()):
		card_data.values[i] = max(0, card_data.values[i] - reduction_amount)
	
	print("RaceAbility: Reduced card stats by ", reduction_amount, ". New values: ", card_data.values)

func complete_race():
	"""Complete the race sequence and switch turns"""
	
	# End race mode
	race_mode_active = false
	current_racer_position = -1
	current_racer_owner = Owner.NONE
	current_racer_card = null
	
	# Update displays
	update_game_status()
	
	# Check if game should end
	if should_game_end():
		end_game()
		return
	
	# Switch turns after race is complete
	print("Race complete - switching turns")
	turn_manager.next_turn()

func clear_all_race_constraints():
	if race_mode_active:
		race_mode_active = false
		current_racer_position = -1
		current_racer_owner = Owner.NONE
		current_racer_card = null
		print("All race constraints cleared")


func start_camouflage_mode(camouflage_position: int, camouflage_owner: Owner, camouflage_card: CardResource):
	"""Start camouflage effect for a card at the specified position"""
	print("Camouflage mode activated for ", camouflage_card.card_name, " at position ", camouflage_position)
	
	# Store camouflage data
	active_camouflage_slots[camouflage_position] = {
		"card": camouflage_card,
		"owner": camouflage_owner,
		"turns_remaining": 2  # Lasts one turn (opponent's next turn)
	}
	
	# Hide the card visually
	var card_display = get_card_display_at_position(camouflage_position)
	if card_display:
		hide_camouflaged_card(card_display)
	
	print("Card camouflaged! Hidden for 1 turn at position ", camouflage_position)

func check_camouflage_capture(target_slot: int, placing_owner: Owner) -> bool:
	"""Check if placing a card triggers camouflage capture"""
	if target_slot not in active_camouflage_slots:
		return false
	
	var camouflage_data = active_camouflage_slots[target_slot]
	var camouflaged_owner = camouflage_data["owner"]
	
	# Only trigger if opponent is trying to place in the camouflaged slot
	if placing_owner != camouflaged_owner:
		print("CAMOUFLAGE TRIGGERED! Opponent tried to place in camouflaged slot ", target_slot)
		execute_camouflage_capture(target_slot, placing_owner)
		return true
	
	return false

func execute_camouflage_capture(camouflage_slot: int, captured_owner: Owner):
	"""Execute the camouflage capture sequence"""
	var camouflage_data = active_camouflage_slots[camouflage_slot]
	var camouflaged_card = camouflage_data["card"]
	var camouflaged_owner = camouflage_data["owner"]
	
	print("Executing camouflage capture at slot ", camouflage_slot)
	
	# Get the attacking card data that needs to be captured
	var attacking_card_data = null
	var attacking_card_level = 1
	
	if captured_owner == Owner.PLAYER:
		if selected_card_index >= 0 and selected_card_index < player_deck.size():
			attacking_card_data = player_deck[selected_card_index].duplicate(true)
			attacking_card_level = get_card_level(selected_card_index)
	else:
		attacking_card_data = opponent_manager.get_last_played_card()
		if attacking_card_data:
			attacking_card_data = attacking_card_data.duplicate(true)
			attacking_card_level = get_card_level(0)
	
	if not attacking_card_data:
		print("ERROR: Could not get attacking card data for camouflage capture!")
		return
	
	# SIMPLE FIX: Clear the slot completely first (removes camouflaged card display)
	var slot = grid_slots[camouflage_slot]
	for child in slot.get_children():
		child.queue_free()
	
	# Update grid data for the captured card (owned by camouflage owner)
	grid_occupied[camouflage_slot] = true
	grid_ownership[camouflage_slot] = camouflaged_owner
	grid_card_data[camouflage_slot] = attacking_card_data
	
	# Create new card display for the captured card
	var captured_card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
	slot.add_child(captured_card_display)
	captured_card_display.setup(attacking_card_data, attacking_card_level, current_god, 0, camouflaged_owner == Owner.OPPONENT)
	
	# Apply correct styling
	if camouflaged_owner == Owner.PLAYER:
		captured_card_display.panel.add_theme_stylebox_override("panel", player_card_style)
	else:
		captured_card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
	
	# Find next available slot for the camouflaged card
	var next_slot = find_next_available_slot(camouflage_slot)
	
	if next_slot != -1:
		# Place camouflaged card in next available slot (no longer hidden)
		grid_occupied[next_slot] = true
		grid_ownership[next_slot] = camouflaged_owner
		grid_card_data[next_slot] = camouflaged_card
		
		var next_slot_container = grid_slots[next_slot]
		var camouflaged_card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
		next_slot_container.add_child(camouflaged_card_display)
		camouflaged_card_display.setup(camouflaged_card, 1, current_god, 0, camouflaged_owner == Owner.OPPONENT)
		
		# Apply correct styling to revealed camouflaged card
		if camouflaged_owner == Owner.PLAYER:
			camouflaged_card_display.panel.add_theme_stylebox_override("panel", player_card_style)
		else:
			camouflaged_card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
	
	# Remove camouflage effect
	active_camouflage_slots.erase(camouflage_slot)
	
	# Update game status
	var owner_name = "Player" if camouflaged_owner == Owner.PLAYER else "Opponent"
	var captured_name = "Player" if captured_owner == Owner.PLAYER else "Opponent"
	game_status_label.text = "🎭 CAMOUFLAGE ACTIVATED! " + owner_name + "'s card captured " + captured_name + "'s card!"

func _setup_captured_card_display(card_display: CardDisplay, card_data: CardResource, card_level: int, is_opponent_card: bool, slot_index: int):
	"""Helper function to set up a captured card display after it's been added to the scene"""
	if not card_display or not card_display.panel:
		print("ERROR: Card display or panel is null in _setup_captured_card_display")
		return
	
	# Setup the captured card display
	card_display.setup(card_data, card_level, current_god, 0, is_opponent_card)
	
	# Apply correct ownership styling to the captured card
	if not is_opponent_card:
		card_display.panel.add_theme_stylebox_override("panel", player_card_style)
	else:
		card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
	
	# Connect hover and input signals for the captured card
	card_display.card_hovered.connect(_on_card_hovered)
	card_display.card_unhovered.connect(_on_card_unhovered)
	if card_display.panel:
		card_display.panel.gui_input.connect(_on_grid_card_right_click.bind(slot_index))
	
	print("Captured card display setup complete for slot ", slot_index)

func _check_game_end_after_camouflage():
	"""Check if game should end after camouflage sequence completes"""
	print("Checking if game should end after camouflage sequence...")
	
	if should_game_end():
		print("Game should end after camouflage - triggering end_game()")
		end_game()
	else:
		print("Game continues after camouflage sequence")



func find_next_available_slot(starting_slot: int) -> int:
	"""Find the next numerically available slot after the starting slot"""
	# Start searching from the slot after the current one
	for i in range(starting_slot + 1, grid_slots.size()):
		if not grid_occupied[i]:
			return i
	
	# If no slot found after starting_slot, search from beginning
	for i in range(0, starting_slot):
		if not grid_occupied[i]:
			return i
	
	return -1  # No available slots

func move_camouflaged_card(from_slot: int, to_slot: int, card: CardResource, card_owner: Owner):
	"""Move a camouflaged card from one slot to another and reveal it"""
	print("Moving camouflaged card from slot ", from_slot, " to slot ", to_slot)
	
	# Get the card display from the original slot
	var card_display = get_card_display_at_position(from_slot)
	
	# Update data structures - clear source
	grid_occupied[from_slot] = false
	grid_ownership[from_slot] = Owner.NONE
	grid_card_data[from_slot] = null
	
	# Update data structures - set destination
	grid_occupied[to_slot] = true
	grid_ownership[to_slot] = card_owner
	grid_card_data[to_slot] = card
	
	# Move collection index mapping if it exists
	if from_slot in grid_to_collection_index:
		var collection_index = grid_to_collection_index[from_slot]
		grid_to_collection_index.erase(from_slot)
		grid_to_collection_index[to_slot] = collection_index
	
	# Move the visual display
	if card_display:
		var source_slot = grid_slots[from_slot]
		var target_slot = grid_slots[to_slot]
		
		# Remove from source slot
		source_slot.remove_child(card_display)
		
		# Add to target slot
		target_slot.add_child(card_display)
		
		# Reveal the card (remove any camouflage visual effects)
		reveal_camouflaged_card(card_display)
	
	print("Camouflaged card moved and revealed at slot ", to_slot)

func reveal_camouflaged_card(card_display: CardDisplay):
	"""Reveal a camouflaged card (remove visual hiding effects)"""
	# Validate the card display still exists and is valid
	if not is_instance_valid(card_display):
		print("reveal_camouflaged_card: Card display is no longer valid")
		return
	
	if not card_display.panel:
		print("reveal_camouflaged_card: Card display panel is null")
		return
	
	# Check if panel is still valid (not freed)
	if not is_instance_valid(card_display.panel):
		print("reveal_camouflaged_card: Card display panel has been freed")
		return
	
	# Restore full opacity
	card_display.modulate = Color(1, 1, 1, 1)
	
	# CRITICAL FIX: Restore normal mouse input handling
	card_display.panel.mouse_filter = Control.MOUSE_FILTER_PASS
	print("Restored camouflaged card mouse_filter to PASS")
	
	# Restore normal ownership styling
	var grid_position = -1
	for i in range(grid_slots.size()):
		if get_card_display_at_position(i) == card_display:
			grid_position = i
			break
	
	if grid_position != -1:
		var owner = grid_ownership[grid_position]
		if owner == Owner.PLAYER:
			card_display.panel.add_theme_stylebox_override("panel", player_card_style)
		else:
			card_display.panel.add_theme_stylebox_override("panel", opponent_card_style)
	
	print("Revealed camouflaged card: ", card_display.get_card_data().card_name if card_display.get_card_data() else "Unknown")

func process_camouflage_turn_end():
	"""Process camouflage effects at the end of each turn"""
	var slots_to_reveal = []
	
	# Check all active camouflage slots
	for slot in active_camouflage_slots.keys():
		var camouflage_data = active_camouflage_slots[slot]
		camouflage_data["turns_remaining"] -= 1
		
		if camouflage_data["turns_remaining"] <= 0:
			slots_to_reveal.append(slot)
	
	# Reveal cards whose camouflage has expired
	for slot in slots_to_reveal:
		reveal_camouflage_effect(slot)

func reveal_camouflage_effect(slot: int):
	"""Reveal a camouflaged card when its duration expires"""
	if slot not in active_camouflage_slots:
		return
	
	var camouflage_data = active_camouflage_slots[slot]
	var card = camouflage_data["card"]
	
	print("Camouflage expired - revealing card at slot ", slot, ": ", card.card_name)
	
	# Get the card display and reveal it
	var card_display = get_card_display_at_position(slot)
	if card_display:
		reveal_camouflaged_card(card_display)
	
	# Remove from active camouflage tracking
	active_camouflage_slots.erase(slot)

func is_slot_camouflaged(slot: int) -> bool:
	"""Check if a slot contains a camouflaged card"""
	return slot in active_camouflage_slots

func clear_all_camouflage_effects():
	"""Clear all camouflage effects (for game end or reset)"""
	for slot in active_camouflage_slots.keys():
		reveal_camouflage_effect(slot)
	active_camouflage_slots.clear()
	print("All camouflage effects cleared")


func hide_camouflaged_card(card_display: CardDisplay):
	"""Hide a camouflaged card visually"""
	print("=== HIDE CAMOUFLAGED CARD DEBUG ===")
	print("Card display exists: ", card_display != null)
	print("Card display panel exists: ", card_display.panel != null if card_display else "N/A")
	
	if card_display and card_display.panel:
		print("BEFORE hiding - card modulate: ", card_display.modulate)
		print("BEFORE hiding - panel style override exists: ", card_display.panel.has_theme_stylebox_override("panel"))
		
		# Make the card completely transparent
		card_display.modulate = Color(1, 1, 1, 0)
		
		# CRITICAL FIX: Allow mouse input to pass through the camouflaged card
		# so clicks can reach the underlying grid slot
		card_display.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Set camouflaged card mouse_filter to IGNORE")
		
		# Remove any ownership styling to make the slot appear empty
		card_display.panel.remove_theme_stylebox_override("panel")
		
		print("AFTER hiding - card modulate: ", card_display.modulate)
		print("AFTER hiding - mouse_filter: ", card_display.panel.mouse_filter)
	
	print("Card successfully camouflaged and mouse input set to pass through")


func create_battle_snapshot():
	print("=== CREATING BATTLE SNAPSHOT ===")
	
	battle_snapshot = {
		"experience_data": {},
		"stat_growth_data": {},
		"deck_power_state": {},
		"enemy_deck_power_state": {},
		"player_deck": [],
		"deck_card_indices": [],
		"god_name": current_god,
		"deck_index": selected_deck_index,
		"battle_params": get_scene_params(),
		"coordinate_used": coordinate_used,
		"is_coordination_active": is_coordination_active,
		"rhythm_slot": rhythm_slot,
		"rhythm_boost_value": rhythm_boost_value
	}
	
	# Snapshot experience tracker state
	var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	if exp_tracker:
		battle_snapshot["experience_data"] = exp_tracker.get_all_experience().duplicate(true)
		print("Snapshotted experience data: ", battle_snapshot["experience_data"])
	
	# Snapshot stat growth tracker state  
	var growth_tracker = get_node_or_null("/root/RunStatGrowthTrackerAutoload")
	if growth_tracker:
		battle_snapshot["stat_growth_data"] = growth_tracker.run_stat_growth.duplicate()
		print("Snapshotted stat growth data: ", battle_snapshot["stat_growth_data"])
	
	# Snapshot deck power state
	battle_snapshot["deck_power_state"] = {
		"active_deck_power": active_deck_power,
		"misdirection_used": misdirection_used,
		"sunlit_positions": sunlit_positions.duplicate() if sunlit_positions else [],
		"darkness_shroud_active": darkness_shroud_active,
		"discordant_active": discordant_active,
		"soothe_active": soothe_active,
		"visual_stat_inversion_active": visual_stat_inversion_active,
		"is_hermes_boss_battle": is_hermes_boss_battle,
		"fimbulwinter_boss_active": fimbulwinter_boss_active,
		"coordinate_used": coordinate_used,
		"is_coordination_active": is_coordination_active,
		"is_artemis_boss_battle": is_artemis_boss_battle,
		"artemis_boss_counter_triggered": artemis_boss_counter_triggered  
	}
	
	# Snapshot enemy deck power state
	battle_snapshot["enemy_deck_power_state"] = {
		"active_enemy_deck_power": active_enemy_deck_power
	}
	
	# Snapshot player deck (deep copy the card resources)
	battle_snapshot["player_deck"] = []
	for card in player_deck:
		if card:
			var card_copy = card.duplicate()
			battle_snapshot["player_deck"].append(card_copy)
		else:
			battle_snapshot["player_deck"].append(null)
	
	# Snapshot deck card indices
	battle_snapshot["deck_card_indices"] = deck_card_indices.duplicate()
	
	# NOTE: No opponent deck snapshot needed - we just reload from definition
	# The opponent always has the same deck, so we don't need to snapshot it
	
	print("Battle snapshot created successfully with ", battle_snapshot.keys().size(), " data categories")
	
	
	
func restore_battle_from_snapshot() -> bool:
	print("=== RESTORING BATTLE FROM SNAPSHOT ===")
	
	if battle_snapshot.is_empty():
		print("ERROR: No battle snapshot available!")
		return false
	
	# Clear all visual effects first
	if visual_effects_manager:
		visual_effects_manager.clear_all_tremor_shake_effects(grid_slots)
		visual_effects_manager.clear_all_hunt_effects(grid_slots)
	
	# Clear all special game state
	clear_all_hunt_traps()
	active_passive_abilities.clear()
	active_tremors.clear()
	grid_to_collection_index.clear()
	clear_all_sanctuary_effects()
	clear_all_coerce_constraints()
	clear_all_camouflage_effects()
	clear_cloak_of_night_ability()
	
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
	
	# Wait for cleanup to complete - NO AWAIT HERE since this is not async
	# await get_tree().process_frame  # REMOVE THIS LINE
	
	# Restore experience tracker state
	var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	if exp_tracker and battle_snapshot.has("experience_data"):
		exp_tracker.run_experience = battle_snapshot["experience_data"].duplicate(true)
		exp_tracker.current_deck_indices = battle_snapshot["deck_card_indices"].duplicate()
		print("Restored experience tracker to snapshot state")
	
	# Restore stat growth tracker state
	var growth_tracker = get_node_or_null("/root/RunStatGrowthTrackerAutoload")
	if growth_tracker and battle_snapshot.has("stat_growth_data"):
		growth_tracker.run_stat_growth = battle_snapshot["stat_growth_data"].duplicate()
		growth_tracker.current_deck_indices = battle_snapshot["deck_card_indices"].duplicate()
		print("Restored stat growth tracker to snapshot state")
	
	
	# Restore deck power state
	if battle_snapshot.has("deck_power_state"):
		var deck_power_state = battle_snapshot["deck_power_state"]
		active_deck_power = deck_power_state.get("active_deck_power", DeckDefinition.DeckPowerType.NONE)
		misdirection_used = deck_power_state.get("misdirection_used", false)
		var restored_sunlit = deck_power_state.get("sunlit_positions", [])
		sunlit_positions.clear()
		for pos in restored_sunlit:
			sunlit_positions.append(pos)
		darkness_shroud_active = deck_power_state.get("darkness_shroud_active", false)
		discordant_active = deck_power_state.get("discordant_active", false)
		soothe_active = deck_power_state.get("soothe_active", false)
		visual_stat_inversion_active = deck_power_state.get("visual_stat_inversion_active", false)
		is_hermes_boss_battle = deck_power_state.get("is_hermes_boss_battle", false)
		fimbulwinter_boss_active = deck_power_state.get("fimbulwinter_boss_active", false)
		coordinate_used = deck_power_state.get("coordinate_used", false)
		is_coordination_active = deck_power_state.get("is_coordination_active", false)
		rhythm_slot = deck_power_state.get("rhythm_slot", -1)
		rhythm_boost_value = deck_power_state.get("rhythm_boost_value", 1)
		is_artemis_boss_battle = deck_power_state.get("is_artemis_boss_battle", false) 
		artemis_boss_counter_triggered = deck_power_state.get("artemis_boss_counter_triggered", false)  
		
		print("Restored deck power state")
	
	# Restore enemy deck power state
	if battle_snapshot.has("enemy_deck_power_state"):
		var enemy_power_state = battle_snapshot["enemy_deck_power_state"]
		active_enemy_deck_power = enemy_power_state.get("active_enemy_deck_power", EnemyDeckDefinition.EnemyDeckPowerType.NONE)
		print("Restored enemy deck power state")
	
	# Restore player deck
	if battle_snapshot.has("player_deck"):
		player_deck = []
		for card_data in battle_snapshot["player_deck"]:
			if card_data:
				player_deck.append(card_data.duplicate())
			else:
				player_deck.append(null)
		print("Restored player deck: ", player_deck.size(), " cards")
	
	# Restore deck card indices
	if battle_snapshot.has("deck_card_indices"):
		deck_card_indices = battle_snapshot["deck_card_indices"].duplicate()
		print("Restored deck card indices: ", deck_card_indices)
	
	# Restore opponent deck - SIMPLIFIED: Just reload from original opponent definition
	restore_opponent_deck_from_snapshot()
	
	# Re-apply visual effects for powers that should be active based on restored state
	reapply_battle_visual_effects()
	
	print("Battle restoration from snapshot completed successfully")
	return true


func reapply_battle_visual_effects():
	print("=== REAPPLYING BATTLE VISUAL EFFECTS ===")
	
	# Re-apply sunlit styling if sun power is active
	if active_deck_power == DeckDefinition.DeckPowerType.SUN_POWER:
		for position in sunlit_positions:
			apply_sunlit_styling(position)
		print("Re-applied sunlit styling to positions: ", sunlit_positions)
	# Re-apply rhythm slot visual if active
	if active_deck_power == DeckDefinition.DeckPowerType.RHYTHM_POWER:
		if rhythm_slot >= 0 and not grid_occupied[rhythm_slot]:
			apply_rhythm_slot_visual(rhythm_slot)
		print("Re-applied rhythm slot visual to position: ", rhythm_slot)
	
	# CRITICAL: Re-apply enemy deck powers that affect player powers
	if active_enemy_deck_power == EnemyDeckDefinition.EnemyDeckPowerType.DARKNESS_SHROUD:
		print("Re-applying Darkness Shroud effect after battle restart")
		setup_darkness_shroud()  # This will counter sun power again
	
	if active_enemy_deck_power == EnemyDeckDefinition.EnemyDeckPowerType.DISCORDANT:
		print("Re-applying Discordant effect after battle restart")
		setup_discordant()  # This will counter rhythm power again
	
	print("Battle visual effects and enemy powers reapplied")

# Clear snapshot when battle ends (win/loss)
func clear_battle_snapshot():
	battle_snapshot.clear()
	print("Battle snapshot cleared")

func restore_opponent_deck_from_snapshot():
	print("Restoring opponent deck from original definition...")
	
	# Re-setup opponent based on current parameters (same as original system)
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
	
	print("Opponent deck restored: ", opponent_manager.get_remaining_cards(), " cards")

func setup_coordinate_power():
	print("Setting up Coordinate power")
	coordinate_used = false
	is_coordination_active = false
	create_coordinate_button()

func create_coordinate_button():
	# Create coordinate button similar to seasons status label
	coordinate_button = Button.new()
	coordinate_button.name = "CoordinateButton"
	coordinate_button.text = "🎯 Coordinate"
	coordinate_button.custom_minimum_size = Vector2(150, 40)
	coordinate_button.add_theme_font_size_override("font_size", 14)
	coordinate_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Position it in the same area as seasons label (around position 10, 100)
	coordinate_button.position = Vector2(10, 100)
	
	# Connect the button signal
	coordinate_button.pressed.connect(_on_coordinate_button_pressed)
	
	# Add to scene
	add_child(coordinate_button)
	
	print("Coordinate button created and added to battle scene")

func _on_coordinate_button_pressed():
	activate_coordinate_power()

func activate_coordinate_power():
	if coordinate_used:
		print("Coordinate power already used this battle")
		if notification_manager:
			notification_manager.show_notification("Coordinate already used this battle")
		return false
	
	if not active_deck_power == DeckDefinition.DeckPowerType.COORDINATE_POWER:
		print("Coordinate power not available for this deck")
		return false
	
	# Can only use during player's turn
	if turn_manager.current_player != TurnManager.Player.HUMAN:
		print("Coordinate can only be used during your turn")
		if notification_manager:
			notification_manager.show_notification("Coordinate can only be used during your turn")
		return false
	
	print("=== COORDINATE POWER ACTIVATED ===")
	coordinate_used = true
	is_coordination_active = true
	
	# Update button appearance
	if coordinate_button:
		coordinate_button.disabled = true
		coordinate_button.modulate = Color(0.5, 0.5, 0.5)
		coordinate_button.text = "🎯 Coordinate (Used)"
	
	# Show notification
	if notification_manager:
		notification_manager.show_notification("🎯 Coordinate activated! You will play twice in a row.")
	
	return true

func show_volley_direction_modal(source_position: int, owner: Owner, card: CardResource):
	"""Show the directional selection modal for the Volley ability"""
	if volley_direction_modal:
		print("Volley direction modal already open - skipping")
		return
	
	# Pause game interactions
	game_paused_for_modal = true
	disable_player_input()
	
	print("Creating volley direction modal...")
	
	# Create the modal from the scene file
	var modal_scene = preload("res://Scenes/VolleyDirectionModal.tscn")
	volley_direction_modal = modal_scene.instantiate()
	
	# Add it to the scene tree at a high layer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "VolleyModalLayer"
	add_child(canvas_layer)
	canvas_layer.add_child(volley_direction_modal)
	
	# Connect the direction selected signal
	volley_direction_modal.direction_selected.connect(_on_volley_direction_selected.bind(source_position, owner, card))
	
	print("Volley direction modal displayed")

func _on_volley_direction_selected(direction: int, source_position: int, owner: Owner, card: CardResource):
	"""Handle when a direction is selected for volley"""
	print("Volley direction selected: ", direction, " for card at position ", source_position)
	
	# Register the volley
	register_volley(source_position, direction, owner, 3)
	
	# Clean up modal reference
	volley_direction_modal = null
	
	# Remove the canvas layer
	var modal_layer = get_node_or_null("VolleyModalLayer")
	if modal_layer:
		modal_layer.queue_free()
	
	# Resume game
	game_paused_for_modal = false
	
	# Re-enable player input if it's still the player's turn
	if turn_manager.current_player == TurnManager.Player.HUMAN and turn_manager.is_game_active:
		enable_player_input()
	
	# If it's the opponent's turn and they haven't started yet, start their turn
	if turn_manager.is_opponent_turn() and not opponent_is_thinking:
		call_deferred("opponent_take_turn")

# ============================================
# Add this function to register volleys
# Can be placed near register_tremors() around line 2070
# ============================================

func register_volley(source_position: int, direction: int, owner: Owner, shots_remaining: int):
	var volley_id = volley_id_counter
	volley_id_counter += 1
	
	active_volleys[volley_id] = {
		"source_position": source_position,
		"direction": direction,  # 0=North, 1=East, 2=South, 3=West
		"owner": owner,
		"shots_remaining": shots_remaining,
		"turn_registered": get_current_turn_number()
	}
	
	print("Volley registered: ID ", volley_id, " from position ", source_position, " direction ", direction, " for ", shots_remaining, " shots")

# ============================================
# Add this function to process volleys at turn start
# Can be placed near process_tremors_for_player() around line 2080
# ============================================

func process_volleys_for_player(player_owner: Owner):
	print("Processing volleys for ", "Player" if player_owner == Owner.PLAYER else "Opponent")
	
	var volleys_to_remove = []
	
	for volley_id in active_volleys:
		var volley_data = active_volleys[volley_id]
		
		# Only process volleys owned by the current player
		if volley_data.owner != player_owner:
			continue
		
		# Check if source card still exists and is owned by the original owner
		var source_position = volley_data.source_position
		if not grid_occupied[source_position] or grid_ownership[source_position] != volley_data.owner:
			print("Volley source card captured/removed - ending volleys for ID ", volley_id)
			volleys_to_remove.append(volley_id)
			continue
		
		# Get the direction name for notification
		var direction_name = get_direction_name_from_index(volley_data.direction)
		var shot_num = 4 - volley_data.shots_remaining
		
		# Show notification
		if notification_manager:
			notification_manager.show_notification("Volley " + str(shot_num) + " of 3 fired " + direction_name)
		
		# Process the volley shot
		process_single_volley(volley_id, volley_data)
		
		# Decrease shots remaining
		volley_data.shots_remaining -= 1
		if volley_data.shots_remaining <= 0:
			print("Volley expired: ID ", volley_id)
			volleys_to_remove.append(volley_id)
	
	# Remove expired volleys
	for volley_id in volleys_to_remove:
		active_volleys.erase(volley_id)

# ============================================
# Add this function to process a single volley shot
# Can be placed after process_volleys_for_player()
# ============================================

func process_single_volley(volley_id: int, volley_data: Dictionary):
	var source_position = volley_data.source_position
	var direction = volley_data.direction
	var volley_owner = volley_data.owner
	
	# Get source card data
	var source_card = grid_card_data[source_position]
	if not source_card:
		print("Warning: Volley source card data missing")
		return
	
	# Get direction deltas
	var dir_info = get_direction_info(direction)
	if not dir_info:
		print("Warning: Invalid volley direction")
		return
	
	# Calculate source position in grid coordinates
	var source_x = source_position % grid_size
	var source_y = source_position / grid_size
	
	# Check slot 1 (adjacent)
	var target1_x = source_x + dir_info.dx
	var target1_y = source_y + dir_info.dy
	var target1_index = -1
	
	if target1_x >= 0 and target1_x < grid_size and target1_y >= 0 and target1_y < grid_size:
		target1_index = target1_y * grid_size + target1_x
	
	# Check slot 2 (2 spaces away)
	var target2_x = source_x + (dir_info.dx * 2)
	var target2_y = source_y + (dir_info.dy * 2)
	var target2_index = -1
	
	if target2_x >= 0 and target2_x < grid_size and target2_y >= 0 and target2_y < grid_size:
		target2_index = target2_y * grid_size + target2_x
	
	# Determine which target to hit
	var target_index = -1
	
	if target1_index != -1 and grid_occupied[target1_index]:
		# Slot 1 has a card - arrow stops here
		target_index = target1_index
	elif target2_index != -1 and grid_occupied[target2_index]:
		# Slot 1 empty, slot 2 has a card
		target_index = target2_index
	else:
		# No targets - miss
		print("Volley missed - no targets in firing line")
		if notification_manager:
			notification_manager.show_notification("Volley missed!")
		return
	
	# We have a target
	var target_owner = grid_ownership[target_index]
	var target_card = grid_card_data[target_index]
	
	# Check if target is an ally
	if target_owner == volley_owner:
		print("Volley hit allied card - no effect")
		if notification_manager:
			notification_manager.show_notification("Arrow blocked by ally")
		return
	
	# Target is an enemy - resolve combat
	print("Volley hitting enemy at position ", target_index)
	
	# Use directional combat
	var attacker_value = source_card.values[dir_info.my_value_index]
	var defender_value = target_card.values[dir_info.their_value_index]
	
	print("Volley combat: Attacker ", attacker_value, " vs Defender ", defender_value)
	
	if attacker_value > defender_value:
		# Capture the target
		print("Volley captured enemy card at position ", target_index)
		
		# Execute capture
		grid_ownership[target_index] = volley_owner
		
		# Show capture visual
		var target_card_display = get_card_display_at_position(target_index)
		if target_card_display and visual_effects_manager:
			visual_effects_manager.show_capture_flash(target_card_display, volley_owner == Owner.PLAYER)
		
		# Award experience for volley capture
		if volley_owner == Owner.PLAYER:
			var source_card_index = get_card_collection_index(source_position)
			if source_card_index != -1:
				var exp_tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
				if exp_tracker:
					exp_tracker.add_capture_exp(source_card_index, 10)
					print("Volley capture awarded 10 exp to card at collection index ", source_card_index)
		
		# Execute ON_CAPTURE abilities
		var target_card_collection_index = get_card_collection_index(target_index)
		var target_card_level = get_card_level(target_card_collection_index)
		
		if target_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, target_card_level):
			var capture_context = {
				"captured_card": target_card,
				"captured_position": target_index,
				"capturing_card": source_card,
				"capturing_position": source_position,
				"game_manager": self,
				"direction": dir_info.name,
				"card_level": target_card_level
			}
			target_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, target_card_level)
		
		# Update UI
		update_board_visuals()
	else:
		print("Volley failed to capture - defender too strong")
		if notification_manager:
			notification_manager.show_notification("Volley deflected!")

# ============================================
# Add this helper function to get direction info
# Can be placed after process_single_volley()
# ============================================

func get_direction_info(direction: int) -> Dictionary:
	# Returns direction delta and value indices for combat
	match direction:
		0:  # North
			return {"dx": 0, "dy": -1, "my_value_index": 0, "their_value_index": 2, "name": "North"}
		1:  # East
			return {"dx": 1, "dy": 0, "my_value_index": 1, "their_value_index": 3, "name": "East"}
		2:  # South
			return {"dx": 0, "dy": 1, "my_value_index": 2, "their_value_index": 0, "name": "South"}
		3:  # West
			return {"dx": -1, "dy": 0, "my_value_index": 3, "their_value_index": 1, "name": "West"}
		_:
			return {}

func setup_rhythm_power():
	print("=== SETTING UP RHYTHM POWER ===")
	
	
	if notification_manager:
		notification_manager.show_notification("🎵 The rhythm guides your moves")

func assign_new_rhythm_slot():
	# Get all empty slots - use explicit typing
	var empty_slots: Array[int] = []
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:
			empty_slots.append(i)
	
	# If no empty slots, rhythm power is inactive for this turn
	if empty_slots.is_empty():
		rhythm_slot = -1
		print("No empty slots available for rhythm slot")
		return
	
	# Randomly select an empty slot - use proper array access
	var random_index = randi() % empty_slots.size()
	rhythm_slot = empty_slots[random_index]
	print("Rhythm slot assigned to position: ", rhythm_slot, " (boost value: +", rhythm_boost_value, ")")
	
	# Apply visual effect to the rhythm slot
	apply_rhythm_slot_visual(rhythm_slot)

func apply_rhythm_slot_visual(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	
	# Create purple/magenta glow style for rhythm
	var rhythm_style = StyleBoxFlat.new()
	rhythm_style.bg_color = Color(0.8, 0.2, 0.8, 0.3)  # Purple/magenta with transparency
	rhythm_style.border_color = Color(1.0, 0.4, 1.0, 0.8)  # Bright magenta border
	rhythm_style.border_width_left = 3
	rhythm_style.border_width_right = 3
	rhythm_style.border_width_top = 3
	rhythm_style.border_width_bottom = 3
	rhythm_style.corner_radius_top_left = 8
	rhythm_style.corner_radius_top_right = 8
	rhythm_style.corner_radius_bottom_left = 8
	rhythm_style.corner_radius_bottom_right = 8
	
	slot.add_theme_stylebox_override("panel", rhythm_style)
	print("Applied rhythm visual effect to slot ", grid_index)

func clear_rhythm_slot_visual(grid_index: int):
	if grid_index < 0 or grid_index >= grid_slots.size():
		return
	
	var slot = grid_slots[grid_index]
	slot.remove_theme_stylebox_override("panel")
	print("Cleared rhythm visual effect from slot ", grid_index)

func apply_rhythm_boost(card_data: CardResource) -> bool:
	if rhythm_slot < 0:
		return false
	
	# Check if Discordant is active - invert the boost
	var effective_boost = rhythm_boost_value
	var boost_emoji = "🎵"
	var boost_text = "+"
	
	if discordant_active:
		effective_boost = -rhythm_boost_value  # Invert to negative
		boost_emoji = "🎭"
		boost_text = ""  # Negative sign is already in the number
		print("🎭 DISCORDANT CORRUPTION! Card receives ", effective_boost, " to all stats (Wrong Note inverts the rhythm)")
	else:
		print("🎵 RHYTHM BOOST ACTIVATED! Card receives +", rhythm_boost_value, " to all stats")
	
	# Apply boost (or penalty) to all directional stats, with floor at 0 for penalties
	if discordant_active:
		# When discordant is active, ensure values don't go below 0
		card_data.values[0] = max(0, card_data.values[0] + effective_boost)  # North
		card_data.values[1] = max(0, card_data.values[1] + effective_boost)  # East
		card_data.values[2] = max(0, card_data.values[2] + effective_boost)  # South
		card_data.values[3] = max(0, card_data.values[3] + effective_boost)  # West
	else:
		# Normal rhythm boost - no floor needed for positive values
		card_data.values[0] += effective_boost  # North
		card_data.values[1] += effective_boost  # East
		card_data.values[2] += effective_boost  # South
		card_data.values[3] += effective_boost  # West
	
	# Double the boost value for next use (magnitude increases regardless of sign)
	rhythm_boost_value *= 2
	print("Rhythm boost magnitude increased to: ", rhythm_boost_value)
	
	# Clear the visual effect from the used slot
	clear_rhythm_slot_visual(rhythm_slot)
	
	# Show notification
	if notification_manager:
		if discordant_active:
			notification_manager.show_notification(boost_emoji + " Discordant strike! Next penalty: " + str(-rhythm_boost_value))
		else:
			notification_manager.show_notification(boost_emoji + " Rhythm unleashed! Next rhythm: +" + str(rhythm_boost_value))
	
	return true


func activate_cloak_of_night_ability():
	print("=== ACTIVATING CLOAK OF NIGHT ABILITY ===")
	cloak_of_night_active = true
	cloak_of_night_turns_remaining = 2  # Lasts for 2 opponent turns
	
	# Hide all currently visible opponent cards
	hide_all_opponent_cards()
	
	# Show notification
	if notification_manager:
		notification_manager.show_notification("🌑 Cloak of Night: Enemy cards are hidden!")
	
	print("Cloak of Night activated - will last for 2 opponent turns")

func hide_all_opponent_cards():
	print("Hiding all opponent cards on the grid")
	hidden_opponent_cards.clear()
	
	for i in range(grid_slots.size()):
		if grid_occupied[i] and grid_ownership[i] == Owner.OPPONENT:
			hide_opponent_card_at_position(i)
			hidden_opponent_cards.append(i)
	
	print("Hidden ", hidden_opponent_cards.size(), " opponent cards")

func hide_opponent_card_at_position(grid_index: int):
	var card_display = get_card_display_at_position(grid_index)
	if not card_display:
		return
	
	# Make the card content invisible but keep a darkened placeholder
	card_display.modulate = Color(0.3, 0.3, 0.3, 1.0)  # Dark gray tint
	
	# Disable hover interactions
	card_display.set_meta("cloaked", true)
	if card_display.panel:
		card_display.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Apply special cloaked styling to the slot
	var slot = grid_slots[grid_index]
	var cloaked_style = StyleBoxFlat.new()
	cloaked_style.bg_color = Color("#1A1A2A")  # Very dark blue
	cloaked_style.border_color = Color("#4A4A6A")  # Slightly lighter border
	cloaked_style.border_width_left = 3
	cloaked_style.border_width_top = 3
	cloaked_style.border_width_right = 3
	cloaked_style.border_width_bottom = 3
	slot.add_theme_stylebox_override("panel", cloaked_style)
	
	print("Hidden opponent card at position ", grid_index)

func reveal_opponent_card_at_position(grid_index: int):
	var card_display = get_card_display_at_position(grid_index)
	if not card_display:
		return
	
	# Restore normal visibility
	card_display.modulate = Color(1, 1, 1, 1)
	
	# Re-enable hover interactions
	card_display.set_meta("cloaked", false)
	if card_display.panel:
		card_display.panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Restore opponent card styling
	var slot = grid_slots[grid_index]
	slot.add_theme_stylebox_override("panel", opponent_card_style)
	
	print("Revealed opponent card at position ", grid_index)

func reveal_all_opponent_cards():
	print("Revealing all opponent cards")
	
	for position in hidden_opponent_cards:
		if grid_occupied[position] and grid_ownership[position] == Owner.OPPONENT:
			reveal_opponent_card_at_position(position)
	
	hidden_opponent_cards.clear()
	print("All opponent cards revealed")

func process_cloak_of_night_turn():
	if not cloak_of_night_active:
		return
	
	# Only count down on opponent turns
	if turn_manager.is_opponent_turn():
		cloak_of_night_turns_remaining -= 1
		print("Cloak of Night turns remaining: ", cloak_of_night_turns_remaining)
		
		if cloak_of_night_turns_remaining <= 0:
			end_cloak_of_night_ability()

func end_cloak_of_night_ability():
	print("=== CLOAK OF NIGHT ENDING ===")
	cloak_of_night_active = false
	cloak_of_night_turns_remaining = 0
	
	# Reveal all hidden cards
	reveal_all_opponent_cards()
	
	# Show notification
	if notification_manager:
		notification_manager.show_notification("The shadows recede...")
	
	print("Cloak of Night effect ended")

func clear_cloak_of_night_ability():
	if cloak_of_night_active:
		end_cloak_of_night_ability()
	cloak_of_night_active = false
	cloak_of_night_turns_remaining = 0
	hidden_opponent_cards.clear()
	print("Cloak of Night ability cleared")


func set_disarray_active(active: bool):
	disarray_active = active
	if active:
		print("Disarray effect activated - next opponent card will attack both friendly and enemy cards")
	else:
		print("Disarray effect deactivated")


func should_apply_exploit(attacking_card: CardResource, attacker_position: int) -> bool:
	if not attacking_card:
		return false
	
	# Get the card level for ability checks
	var card_collection_index = get_card_collection_index(attacker_position)
	var card_level = get_card_level(card_collection_index)
	
	# Check if the card has exploit ability and can still use it
	if attacking_card.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level):
		var abilities = attacking_card.get_available_abilities(card_level)
		for ability in abilities:
			if ability.ability_name == "Exploit":
				return ExploitAbility.can_use_exploit(attacking_card)
	
	return false


func try_second_chance_rescue(captured_index: int, captured_card: CardResource, attacker_pos: int, attacking_card: CardResource, attacking_owner: Owner) -> bool:
	"""
	Attempts to rescue a card using Second Chance ability.
	Returns true if the card was rescued (capture prevented).
	"""
	print("=== TRY_SECOND_CHANCE_RESCUE ===")
	print("Captured card: ", captured_card.card_name if captured_card else "NULL")
	print("Position: ", captured_index)
	
	# Safety checks
	if not captured_card or not is_instance_valid(captured_card):
		print("Second Chance: Invalid card")
		return false
	
	# Get card level
	var card_collection_index = get_card_collection_index(captured_index)
	var card_level = get_card_level(card_collection_index)
	
	# Check if card has Second Chance ability
	if not captured_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, card_level):
		print("Second Chance: No ON_CAPTURE abilities")
		return false
	
	# Look for Second Chance ability specifically
	var second_chance_ability = null
	var available_abilities = captured_card.get_available_abilities(card_level)
	for ability in available_abilities:
		if ability.ability_name == "Second Chance":
			second_chance_ability = ability
			break
	
	if not second_chance_ability:
		print("Second Chance: Ability not found")
		return false
	
	# Check if already used
	if captured_card.has_meta("second_chance_used") and captured_card.get_meta("second_chance_used"):
		print("Second Chance: Already used this battle")
		return false
	
	# Mark as used
	captured_card.set_meta("second_chance_used", true)
	print("SECOND CHANCE ACTIVATED! ", captured_card.card_name, " will return to hand!")
	
	# Get stored card info
	if not captured_index in second_chance_cards:
		print("ERROR: Card not registered in second_chance_cards dictionary!")
		return false
	
	var card_info = second_chance_cards[captured_index]
	var original_owner = card_info.owner
	var original_collection_index = card_info.collection_index
	
	# Remove from board
	grid_occupied[captured_index] = false
	grid_ownership[captured_index] = Owner.NONE
	grid_card_data[captured_index] = null
	
	# Remove card display
	var slot = grid_slots[captured_index]
	for child in slot.get_children():
		if child is CardDisplay:
			child.queue_free()
			break
	
	# Remove from tracking
	grid_to_collection_index.erase(captured_index)
	if captured_index in active_passive_abilities:
		active_passive_abilities.erase(captured_index)
	
	# Return to appropriate hand
	if original_owner == Owner.PLAYER:
		player_deck.append(captured_card)
		deck_card_indices.append(original_collection_index)
		display_player_hand()
		print("Returned ", captured_card.card_name, " to player hand")
	elif original_owner == Owner.OPPONENT:
		if opponent_manager:
			opponent_manager.opponent_deck.append(captured_card)
			print("Returned ", captured_card.card_name, " to opponent hand")
	
	# Clean up registration
	second_chance_cards.erase(captured_index)
	
	# Award reduced experience to attacker
	if attacking_owner == Owner.PLAYER:
		var attacker_collection_index = get_card_collection_index(attacker_pos)
		if attacker_collection_index != -1:
			var exp_tracker = get_node("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(attacker_collection_index, 5)
				print("Player gained 5 exp for attack (card returned via Second Chance)")
	
	return true  # Capture was prevented


func register_second_chance_if_needed(grid_position: int, card: CardResource, owner: Owner) -> void:
	# Check if this card has Second Chance ability
	var card_collection_index = get_card_collection_index(grid_position)
	var card_level = get_card_level(card_collection_index)
	
	if card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, card_level):
		var available_abilities = card.get_available_abilities(card_level)
		for ability in available_abilities:
			if ability.ability_name == "Second Chance":
				# Store this card's info for potential return to hand
				second_chance_cards[grid_position] = {
					"card": card,
					"owner": owner,
					"collection_index": card_collection_index
				}
				print("Registered Second Chance card at position ", grid_position)
				break

func start_aristeia_mode(aristeia_position: int, aristeia_owner: Owner, aristeia_card: CardResource):
	aristeia_mode_active = true
	current_aristeia_position = aristeia_position
	current_aristeia_owner = aristeia_owner
	current_aristeia_card = aristeia_card
	
	# Update game status
	if aristeia_owner == Owner.PLAYER:
		game_status_label.text = "⚔️ ARISTEIA: Select an empty slot to move and fight again"
	else:
		game_status_label.text = "⚔️ " + opponent_manager.get_opponent_info().name + " is in aristeia..."
		# Auto-select target for opponent
		call_deferred("opponent_select_aristeia_target")
	
	print("Aristeia mode activated for ", aristeia_card.card_name, " at position ", aristeia_position)

func select_aristeia_target(target_position: int):
	if not aristeia_mode_active:
		return
	
	print("Aristeia target selected: position ", target_position)
	
	# Get the aristeia card data from the original position
	var aristeia_card = current_aristeia_card
	var original_position = current_aristeia_position
	var aristeia_owner = current_aristeia_owner
	
	
	
	# Move the card from original position to target position
	execute_aristeia_move(original_position, target_position, aristeia_card, aristeia_owner)

func execute_aristeia_move(from_position: int, to_position: int, aristeia_card: CardResource, aristeia_owner: Owner):
	print("Executing aristeia move from position ", from_position, " to position ", to_position)
	
	# Get card collection info before clearing original position
	var card_collection_index = get_card_collection_index_for_dance(from_position)
	var card_level = get_card_level(card_collection_index)
	
	var existing_card_display = null
	var from_slot = grid_slots[from_position]
	for child in from_slot.get_children():
		if child is CardDisplay:
			existing_card_display = child
			break

	# Clear the original position without freeing the card display
	grid_occupied[from_position] = false
	grid_ownership[from_position] = Owner.NONE
	grid_card_data[from_position] = null

	# Clear passive abilities for this position
	if from_position in active_passive_abilities:
		active_passive_abilities.erase(from_position)

	# Place the card at the new position
	grid_occupied[to_position] = true
	grid_ownership[to_position] = aristeia_owner
	grid_card_data[to_position] = aristeia_card

	# Update grid to collection mapping for the new position
	if card_collection_index != -1:
		grid_to_collection_index[to_position] = card_collection_index
		grid_to_collection_index.erase(from_position)

	# Move the existing card display instead of creating a new one
	if existing_card_display and is_instance_valid(existing_card_display):
		# Remove from old slot
		from_slot.remove_child(existing_card_display)
		
		# Add to new slot
		var to_slot = grid_slots[to_position]
		to_slot.add_child(existing_card_display)
		
		print("AristeiaAbility: Moved existing CardDisplay from position ", from_position, " to ", to_position)
	else:
		# Fallback: create new card display if the old one was somehow invalid
		var slot = grid_slots[to_position]
		var card_display_scene = preload("res://Scenes/CardDisplay.tscn")
		var card_display = card_display_scene.instantiate()
		card_display.setup(aristeia_card, card_level, "", card_collection_index, aristeia_owner == Owner.OPPONENT)
		slot.add_child(card_display)
		print("AristeiaAbility: Created new CardDisplay as fallback")
	
	# Execute placement effects at new location (like ordain bonus)
	if aristeia_owner == Owner.PLAYER:
		apply_ordain_bonus_if_applicable(to_position, aristeia_card, aristeia_owner)
	
	# Handle passive abilities at new position
	handle_passive_abilities_on_place(to_position, aristeia_card, card_level)
	
	# Check for couple union at new position
	check_for_couple_union(aristeia_card, to_position)
	
	# Resolve combat at the new position
	var captures = resolve_combat(to_position, aristeia_owner, aristeia_card)
	if captures > 0:
		print("Aristeia card captured ", captures, " cards after moving!")
		
		# Chain Aristeia if more captures made
		if aristeia_card.has_ability_type(CardAbility.TriggerType.ON_PLAY, card_level):
			var available_abilities = aristeia_card.get_available_abilities(card_level)
			for ability in available_abilities:
				if ability.ability_name == "Aristeia":
					print("Aristeia chain triggered!")
					
					var aristeia_context = {
						"placed_card": aristeia_card,
						"grid_position": to_position,
						"game_manager": self,
						"placing_owner": aristeia_owner,
						"card_level": card_level,
						"captures_made": captures
					}
					
					ability.execute(aristeia_context)
					return  # Keep mode active for next move

	# No more captures - end aristeia
	aristeia_mode_active = false
	current_aristeia_position = -1
	current_aristeia_owner = Owner.NONE
	current_aristeia_card = null

	update_card_display(to_position, aristeia_card)
	update_game_status()

	if should_game_end():
		end_game()
		return
	
	print("Aristeia complete - switching turns")
	turn_manager.next_turn()	

func opponent_select_aristeia_target():
	if not aristeia_mode_active:
		return
	
	# Simple AI: pick a random empty slot
	var possible_targets = []
	
	for i in range(grid_slots.size()):
		if not grid_occupied[i]:  # Only empty slots
			possible_targets.append(i)
	
	var target_position = -1
	if possible_targets.size() > 0:
		target_position = possible_targets[randi() % possible_targets.size()]
	
	if target_position != -1:
		select_aristeia_target(target_position)

func clear_all_aristeia_constraints():
	if aristeia_mode_active:
		aristeia_mode_active = false
		current_aristeia_position = -1
		current_aristeia_owner = Owner.NONE
		current_aristeia_card = null
		print("All aristeia constraints cleared")


func artemis_boss_return_cards_to_hand():
	"""
	Artemis boss mechanic: Return 2 opponent cards to their hand
	Priority: Captured opponent original cards > random opponent cards
	"""
	print("=== ARTEMIS BOSS COUNTER: Returning cards to opponent hand ===")
	
	# Find all opponent cards on the board
	var opponent_original_cards = []  # Cards that started in opponent's hand
	var other_opponent_cards = []  # Other opponent cards (captured from player)
	
	for i in range(grid_ownership.size()):
		if grid_occupied[i] and grid_ownership[i] == Owner.OPPONENT:
			var card = grid_card_data[i]
			
			# Check if this card is an opponent original (was placed by opponent, not captured)
			# We can check if the card was registered in second_chance_cards as opponent owned
			# OR check the opponent_manager to see if this card matches their original deck
			var is_opponent_original = false
			
			# Check if card matches any in opponent's original deck
			var opponent_info = opponent_manager.get_opponent_info()
			for opp_card in opponent_info.deck:
				if opp_card.card_name == card.card_name:
					is_opponent_original = true
					break
			
			if is_opponent_original:
				opponent_original_cards.append(i)
			else:
				other_opponent_cards.append(i)
	
	print("Found ", opponent_original_cards.size(), " opponent original cards")
	print("Found ", other_opponent_cards.size(), " other opponent cards")
	
	# Select up to 2 cards to return (prioritize originals)
	var cards_to_return = []
	
	# First, add opponent originals (up to 2)
	for i in range(min(2, opponent_original_cards.size())):
		cards_to_return.append(opponent_original_cards[i])
	
	# If we still need more, add from other cards
	if cards_to_return.size() < 2:
		var remaining_needed = 2 - cards_to_return.size()
		for i in range(min(remaining_needed, other_opponent_cards.size())):
			cards_to_return.append(other_opponent_cards[i])
	
	print("Returning ", cards_to_return.size(), " cards to opponent hand")
	
	# Return each selected card to opponent hand
	for grid_index in cards_to_return:
		var card = grid_card_data[grid_index]
		if not card:
			continue
		
		print("Returning ", card.card_name, " from position ", grid_index, " to opponent hand")
		
		# Create a fresh copy at base stats
		var base_card = card.duplicate(true)
		# Reset to base level values (level 1)
		var base_values = card.get_effective_values(1)
		base_card.values = base_values.duplicate()
		
		# Remove from board (similar to Second Chance logic)
		grid_occupied[grid_index] = false
		grid_ownership[grid_index] = Owner.NONE
		grid_card_data[grid_index] = null
		
		# Remove card display
		var slot = grid_slots[grid_index]
		for child in slot.get_children():
			if child is CardDisplay:
				child.queue_free()
				break
		
		# Remove from tracking
		grid_to_collection_index.erase(grid_index)
		if grid_index in active_passive_abilities:
			# Remove passive abilities without triggering effects
			active_passive_abilities.erase(grid_index)
		
		# Add back to opponent hand
		if opponent_manager:
			opponent_manager.opponent_deck.append(base_card)
			print("Added ", base_card.card_name, " back to opponent deck")
	
	# Update board visuals
	update_board_visuals()
	update_game_status()
	
	print("Artemis boss counter complete - ", cards_to_return.size(), " cards returned")
