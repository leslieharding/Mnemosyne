# res://Scripts/run_map.gd
extends Node2D

# UI References
@onready var map_container = $MapContainer
@onready var title_label = $UI/VBoxContainer/Title
@onready var progress_label = $UI/VBoxContainer/ProgressLabel
@onready var back_button = $UI/VBoxContainer/BackButton

# Map data
var current_map: MapData
var map_node_icons: Array[TextureButton] = []
var path_lines_node: Node2D = null
@export var texture_battle: Texture2D
@export var texture_boss: Texture2D

# Run state - we'll get this from the previous scene
var selected_god: String = "Apollo"
var selected_deck_index: int = 0

var exit_popup: Panel
var exit_popup_save_button: Button
var exit_popup_abandon_button: Button



# Journal button reference
var journal_button: JournalButton

func _ready():
	# Connect back button
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Get run parameters from previous scene
	get_run_parameters()
	
	
	
	# Check if we're returning from a battle, resuming a saved run, or starting fresh
	var params = get_scene_params()
	if params.has("map_data") and params["map_data"] != null:
		# Returning from battle or resuming a saved run - use the provided map data
		current_map = params["map_data"]
		display_map()
	else:
		# Starting fresh - generate new map
		generate_new_map()
	
	# Update UI
	update_ui()
	



# Get parameters passed from the deck selection scene
func get_run_parameters():
	var params = get_scene_params()
	if params.has("god"):
		selected_god = params.god
	if params.has("deck_index"):
		selected_deck_index = params.deck_index
	
	# If resuming, use the restored map data instead of generating a new one
	if params.has("map_data") and params["map_data"] != null:
		current_map = params["map_data"]
		print("RunMap: Resuming saved run with restored map data")
	else:
		generate_new_map()
		print("RunMap: Generated new map for ", selected_god)
	
	print("Starting run with: ", selected_god, " deck ", selected_deck_index)



func generate_new_map():
	# Sync generator dimensions to viewport coordinate space
	var viewport_size = get_viewport().get_visible_rect().size
	MapGenerator.MAP_WIDTH = viewport_size.x
	MapGenerator.MAP_HEIGHT = viewport_size.y
	MapGenerator.LAYER_SPACING = MapGenerator.MAP_HEIGHT / (MapGenerator.LAYER_COUNT - 1)
	
	var collection_path = "res://Resources/Collections/" + selected_god + ".tres"
	var collection = load(collection_path)
	var deck_name = ""
	
	if collection and selected_deck_index < collection.decks.size():
		deck_name = collection.decks[selected_deck_index].deck_name
	
	current_map = MapGenerator.generate_map(selected_god, deck_name)
	display_map()

# Display the map visually
func display_map() -> void:
	clear_map_display()

	# Lines added first so they render behind the icons
	path_lines_node = MapPathLines.new()
	map_container.add_child(path_lines_node)
	path_lines_node.set_map_nodes(current_map.nodes)

	for map_node in current_map.nodes:
		create_map_node_icon(map_node)

# Clear existing map display
func clear_map_display() -> void:
	for icon in map_node_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	map_node_icons.clear()
	if is_instance_valid(path_lines_node):
		path_lines_node.queue_free()
	path_lines_node = null


	


# Handle map node button press
func _on_map_node_pressed(map_node: MapNode):
	SoundManagerAutoload.play_randomized('click')
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
			TransitionManagerAutoload.change_scene_to("res://Scenes/CardBattle.tscn")
		_:
			# Future: handle other node types
			TransitionManagerAutoload.change_scene_to("res://Scenes/CardBattle.tscn")

func create_map_node_icon(map_node: MapNode) -> void:
	var icon_size := Vector2(64, 64)
	var btn := TextureButton.new()

	match map_node.node_type:
		MapNode.NodeType.BOSS:
			btn.texture_normal = texture_boss
		_:
			btn.texture_normal = texture_battle

	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = icon_size
	btn.size = icon_size
	btn.position = Vector2(
		map_node.position.x - icon_size.x / 2.0,
		map_node.position.y - icon_size.y / 2.0
	)

	if map_node.is_completed:
		btn.modulate = Color(0.5, 1.0, 0.5, 0.85)
		btn.disabled = true
	elif map_node.is_available:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		btn.disabled = false
	else:
		btn.modulate = Color(0.35, 0.35, 0.35, 0.5)
		btn.disabled = true

	btn.pressed.connect(_on_map_node_pressed.bind(map_node))
	# Hover feedback only on nodes the player can actually click
	if map_node.is_available:
		btn.pivot_offset = icon_size / 2.0
		btn.mouse_entered.connect(func():
			var t := btn.create_tween()
			t.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.1)
		)
		btn.mouse_exited.connect(func():
			var t := btn.create_tween()
			t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		)
	map_container.add_child(btn)
	map_node_icons.append(btn)

# Update the UI labels
func update_ui():
	
	var completed_count = current_map.completed_nodes.size()
	var total_count = current_map.nodes.size()
	
	# Check if run is complete
	check_run_completion()

# Check if the run is complete after returning from battle
func check_run_completion():
	if current_map.is_map_complete():
		print("Run completed! Going directly to run summary")
		
		# Go directly to run summary instead of showing completion UI
		get_tree().set_meta("scene_params", {
			"god": selected_god,
			"deck_index": selected_deck_index,
			"victory": true
		})
		TransitionManagerAutoload.change_scene_to("res://Scenes/RunSummary.tscn")

# Handle starting a new run
func _on_new_run_pressed():
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")




func _on_back_button_pressed():
	SoundManagerAutoload.play("click")
	_show_exit_popup()

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

func _show_exit_popup():
	if exit_popup and is_instance_valid(exit_popup):
		exit_popup.queue_free()
	
	# Build a manual popup panel rather than relying on AcceptDialog internals
	exit_popup = Panel.new()
	exit_popup.custom_minimum_size = Vector2(400, 220)
	add_child(exit_popup)
	
	# Centre it on screen
	var screen_size = get_viewport().get_visible_rect().size
	exit_popup.position = (screen_size - exit_popup.custom_minimum_size) / 2
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	exit_popup.add_child(vbox)
	
	var label = Label.new()
	label.text = "Leave Run?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label)
	
	var sublabel = Label.new()
	sublabel.text = "What would you like to do with your current run?"
	sublabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sublabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sublabel)
	
	exit_popup_save_button = Button.new()
	exit_popup_save_button.text = "Save & Exit"
	exit_popup_save_button.pressed.connect(_on_exit_save_pressed)
	vbox.add_child(exit_popup_save_button)
	
	exit_popup_abandon_button = Button.new()
	exit_popup_abandon_button.text = "Abandon Run"
	exit_popup_abandon_button.pressed.connect(_on_exit_abandon_pressed)
	vbox.add_child(exit_popup_abandon_button)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func(): exit_popup.queue_free())
	vbox.add_child(cancel_button)

func _on_exit_save_pressed():
	exit_popup.hide()
	if has_node("/root/RunSaveManagerAutoload"):
		var save_manager = get_node("/root/RunSaveManagerAutoload")
		var success = save_manager.save_run(selected_god, selected_deck_index, current_map)
		if success:
			print("Run saved - returning to main menu")
		else:
			print("WARNING: Run save failed - returning to main menu anyway")
	TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")

func _on_exit_abandon_pressed():
	exit_popup.hide()
	# Clear any saved run file for this run since we're abandoning definitively
	if has_node("/root/RunSaveManagerAutoload"):
		get_node("/root/RunSaveManagerAutoload").clear_saved_run()
	
	# Go to run summary as a loss - existing flow handles exp commit
	get_tree().set_meta("scene_params", {
		"god": selected_god,
		"deck_index": selected_deck_index,
		"victory": false
	})
	TransitionManagerAutoload.change_scene_to("res://Scenes/RunSummary.tscn")
