# res://Scripts/reward_screen.gd
extends Control

# UI References
@onready var main_container = $ScrollContainer/VBoxContainer
@onready var title_label = $ScrollContainer/VBoxContainer/Title
@onready var continue_button = $ScrollContainer/VBoxContainer/ContinueButton

# Card selection
var current_deck: Array[CardResource] = []
var deck_indices: Array[int] = []
var selected_card_index: int = -1
var selected_experience_type: String = ""  # "capture" or "defense"


# UI components we'll create
var cards_container: HBoxContainer
var card_displays: Array[CardDisplay] = []
var capture_button: Button
var defense_button: Button
var mnemosyne_button: Button
var reward_info_label: Label

var is_perfect_victory: bool = false
var rewards_remaining: int = 1
var claimed_rewards: Array[String] = []


func _ready():
	print("=== REWARD SCREEN STARTING ===")
	
	# Get perfect victory status
	var params = get_scene_params()
	is_perfect_victory = params.get("perfect_victory", false)
	rewards_remaining = 2 if is_perfect_victory else 1
	
	print("Perfect victory: ", is_perfect_victory, " - Rewards available: ", rewards_remaining)
	
	# Connect the continue button first
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.disabled = true
		continue_button.text = get_continue_button_text()
	else:
		print("Error: Continue button not found!")
		return
	
	# Setup the interface
	setup_reward_interface()
	
	# Load deck data synchronously
	load_deck_data_sync()
	
	print("=== REWARD SCREEN READY ===")


func get_continue_button_text() -> String:
	if rewards_remaining > 1:
		return "Choose " + str(rewards_remaining) + " Rewards"
	elif rewards_remaining == 1:
		return "Choose a Reward"
	else:
		return "Continue"

# Replace the load_deck_data function with synchronous version
func load_deck_data_sync():
	print("=== LOADING DECK DATA SYNC ===")
	
	var params = get_scene_params()
	var god_name = params.get("god", "Apollo")
	var deck_index = params.get("deck_index", 0)
	
	print("Loading deck data for: ", god_name, " deck ", deck_index)
	
	# Load the god's collection
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"

	
	if not ResourceLoader.exists(collection_path):
		print("ERROR: Collection does not exist at: ", collection_path)
		return
	
	var collection: GodCardCollection = load(collection_path)
	
	if not collection:
		print("ERROR: Failed to load collection: ", collection_path)
		return
	
	if deck_index >= collection.decks.size():
		print("ERROR: Invalid deck index: ", deck_index, " (collection has ", collection.decks.size(), " decks)")
		return
	
	# Get the deck and indices
	current_deck = collection.get_deck(deck_index)
	deck_indices = collection.decks[deck_index].card_indices.duplicate()
	
	print("Loaded deck with ", current_deck.size(), " cards")
	print("Deck indices: ", deck_indices)
	
	# Debug: Print card names
	for i in range(current_deck.size()):
		if current_deck[i]:
			print("Card ", i, ": ", current_deck[i].card_name)
		else:
			print("Card ", i, ": NULL")
	
	# Create card displays synchronously
	create_card_displays_sync()
	
	# Update Mnemosyne button with current level info
	update_mnemosyne_button_text()

func safe_load_deck_data():
	# Double-check we're still in the tree
	if not get_tree():
		print("Error: Node not in scene tree during safe_load_deck_data!")
		return
	
	await load_deck_data()

func setup_reward_interface():
	print("Setting up reward interface...")
	print("Main container children before setup: ", main_container.get_child_count())
	
	if is_perfect_victory:
		title_label.text = "🏆 Perfect Victory! Choose Two Rewards 🏆"
		title_label.add_theme_color_override("font_color", Color("#FFD700"))  # Gold color
	else:
		title_label.text = "Choose Your Reward"
	
	# Create card selection area with explicit sizing
	var card_section = VBoxContainer.new()
	card_section.name = "CardSection"
	card_section.custom_minimum_size = Vector2(900, 200)  # Wider for card+exp layout
	card_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var card_label = Label.new()
	card_label.text = "Select a card to enhance:"
	card_label.add_theme_font_size_override("font_size", 16)
	card_label.add_theme_color_override("font_color", Color.WHITE)  # Make sure it's visible
	card_section.add_child(card_label)
	
	# Container for card displays with explicit sizing (wider for card+exp layout)
	cards_container = HBoxContainer.new()
	cards_container.name = "CardsContainer"
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)  # More separation between card groups
	cards_container.custom_minimum_size = Vector2(900, 160)  # Much wider to accommodate card+exp layout
	cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Don't expand vertically
	card_section.add_child(cards_container)
	
	# Experience type selection with explicit sizing
	var exp_section = VBoxContainer.new()
	exp_section.name = "ExperienceSection"
	exp_section.custom_minimum_size = Vector2(400, 100)
	exp_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var exp_label = Label.new()
	exp_label.text = "Choose experience type:"
	exp_label.add_theme_font_size_override("font_size", 16)
	exp_label.add_theme_color_override("font_color", Color.WHITE)
	exp_section.add_child(exp_label)
	
	var exp_buttons = HBoxContainer.new()
	exp_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	exp_buttons.add_theme_constant_override("separation", 20)
	exp_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	capture_button = Button.new()
	capture_button.text = "⚔️ +15 Capture XP"
	capture_button.disabled = true
	capture_button.custom_minimum_size = Vector2(150, 40)
	capture_button.pressed.connect(_on_capture_button_pressed)
	exp_buttons.add_child(capture_button)
	
	defense_button = Button.new()
	defense_button.text = "🛡️ +15 Defense XP"
	defense_button.disabled = true
	defense_button.custom_minimum_size = Vector2(150, 40)
	defense_button.pressed.connect(_on_defense_button_pressed)
	exp_buttons.add_child(defense_button)
	
	exp_section.add_child(exp_buttons)
	
	# Mnemosyne section with explicit sizing
	var mnemosyne_section = VBoxContainer.new()
	mnemosyne_section.name = "MnemosyneSection"
	mnemosyne_section.custom_minimum_size = Vector2(400, 80)
	mnemosyne_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var mnemosyne_label = Label.new()
	mnemosyne_label.text = "Or enhance Mnemosyne's consciousness:"
	mnemosyne_label.add_theme_font_size_override("font_size", 16)
	mnemosyne_label.add_theme_color_override("font_color", Color.WHITE)
	mnemosyne_section.add_child(mnemosyne_label)
	
	mnemosyne_button = Button.new()
	mnemosyne_button.text = "🧠 Consciousness Boost"
	mnemosyne_button.custom_minimum_size = Vector2(200, 40)
	mnemosyne_button.pressed.connect(_on_mnemosyne_button_pressed)
	mnemosyne_section.add_child(mnemosyne_button)
	
	# Info label for showing current selection
	reward_info_label = Label.new()
	reward_info_label.text = "Loading deck..."  # Give it initial text
	reward_info_label.add_theme_font_size_override("font_size", 12)
	reward_info_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	reward_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_info_label.custom_minimum_size = Vector2(400, 30)
	
	# Simple approach: just add everything to the end, before continue button
	var continue_button_index = main_container.get_children().find(continue_button)
	print("Continue button found at index: ", continue_button_index)
	
	# Use a simpler approach - just insert before the continue button
	if continue_button_index != -1:
		main_container.add_child(card_section)
		main_container.move_child(card_section, continue_button_index)
		continue_button_index += 1
		
		var separator1 = HSeparator.new()
		main_container.add_child(separator1)
		main_container.move_child(separator1, continue_button_index)
		continue_button_index += 1
		
		main_container.add_child(exp_section)
		main_container.move_child(exp_section, continue_button_index)
		continue_button_index += 1
		
		var separator2 = HSeparator.new()
		main_container.add_child(separator2)
		main_container.move_child(separator2, continue_button_index)
		continue_button_index += 1
		
		main_container.add_child(mnemosyne_section)
		main_container.move_child(mnemosyne_section, continue_button_index)
		continue_button_index += 1
		
		var separator3 = HSeparator.new()
		main_container.add_child(separator3)
		main_container.move_child(separator3, continue_button_index)
		continue_button_index += 1
		
		main_container.add_child(reward_info_label)
		main_container.move_child(reward_info_label, continue_button_index)
		
		print("Successfully added all sections")
	else:
		print("ERROR: Could not find continue button, adding at end")
		main_container.add_child(card_section)
		main_container.add_child(HSeparator.new())
		main_container.add_child(exp_section)
		main_container.add_child(HSeparator.new())
		main_container.add_child(mnemosyne_section)
		main_container.add_child(HSeparator.new())
		main_container.add_child(reward_info_label)
	
	print("Main container children after setup: ", main_container.get_child_count())
	print("Reward interface setup complete!")
	
	# Force a layout update
	main_container.queue_redraw()
	
	# Debug: print all children
	for i in range(main_container.get_child_count()):
		var child = main_container.get_child(i)
		print("Child ", i, ": ", child.name, " (", child.get_class(), ") - visible: ", child.visible, " - size: ", child.size)

func load_deck_data():
	var params = get_scene_params()
	var god_name = params.get("god", "Apollo")
	var deck_index = params.get("deck_index", 0)
	
	print("Loading deck data for: ", god_name, " deck ", deck_index)
	
	# Load the god's collection
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	
	if not collection:
		print("Failed to load collection for rewards: ", collection_path)
		return
	
	if deck_index >= collection.decks.size():
		print("Invalid deck index: ", deck_index)
		return
	
	# Get the deck and indices
	current_deck = collection.get_deck(deck_index)
	deck_indices = collection.decks[deck_index].card_indices.duplicate()
	
	print("Loaded deck with ", current_deck.size(), " cards")
	
	# Create card displays with safer autoload access
	await create_card_displays_sync()
	
	# Update Mnemosyne button with current level info
	update_mnemosyne_button_text()

func create_card_displays_sync():
	print("=== CREATING CARD DISPLAYS ===")
	
	# Safety check
	if not cards_container:
		print("ERROR: cards_container is null!")
		return
	
	if current_deck.is_empty():
		print("ERROR: current_deck is empty!")
		return
	
	if deck_indices.is_empty():
		print("ERROR: deck_indices is empty!")
		return
	
	# Clear existing displays
	for display in card_displays:
		if is_instance_valid(display):
			display.queue_free()
	card_displays.clear()
	
	# Clear container
	for child in cards_container.get_children():
		child.queue_free()
	
	# Get tracker safely
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	if not tracker:
		print("WARNING: RunExperienceTrackerAutoload not found!")
	
	print("Creating displays for ", current_deck.size(), " cards")
	
	# Create display for each card
	for i in range(current_deck.size()):
		var card = current_deck[i]
		var card_index = deck_indices[i]
		
		print("Creating display for card ", i, ": ", card.card_name, " (index ", card_index, ")")
		
		# Create a horizontal container for card + exp info
		var card_with_exp_container = HBoxContainer.new()
		card_with_exp_container.name = "CardWithExpContainer" + str(i)
		card_with_exp_container.custom_minimum_size = Vector2(180, 150)
		card_with_exp_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_with_exp_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_with_exp_container.add_theme_constant_override("separation", 15)
		
		# Create a Control wrapper for the Node2D card display
		var card_wrapper = Control.new()
		card_wrapper.name = "CardWrapper" + str(i)
		card_wrapper.custom_minimum_size = Vector2(110, 150)
		card_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Create card display
		var card_display_scene = preload("res://Scenes/CardDisplay.tscn")
		if not card_display_scene:
			print("ERROR: Could not load CardDisplay scene!")
			continue
		
		var card_display = card_display_scene.instantiate()
		if not card_display:
			print("ERROR: Could not instantiate CardDisplay!")
			continue
		
		# Add card to wrapper
		card_wrapper.add_child(card_display)
		
		# Setup the card immediately (no await)
		card_display.setup(card)
		
		# Center the card within its wrapper
		card_display.position = Vector2(5, 5)
		
		# Create experience info display
		var exp_info_container = create_experience_info_display_sync(card_index, tracker)
		
		# Add card wrapper and exp info to the horizontal container
		card_with_exp_container.add_child(card_wrapper)
		card_with_exp_container.add_child(exp_info_container)
		
		# Add the complete container to the cards container
		cards_container.add_child(card_with_exp_container)
		
		# Connect selection - using both wrapper and panel for better coverage
		card_wrapper.gui_input.connect(_on_card_wrapper_input.bind(i))
		if card_display.panel:
			card_display.panel.gui_input.connect(_on_card_panel_input.bind(i))
		else:
			print("WARNING: Card display panel is null for card ", i)
		
		# Store reference
		card_displays.append(card_display)
		
		print("Successfully created display for card ", i)
	
	print("Created ", card_displays.size(), " card displays")
	
	print("=== FINAL DEBUG OUTPUT ===")
	print("Cards container children: ", cards_container.get_child_count())
	print("Cards container size: ", cards_container.size)
	print("Cards container visible: ", cards_container.visible)
	print("Main container children: ", main_container.get_child_count())
	
	# Force layout update
	cards_container.queue_redraw()

func create_experience_info_display_sync(card_index: int, tracker) -> Control:
	# Create container for experience info
	var exp_container = VBoxContainer.new()
	exp_container.name = "ExperienceInfo"
	exp_container.custom_minimum_size = Vector2(80, 150)
	exp_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exp_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_container.add_theme_constant_override("separation", 6)
	
	# Add title
	var title_label = Label.new()
	title_label.text = "This Run:"
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_container.add_child(title_label)
	
	# Get experience data if tracker exists
	if tracker and is_instance_valid(tracker):
		var exp_data = tracker.get_card_experience(card_index)
		
		print("Card ", card_index, " exp data: ", exp_data)
		
		# Capture experience label
		var capture_label = Label.new()
		capture_label.text = "⚔️ +" + str(exp_data["capture_exp"])
		capture_label.add_theme_font_size_override("font_size", 12)
		capture_label.add_theme_color_override("font_color", Color("#FFD700"))
		capture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(capture_label)
		
		# Defense experience label  
		var defense_label = Label.new()
		defense_label.text = "🛡️ +" + str(exp_data["defense_exp"])
		defense_label.add_theme_font_size_override("font_size", 12)
		defense_label.add_theme_color_override("font_color", Color("#87CEEB"))
		defense_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(defense_label)
		
		# Add small separator
		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 4)
		exp_container.add_child(separator)
		
		# Total experience section
		var total_title = Label.new()
		total_title.text = "Total:"
		total_title.add_theme_font_size_override("font_size", 10)
		total_title.add_theme_color_override("font_color", Color("#AAAAAA"))
		total_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(total_title)
		
		# Get total experience from global tracker
		var params = get_scene_params()
		var god_name = params.get("god", "Apollo")
		
		var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
		if global_tracker and is_instance_valid(global_tracker):
			var total_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
			var total_capture = total_exp_data.get("capture_exp", 0)
			var total_defense = total_exp_data.get("defense_exp", 0)
			
			# Total capture experience
			var total_capture_label = Label.new()
			total_capture_label.text = "⚔️ " + str(total_capture)
			total_capture_label.add_theme_font_size_override("font_size", 10)
			total_capture_label.add_theme_color_override("font_color", Color("#B8860B"))
			total_capture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exp_container.add_child(total_capture_label)
			
			# Total defense experience
			var total_defense_label = Label.new()
			total_defense_label.text = "🛡️ " + str(total_defense)
			total_defense_label.add_theme_font_size_override("font_size", 10)
			total_defense_label.add_theme_color_override("font_color", Color("#4682B4"))
			total_defense_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exp_container.add_child(total_defense_label)
			
			# Add level display for quick reference
			var combined_total = total_capture + total_defense
			if combined_total > 0:
				var level = ExperienceHelpers.calculate_level(combined_total)
				var level_label = Label.new()
				level_label.text = "Lv." + str(level)
				level_label.add_theme_font_size_override("font_size", 9)
				level_label.add_theme_color_override("font_color", Color("#888888"))
				level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				exp_container.add_child(level_label)
		else:
			# No global tracker - show notice
			var no_total_label = Label.new()
			no_total_label.text = "Total:\nN/A"
			no_total_label.add_theme_font_size_override("font_size", 9)
			no_total_label.add_theme_color_override("font_color", Color("#666666"))
			no_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			no_total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exp_container.add_child(no_total_label)
	else:
		# No tracker available
		var no_data_label = Label.new()
		no_data_label.text = "No data\navailable"
		no_data_label.add_theme_font_size_override("font_size", 10)
		no_data_label.add_theme_color_override("font_color", Color("#888888"))
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		exp_container.add_child(no_data_label)
	
	return exp_container

func create_experience_info_display(card_index: int, tracker) -> Control:
	# Create container for experience info
	var exp_container = VBoxContainer.new()
	exp_container.name = "ExperienceInfo"
	exp_container.custom_minimum_size = Vector2(80, 150)  # Slightly wider for total exp
	exp_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exp_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_container.add_theme_constant_override("separation", 6)  # Tighter spacing for more content
	
	# Add title
	var title_label = Label.new()
	title_label.text = "This Run:"
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_container.add_child(title_label)
	
	# Get experience data if tracker exists
	if tracker and is_instance_valid(tracker):
		var exp_data = tracker.get_card_experience(card_index)
		
		# Capture experience label
		var capture_label = Label.new()
		capture_label.text = "⚔️ +" + str(exp_data["capture_exp"])
		capture_label.add_theme_font_size_override("font_size", 12)
		capture_label.add_theme_color_override("font_color", Color("#FFD700"))
		capture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(capture_label)
		
		# Defense experience label  
		var defense_label = Label.new()
		defense_label.text = "🛡️ +" + str(exp_data["defense_exp"])
		defense_label.add_theme_font_size_override("font_size", 12)
		defense_label.add_theme_color_override("font_color", Color("#87CEEB"))
		defense_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(defense_label)
		
		# Add small separator
		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 4)
		exp_container.add_child(separator)
		
		# Total experience section
		var total_title = Label.new()
		total_title.text = "Total:"
		total_title.add_theme_font_size_override("font_size", 10)
		total_title.add_theme_color_override("font_color", Color("#AAAAAA"))
		total_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(total_title)
		
		# Get total experience from global tracker
		var params = get_scene_params()
		var god_name = params.get("god", "Apollo")
		
		var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
		if global_tracker and is_instance_valid(global_tracker):
			var total_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
			var total_capture = total_exp_data.get("capture_exp", 0)
			var total_defense = total_exp_data.get("defense_exp", 0)
			
			# Total capture experience
			var total_capture_label = Label.new()
			total_capture_label.text = "⚔️ " + str(total_capture)
			total_capture_label.add_theme_font_size_override("font_size", 10)
			total_capture_label.add_theme_color_override("font_color", Color("#B8860B"))  # Darker gold
			total_capture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exp_container.add_child(total_capture_label)
			
			# Total defense experience
			var total_defense_label = Label.new()
			total_defense_label.text = "🛡️ " + str(total_defense)
			total_defense_label.add_theme_font_size_override("font_size", 10)
			total_defense_label.add_theme_color_override("font_color", Color("#4682B4"))  # Darker blue
			total_defense_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exp_container.add_child(total_defense_label)
			
			# Add level display for quick reference
			var combined_total = total_capture + total_defense
			if combined_total > 0:
				var level = ExperienceHelpers.calculate_level(combined_total)
				var level_label = Label.new()
				level_label.text = "Lv." + str(level)
				level_label.add_theme_font_size_override("font_size", 9)
				level_label.add_theme_color_override("font_color", Color("#888888"))
				level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				exp_container.add_child(level_label)
		else:
			# No global tracker - show notice
			var no_total_label = Label.new()
			no_total_label.text = "Total:\nN/A"
			no_total_label.add_theme_font_size_override("font_size", 9)
			no_total_label.add_theme_color_override("font_color", Color("#666666"))
			no_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			no_total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exp_container.add_child(no_total_label)
	else:
		# No tracker available
		var no_data_label = Label.new()
		no_data_label.text = "No data\navailable"
		no_data_label.add_theme_font_size_override("font_size", 10)
		no_data_label.add_theme_color_override("font_color", Color("#888888"))
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		exp_container.add_child(no_data_label)
	
	return exp_container

func update_mnemosyne_button_text():
	# Safety check
	if not get_tree():
		print("Error: No scene tree in update_mnemosyne_button_text")
		return
	
	# Use get_node_or_null instead of has_node check
	var memory_manager = get_node_or_null("/root/MemoryJournalManagerAutoload")
	if not memory_manager:
		print("MemoryJournalManagerAutoload not found for Mnemosyne button update")
		mnemosyne_button.text = "🧠 Consciousness Boost\n(Memory Manager Unavailable)"
		return
	
	var mnemosyne_data = memory_manager.get_mnemosyne_memory()
	var current_level = mnemosyne_data.get("consciousness_level", 1)
	var current_desc = memory_manager.get_consciousness_description(current_level)
	var next_desc = memory_manager.get_consciousness_description(current_level + 1)
	
	mnemosyne_button.text = "🧠 Consciousness Boost\n" + current_desc + " → " + next_desc

# Separate input handlers for wrapper and panel
func _on_card_wrapper_input(event: InputEvent, card_index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Wrapper input detected for card ", card_index)
		_on_card_selected(card_index)

func _on_card_panel_input(event: InputEvent, card_index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Panel input detected for card ", card_index)
		_on_card_selected(card_index)

func _on_card_selected(card_index: int):
	# Check if we can still claim rewards
	if rewards_remaining <= 0:
		print("No rewards remaining, ignoring selection")
		return
	
	print("=== CARD SELECTION DEBUG ===")
	print("Card selection attempted - index: ", card_index, ", current selected: ", selected_card_index)
	print("Card displays array size: ", card_displays.size())
	print("Rewards remaining: ", rewards_remaining)
	
	# Deselect all cards
	print("Deselecting all cards...")
	for i in range(card_displays.size()):
		if is_instance_valid(card_displays[i]):
			print("  Checking card ", i, " - has deselect method: ", card_displays[i].has_method("deselect"))
			if card_displays[i].has_method("deselect"):
				card_displays[i].deselect()
				print("    Deselected card ", i)
			else:
				print("    Card ", i, " has no deselect method!")
		else:
			print("  Card ", i, " is not valid")
	
	# Select this card
	if card_index < card_displays.size() and is_instance_valid(card_displays[card_index]):
		print("Selecting card ", card_index)
		if card_displays[card_index].has_method("select"):
			card_displays[card_index].select()
			print("  Successfully called select() on card ", card_index)
		else:
			print("  Card ", card_index, " has no select method!")
		
		selected_card_index = card_index
		print("Set selected_card_index to: ", selected_card_index)
		
		# Enable experience buttons
		print("Enabling experience buttons...")
		print("  Capture button before: disabled = ", capture_button.disabled)
		print("  Defense button before: disabled = ", defense_button.disabled)
		
		capture_button.disabled = false
		defense_button.disabled = false
		
		print("  Capture button after: disabled = ", capture_button.disabled)
		print("  Defense button after: disabled = ", defense_button.disabled)
		
		# Update info
		var card_name = current_deck[card_index].card_name
		reward_info_label.text = "Selected: " + card_name
		print("Updated info label to: ", reward_info_label.text)
		
		print("Selected card: ", card_name, " at index: ", card_index)
	else:
		print("Failed to select card - invalid index or card display")
		print("  card_index: ", card_index, " < card_displays.size(): ", card_displays.size())
		if card_index < card_displays.size():
			print("  is_instance_valid: ", is_instance_valid(card_displays[card_index]))
	
	print("=== END CARD SELECTION DEBUG ===")
	print("")

func _on_capture_button_pressed():
	print("Capture button pressed - selected_card_index: ", selected_card_index, ", rewards_remaining: ", rewards_remaining)
	if selected_card_index == -1 or rewards_remaining <= 0:
		print("Cannot apply capture reward - no card selected or no rewards remaining")
		return
	
	apply_experience_reward("capture")

func _on_defense_button_pressed():
	print("Defense button pressed - selected_card_index: ", selected_card_index, ", rewards_remaining: ", rewards_remaining)
	if selected_card_index == -1 or rewards_remaining <= 0:
		print("Cannot apply defense reward - no card selected or no rewards remaining")
		return
	
	apply_experience_reward("defense")

func _on_mnemosyne_button_pressed():
	if rewards_remaining <= 0:
		print("No rewards remaining, cannot claim Mnemosyne reward")
		return
	
	apply_mnemosyne_reward()

func apply_experience_reward(exp_type: String):
	var card_index = deck_indices[selected_card_index]
	var card_name = current_deck[selected_card_index].card_name
	var bonus_amount = 15
	
	# Check if tracker exists
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	if not tracker:
		print("RunExperienceTrackerAutoload not found!")
		return
	
	# Apply to run tracker
	if exp_type == "capture":
		tracker.add_capture_exp(card_index, bonus_amount)
	else:
		tracker.add_defense_exp(card_index, bonus_amount)
	
	# Track this reward
	var reward_desc = card_name + " +" + str(bonus_amount) + " " + exp_type.capitalize() + " XP"
	claimed_rewards.append(reward_desc)
	rewards_remaining -= 1
	
	# Reset selection state for next reward
	selected_card_index = -1
	selected_experience_type = ""
	
	# Deselect all cards
	for display in card_displays:
		if is_instance_valid(display):
			display.deselect()
	
	# Update UI based on remaining rewards
	if rewards_remaining > 0:
		# More rewards to claim - re-enable selection
		update_for_next_reward()
	else:
		# All rewards claimed - finish
		finish_reward_selection()

func apply_mnemosyne_reward():
	# Check if memory manager exists
	var memory_manager = get_node_or_null("/root/MemoryJournalManagerAutoload")
	if not memory_manager:
		print("MemoryJournalManagerAutoload not found!")
		return
	
	# Apply consciousness boost
	var boost_amount = 3
	memory_manager.add_memory_fragments(boost_amount)
	
	# Force consciousness level recalculation
	var current_battles = memory_manager.get_mnemosyne_memory()["total_battles"]
	memory_manager.memory_data["mnemosyne"]["total_battles"] += boost_amount
	var new_level = memory_manager.calculate_mnemosyne_consciousness_level()
	memory_manager.memory_data["mnemosyne"]["consciousness_level"] = new_level
	memory_manager.memory_data["mnemosyne"]["total_battles"] = current_battles
	
	memory_manager.save_memory_data()
	
	# Track this reward
	claimed_rewards.append("Mnemosyne Consciousness Boost")
	rewards_remaining -= 1
	
	# Reset selection state
	selected_card_index = -1
	
	# Deselect all cards
	for display in card_displays:
		if is_instance_valid(display):
			display.deselect()
	
	# Update UI based on remaining rewards
	if rewards_remaining > 0:
		update_for_next_reward()
	else:
		finish_reward_selection()


func update_for_next_reward():
	# Re-enable all reward options for next selection
	capture_button.disabled = true  # Will be enabled when card is selected
	defense_button.disabled = true  # Will be enabled when card is selected
	
	# Only enable Mnemosyne button if it hasn't been claimed yet
	var mnemosyne_already_claimed = false
	for reward in claimed_rewards:
		if reward.contains("Mnemosyne"):
			mnemosyne_already_claimed = true
			break
	
	mnemosyne_button.disabled = mnemosyne_already_claimed
	
	# Update continue button
	continue_button.disabled = true
	continue_button.text = get_continue_button_text()
	
	# Update info label to show progress
	var rewards_claimed_text = "Claimed: " + " | ".join(claimed_rewards)
	reward_info_label.text = rewards_claimed_text + "\n" + "Choose your next reward"
	reward_info_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	
	print("Updated for next reward - ", rewards_remaining, " remaining")

func finish_reward_selection():
	# All rewards claimed - finalize
	capture_button.disabled = true
	defense_button.disabled = true
	mnemosyne_button.disabled = true
	
	# Enable continue button
	continue_button.disabled = false
	continue_button.text = "Continue"
	
	# Update info label with summary
	var summary_text = "Rewards Claimed:\n" + "\n".join(claimed_rewards)
	reward_info_label.text = summary_text
	reward_info_label.add_theme_color_override("font_color", Color("#66BB6A"))
	
	print("All rewards claimed: ", claimed_rewards)


func _on_continue_pressed():
	if rewards_remaining > 0:
		print("Still have rewards remaining, cannot continue yet")
		return
	
	# Get the map data and return to map
	var params = get_scene_params()
	
	# Pass everything back to the map
	get_tree().set_meta("scene_params", {
		"god": params.get("god", "Apollo"),
		"deck_index": params.get("deck_index", 0),
		"map_data": params.get("map_data"),
		"returning_from_battle": true
	})
	
	TransitionManagerAutoload.change_scene_to("res://Scenes/RunMap.tscn")

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}
