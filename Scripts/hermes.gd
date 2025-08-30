extends Node2D

# Reference to the Hermes card collection
var hermes_collection: GodCardCollection
var selected_deck_index: int = -1  # -1 means no deck selected
var journal_button: JournalButton

# UI References
@onready var deck1_button = $MainContainer/LeftPanel/Deck1Button
@onready var deck2_button = $MainContainer/LeftPanel/Deck2Button
@onready var deck3_button = $MainContainer/LeftPanel/Deck3Button
@onready var start_game_button = $MainContainer/LeftPanel/StartGameButton
@onready var right_panel = $MainContainer/RightPanel
@onready var selected_deck_title = $MainContainer/RightPanel/DeckInfoContainer/DeckTitleContainer/SelectedDeckTitle
@onready var selected_deck_description = $MainContainer/RightPanel/DeckInfoContainer/DeckTitleContainer/SelectedDeckDescription
@onready var card_container = $MainContainer/RightPanel/CardsContainer/CardContainer

func _ready():
	print("=== HERMES SCENE STARTING ===")
	
	# Load the Hermes card collection
	hermes_collection = load("res://Resources/Collections/Hermes.tres")
	
	if not hermes_collection:
		print("ERROR: Failed to load Hermes collection!")
		# Try alternative loading method
		var collection_path = "res://Resources/Collections/Hermes.tres"
		if ResourceLoader.exists(collection_path):
			hermes_collection = ResourceLoader.load(collection_path)
			if hermes_collection:
				print("Hermes collection loaded with ResourceLoader")
			else:
				print("ResourceLoader also failed")
				return
		else:
			print("Hermes.tres file does not exist!")
			return
	
	print("Hermes collection loaded successfully")
	print("Cards: ", hermes_collection.cards.size())
	print("Decks: ", hermes_collection.decks.size())
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Update the deck button labels and unlock states
	if hermes_collection:
		setup_deck_buttons()
	
	# The StartGameButton should start disabled until a deck is selected
	start_game_button.disabled = true
	
	# Right panel starts hidden
	right_panel.visible = false
	
	setup_journal_button()


func _on_start_game_button_pressed() -> void:
	if selected_deck_index >= 0:
		# Only allow starting if deck is unlocked
		var deck_def = hermes_collection.decks[selected_deck_index]
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress("Hermes")
		if not deck_def.is_unlocked("Hermes", god_progress):
			print("Cannot start game - deck is locked!")
			return
		
		# Clear stat growth tracker for new run
		if has_node("/root/RunStatGrowthTrackerAutoload"):
			var growth_tracker = get_node("/root/RunStatGrowthTrackerAutoload")
			growth_tracker.clear_run()
			print("Cleared stat growth data for new run")
		
		# Initialize the experience tracker for this new run
		get_node("/root/RunExperienceTrackerAutoload").start_new_run(deck_def.card_indices)
		print("Initialized experience tracker for new run with deck: ", deck_def.deck_name)
		
		# Initialize boss prediction tracker
		get_node("/root/BossPredictionTrackerAutoload").clear_patterns()
		print("Initialized boss prediction tracker for new run")
		
		# Pass the selected god and deck index to the map scene
		get_tree().set_meta("scene_params", {
			"god": "Hermes",
			"deck_index": selected_deck_index
		})
		
		# Change to the map scene instead of directly to game
		TransitionManagerAutoload.change_scene_to("res://Scenes/RunMap.tscn")

func _on_button_pressed() -> void:
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")


func _on_deck_1_button_pressed() -> void:
	select_deck(0)


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
		
		print("Hermes: Journal button added with CanvasLayer")

# Set up deck buttons with unlock conditions
func setup_deck_buttons():
	print("=== SETTING UP DECK BUTTONS ===")
	
	if not hermes_collection:
		print("ERROR: Hermes collection is null in setup_deck_buttons!")
		return
	
	if hermes_collection.decks.size() == 0:
		print("ERROR: Hermes collection has no decks!")
		return
	
	var deck_buttons = [deck1_button, deck2_button, deck3_button]
	
	# Verify buttons exist
	for i in range(deck_buttons.size()):
		if not deck_buttons[i]:
			print("ERROR: Button ", i, " is null!")
			return
	
	print("Hermes collection has ", hermes_collection.decks.size(), " decks")
	
	# Get progress tracker
	var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	var god_progress = {}
	
	if progress_tracker:
		print("GlobalProgressTrackerAutoload found")
		god_progress = progress_tracker.get_god_progress("Hermes")
		print("God progress entries: ", god_progress.size())
	else:
		print("WARNING: GlobalProgressTrackerAutoload not found!")
	
	# Set up each button - but only for available decks
	for i in range(deck_buttons.size()):
		var button = deck_buttons[i]
		
		if i < hermes_collection.decks.size():
			# We have a deck for this button
			var deck_def = hermes_collection.decks[i]
			
			print("=== DECK ", i, " SETUP ===")
			print("Deck name: ", deck_def.deck_name)
			
			# Set button text to the actual deck name
			button.text = deck_def.deck_name
			button.visible = true
			print("Button text set to: ", button.text)
			
			# Check unlock status
			var is_unlocked = deck_def.is_unlocked("Hermes", god_progress)
			
			# Apply button styling
			if not is_unlocked:
				button.modulate = Color(0.6, 0.6, 0.6)
				button.disabled = false  # Keep clickable for requirement display
				print("Button styled as LOCKED")
			else:
				button.modulate = Color.WHITE
				button.disabled = false
				print("Button styled as UNLOCKED")
			
			print("Button ", i, " setup complete")
		else:
			# No deck for this button - hide it
			button.visible = false
			button.disabled = true
			print("Button ", i, " hidden (no corresponding deck)")
		
		print("=======================")
	
	print("=== DECK BUTTONS SETUP COMPLETE ===")


func select_deck(index: int) -> void:
	var deck_def = hermes_collection.decks[index]
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var god_progress = progress_tracker.get_god_progress("Hermes")
	var is_unlocked = deck_def.is_unlocked("Hermes", god_progress)
	
	selected_deck_index = index
	
	# Reset all buttons to normal appearance (only for unlocked decks)
	for i in range(hermes_collection.decks.size()):  # CHANGED: only loop through actual decks
		if i >= 3:  # Safety check - don't access buttons that don't exist
			break
			
		var button = [deck1_button, deck2_button, deck3_button][i]
		if not button or not button.visible:  # Skip hidden buttons
			continue
			
		var deck = hermes_collection.decks[i]
		if deck.is_unlocked("Hermes", god_progress):
			button.disabled = false
			button.modulate = Color.WHITE
			# IMPORTANT: Keep the original deck name, don't reset to generic text
			button.text = deck.deck_name  # This was missing!
		else:
			# Keep locked decks grayed out but clickable
			button.modulate = Color(0.6, 0.6, 0.6)
			button.disabled = false
			button.text = deck.deck_name  # This was missing!
	
	# Disable the selected button to show which is selected
	var button_array = [deck1_button, deck2_button, deck3_button]
	if index < button_array.size() and button_array[index].visible:
		var selected_button = button_array[index]
		selected_button.disabled = true
		# Make sure the selected button keeps its deck name too
		selected_button.text = deck_def.deck_name
	
	# Enable/disable start button based on whether deck is unlocked
	start_game_button.disabled = not is_unlocked
	
	# Display the deck info (works for both locked and unlocked)
	if is_unlocked:
		display_deck_cards(index)
	else:
		display_unlock_requirements(index)
	
	# Show the right panel
	right_panel.visible = true
	
	print("Selected deck: ", hermes_collection.decks[index].deck_name)
	if is_unlocked:
		print("Description: ", hermes_collection.decks[index].deck_description)
	else:
		print("Deck is locked - showing unlock requirements")

# Display unlock requirements for locked decks
func display_unlock_requirements(deck_index: int) -> void:
	if not hermes_collection or deck_index < 0 or deck_index >= hermes_collection.decks.size():
		return
	
	var deck_def = hermes_collection.decks[deck_index]
	
	# Update deck title and description
	selected_deck_title.text = deck_def.deck_name + " (LOCKED)"
	selected_deck_description.text = deck_def.deck_description
	
	# Clear existing content
	for child in card_container.get_children():
		child.queue_free()
	
	# Wait a frame to ensure old children are removed
	await get_tree().process_frame
	
	# Create unlock requirements display
	var requirements_panel = create_unlock_requirements_panel(deck_def)
	card_container.add_child(requirements_panel)

# Create a panel showing unlock requirements
func create_unlock_requirements_panel(deck_def: DeckDefinition) -> Control:
	# Main container
	var main_container = VBoxContainer.new()
	main_container.custom_minimum_size = Vector2(0, 150)
	
	# Create background panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#4A2D2D")  # Reddish background for locked
	style.border_color = Color("#8A4A4A")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	
	# Margin for content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	
	var content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 12)
	
	# Display requirements
	if deck_def.required_capture_exp > 0 or deck_def.required_defense_exp > 0:
		# Get current progress data
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress("Hermes")
		
		# Calculate current totals using unified experience
		var current_total_exp = 0
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			current_total_exp += card_exp.get("total_exp", 0)
		
		# Convert to combined requirement
		var required_total_exp = deck_def.required_capture_exp + deck_def.required_defense_exp
		
		var total_req = create_requirement_display(
			"⚡ Total Experience", 
			current_total_exp, 
			required_total_exp,
			Color("#FFD700")
		)
		content_container.add_child(total_req)
	else:
		# This shouldn't happen for non-starter decks, but just in case
		var error_label = Label.new()
		error_label.text = "No requirements defined"
		error_label.add_theme_color_override("font_color", Color("#AAAAAA"))
		content_container.add_child(error_label)
	
	# Assemble the structure
	margin.add_child(content_container)
	panel.add_child(margin)
	main_container.add_child(panel)
	
	return main_container

# Create a display for a single requirement (current/required)
func create_requirement_display(title: String, current: int, required: int, color: Color) -> Control:
	var req_container = VBoxContainer.new()
	
	# Title
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", color)
	req_container.add_child(title_label)
	
	# Progress container
	var progress_container = HBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 10)
	
	# Progress bar
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = required
	progress_bar.value = current
	progress_bar.custom_minimum_size = Vector2(200, 20)
	progress_bar.show_percentage = false
	
	# Style the progress bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#333333")
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color("#555555")
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	progress_container.add_child(progress_bar)
	
	# Progress text
	var progress_text = Label.new()
	progress_text.text = str(current) + " / " + str(required)
	progress_text.add_theme_font_size_override("font_size", 12)
	progress_text.add_theme_color_override("font_color", Color("#DDDDDD"))
	progress_container.add_child(progress_text)
	
	req_container.add_child(progress_container)
	
	return req_container

# Display the cards for the selected deck with experience info
func display_deck_cards(deck_index: int) -> void:
	if not hermes_collection or deck_index < 0 or deck_index >= hermes_collection.decks.size():
		return
	
	var deck_def = hermes_collection.decks[deck_index]
	
	# Update deck title and description
	selected_deck_title.text = deck_def.deck_name
	selected_deck_description.text = deck_def.deck_description
	
	var power_description = deck_def.get_power_description()
	if power_description != "":
		selected_deck_description.text += "\n\n" + power_description

	# Ensure the description label has proper text wrapping
	selected_deck_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_deck_description.clip_contents = true
	
	# Clear existing card displays
	for child in card_container.get_children():
		child.queue_free()
	
	# Wait a frame to ensure old children are removed
	await get_tree().process_frame
	
	# Create card displays for each card in the deck
	for i in range(deck_def.card_indices.size()):
		var card_index = deck_def.card_indices[i]
		if card_index < hermes_collection.cards.size():
			var card = hermes_collection.cards[card_index]
			var card_display = create_deck_card_display(card, card_index)
			card_container.add_child(card_display)

# Create a card display panel for deck preview - UNIFIED EXPERIENCE VERSION
func create_deck_card_display(card: CardResource, card_index: int) -> Control:
	# Main container for this card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 120)
	
	# Create a style for the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#3A3A3A")
	style.border_color = Color("#555555")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card_panel.add_theme_stylebox_override("panel", style)
	
	# Margin container for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card_panel.add_child(margin)
	
	# Main horizontal layout
	var h_container = HBoxContainer.new()
	margin.add_child(h_container)
	
	# Left side - Card info
	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_container.add_child(left_side)
	
	# Get current level for this card
	var current_level = 1
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		current_level = progress_tracker.get_card_level("Hermes", card_index)
	
	# Card name with level indicator
	var name_label = Label.new()
	name_label.text = card.card_name + " (Lv." + str(current_level) + ")"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	left_side.add_child(name_label)
	
	# Card values using effective values for current level
	var effective_values = card.get_effective_values(current_level)
	var values_container = HBoxContainer.new()
	left_side.add_child(values_container)
	
	var directions = ["N", "E", "S", "W"]
	for i in range(4):
		var dir_label = Label.new()
		dir_label.text = directions[i] + ":" + str(effective_values[i])
		dir_label.add_theme_font_size_override("font_size", 12)
		dir_label.add_theme_color_override("font_color", Color("#AAAAAA"))
		dir_label.custom_minimum_size.x = 35
		values_container.add_child(dir_label)
		
		# Add small spacer between values
		if i < 3:
			var spacer = Control.new()
			spacer.custom_minimum_size.x = 5
			values_container.add_child(spacer)
	
	# Separator
	var v_separator = VSeparator.new()
	h_container.add_child(v_separator)
	
	# Right side - Unified Experience info
	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_side.custom_minimum_size.x = 180
	h_container.add_child(right_side)
	
	# Experience title
	var exp_title = Label.new()
	exp_title.text = "Experience"
	exp_title.add_theme_font_size_override("font_size", 14)
	exp_title.add_theme_color_override("font_color", Color("#CCCCCC"))
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(exp_title)
	
	# Get experience data from GlobalProgressTracker - UNIFIED VERSION
	var total_exp = 0
	
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var exp_data = progress_tracker.get_card_total_experience("Hermes", card_index)
		total_exp = exp_data.get("total_exp", 0)
	
	# Show unified experience and level
	var exp_container = VBoxContainer.new()
	right_side.add_child(exp_container)
	
	var total_exp_label = Label.new()
	total_exp_label.text = "⚡ " + str(total_exp) + " Total XP"
	total_exp_label.add_theme_font_size_override("font_size", 12)
	total_exp_label.add_theme_color_override("font_color", Color("#FFD700"))
	total_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_container.add_child(total_exp_label)
	
	# Show level and progress
	var level_text = Label.new()
	level_text.text = ExperienceHelpers.format_level_display(total_exp)
	level_text.add_theme_font_size_override("font_size", 10)
	level_text.add_theme_color_override("font_color", Color("#CCCCCC"))
	level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_container.add_child(level_text)
	
	# Show next level requirements if not max level
	var next_level_exp = ExperienceHelpers.get_xp_to_next_level(total_exp)
	if next_level_exp > 0:
		var next_level_label = Label.new()
		next_level_label.text = str(next_level_exp) + " XP to next level"
		next_level_label.add_theme_font_size_override("font_size", 9)
		next_level_label.add_theme_color_override("font_color", Color("#AAAAAA"))
		next_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		exp_container.add_child(next_level_label)
	
	return card_panel
	
