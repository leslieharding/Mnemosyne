# res://Scripts/run_summary.gd
extends Control

var god_name: String = "Apollo"
var deck_index: int = 0
var victory: bool = true

func _ready():
	print("RunSummary _ready() called")
	
	# Get parameters from previous scene first
	var params = get_scene_params()
	god_name = params.get("god", "Apollo")
	deck_index = params.get("deck_index", 0)
	victory = params.get("victory", true)
	
	# Set up UI immediately without waiting
	setup_ui_safely()

func setup_ui_safely():
	print("\n=== Setting up UI ===")
	
	# Get all required nodes
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		push_error("VBoxContainer not found!")
		return
	
	var title = vbox.get_node_or_null("Title")
	var result = vbox.get_node_or_null("ResultLabel")
	var total_exp_container = vbox.get_node_or_null("TotalExpContainer")
	var capture_total = total_exp_container.get_node_or_null("CaptureTotal")
	var defense_total = total_exp_container.get_node_or_null("DefenseTotal")
	var scroll_container = vbox.get_node_or_null("ScrollContainer")
	var card_details = scroll_container.get_node_or_null("CardDetailsContainer")
	
	if not title or not result or not capture_total or not defense_total or not card_details:
		push_error("Required UI nodes not found!")
		return
	
	print("All nodes found successfully!")
	
	# Set basic text
	title.text = god_name + " - Run Summary"
	
	if victory:
		result.text = "Victory!"
		result.add_theme_color_override("font_color", Color("#4A8A4A"))
	else:
		result.text = "Defeat"
		result.add_theme_color_override("font_color", Color("#8A4A4A"))
	
	# Set up experience summary without async
	setup_experience_summary_sync(capture_total, defense_total, card_details)

func setup_experience_summary_sync(capture_total_node: Label, defense_total_node: Label, card_details_node: VBoxContainer):
	print("\n=== Setting up experience summary ===")
	
	# Check autoloads
	if not has_node("/root/RunExperienceTrackerAutoload") or not has_node("/root/GlobalProgressTrackerAutoload"):
		print("ERROR: Required autoloads not found")
		return
	
	# Get experience data
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var all_exp = tracker.get_all_experience()
	var totals = tracker.get_total_experience()
	
	print("Total unified experience: " + str(totals["total_exp"]))
	
	# Update the labels to show unified experience
	capture_total_node.text = "⚡ Total Experience Gained: " + str(totals["total_exp"])
	defense_total_node.visible = false  # Hide the old defense label
	
	# Load collection
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		print("Failed to load collection")
		return
	
	print("Creating card displays...")
	
	# Create card displays synchronously
	for card_index in all_exp:
		var run_exp_data = all_exp[card_index]
		
		# Skip cards with no experience
		if run_exp_data["total_exp"] == 0:
			continue
		
		# Get card data
		var card = collection.cards[card_index] if card_index < collection.cards.size() else null
		if not card:
			continue
		
		print("Creating display for: ", card.card_name)
		
		# Get total experience data - UNIFIED VERSION
		var before_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
		var before_total = before_exp_data["total_exp"]
		var total_gain = run_exp_data["total_exp"]
		var after_total = before_total + total_gain
		
		# Create card display with unified experience
		var card_container = create_simple_card_display(
			card, 
			before_total, after_total,
			total_gain
		)
		
		card_details_node.add_child(card_container)
		print("Added card container for: ", card.card_name)
		
		# Add separator
		var separator = HSeparator.new()
		card_details_node.add_child(separator)
	
	print("Experience summary setup complete!")

func create_simple_card_display(
	card: CardResource, 
	before_total: int, after_total: int,
	total_gain: int
) -> Control:
	
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(500, 120)
	
	# Create panel with background
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A2A2A")
	style.border_color = Color("#444444")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var inner_container = VBoxContainer.new()
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	inner_container.add_child(name_label)
	
	# Experience gained summary
	var gains_container = HBoxContainer.new()
	
	if total_gain > 0:
		var gain_label = Label.new()
		gain_label.text = "⚡ +" + str(total_gain) + " Experience"
		gain_label.add_theme_color_override("font_color", Color("#FFD700"))
		gain_label.add_theme_font_size_override("font_size", 16)
		gains_container.add_child(gain_label)
	
	inner_container.add_child(gains_container)
	
	# Before/After display
	var progress_container = VBoxContainer.new()
	progress_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var progress_title = Label.new()
	progress_title.text = "Experience Progress"
	progress_title.add_theme_font_size_override("font_size", 14)
	progress_title.add_theme_color_override("font_color", Color("#FFD700"))
	progress_container.add_child(progress_title)
	
	# Simple before/after text
	var before_after = Label.new()
	var before_level = ExperienceHelpers.calculate_level(before_total)
	var after_level = ExperienceHelpers.calculate_level(after_total)
	var before_progress = ExperienceHelpers.calculate_progress(before_total)
	var after_progress = ExperienceHelpers.calculate_progress(after_total)
	
	before_after.text = "Lv." + str(before_level) + " (" + str(before_progress) + "/50) → Lv." + str(after_level) + " (" + str(after_progress) + "/50)"
	before_after.add_theme_font_size_override("font_size", 12)
	before_after.add_theme_color_override("font_color", Color("#CCCCCC"))
	progress_container.add_child(before_after)
	
	# Level up notification if applicable
	if after_level > before_level:
		var level_up_label = Label.new()
		level_up_label.text = "🎉 LEVEL UP! 🎉"
		level_up_label.add_theme_font_size_override("font_size", 14)
		level_up_label.add_theme_color_override("font_color", Color("#00FF00"))
		level_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_container.add_child(level_up_label)
	
	inner_container.add_child(progress_container)
	
	# Assemble structure
	margin.add_child(inner_container)
	panel.add_child(margin)
	container.add_child(panel)
	
	return container

func get_scene_params() -> Dictionary:
	if get_tree().has_meta("scene_params"):
		return get_tree().get_meta("scene_params")
	return {}

func _on_new_run_button_pressed() -> void:
	save_run_to_global_progress()
	if has_node("/root/RunExperienceTrackerAutoload"):
		get_node("/root/RunExperienceTrackerAutoload").clear_run()
	TransitionManagerAutoload.change_scene_to("res://Scenes/GameModeSelect.tscn")

func _on_main_menu_button_pressed() -> void:
	save_run_to_global_progress()
	if has_node("/root/RunExperienceTrackerAutoload"):
		get_node("/root/RunExperienceTrackerAutoload").clear_run()
	TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")

func save_run_to_global_progress():
	if not has_node("/root/RunExperienceTrackerAutoload") or not has_node("/root/GlobalProgressTrackerAutoload"):
		return
		
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	var run_exp = tracker.get_all_experience()
	
	if run_exp.size() > 0:
		global_tracker.add_run_experience(god_name, run_exp)
		print("Saved run experience to global progress for ", god_name)
