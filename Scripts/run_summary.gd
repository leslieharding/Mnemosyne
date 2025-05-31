# res://Scripts/run_summary.gd
extends Control

@onready var title_label = $VBoxContainer/Title
@onready var result_label = $VBoxContainer/ResultLabel
@onready var capture_total_label = $VBoxContainer/TotalExpContainer/CaptureTotal
@onready var defense_total_label = $VBoxContainer/TotalExpContainer/DefenseTotal
@onready var card_details_container = $VBoxContainer/ScrollContainer/CardDetailsContainer

var god_name: String = "Apollo"
var deck_index: int = 0
var victory: bool = true

func _ready():
	# Get parameters from previous scene
	var params = get_scene_params()
	god_name = params.get("god", "Apollo")
	deck_index = params.get("deck_index", 0)
	victory = params.get("victory", true)
	
	# Update title and result
	title_label.text = god_name + " - Run Summary"
	if victory:
		result_label.text = "Victory!"
		result_label.add_theme_color_override("font_color", Color("#4A8A4A"))
	else:
		result_label.text = "Defeat"
		result_label.add_theme_color_override("font_color", Color("#8A4A4A"))
	
	# Display experience summary
	display_experience_summary()

func display_experience_summary():
	# Get experience data from the tracker
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	var all_exp = tracker.get_all_experience()
	var totals = tracker.get_total_experience()
	
	# Update total labels
	capture_total_label.text = "⚔️ Total Capture: " + str(totals["capture_exp"])
	defense_total_label.text = "🛡️ Total Defense: " + str(totals["defense_exp"])
	
	# Load the god's collection to get card names
	var collection: GodCardCollection = load("res://Resources/Collections/" + god_name.to_lower() + ".tres")
	if not collection:
		print("Failed to load collection for " + god_name)
		return
	
	# Create detailed view for each card that gained experience
	for card_index in all_exp:
		var exp_data = all_exp[card_index]
		
		# Skip cards with no experience
		if exp_data["capture_exp"] == 0 and exp_data["defense_exp"] == 0:
			continue
		
		# Get card data
		var card = collection.cards[card_index] if card_index < collection.cards.size() else null
		if not card:
			continue
		
		# Create a container for this card
		var card_container = create_card_exp_display(card, exp_data)
		card_details_container.add_child(card_container)
		
		# Add separator
		var separator = HSeparator.new()
		card_details_container.add_child(separator)

func create_card_exp_display(card: CardResource, exp_data: Dictionary) -> Control:
	var container = VBoxContainer.new()
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 18)
	container.add_child(name_label)
	
	# Experience details
	var exp_container = HBoxContainer.new()
	
	if exp_data["capture_exp"] > 0:
		var capture_label = Label.new()
		capture_label.text = "⚔️ Capture: +" + str(exp_data["capture_exp"])
		capture_label.add_theme_color_override("font_color", Color("#FFD700"))
		capture_label.add_theme_font_size_override("font_size", 16)
		exp_container.add_child(capture_label)
	
	if exp_data["defense_exp"] > 0:
		if exp_data["capture_exp"] > 0:
			var spacer = Control.new()
			spacer.custom_minimum_size.x = 20
			exp_container.add_child(spacer)
		
		var defense_label = Label.new()
		defense_label.text = "🛡️ Defense: +" + str(exp_data["defense_exp"])
		defense_label.add_theme_color_override("font_color", Color("#87CEEB"))
		defense_label.add_theme_font_size_override("font_size", 16)
		exp_container.add_child(defense_label)
	
	container.add_child(exp_container)
	
	return container

func _on_new_run_pressed():
	# Clear the run data before starting a new run
	get_node("/root/RunExperienceTrackerAutoload").clear_run()
	# Go to god selection
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

func _on_main_menu_pressed():
	# Clear the run data before going to main menu
	get_node("/root/RunExperienceTrackerAutoload").clear_run()
	# Go to main menu
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}


func _on_new_run_button_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_button_pressed() -> void:
	pass # Replace with function body.
