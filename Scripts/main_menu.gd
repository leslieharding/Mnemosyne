extends Control

# UI References
@onready var menu_container = $MenuContainer
@onready var new_game_button = $MenuContainer/NewGameButton
@onready var continue_button = $MenuContainer/ContinueButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var quit_button = $MenuContainer/QuitButton

# Confirmation dialog for new game
var confirmation_dialog: ConfirmationDialog

func _ready():
	setup_menu_based_on_save_data()
	setup_confirmation_dialog()

func setup_menu_based_on_save_data():
	# Check if there's any existing progress
	var has_progress = false
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		has_progress = global_tracker.has_any_progress()
	
	if has_progress:
		# Returning player - Continue on top, New Game below with warning
		setup_returning_player_menu()
	else:
		# First-time player - New Game on top, Continue disabled
		setup_first_time_player_menu()

func setup_first_time_player_menu():
	print("Setting up menu for first-time player")
	
	# Move New Game button to top position (index 1, after the title)
	menu_container.move_child(new_game_button, 1)
	
	# Move Continue button to second position
	menu_container.move_child(continue_button, 2)
	
	# Disable continue button and make it gray
	continue_button.disabled = true
	continue_button.modulate = Color(0.6, 0.6, 0.6)  # Gray it out
	
	# Connect New Game button normally (no confirmation needed)
	if not new_game_button.pressed.is_connected(_on_new_game_button_pressed_direct):
		new_game_button.pressed.connect(_on_new_game_button_pressed_direct)

func setup_returning_player_menu():
	print("Setting up menu for returning player")
	
	# Move Continue button to top position (index 1, after the title)
	menu_container.move_child(continue_button, 1)
	
	# Move New Game button to second position
	menu_container.move_child(new_game_button, 2)
	
	# Enable continue button and restore normal appearance
	continue_button.disabled = false
	continue_button.modulate = Color.WHITE
	
	# Connect Continue button
	if not continue_button.pressed.is_connected(_on_continue_button_pressed):
		continue_button.pressed.connect(_on_continue_button_pressed)
	
	# Connect New Game button with confirmation (override existing connection)
	if new_game_button.pressed.is_connected(_on_new_game_button_pressed_direct):
		new_game_button.pressed.disconnect(_on_new_game_button_pressed_direct)
	if not new_game_button.pressed.is_connected(_on_new_game_button_pressed_with_confirmation):
		new_game_button.pressed.connect(_on_new_game_button_pressed_with_confirmation)

func setup_confirmation_dialog():
	# Create confirmation dialog
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Starting a new game will erase all your current progress.\n\nAre you sure you want to continue?"
	confirmation_dialog.title = "Confirm New Game"
	confirmation_dialog.ok_button_text = "Erase Progress"
	confirmation_dialog.cancel_button_text = "Cancel"
	
	# Add to scene
	add_child(confirmation_dialog)
	
	# Connect signals
	confirmation_dialog.confirmed.connect(_on_new_game_confirmed)

# Direct new game for first-time players
func _on_new_game_button_pressed_direct():
	# Trigger the opening cutscene for first-time players too
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").play_cutscene("opening_awakening")
	else:
		# Fallback if cutscene manager isn't available
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

# New game with confirmation for returning players
func _on_new_game_button_pressed_with_confirmation():
	confirmation_dialog.popup_centered()

# Continue game for returning players
func _on_continue_button_pressed():
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

# Confirmed new game - erase progress and start fresh
func _on_new_game_confirmed():
	print("Player confirmed new game - erasing all progress")
	
	# Clear all progress data
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		global_tracker.clear_all_progress()
		print("All progress data cleared")
	
	# Also clear any current run data
	if has_node("/root/RunExperienceTrackerAutoload"):
		var run_tracker = get_node("/root/RunExperienceTrackerAutoload")
		run_tracker.clear_run()
		print("Current run data cleared")
	
	# Trigger the opening cutscene instead of going directly to god select
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").play_cutscene("opening_awakening")
	else:
		# Fallback if cutscene manager isn't available
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")




func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	TransitionManagerAutoload.change_scene_to("res://Scenes/SettingsMenu.tscn")
