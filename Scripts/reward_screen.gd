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
var reward_claimed: bool = false

# UI components we'll create
var cards_container: HBoxContainer
var card_displays: Array[CardDisplay] = []
var capture_button: Button
var defense_button: Button
var mnemosyne_button: Button
var reward_info_label: Label

func _ready():
	# Connect the continue button first
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.disabled = true
		continue_button.text = "Choose a Reward"
	else:
		print("Error: Continue button not found!")
		return
	
	# Wait a frame to ensure all @onready variables are initialized
	await get_tree().process_frame
	
	# Setup the interface
	setup_reward_interface()
	
	# Load deck data
	await safe_load_deck_data()

func safe_load_deck_data():
	# Double-check we're still in the tree
	if not get_tree():
		print("Error: Node not in scene tree during safe_load_deck_data!")
		return
	
	await load_deck_data()



func setup_reward_interface():
	print("Setting up reward interface...")
	print("Main container children before setup: ", main_container.get_child_count())
	
	# Update title
	title_label.text = "Choose Your Reward"
	
	# Create a test label to see if anything shows up
	var test_label = Label.new()
	test_label.text = "TEST LABEL - IF YOU SEE THIS, DYNAMIC UI IS WORKING"
	test_label.add_theme_font_size_override("font_size", 20)
	test_label.add_theme_color_override("font_color", Color.RED)
	main_container.add_child(test_label)
	
	print("Test label added - check if visible on screen")
	
	# Create card selection area with explicit sizing
	var card_section = VBoxContainer.new()
	card_section.name = "CardSection"
	card_section.custom_minimum_size = Vector2(600, 200)  # Give it a minimum size
	card_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var card_label = Label.new()
	card_label.text = "Select a card to enhance:"
	card_label.add_theme_font_size_override("font_size", 16)
	card_label.add_theme_color_override("font_color", Color.WHITE)  # Make sure it's visible
	card_section.add_child(card_label)
	
	# Container for card displays with explicit sizing
	cards_container = HBoxContainer.new()
	cards_container.name = "CardsContainer"
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 10)
	cards_container.custom_minimum_size = Vector2(500, 150)  # Give it a minimum size
	cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var collection_path = "res://Resources/Collections/" + god_name.to_lower() + ".tres"
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
	await create_card_displays_safe()
	
	# Update Mnemosyne button with current level info
	update_mnemosyne_button_text()

func create_card_displays_safe():
	# Safety check
	if not get_tree():
		print("Error: No scene tree in create_card_displays_safe")
		return
	
	# Clear existing displays
	for display in card_displays:
		if is_instance_valid(display):
			display.queue_free()
	card_displays.clear()
	
	# Get tracker safely
	var tracker = null
	if get_tree().has_node("/root/RunExperienceTrackerAutoload"):
		tracker = get_tree().get_node("/root/RunExperienceTrackerAutoload")
	
	if not tracker:
		print("RunExperienceTrackerAutoload not found! Creating cards without experience data.")
	
	# Create display for each card
	for i in range(current_deck.size()):
		var card = current_deck[i]
		var card_index = deck_indices[i]
		
		print("Creating display for card: ", card.card_name)
		
		# Create card display
		var card_display = preload("res://Scenes/CardDisplay.tscn").instantiate()
		cards_container.add_child(card_display)
		
		# Wait for ready
		await get_tree().process_frame
		
		# Setup the card
		card_display.setup(card)
		
		# Add experience info overlay (only if tracker exists)
		if tracker:
			add_experience_overlay_safe(card_display, card_index, tracker)
		
		# Connect selection safely
		if card_display.panel:
			card_display.panel.gui_input.connect(_on_card_selected.bind(i))
		else:
			print("Warning: Card display panel is null for card ", i)
		
		# Store reference
		card_displays.append(card_display)
	
	print("Created ", card_displays.size(), " card displays")

func add_experience_overlay_safe(card_display: CardDisplay, card_index: int, tracker):
	# Verify tracker is still valid
	if not is_instance_valid(tracker):
		print("Tracker is no longer valid, skipping overlay")
		return
	
	# Get current run experience for this card
	var exp_data = tracker.get_card_experience(card_index)
	
	# Create overlay container
	var overlay = VBoxContainer.new()
	overlay.name = "ExperienceOverlay"
	overlay.position = Vector2(5, 5)
	overlay.add_theme_constant_override("separation", 2)
	
	# Capture experience label
	var capture_label = Label.new()
	capture_label.text = "⚔️+" + str(exp_data["capture_exp"])
	capture_label.add_theme_font_size_override("font_size", 10)
	capture_label.add_theme_color_override("font_color", Color("#FFD700"))
	overlay.add_child(capture_label)
	
	# Defense experience label  
	var defense_label = Label.new()
	defense_label.text = "🛡️+" + str(exp_data["defense_exp"])
	defense_label.add_theme_font_size_override("font_size", 10)
	defense_label.add_theme_color_override("font_color", Color("#87CEEB"))
	overlay.add_child(defense_label)
	
	# Add to card panel safely
	if card_display.panel:
		card_display.panel.add_child(overlay)
		overlay.z_index = 10
	else:
		print("Warning: Card display panel is null, cannot add overlay")

func update_mnemosyne_button_text():
	# Safety check
	if not get_tree():
		print("Error: No scene tree in update_mnemosyne_button_text")
		return
	
	if not get_tree().has_node("/root/MemoryJournalManagerAutoload"):
		print("MemoryJournalManagerAutoload not found for Mnemosyne button update")
		mnemosyne_button.text = "🧠 Consciousness Boost\n(Memory Manager Unavailable)"
		return
	
	var memory_manager = get_tree().get_node("/root/MemoryJournalManagerAutoload")
	var mnemosyne_data = memory_manager.get_mnemosyne_memory()
	var current_level = mnemosyne_data.get("consciousness_level", 1)
	var current_desc = memory_manager.get_consciousness_description(current_level)
	var next_desc = memory_manager.get_consciousness_description(current_level + 1)
	
	mnemosyne_button.text = "🧠 Consciousness Boost\n" + current_desc + " → " + next_desc

func _on_card_selected(card_index: int):
	if reward_claimed:
		return
	
	# Deselect all cards
	for i in range(card_displays.size()):
		if is_instance_valid(card_displays[i]):
			card_displays[i].deselect()
	
	# Select this card
	if card_index < card_displays.size() and is_instance_valid(card_displays[card_index]):
		card_displays[card_index].select()
		selected_card_index = card_index
		
		# Enable experience buttons
		capture_button.disabled = false
		defense_button.disabled = false
		
		# Update info
		var card_name = current_deck[card_index].card_name
		reward_info_label.text = "Selected: " + card_name
		
		# Disable Mnemosyne button when card is selected
		mnemosyne_button.disabled = true
		
		print("Selected card: ", card_name)

func _on_capture_button_pressed():
	if selected_card_index == -1 or reward_claimed:
		return
	
	apply_experience_reward("capture")

func _on_defense_button_pressed():
	if selected_card_index == -1 or reward_claimed:
		return
	
	apply_experience_reward("defense")

func _on_mnemosyne_button_pressed():
	if reward_claimed:
		return
	
	apply_mnemosyne_reward()

func apply_experience_reward(exp_type: String):
	var card_index = deck_indices[selected_card_index]
	var card_name = current_deck[selected_card_index].card_name
	var bonus_amount = 15
	
	# Check if tracker exists
	if not has_node("/root/RunExperienceTrackerAutoload"):
		print("RunExperienceTrackerAutoload not found!")
		return
	
	# Apply to run tracker
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	if exp_type == "capture":
		tracker.add_capture_exp(card_index, bonus_amount)
	else:
		tracker.add_defense_exp(card_index, bonus_amount)
	
	# Update UI
	reward_claimed = true
	continue_button.disabled = false
	continue_button.text = "Continue"
	
	# Disable all reward options
	capture_button.disabled = true
	defense_button.disabled = true
	mnemosyne_button.disabled = true
	
	# Update info label
	var exp_icon = "⚔️" if exp_type == "capture" else "🛡️"
	var exp_name = exp_type.capitalize()
	reward_info_label.text = "Reward Applied: " + card_name + " gained " + str(bonus_amount) + " " + exp_name + " XP!"
	reward_info_label.add_theme_color_override("font_color", Color("#66BB6A"))
	
	print("Applied ", bonus_amount, " ", exp_type, " experience to ", card_name)

func apply_mnemosyne_reward():
	# Check if memory manager exists
	if not has_node("/root/MemoryJournalManagerAutoload"):
		print("MemoryJournalManagerAutoload not found!")
		return
	
	# Apply consciousness boost
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var boost_amount = 3  # Equivalent to 3 battles worth of progress
	memory_manager.add_memory_fragments(boost_amount)
	
	# Force consciousness level recalculation by adding battles
	var current_battles = memory_manager.get_mnemosyne_memory()["total_battles"]
	# Temporarily boost battle count to trigger level up, then restore
	memory_manager.memory_data["mnemosyne"]["total_battles"] += boost_amount
	var new_level = memory_manager.calculate_mnemosyne_consciousness_level()
	memory_manager.memory_data["mnemosyne"]["consciousness_level"] = new_level
	memory_manager.memory_data["mnemosyne"]["total_battles"] = current_battles  # Restore original
	
	memory_manager.save_memory_data()
	
	# Update UI
	reward_claimed = true
	continue_button.disabled = false
	continue_button.text = "Continue"
	
	# Disable all reward options
	capture_button.disabled = true
	defense_button.disabled = true
	mnemosyne_button.disabled = true
	
	# Deselect any card
	for display in card_displays:
		if is_instance_valid(display):
			display.deselect()
	
	# Update info label
	reward_info_label.text = "Reward Applied: Mnemosyne's consciousness has expanded!"
	reward_info_label.add_theme_color_override("font_color", Color("#DDA0DD"))
	
	print("Applied consciousness boost to Mnemosyne")

func _on_continue_pressed():
	if not reward_claimed:
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
	
	get_tree().change_scene_to_file("res://Scenes/RunMap.tscn")

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}
