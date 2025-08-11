# Updated res://Scripts/game_mode_select.gd
extends Control

var journal_button: JournalButton

# God button references
@onready var apollo_button: Button = $VBoxContainer/HBoxContainer/ApolloButton
@onready var hermes_button: Button = $VBoxContainer/HBoxContainer/HermesButton
@onready var artemis_button: Button = $VBoxContainer/HBoxContainer/ArtemisButton
@onready var aphrodite_button: Button = $VBoxContainer/HBoxContainer/AphroditeButton  
@onready var chiron_button: ChironButton = $ChironButton

func _ready():
	setup_journal_button()
	setup_god_buttons()

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
	setup_individual_god_button("Aphrodite", aphrodite_button, unlocked_gods)  # Add this line
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
		
		var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
		var unlock_desc = progress_tracker.get_god_unlock_description(god_name)
		button.tooltip_text = "Locked: " + unlock_desc

func _on_apollo_button_pressed() -> void:
	if is_god_available("Apollo"):
		TransitionManagerAutoload.change_scene_to("res://Scenes/Apollo.tscn")

func _on_hermes_button_pressed() -> void:
	if is_god_available("Hermes"):
		TransitionManagerAutoload.change_scene_to("res://Scenes/Hermes.tscn")
	else:
		show_unlock_requirements("Hermes")

func _on_artemis_button_pressed() -> void:
	if is_god_available("Artemis"):
		TransitionManagerAutoload.change_scene_to("res://Scenes/Artemis.tscn")
	else:
		show_unlock_requirements("Artemis")

func _on_aphrodite_button_pressed() -> void:
	if is_god_available("Aphrodite"):
		TransitionManagerAutoload.change_scene_to("res://Scenes/Aphrodite.tscn")
	else:
		show_unlock_requirements("Aphrodite")

func is_god_available(god_name: String) -> bool:
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return god_name == "Apollo"  # Fallback
	
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	return progress_tracker.is_god_unlocked(god_name)

func show_unlock_requirements(god_name: String):
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var unlock_desc = progress_tracker.get_god_unlock_description(god_name)
	
	# Create a simple dialog showing unlock requirements
	var dialog = AcceptDialog.new()
	dialog.dialog_text = god_name + " is locked.\n\n" + unlock_desc
	dialog.title = "God Locked"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_button_pressed() -> void:
	TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")
