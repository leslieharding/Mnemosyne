extends Control

# UI References
@onready var menu_container = $MenuContainer
@onready var new_game_button = $MenuContainer/NewGameButton
@onready var continue_button = $MenuContainer/ContinueButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var quit_button = $MenuContainer/QuitButton

# Confirmation dialog for new game
var confirmation_dialog: ConfirmationDialog

var continue_button_ripple: ButtonRipple
var new_game_ripple: ButtonRipple
var settings_ripple: ButtonRipple
var quit_ripple: ButtonRipple

func _process(_delta):
	if continue_button_ripple:
		continue_button_ripple.update_mouse_position()
	if new_game_ripple:
		new_game_ripple.update_mouse_position()
	if settings_ripple:
		settings_ripple.update_mouse_position()
	if quit_ripple:
		quit_ripple.update_mouse_position()

func _ready():
	setup_menu_based_on_save_data()
	continue_button_ripple = ButtonRipple.new(continue_button)
	new_game_ripple = ButtonRipple.new(new_game_button)
	settings_ripple = ButtonRipple.new(settings_button)
	quit_ripple = ButtonRipple.new(quit_button)
	setup_confirmation_dialog()
	print("=== EXPORT DEBUG START ===")
	
	# Check autoloads
	var autoloads = [
		"RunExperienceTrackerAutoload",
		"GlobalProgressTrackerAutoload", 
		"MemoryJournalManagerAutoload",
		"ConversationManagerAutoload",
		"CutsceneManagerAutoload",
		"BossPredictionTrackerAutoload",
		"TransitionManagerAutoload"
	]
	
	print("--- AUTOLOAD CHECK ---")
	for autoload_name in autoloads:
		var path = "/root/" + autoload_name
		if has_node(path):
			print("✓ " + autoload_name + " loaded")
		else:
			print("✗ " + autoload_name + " MISSING!")
	
	# Check critical resources
	var resources = [
		"res://Resources/Collections/Apollo.tres",
		"res://Resources/Collections/Enemies.tres", 
		"res://Resources/Collections/Mnemosyne.tres",
		"res://Resources/Abilities/defensive_counter.tres",
		"res://Resources/Abilities/passive_boost.tres",
		"res://Resources/Abilities/stat_boost.tres",
		"res://Resources/Abilities/stat_nullify.tres"
	]
	
	print("--- RESOURCE CHECK ---")
	for res_path in resources:
		if ResourceLoader.exists(res_path):
			var resource = load(res_path)
			if resource:
				print("✓ " + res_path + " loaded successfully")
			else:
				print("⚠ " + res_path + " exists but failed to load")
		else:
			print("✗ " + res_path + " does not exist")
	
	# Check scenes
	var scenes = [
		"res://Scenes/MainMenu.tscn",
		"res://Scenes/GameModeSelect.tscn",
		"res://Scenes/Apollo.tscn",
		"res://Scenes/CardBattle.tscn",
		"res://Scenes/CardDisplay.tscn"
	]
	
	print("--- SCENE CHECK ---")
	for scene_path in scenes:
		if ResourceLoader.exists(scene_path):
			print("✓ " + scene_path + " exists")
		else:
			print("✗ " + scene_path + " missing")
	
	# Check if we can instantiate key scenes
	print("--- INSTANTIATION CHECK ---")
	var card_display_scene = load("res://Scenes/CardDisplay.tscn")
	if card_display_scene:
		var instance = card_display_scene.instantiate()
		if instance:
			print("✓ CardDisplay instantiation works")
			instance.queue_free()
		else:
			print("✗ CardDisplay instantiation failed")
	else:
		print("✗ CardDisplay scene failed to load")
	
	print("=== EXPORT DEBUG END ===")

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
	SoundManagerAutoload.play_randomized('click')
	continue_button_ripple.on_pressed()
	
	
	# Trigger the tutorial sequence for first-time players
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").play_cutscene("tutorial_intro")
	else:
		# Fallback if cutscene manager isn't available
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

# New game with confirmation for returning players
func _on_new_game_button_pressed_with_confirmation():
	confirmation_dialog.popup_centered()

# Continue game for returning players
func _on_continue_button_pressed():
	continue_button_ripple.on_pressed()
	SoundManagerAutoload.play_randomized("click")
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

# Replace this entire function in Scripts/main_menu.gd (around lines 95-125)

func _on_new_game_confirmed():
	print("Player confirmed new game - erasing all progress")
	
	# Clear all progress data AND reset god unlocks
	if has_node("/root/GlobalProgressTrackerAutoload"):
		var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		global_tracker.clear_all_progress()
		print("All progress data cleared and god unlocks reset to Apollo only")
	
	# Also clear any current run data
	if has_node("/root/RunExperienceTrackerAutoload"):
		var run_tracker = get_node("/root/RunExperienceTrackerAutoload")
		run_tracker.clear_run()
		print("Current run data cleared")
	
	# Clear memory journal data
	if has_node("/root/MemoryJournalManagerAutoload"):
		var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
		memory_manager.clear_all_memories()
		print("Memory journal data cleared")
	
	# Clear conversation data
	if has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		conv_manager.clear_all_conversations()
		print("Conversation data cleared")
	
	# Clear boss prediction patterns
	if has_node("/root/BossPredictionTrackerAutoload"):
		var boss_tracker = get_node("/root/BossPredictionTrackerAutoload")
		boss_tracker.clear_patterns()
		print("Boss prediction patterns cleared")
	
	# FIXED: Always trigger the tutorial cutscene for new games, regardless of previous data
	if has_node("/root/CutsceneManagerAutoload"):
		TransitionManagerAutoload.change_scene_to("res://Scenes/Cutscene.tscn")
		# The cutscene manager will handle setting up the cutscene data
		get_node("/root/CutsceneManagerAutoload").play_cutscene("tutorial_intro")
	else:
		TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")




func _on_quit_button_pressed() -> void:
	SoundManagerAutoload.play_randomized('click')
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	settings_ripple.on_pressed()
	SoundManagerAutoload.play_randomized('click')
	TransitionManagerAutoload.change_scene_to("res://Scenes/SettingsMenu.tscn")


func _on_quit_button_mouse_entered() -> void:
	SoundManagerAutoload.play_hover()
	quit_ripple.on_mouse_entered()


func _on_settings_button_mouse_entered() -> void:
	SoundManagerAutoload.play_hover()
	settings_ripple.on_mouse_entered()


func _on_continue_button_mouse_entered() -> void:
	continue_button_ripple.on_mouse_entered()
	SoundManagerAutoload.play_hover()


func _on_new_game_button_mouse_entered() -> void:
	SoundManagerAutoload.play_hover()
	new_game_ripple.on_mouse_entered()
	


func _on_continue_button_mouse_exited() -> void:
	continue_button_ripple.on_mouse_exited() 


func _on_new_game_button_mouse_exited() -> void:
	new_game_ripple.on_mouse_exited()


func _on_settings_button_mouse_exited() -> void:
	settings_ripple.on_mouse_exited()


func _on_quit_button_mouse_exited() -> void:
	quit_ripple.on_mouse_exited()
