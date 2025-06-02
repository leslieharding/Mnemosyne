# res://Scripts/run_summary.gd
extends Control



var god_name: String = "Apollo"
var deck_index: int = 0
var victory: bool = true

func _ready():
	# Get parameters from previous scene first
	var params = get_scene_params()
	god_name = params.get("god", "Apollo")
	deck_index = params.get("deck_index", 0)
	victory = params.get("victory", true)
	
	# Use call_deferred to ensure scene tree is ready
	call_deferred("setup_ui_safely")

func setup_ui_safely():
	# Get references manually instead of relying on @onready
	var title = get_node("VBoxContainer/Title")
	var result = get_node("VBoxContainer/ResultLabel")
	var capture_total = get_node("VBoxContainer/TotalExpContainer/CaptureTotal")
	var defense_total = get_node("VBoxContainer/TotalExpContainer/DefenseTotal")
	var card_details = get_node("VBoxContainer/ScrollContainer/CardDetailsContainer")
	
	# Validate all nodes exist
	if not title or not result or not capture_total or not defense_total or not card_details:
		push_error("Failed to find required UI nodes in RunSummary")
		return
	
	# Set up the UI
	title.text = god_name + " - Run Summary"
	if victory:
		result.text = "Victory!"
		result.add_theme_color_override("font_color", Color("#4A8A4A"))
	else:
		result.text = "Defeat"
		result.add_theme_color_override("font_color", Color("#8A4A4A"))
	
	# Set up experience summary
	setup_experience_summary(capture_total, defense_total, card_details)



func setup_experience_summary(capture_total_node: Label, defense_total_node: Label, card_details_node: VBoxContainer):
	# Double-check that tracker exists
	if not has_node("/root/RunExperienceTrackerAutoload"):
		print("ERROR: RunExperienceTrackerAutoload not found")
		return
	
	# Get experience data from the tracker
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	var all_exp = tracker.get_all_experience()
	var totals = tracker.get_total_experience()
	
	# Set totals safely
	capture_total_node.text = "⚔️ Total Capture: " + str(totals["capture_exp"])
	defense_total_node.text = "🛡️ Total Defense: " + str(totals["defense_exp"])
	
	# Load the god's collection to get card names
	var collection_path = "res://Resources/Collections/" + god_name.to_lower() + ".tres"
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		print("Failed to load collection at: " + collection_path)
		return
	
	# Get global progress for before/after comparison
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		print("ERROR: GlobalProgressTrackerAutoload not found")
		return
		
	var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	
	# Create detailed view for each card that gained experience
	for card_index in all_exp:
		var run_exp_data = all_exp[card_index]
		
		# Skip cards with no experience
		if run_exp_data["capture_exp"] == 0 and run_exp_data["defense_exp"] == 0:
			continue
		
		# Get card data
		var card = collection.cards[card_index] if card_index < collection.cards.size() else null
		if not card:
			continue
		
		# Get total experience (before this run was added to global)
		var total_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
		
		# Calculate before experience (total minus this run)
		var before_capture = total_exp_data["capture_exp"] - run_exp_data["capture_exp"]
		var before_defense = total_exp_data["defense_exp"] - run_exp_data["defense_exp"]
		
		# Create a container for this card
		var card_container = create_detailed_card_exp_display(
			card, 
			before_capture, total_exp_data["capture_exp"],
			before_defense, total_exp_data["defense_exp"],
			run_exp_data["capture_exp"], run_exp_data["defense_exp"]
		)
		card_details_node.add_child(card_container)
		
		# Add separator
		var separator = HSeparator.new()
		card_details_node.add_child(separator)

func create_detailed_card_exp_display(
	card: CardResource, 
	before_capture: int, after_capture: int,
	before_defense: int, after_defense: int,
	capture_gain: int, defense_gain: int
) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 120)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	container.add_child(name_label)
	
	# Experience gained summary
	var summary_container = HBoxContainer.new()
	
	if capture_gain > 0:
		var capture_gain_label = Label.new()
		capture_gain_label.text = "⚔️ +" + str(capture_gain) + " Capture XP"
		capture_gain_label.add_theme_color_override("font_color", Color("#FFD700"))
		capture_gain_label.add_theme_font_size_override("font_size", 14)
		summary_container.add_child(capture_gain_label)
	
	if defense_gain > 0:
		if capture_gain > 0:
			var spacer = Control.new()
			spacer.custom_minimum_size.x = 20
			summary_container.add_child(spacer)
		
		var defense_gain_label = Label.new()
		defense_gain_label.text = "🛡️ +" + str(defense_gain) + " Defense XP"
		defense_gain_label.add_theme_color_override("font_color", Color("#87CEEB"))
		defense_gain_label.add_theme_font_size_override("font_size", 14)
		summary_container.add_child(defense_gain_label)
	
	container.add_child(summary_container)
	
	# Progress bars container
	var progress_container = HBoxContainer.new()
	container.add_child(progress_container)
	
	# Capture progress (if any experience gained)
	if capture_gain > 0:
		var capture_section = VBoxContainer.new()
		capture_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var capture_title = Label.new()
		capture_title.text = "Capture Progress"
		capture_title.add_theme_font_size_override("font_size", 12)
		capture_title.add_theme_color_override("font_color", Color("#FFD700"))
		capture_section.add_child(capture_title)
		
		# Before state
		var before_capture_bar = preload("res://Scenes/ExpProgressBar.tscn").instantiate()
		before_capture_bar.setup_progress(before_capture, "capture", ExpProgressBar.DisplayMode.DETAILED)
		capture_section.add_child(before_capture_bar)
		
		# Arrow
		var arrow_label = Label.new()
		arrow_label.text = "↓"
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_label.add_theme_font_size_override("font_size", 16)
		capture_section.add_child(arrow_label)
		
		# After state (will be animated)
		var after_capture_bar = preload("res://Scenes/ExpProgressBar.tscn").instantiate()
		after_capture_bar.setup_progress(before_capture, "capture", ExpProgressBar.DisplayMode.DETAILED)
		capture_section.add_child(after_capture_bar)
		
		# Schedule animation
		call_deferred("animate_progress_bar", after_capture_bar, before_capture, after_capture)
		
		progress_container.add_child(capture_section)
	
	# Spacer between progress bars
	if capture_gain > 0 and defense_gain > 0:
		var spacer = VSeparator.new()
		progress_container.add_child(spacer)
	
	# Defense progress (if any experience gained)
	if defense_gain > 0:
		var defense_section = VBoxContainer.new()
		defense_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var defense_title = Label.new()
		defense_title.text = "Defense Progress"
		defense_title.add_theme_font_size_override("font_size", 12)
		defense_title.add_theme_color_override("font_color", Color("#87CEEB"))
		defense_section.add_child(defense_title)
		
		# Before state
		var before_defense_bar = preload("res://Scenes/ExpProgressBar.tscn").instantiate()
		before_defense_bar.setup_progress(before_defense, "defense", ExpProgressBar.DisplayMode.DETAILED)
		defense_section.add_child(before_defense_bar)
		
		# Arrow
		var arrow_label = Label.new()
		arrow_label.text = "↓"
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_label.add_theme_font_size_override("font_size", 16)
		defense_section.add_child(arrow_label)
		
		# After state (will be animated)
		var after_defense_bar = preload("res://Scenes/ExpProgressBar.tscn").instantiate()
		after_defense_bar.setup_progress(before_defense, "defense", ExpProgressBar.DisplayMode.DETAILED)
		defense_section.add_child(after_defense_bar)
		
		# Schedule animation
		call_deferred("animate_progress_bar", after_defense_bar, before_defense, after_defense)
		
		progress_container.add_child(defense_section)
	
	return container

# Helper function to animate progress bars with a delay
func animate_progress_bar(progress_bar: ExpProgressBar, old_xp: int, new_xp: int):
	# Add a small delay so the UI settles first
	await get_tree().create_timer(0.5).timeout
	progress_bar.animate_progress_change(old_xp, new_xp, 1.5)

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

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}

func _on_new_run_button_pressed() -> void:
	# Add run experience to global tracker before clearing
	save_run_to_global_progress()
	
	# Clear the run data before starting a new run
	if has_node("/root/RunExperienceTrackerAutoload"):
		get_node("/root/RunExperienceTrackerAutoload").clear_run()
	# Go to god selection
	get_tree().change_scene_to_file("res://Scenes/GameModeSelect.tscn")

func _on_main_menu_button_pressed() -> void:
	# Add run experience to global tracker before clearing
	save_run_to_global_progress()
	
	# Clear the run data before going to main menu
	get_node("/root/RunExperienceTrackerAutoload").clear_run()
	# Go to main menu
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

# Save the run experience to global progress
func save_run_to_global_progress():
	if not has_node("/root/RunExperienceTrackerAutoload"):
		print("Warning: RunExperienceTrackerAutoload not found")
		return
		
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		print("Warning: GlobalProgressTrackerAutoload not found")
		return
		
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	
	# Get all experience from this run
	var run_exp = tracker.get_all_experience()
	
	# Add it to the global tracker
	if run_exp.size() > 0:
		global_tracker.add_run_experience(god_name, run_exp)
		print("Saved run experience to global progress for ", god_name)
