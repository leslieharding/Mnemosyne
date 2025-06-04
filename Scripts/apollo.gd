extends Node2D

# Reference to the Apollo card collection
var apollo_collection: GodCardCollection
var selected_deck_index: int = -1  # -1 means no deck selected
var journal_button: JournalButton

# UI References
@onready var deck1_button = $MainContainer/LeftPanel/Deck1Button
@onready var deck2_button = $MainContainer/LeftPanel/Deck2Button
@onready var deck3_button = $MainContainer/LeftPanel/Deck3Button
@onready var start_game_button = $MainContainer/LeftPanel/StartGameButton
@onready var right_panel = $MainContainer/RightPanel
@onready var selected_deck_title = $MainContainer/RightPanel/DeckTitleContainer/SelectedDeckTitle
@onready var selected_deck_description = $MainContainer/RightPanel/DeckTitleContainer/SelectedDeckDescription
@onready var card_container = $MainContainer/RightPanel/ScrollContainer/CardContainer

func _ready():
	# Load the Apollo card collection
	apollo_collection = load("res://Resources/Collections/apollo.tres")
	
	# Update the deck button labels and unlock states
	if apollo_collection:
		setup_deck_buttons()
	
	# The StartGameButton should start disabled until a deck is selected
	start_game_button.disabled = true
	
	# Right panel starts hidden
	right_panel.visible = false
	
	setup_journal_button()


func setup_journal_button():
	journal_button = preload("res://Scenes/JournalButton.tscn").instantiate()
	add_child(journal_button)

# Set up deck buttons with unlock conditions
func setup_deck_buttons():
	var deck_buttons = [deck1_button, deck2_button, deck3_button]
	
	# DEBUG: Check what experience data we actually have
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress("Apollo")
		print("=== APOLLO PROGRESS DEBUG ===")
		print("Total god progress entries: ", god_progress.size())
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			print("Card ", card_index, ": Capture=", card_exp.get("capture_exp", 0), " Defense=", card_exp.get("defense_exp", 0))
	
	for i in range(apollo_collection.decks.size()):
		var deck_def = apollo_collection.decks[i]
		var button = deck_buttons[i]
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress("Apollo")
		var is_unlocked = deck_def.is_unlocked("Apollo", god_progress)
		
		# DEBUG: Show unlock calculation details for deck 1 only
		if i == 1:
			print("=== DECK 1 DEBUG ===")
			print("Required capture exp: ", deck_def.required_capture_exp)
			print("Current capture exp: ", deck_def.get_current_capture_exp("Apollo"))
			print("Is unlocked: ", is_unlocked)
		
		# Set button text
		button.text = deck_def.deck_name
		
		# Style button based on unlock status
		if not is_unlocked:
			# Gray out locked deck
			button.modulate = Color(0.6, 0.6, 0.6)
			button.disabled = false  # Keep enabled so they can still click to see requirements
		else:
			# Normal appearance for unlocked decks
			button.modulate = Color.WHITE
			button.disabled = false

# Back button
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# Connect these in the editor or use the existing connections
func _on_deck_1_button_pressed() -> void:
	select_deck(0)

func _on_deck_2_button_pressed() -> void:
	select_deck(1)

func _on_deck_3_button_pressed() -> void:
	select_deck(2)
	
func _on_start_game_button_pressed() -> void:
	if selected_deck_index >= 0:
		# Only allow starting if deck is unlocked
		var deck_def = apollo_collection.decks[selected_deck_index]
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress("Apollo")
		if not deck_def.is_unlocked("Apollo", god_progress):
			print("Cannot start game - deck is locked!")
			return
			
		# Initialize the experience tracker for this new run
		get_node("/root/RunExperienceTrackerAutoload").start_new_run(deck_def.card_indices)
		print("Initialized experience tracker for new run with deck: ", deck_def.deck_name)
		
		# Pass the selected god and deck index to the map scene
		get_tree().set_meta("scene_params", {
			"god": "Apollo",
			"deck_index": selected_deck_index
		})
		
		# Change to the map scene instead of directly to game
		get_tree().change_scene_to_file("res://Scenes/RunMap.tscn")
	
# Helper function to handle deck selection - now handles both locked and unlocked decks
func select_deck(index: int) -> void:
	var deck_def = apollo_collection.decks[index]
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var god_progress = progress_tracker.get_god_progress("Apollo")
	var is_unlocked = deck_def.is_unlocked("Apollo", god_progress)
	
	selected_deck_index = index
	
	# Reset all buttons to normal appearance (only for unlocked decks)
	for i in range(apollo_collection.decks.size()):
		var button = [deck1_button, deck2_button, deck3_button][i]
		var deck = apollo_collection.decks[i]
		if deck.is_unlocked("Apollo"):
			button.disabled = false
			button.modulate = Color.WHITE
		else:
			# Keep locked decks grayed out but clickable
			button.modulate = Color(0.6, 0.6, 0.6)
			button.disabled = false
	
	# Disable the selected button to show which is selected
	var selected_button = [deck1_button, deck2_button, deck3_button][index]
	selected_button.disabled = true
	
	# Enable/disable start button based on whether deck is unlocked
	start_game_button.disabled = not is_unlocked
	
	# Display the deck info (works for both locked and unlocked)
	if is_unlocked:
		display_deck_cards(index)
	else:
		display_unlock_requirements(index)
	
	# Show the right panel
	right_panel.visible = true
	
	print("Selected deck: ", apollo_collection.decks[index].deck_name)
	if is_unlocked:
		print("Description: ", apollo_collection.decks[index].deck_description)
	else:
		print("Deck is locked - showing unlock requirements")

# Display unlock requirements for locked decks
func display_unlock_requirements(deck_index: int) -> void:
	if not apollo_collection or deck_index < 0 or deck_index >= apollo_collection.decks.size():
		return
	
	var deck_def = apollo_collection.decks[deck_index]
	
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
		var god_progress = progress_tracker.get_god_progress("Apollo")
		
		# Calculate current totals
		var current_capture_exp = 0
		var current_defense_exp = 0
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			current_capture_exp += card_exp.get("capture_exp", 0)
			current_defense_exp += card_exp.get("defense_exp", 0)
		
		if deck_def.required_capture_exp > 0:
			var capture_req = create_requirement_display(
				"⚔️ Capture Experience", 
				current_capture_exp, 
				deck_def.required_capture_exp,
				Color("#FFD700")
			)
			content_container.add_child(capture_req)
		
		if deck_def.required_defense_exp > 0:
			var defense_req = create_requirement_display(
				"🛡️ Defense Experience", 
				current_defense_exp, 
				deck_def.required_defense_exp,
				Color("#87CEEB")
			)
			content_container.add_child(defense_req)
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

# Display the cards for the selected deck with experience info (existing function, unchanged)
func display_deck_cards(deck_index: int) -> void:
	if not apollo_collection or deck_index < 0 or deck_index >= apollo_collection.decks.size():
		return
	
	var deck_def = apollo_collection.decks[deck_index]
	
	# Update deck title and description
	selected_deck_title.text = deck_def.deck_name
	selected_deck_description.text = deck_def.deck_description
	
	# Clear existing card displays
	for child in card_container.get_children():
		child.queue_free()
	
	# Wait a frame to ensure old children are removed
	await get_tree().process_frame
	
	# Create card displays for each card in the deck
	for i in range(deck_def.card_indices.size()):
		var card_index = deck_def.card_indices[i]
		if card_index < apollo_collection.cards.size():
			var card = apollo_collection.cards[card_index]
			var card_display = create_deck_card_display(card, card_index)
			card_container.add_child(card_display)

# Create a card display panel for deck preview (existing function, unchanged)
func create_deck_card_display(card: CardResource, card_index: int) -> Control:
	# Main container for this card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 120)  # Slightly taller for progress bars
	
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
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	left_side.add_child(name_label)
	
	# Card values in a compact format
	var values_container = HBoxContainer.new()
	left_side.add_child(values_container)
	
	var directions = ["N", "E", "S", "W"]
	for i in range(4):
		var dir_label = Label.new()
		dir_label.text = directions[i] + ":" + str(card.values[i])
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
	
	# Right side - Experience info with level display
	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_side.custom_minimum_size.x = 180  # Slightly wider for level display
	h_container.add_child(right_side)
	
	# Experience title
	var exp_title = Label.new()
	exp_title.text = "Experience"
	exp_title.add_theme_font_size_override("font_size", 14)
	exp_title.add_theme_color_override("font_color", Color("#CCCCCC"))
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(exp_title)
	
	# Get experience data from GlobalProgressTracker
	var capture_exp = 0
	var defense_exp = 0
	
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var exp_data = progress_tracker.get_card_total_experience("Apollo", card_index)
		capture_exp = exp_data.get("capture_exp", 0)
		defense_exp = exp_data.get("defense_exp", 0)
	
	# Capture experience level display
	var capture_container = VBoxContainer.new()
	right_side.add_child(capture_container)
	
	var capture_label = Label.new()
	capture_label.text = "⚔️ Capture"
	capture_label.add_theme_font_size_override("font_size", 11)
	capture_label.add_theme_color_override("font_color", Color("#FFD700"))
	capture_container.add_child(capture_label)
	
	# Show level and progress for capture
	var capture_text = Label.new()
	capture_text.text = ExperienceHelpers.format_level_display(capture_exp)
	capture_text.add_theme_font_size_override("font_size", 10)
	capture_text.add_theme_color_override("font_color", Color("#FFD700"))
	capture_container.add_child(capture_text)
	
	# Small spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 5
	right_side.add_child(spacer)
	
	# Defense experience level display
	var defense_container = VBoxContainer.new()
	right_side.add_child(defense_container)
	
	var defense_label = Label.new()
	defense_label.text = "🛡️ Defense"
	defense_label.add_theme_font_size_override("font_size", 11)
	defense_label.add_theme_color_override("font_color", Color("#87CEEB"))
	defense_container.add_child(defense_label)
	
	# Show level and progress for defense
	var defense_text = Label.new()
	defense_text.text = ExperienceHelpers.format_level_display(defense_exp)
	defense_text.add_theme_font_size_override("font_size", 10)
	defense_text.add_theme_color_override("font_color", Color("#87CEEB"))
	defense_container.add_child(defense_text)
	
	return card_panel
