extends Node2D

# Reference to the Apollo card collection
var apollo_collection: GodCardCollection
var selected_deck_index: int = -1  # -1 means no deck selected

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
	
	# Update the deck button labels with actual deck names
	if apollo_collection:
		deck1_button.text = apollo_collection.decks[0].deck_name
		deck2_button.text = apollo_collection.decks[1].deck_name
		deck3_button.text = apollo_collection.decks[2].deck_name
	
	# The StartGameButton should start disabled until a deck is selected
	start_game_button.disabled = true
	
	# Right panel starts hidden
	right_panel.visible = false

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
		# Initialize the experience tracker for this new run
		var deck_def = apollo_collection.decks[selected_deck_index]
		get_node("/root/RunExperienceTrackerAutoload").start_new_run(deck_def.card_indices)
		print("Initialized experience tracker for new run with deck: ", deck_def.deck_name)
		
		# Pass the selected god and deck index to the map scene
		get_tree().set_meta("scene_params", {
			"god": "Apollo",
			"deck_index": selected_deck_index
		})
		
		# Change to the map scene instead of directly to game
		get_tree().change_scene_to_file("res://Scenes/RunMap.tscn")
	
# Helper function to handle deck selection
func select_deck(index: int) -> void:
	selected_deck_index = index
	
	# Reset all buttons to normal appearance
	deck1_button.disabled = false
	deck2_button.disabled = false
	deck3_button.disabled = false
	
	# Disable the selected button to show which is selected
	match index:
		0: deck1_button.disabled = true
		1: deck2_button.disabled = true
		2: deck3_button.disabled = true
	
	# Enable the start button now that a deck is selected
	start_game_button.disabled = false
	
	# Display the deck cards and info
	display_deck_cards(index)
	
	# Show the right panel
	right_panel.visible = true
	
	# Optionally, you could display the deck description somewhere
	print("Selected deck: ", apollo_collection.decks[index].deck_name)
	print("Description: ", apollo_collection.decks[index].deck_description)

# Display the cards for the selected deck with experience info
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

# Create a card display panel for deck preview
func create_deck_card_display(card: CardResource, card_index: int) -> Control:
	# Main container for this card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 100)
	
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
	
	# Right side - Experience info
	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_side.custom_minimum_size.x = 150
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
	
	# Experience display
	var exp_container = HBoxContainer.new()
	exp_container.alignment = BoxContainer.ALIGNMENT_CENTER
	right_side.add_child(exp_container)
	
	# Capture experience
	var capture_label = Label.new()
	capture_label.text = "⚔️ " + str(capture_exp)
	capture_label.add_theme_font_size_override("font_size", 12)
	capture_label.add_theme_color_override("font_color", Color("#FFD700"))  # Gold
	exp_container.add_child(capture_label)
	
	# Small spacer
	var exp_spacer = Control.new()
	exp_spacer.custom_minimum_size.x = 10
	exp_container.add_child(exp_spacer)
	
	# Defense experience
	var defense_label = Label.new()
	defense_label.text = "🛡️ " + str(defense_exp)
	defense_label.add_theme_font_size_override("font_size", 12)
	defense_label.add_theme_color_override("font_color", Color("#87CEEB"))  # Sky blue
	exp_container.add_child(defense_label)
	
	# Total experience
	var total_exp = capture_exp + defense_exp
	var total_label = Label.new()
	total_label.text = "Total: " + str(total_exp)
	total_label.add_theme_font_size_override("font_size", 11)
	total_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(total_label)
	
	return card_panel
