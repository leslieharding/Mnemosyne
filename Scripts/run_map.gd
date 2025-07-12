# res://Scripts/run_map.gd
extends Node2D

# UI References
@onready var map_container = $MapContainer
@onready var title_label = $UI/VBoxContainer/Title
@onready var progress_label = $UI/VBoxContainer/ProgressLabel
@onready var back_button = $UI/VBoxContainer/BackButton

# Map data
var current_map: MapData
var map_node_buttons: Array[Button] = []

# Run state - we'll get this from the previous scene
var selected_god: String = "Apollo"
var selected_deck_index: int = 0

# Experience panel reference
var exp_panel: ExpPanel

# Journal button reference
var journal_button: JournalButton

func _ready():
	# Connect back button
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Get run parameters from previous scene
	get_run_parameters()
	
	# Add experience panel
	setup_experience_panel()
	
	# Check if we're returning from a battle or starting fresh
	var params = get_scene_params()
	if params.has("returning_from_battle") and params.has("map_data"):
		# Returning from battle - use existing map data
		current_map = params.map_data
		display_map()
	else:
		# Starting fresh - generate new map
		generate_new_map()
	
	# Update UI
	update_ui()
	setup_journal_button()

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
		
		print("Run Map: Journal button added with CanvasLayer")


# Get parameters passed from the deck selection scene
func get_run_parameters():
	var params = get_scene_params()
	if params.has("god"):
		selected_god = params.god
	if params.has("deck_index"):
		selected_deck_index = params.deck_index
	
	print("Starting run with: ", selected_god, " deck ", selected_deck_index)

# Add new function to set up experience panel
func setup_experience_panel():
	# Only show if we have deck data
	var params = get_scene_params()
	if not params.has("deck_index"):
		return
		
	# Create experience panel
	exp_panel = preload("res://Scenes/ExpPanel.tscn").instantiate()
	exp_panel.position = Vector2(900, 10)
	$UI.add_child(exp_panel)
	
	# Load the deck to display
	var apollo_collection = load("res://Resources/Collections/Apollo.tres")
	if apollo_collection and params.has("deck_index"):
		var deck = apollo_collection.get_deck(params.deck_index)
		var deck_def = apollo_collection.decks[params.deck_index]
		exp_panel.setup_deck(deck, deck_def.card_indices)

# Generate a new map for this run
func generate_new_map():
	current_map = MapGenerator.generate_map()
	display_map()

# Display the map visually
func display_map():
	# Clear any existing map nodes
	clear_map_display()
	
	# Create visual nodes for each map node
	for map_node in current_map.nodes:
		create_map_node_button(map_node)

# Clear existing map display
func clear_map_display():
	for button in map_node_buttons:
		if is_instance_valid(button):
			button.queue_free()
	map_node_buttons.clear()

# Create a visual button for a map node
func create_map_node_button(map_node: MapNode):
	# Create the button
	var button = Button.new()
	button.text = map_node.display_name
	button.custom_minimum_size = Vector2(80, 60)
	
	# Position the button based on the map node's position
	button.position = map_node.position
	
	# Style the button based on node type and availability
	style_map_node_button(button, map_node)
	
	# Connect the button press
	button.pressed.connect(_on_map_node_pressed.bind(map_node))
	
	# Add to the scene and track it
	map_container.add_child(button)
	map_node_buttons.append(button)

# Replace the style_map_node_button function (around lines 150-200)

# Style a map node button based on its state
func style_map_node_button(button: Button, map_node: MapNode):
	# Create custom style based on node state
	var style = StyleBoxFlat.new()
	
	# Base styling
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# Color and state based styling
	if map_node.is_completed:
		# Completed nodes - green
		style.bg_color = Color("#2D5A2D")
		style.border_color = Color("#4A8A4A")
		button.disabled = true
		button.text += " ✓"
		button.modulate.a = 1.0
	elif map_node.is_available:
		# Available nodes - blue/white
		style.bg_color = Color("#2D4A5A")
		style.border_color = Color("#4A7A8A")
		button.disabled = false
		button.modulate.a = 1.0
	else:
		# Unavailable nodes - gray
		style.bg_color = Color("#3A3A3A")
		style.border_color = Color("#5A5A5A")
		button.disabled = true
		button.modulate.a = 0.6
	
	# Node type specific styling
	match map_node.node_type:
		MapNode.NodeType.BATTLE:
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		MapNode.NodeType.BOSS:
			style.bg_color = Color("#5A2D2D")  # Reddish for boss
			style.border_color = Color("#8A4A4A")
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			button.text += " 👑"
	
	# Add enemy info to button text and tooltip
	if map_node.enemy_name != "" and map_node.enemy_difficulty >= 0:
		var difficulty_text = ""
		match map_node.enemy_difficulty:
			0: difficulty_text = "Novice"
			1: difficulty_text = "Adept"
			2: difficulty_text = "Master"
		
		# Update button text to include enemy info
		if not button.text.contains("✓"):
			button.text = map_node.display_name + "\n" + map_node.enemy_name
		
		# Set tooltip with more detailed info
		button.tooltip_text = map_node.enemy_name + " (" + difficulty_text + ")"
	
	# Apply the style
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

# Handle map node button press
func _on_map_node_pressed(map_node: MapNode):
	print("Selected map node: ", map_node.display_name, " (ID: ", map_node.node_id, ")")
	
	# Check if the node is actually available
	if not (map_node.is_available or map_node.can_be_accessed(current_map.completed_nodes)):
		print("Node is not available!")
		return
	
	# Mark this node as completed (for now, since all encounters are battles)
	current_map.complete_node(map_node.node_id)
	
	# Pass all necessary data to the battle scene
	get_tree().set_meta("scene_params", {
		"god": selected_god,
		"deck_index": selected_deck_index,
		"map_data": current_map,
		"current_node": map_node
	})
	
	# For now, all nodes lead to battle - later we'll check node type
	match map_node.node_type:
		MapNode.NodeType.BATTLE, MapNode.NodeType.BOSS:
			get_tree().change_scene_to_file("res://Scenes/CardBattle.tscn")
		_:
			# Future: handle other node types
			get_tree().change_scene_to_file("res://Scenes/CardBattle.tscn")

# Update the UI labels
func update_ui():
	title_label.text = "Choose Your Path - " + selected_god
	
	var completed_count = current_map.completed_nodes.size()
	var total_count = current_map.nodes.size()
	progress_label.text = "Progress: " + str(completed_count) + "/" + str(total_count) + " nodes completed"
	
	# Check if run is complete
	check_run_completion()

# Check if the run is complete after returning from battle
func check_run_completion():
	if current_map.is_map_complete():
		title_label.text = "Run Complete! " + selected_god + " Victorious!"
		progress_label.text = "Congratulations! You've completed this run."
		
		# Disable all remaining buttons
		for button in map_node_buttons:
			button.disabled = true
		
		# Add a "View Run Summary" button
		var summary_button = Button.new()
		summary_button.text = "View Run Summary"
		summary_button.position = Vector2(400, 500)
		summary_button.pressed.connect(_on_view_summary_pressed)
		map_container.add_child(summary_button)

# Handle starting a new run
func _on_new_run_pressed():
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# Handle viewing run summary
func _on_view_summary_pressed():
	# Pass run data to summary screen
	get_tree().set_meta("scene_params", {
		"god": selected_god,
		"deck_index": selected_deck_index,
		"victory": true
	})
	get_tree().change_scene_to_file("res://Scenes/RunSummary.tscn")


# Handle back button press
func _on_back_button_pressed():
	# Return to god selection
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

# Helper to get passed parameters from previous scene
func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}

# Refresh the map display (call this when returning from battles)
func refresh_map():
	# Update node availability
	current_map.update_node_availability()
	
	# Redisplay the map
	display_map()
	
	# Update UI
	update_ui()
	
	# Check if run is complete
	if current_map.is_map_complete():
		title_label.text = "Run Complete! " + selected_god + " Victorious!"
		progress_label.text = "Congratulations! You've completed this run."
