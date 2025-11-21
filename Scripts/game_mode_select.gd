# Updated res://Scripts/game_mode_select.gd
extends Control

var journal_button: JournalButton

# God button references
@onready var apollo_button: Button = $VBoxContainer/HBoxContainer/ApolloButton
@onready var hermes_button: Button = $VBoxContainer/HBoxContainer/HermesButton
@onready var artemis_button: Button = $VBoxContainer/HBoxContainer/ArtemisButton
@onready var aphrodite_button: Button = $VBoxContainer/HBoxContainer/AphroditeButton
@onready var demeter_button: Button = $VBoxContainer/HBoxContainer/DemeterButton  
@onready var chiron_button: ChironButton = $ChironButton

# Test Battle UI References
var test_battle_panel: PanelContainer
var deck_dropdown: OptionButton
var enemy_dropdown: OptionButton
var test_battle_button: Button

# Test Battle Data
var available_decks: Array[Dictionary] = []  # {god: String, deck_index: int, deck_name: String}
var available_enemies: Array[Dictionary] = []  # {enemy_name: String, difficulty: int}
var enemies_collection: EnemiesCollection

func _ready():
	setup_journal_button()
	setup_god_buttons()
	setup_test_battle_panel()
	load_test_battle_data()
	
	if chiron_button:
		# Use call_deferred to ensure the button's _ready() has finished
		call_deferred("refresh_chiron_button")

func refresh_chiron_button():
	if chiron_button:
		print("GameModeSelect: Refreshing Chiron button state")
		chiron_button.update_button_state()

func setup_journal_button():
	if not journal_button:
		# Create a CanvasLayer to ensure consistent positioning like Apollo
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 10  # High layer value to be on top
		canvas_layer.name = "JournalLayer"
		add_child(canvas_layer)
		
		# Create the journal button
		journal_button = preload("res://Scenes/JournalButton.tscn").instantiate()
		canvas_layer.add_child(journal_button)
		
		journal_button.position = Vector2(20, get_viewport().get_visible_rect().size.y - 80)
		journal_button.size = Vector2(60, 60)
		
		print("GameModeSelect: Journal button added with CanvasLayer")

func setup_god_buttons():
	# Check god unlock status
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		print("GlobalProgressTrackerAutoload not found!")
		return
	
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	print("Setting up god buttons - unlocked gods: ", unlocked_gods)
	
	# Set up each god button
	setup_individual_god_button("Apollo", apollo_button, unlocked_gods)
	setup_individual_god_button("Hermes", hermes_button, unlocked_gods)
	setup_individual_god_button("Artemis", artemis_button, unlocked_gods)
	setup_individual_god_button("Aphrodite", aphrodite_button, unlocked_gods)
	setup_individual_god_button("Demeter", demeter_button, unlocked_gods)
	# Add more gods here as needed

func setup_individual_god_button(god_name: String, button: Button, unlocked_gods: Array[String]):
	if not button:
		print("Button not found for god: ", god_name)
		return
	
	if god_name in unlocked_gods:
		# God is unlocked - normal appearance and functionality
		button.disabled = false
		button.modulate = Color.WHITE
		button.tooltip_text = "Play as " + god_name
	else:
		# God is locked - gray out and show unlock condition
		button.disabled = false  # Keep clickable to show unlock info
		button.modulate = Color(0.6, 0.6, 0.6)
		button.text = god_name + " 🔒"
		
		# Get actual unlock condition from progress tracker
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		if progress_tracker:
			button.tooltip_text = progress_tracker.get_god_unlock_description(god_name)
		else:
			button.tooltip_text = "Unknown unlock requirement"

func setup_test_battle_panel():
	# Create the test battle panel in top right
	test_battle_panel = PanelContainer.new()
	test_battle_panel.name = "TestBattlePanel"
	
	# Position in top right corner
	test_battle_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	test_battle_panel.position = Vector2(-250, 10)  # Offset from top right
	test_battle_panel.custom_minimum_size = Vector2(240, 140)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	test_battle_panel.add_theme_stylebox_override("panel", style)
	
	# Create content container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	test_battle_panel.add_child(vbox)
	
	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(content_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Test Battle"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content_vbox.add_child(title)
	
	# Player Deck Dropdown
	var deck_label = Label.new()
	deck_label.text = "Player Deck:"
	deck_label.add_theme_font_size_override("font_size", 12)
	content_vbox.add_child(deck_label)
	
	deck_dropdown = OptionButton.new()
	deck_dropdown.custom_minimum_size = Vector2(200, 0)
	content_vbox.add_child(deck_dropdown)
	
	# Enemy Dropdown
	var enemy_label = Label.new()
	enemy_label.text = "Enemy:"
	enemy_label.add_theme_font_size_override("font_size", 12)
	content_vbox.add_child(enemy_label)
	
	enemy_dropdown = OptionButton.new()
	enemy_dropdown.custom_minimum_size = Vector2(200, 0)
	content_vbox.add_child(enemy_dropdown)
	
	# Start Test Battle Button
	test_battle_button = Button.new()
	test_battle_button.text = "Start Test Battle"
	test_battle_button.disabled = true  # Disabled until selections are made
	test_battle_button.pressed.connect(_on_test_battle_button_pressed)
	content_vbox.add_child(test_battle_button)
	
	add_child(test_battle_panel)
	
	print("Test Battle panel created")

func load_test_battle_data():
	# Load all god collections and their decks
	var god_names = ["Apollo", "Hermes", "Artemis", "Demeter", "Aphrodite", "Dionysus", "Athena"]
	
	for god_name in god_names:
		var collection_path = "res://Resources/Collections/" + god_name + ".tres"
		if ResourceLoader.exists(collection_path):
			var collection: GodCardCollection = load(collection_path)
			if collection and collection.decks.size() > 0:
				for i in range(collection.decks.size()):
					var deck_def = collection.decks[i]
					available_decks.append({
						"god": god_name,
						"deck_index": i,
						"deck_name": deck_def.deck_name
					})
					
					# Add to dropdown
					var display_name = god_name + " - " + deck_def.deck_name
					deck_dropdown.add_item(display_name)
	
	print("Loaded ", available_decks.size(), " decks for testing")
	
	# Load enemies from Enemies.tres
	enemies_collection = load("res://Resources/Collections/Enemies.tres")
	if enemies_collection:
		var enemy_names = enemies_collection.get_enemy_names()
		for enemy_name in enemy_names:
			var enemy_data = enemies_collection.get_enemy(enemy_name)
			if enemy_data and enemy_data.decks.size() > 0:
				# Check if enemy has multiple difficulty decks
				if enemy_data.decks.size() > 1:
					# Multi-difficulty enemy - add each difficulty
					for i in range(enemy_data.decks.size()):
						var difficulty = enemy_data.decks[i].difficulty_level
						available_enemies.append({
							"enemy_name": enemy_name,
							"difficulty": difficulty
						})
						var display_name = enemy_name + " (Diff " + str(difficulty) + ")"
						enemy_dropdown.add_item(display_name)
				else:
					# Boss enemy with single deck - add without difficulty suffix
					available_enemies.append({
						"enemy_name": enemy_name,
						"difficulty": 1  # Default to 1 for single-deck enemies
					})
					enemy_dropdown.add_item(enemy_name)
		
		print("Loaded ", available_enemies.size(), " enemy configurations for testing")
	else:
		print("Failed to load Enemies.tres")
	
	# Enable button if we have data
	if available_decks.size() > 0 and available_enemies.size() > 0:
		test_battle_button.disabled = false
		# Set default selections
		deck_dropdown.selected = 0
		enemy_dropdown.selected = 0

func _on_test_battle_button_pressed():
	var deck_index = deck_dropdown.selected
	var enemy_index = enemy_dropdown.selected
	
	if deck_index < 0 or deck_index >= available_decks.size():
		print("Invalid deck selection")
		return
	
	if enemy_index < 0 or enemy_index >= available_enemies.size():
		print("Invalid enemy selection")
		return
	
	var selected_deck = available_decks[deck_index]
	var selected_enemy = available_enemies[enemy_index]
	
	print("Starting test battle:")
	print("  Deck: ", selected_deck.god, " - ", selected_deck.deck_name)
	print("  Enemy: ", selected_enemy.enemy_name, " (Difficulty ", selected_enemy.difficulty, ")")
	
	# Set up scene parameters for test battle
	get_tree().set_meta("scene_params", {
		"god": selected_deck.god,
		"deck_index": selected_deck.deck_index,
		"enemy_name": selected_enemy.enemy_name,
		"enemy_difficulty": selected_enemy.difficulty,
		"is_test_battle": true  # Flag to identify this as a test battle
	})
	
	# Go directly to battle scene
	TransitionManagerAutoload.change_scene_to("res://Scenes/CardBattle.tscn")

func _on_button_pressed():
	SoundManagerAutoload.play_click()
	TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")

func _on_apollo_button_pressed():
	# Check if Apollo is unlocked
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
		
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	if "Apollo" in unlocked_gods:
		SoundManagerAutoload.play_click()
		TransitionManagerAutoload.change_scene_to("res://Scenes/Apollo.tscn")
	else:
		print("Apollo is locked!")

func _on_hermes_button_pressed():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
		
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	if "Hermes" in unlocked_gods:
		SoundManagerAutoload.play_click()
		TransitionManagerAutoload.change_scene_to("res://Scenes/Hermes.tscn")
	else:
		print("Hermes is locked!")
		# Could show a popup here explaining unlock requirements

func _on_artemis_button_pressed():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
		
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	if "Artemis" in unlocked_gods:
		SoundManagerAutoload.play_click()
		TransitionManagerAutoload.change_scene_to("res://Scenes/Artemis.tscn")
	else:
		print("Artemis is locked!")

func _on_demeter_button_pressed():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
		
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	if "Demeter" in unlocked_gods:
		SoundManagerAutoload.play_click()
		TransitionManagerAutoload.change_scene_to("res://Scenes/Demeter.tscn")
	else:
		print("Demeter is locked!")

func _on_aphrodite_button_pressed():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
		
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlocked_gods = progress_tracker.get_unlocked_gods()
	
	if "Aphrodite" in unlocked_gods:
		SoundManagerAutoload.play_click()
		TransitionManagerAutoload.change_scene_to("res://Scenes/Aphrodite.tscn")
	else:
		print("Aphrodite is locked!")

func _on_dionysus_button_pressed():
	print("Dionysus scene not yet implemented!")

func _on_athena_button_pressed():
	print("Athena scene not yet implemented!")


func _on_apollo_button_mouse_entered() -> void:
	SoundManagerAutoload.play_god_hover("Apollo")


func _on_apollo_button_mouse_exited() -> void:
	SoundManagerAutoload.stop_god_hover_with_fade(0.5,1.5)


func _on_button_mouse_entered() -> void:
	SoundManagerAutoload.play_hover()


func _on_artemis_button_mouse_entered() -> void:
	SoundManagerAutoload.play_god_hover("Artemis")


func _on_artemis_button_mouse_exited() -> void:
	SoundManagerAutoload.stop_god_hover_with_fade(0.5,1.5)


func _on_hermes_button_mouse_entered() -> void:
	SoundManagerAutoload.play_god_hover("Hermes")


func _on_hermes_button_mouse_exited() -> void:
	SoundManagerAutoload.stop_god_hover_with_fade(0.5,1.5)


func _on_demeter_button_mouse_entered() -> void:
	SoundManagerAutoload.play_god_hover("Demeter")


func _on_demeter_button_mouse_exited() -> void:
	SoundManagerAutoload.stop_god_hover_with_fade(0.5,1.5)
