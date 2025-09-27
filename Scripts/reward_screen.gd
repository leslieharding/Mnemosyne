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

# UI components we'll create
var cards_container: HBoxContainer
var card_displays: Array[CardDisplay] = []
var experience_button: Button  # Single unified experience button
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
	create_card_displays_sync(god_name)
	
	# Update Mnemosyne button with current level info
	update_mnemosyne_button_text()

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
	card_section.custom_minimum_size = Vector2(900, 200)
	card_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var card_label = Label.new()
	card_label.text = "Select a card to enhance:"
	card_label.add_theme_font_size_override("font_size", 16)
	card_label.add_theme_color_override("font_color", Color.WHITE)
	card_section.add_child(card_label)
	
	# Container for card displays with explicit sizing
	cards_container = HBoxContainer.new()
	cards_container.name = "CardsContainer"
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	cards_container.custom_minimum_size = Vector2(900, 160)
	cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_section.add_child(cards_container)
	
	# Unified experience section with explicit sizing
	var exp_section = VBoxContainer.new()
	exp_section.name = "ExperienceSection"
	exp_section.custom_minimum_size = Vector2(400, 100)
	exp_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var exp_label = Label.new()
	exp_label.text = "Enhance selected card:"
	exp_label.add_theme_font_size_override("font_size", 16)
	exp_label.add_theme_color_override("font_color", Color.WHITE)
	exp_section.add_child(exp_label)
	
	var exp_button_container = HBoxContainer.new()
	exp_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	exp_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Single unified experience button
	experience_button = Button.new()
	experience_button.text = "⚡ +15 Experience"
	experience_button.disabled = true
	experience_button.custom_minimum_size = Vector2(200, 40)
	experience_button.pressed.connect(_on_experience_button_pressed)
	exp_button_container.add_child(experience_button)
	
	exp_section.add_child(exp_button_container)
	
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
	reward_info_label.text = "Loading deck..."
	reward_info_label.add_theme_font_size_override("font_size", 12)
	reward_info_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	reward_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_info_label.custom_minimum_size = Vector2(400, 30)
	
	# Add everything to the main container before continue button
	var continue_button_index = main_container.get_children().find(continue_button)
	print("Continue button found at index: ", continue_button_index)
	
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

func create_card_displays_sync(god_name: String):
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
		
		# Add to main container first so it's in the scene tree
		card_with_exp_container.add_child(card_wrapper)
		cards_container.add_child(card_with_exp_container)
		
		# Wait one frame to ensure the card display is fully ready before setup
		await get_tree().process_frame
		
		# Setup the card - CALCULATE LEVEL DIRECTLY HERE
		var current_level = 1  # Default level
		
		# Calculate level directly without using CardLevelHelper
		if god_name == "Mnemosyne":
			var memory_manager = get_node_or_null("/root/MemoryJournalManagerAutoload")
			if memory_manager:
				var mnemosyne_data = memory_manager.get_mnemosyne_memory()
				current_level = mnemosyne_data.get("consciousness_level", 1)
		else:
			var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
			if global_tracker:
				current_level = global_tracker.get_card_level(god_name, card_index)
		
		# Create card data with effective values including growth
		var display_card_data = card.duplicate()
		var effective_values = card.get_effective_values(current_level)
		
		var growth_tracker = get_node_or_null("/root/RunStatGrowthTrackerAutoload")
		if growth_tracker:
			effective_values = growth_tracker.apply_growth_to_card_values(effective_values, card_index)
			print("Applied growth to card ", card.card_name, " - values with growth: ", effective_values)
		
		# Apply the values with growth to the display card
		display_card_data.values = effective_values.duplicate()
		display_card_data.abilities = card.get_effective_abilities(current_level).duplicate()
		
		# Debug: Print what we're setting up
		print("Setting up card display with:")
		print("  Card: ", card.card_name)
		print("  Level: ", current_level)
		print("  God: ", god_name)
		print("  Index: ", card_index)
		print("  Final values (with growth): ", display_card_data.values)
		
		# Setup with the modified card data
		card_display.setup(display_card_data, current_level, god_name, card_index)
		
		# Double-check the setup worked
		if card_display.card_data:
			print("Card display setup successful - card_data.card_name: ", card_display.card_data.card_name)
		else:
			print("ERROR: Card display card_data is null after setup!")
		
		# Force an update of the display
		card_display.update_display()
		
		# Center the card within its wrapper
		card_display.position = Vector2(5, 5)
		
		# Create experience info display - UPDATED FOR UNIFIED SYSTEM
		var exp_info_container = create_unified_experience_info_display(card_index, tracker, god_name)
		
		# Add exp info to the horizontal container
		card_with_exp_container.add_child(exp_info_container)
		
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

# UPDATED: Create unified experience info display
func create_unified_experience_info_display(card_index: int, tracker, god_name: String) -> Control:
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
		
		# Total experience gained this run (combine capture + defense)
		var run_total_exp = exp_data.get("total_exp", 0)
		var run_total_label = Label.new()
		run_total_label.text = "⚡ +" + str(run_total_exp)
		run_total_label.add_theme_font_size_override("font_size", 14)
		run_total_label.add_theme_color_override("font_color", Color("#FFD700"))
		run_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(run_total_label)
		
		# Show breakdown if desired (smaller text)
		var breakdown_label = Label.new()
		breakdown_label.text = "(" + str(exp_data.get("capture_exp", 0)) + " + " + str(exp_data.get("defense_exp", 0)) + ")"
		breakdown_label.add_theme_font_size_override("font_size", 8)
		breakdown_label.add_theme_color_override("font_color", Color("#AAAAAA"))
		breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(breakdown_label)
		
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
		var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
		if global_tracker and is_instance_valid(global_tracker):
			var total_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
			var total_exp = total_exp_data.get("total_exp", 0)
			
			# Total experience
			var total_exp_label = Label.new()
			total_exp_label.text = "⚡ " + str(total_exp)
			total_exp_label.add_theme_font_size_override("font_size", 12)
			total_exp_label.add_theme_color_override("font_color", Color("#B8860B"))
			total_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			exp_container.add_child(total_exp_label)
			
			# Add level display for quick reference
			if total_exp > 0:
				var level = ExperienceHelpers.calculate_level(total_exp)
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
	
	# Get the Mnemosyne tracker
	var tracker = get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	if not tracker:
		print("MnemosyneProgressTracker not found for button update")
		mnemosyne_button.text = "🧠 Mnemosyne Progress\n(Tracker Unavailable)"
		return
	
	var params = get_scene_params()
	var god_name = params.get("god", "Apollo")
	var deck_index = params.get("deck_index", 0)
	
	# Check if this god/deck can contribute
	if not tracker.can_contribute(god_name, deck_index):
		mnemosyne_button.text = "🧠 Mnemosyne Progress\n" + god_name + " Deck " + str(deck_index) + " - Max Contributions Reached"
		mnemosyne_button.disabled = true
		return
	
	var remaining = tracker.get_remaining_contributions(god_name, deck_index)
	var next_upgrade = tracker.get_next_upgrade_info()
	
	if next_upgrade.is_empty():
		mnemosyne_button.text = "🧠 Mnemosyne Progress\n(Max Level Reached)"
		mnemosyne_button.disabled = true
		return
	
	mnemosyne_button.text = "🧠 Mnemosyne Progress\n" + "Next: " + next_upgrade["card_name"] + " " + next_upgrade["stat_name"] + " (" + str(remaining) + " left)"


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
		
		# Enable experience button
		print("Enabling experience button...")
		print("  Experience button before: disabled = ", experience_button.disabled)
		
		experience_button.disabled = false
		
		print("  Experience button after: disabled = ", experience_button.disabled)
		
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

# UPDATED: Single experience button handler
func _on_experience_button_pressed():
	print("Experience button pressed - selected_card_index: ", selected_card_index, ", rewards_remaining: ", rewards_remaining)
	if selected_card_index == -1 or rewards_remaining <= 0:
		print("Cannot apply experience reward - no card selected or no rewards remaining")
		return
	
	apply_unified_experience_reward()

func _on_mnemosyne_button_pressed():
	if rewards_remaining <= 0:
		print("No rewards remaining, cannot claim Mnemosyne reward")
		return
	
	apply_mnemosyne_reward()

# UPDATED: Apply unified experience reward
func apply_unified_experience_reward():
	var card_index = deck_indices[selected_card_index]
	var card_name = current_deck[selected_card_index].card_name
	var bonus_amount = 15
	
	# Check if tracker exists
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	if not tracker:
		print("RunExperienceTrackerAutoload not found!")
		return
	
	# For the unified system, we'll add to the total_exp directly
	# The tracker should handle this properly
	if tracker.has_method("add_total_exp"):
		tracker.add_total_exp(card_index, bonus_amount)
	else:
		# Fallback: add to capture_exp (which should update total_exp)
		tracker.add_capture_exp(card_index, bonus_amount)
	
	# Track this reward
	var reward_desc = card_name + " +" + str(bonus_amount) + " Experience"
	claimed_rewards.append(reward_desc)
	rewards_remaining -= 1
	
	# Reset selection state for next reward
	selected_card_index = -1
	
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
	# Check if tracker exists
	var tracker = get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	if not tracker:
		print("MnemosyneProgressTracker not found!")
		return
	
	var params = get_scene_params()
	var god_name = params.get("god", "Apollo")
	var deck_index = params.get("deck_index", 0)
	
	# Check if this god/deck can contribute
	if not tracker.can_contribute(god_name, deck_index):
		print("Cannot apply Mnemosyne reward - contribution limit reached for ", god_name, " deck ", deck_index)
		return
	
	# Get upgrade info before applying (for feedback)
	var upgrade_info = tracker.get_next_upgrade_info()
	if upgrade_info.is_empty():
		print("No more Mnemosyne upgrades available")
		return
	
	# Apply the contribution
	if tracker.apply_contribution(god_name, deck_index):
		# FIX: Convert stat_index to stat_name
		var stat_names = ["North", "East", "South", "West"]
		var stat_name = stat_names[upgrade_info["stat_index"]]
		var reward_desc = "Mnemosyne: " + upgrade_info["card_name"] + " " + stat_name + " upgraded"
		claimed_rewards.append(reward_desc)
		rewards_remaining -= 1
		
		print("Applied Mnemosyne reward: ", reward_desc)
		
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
	else:
		print("Failed to apply Mnemosyne contribution")

func update_for_next_reward():
	# Re-enable reward options for next selection
	experience_button.disabled = true  # Will be enabled when card is selected
	
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
	experience_button.disabled = true
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
