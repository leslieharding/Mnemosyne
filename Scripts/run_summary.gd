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
	
	print("Run Summary parameters:")
	print("  God: ", god_name)
	print("  Deck Index: ", deck_index)
	print("  Victory: ", victory)
	
	# Set up UI immediately without waiting
	setup_ui_safely()

func setup_ui_safely():
	print("\n=== Setting up UI ===")
	
	# Get all required nodes with proper error checking
	var main_container = get_node_or_null("MainContainer")
	if not main_container:
		push_error("MainContainer not found!")
		print("Available children: ", get_children())
		return
	
	print("MainContainer found: ", main_container.name)
	print("MainContainer children: ", main_container.get_children().map(func(child): return child.name))
	
	var left_panel = main_container.get_node_or_null("LeftPanel")
	var right_panel = main_container.get_node_or_null("RightPanel")
	
	if not left_panel:
		push_error("LeftPanel not found!")
		return
	if not right_panel:
		push_error("RightPanel not found!")
		return
	
	print("LeftPanel found: ", left_panel.name)
	print("RightPanel found: ", right_panel.name)
	print("RightPanel children: ", right_panel.get_children().map(func(child): return child.name))
	
	# Get left panel nodes
	var run_details_container = left_panel.get_node_or_null("RunDetailsContainer")
	if not run_details_container:
		push_error("RunDetailsContainer not found!")
		print("LeftPanel children: ", left_panel.get_children().map(func(child): return child.name))
		return
	
	var title = left_panel.get_node_or_null("Title")
	var god_deck_info = run_details_container.get_node_or_null("GodDeckInfo")
	var outcome_label = run_details_container.get_node_or_null("OutcomeLabel")
	
	var total_exp_container = left_panel.get_node_or_null("TotalExpContainer")
	if not total_exp_container:
		push_error("TotalExpContainer not found!")
		print("LeftPanel children: ", left_panel.get_children().map(func(child): return child.name))
		return
	
	var capture_total = total_exp_container.get_node_or_null("CaptureTotal")
	var defense_total = total_exp_container.get_node_or_null("DefenseTotal")
	
	var button_container = left_panel.get_node_or_null("ButtonContainer")
	if not button_container:
		push_error("ButtonContainer not found!")
		return
	
	var new_run_button = button_container.get_node_or_null("NewRunButton")
	var main_menu_button = button_container.get_node_or_null("MainMenuButton")
	
	# Get right panel nodes - FIXED NODE NAME
	var card_display_container = right_panel.get_node_or_null("CardDetailsContainer")
	
	if not card_display_container:
		push_error("CardDetailsContainer not found in RightPanel!")
		print("RightPanel children: ", right_panel.get_children().map(func(child): return child.name))
		return
	
	print("CardDetailsContainer found: ", card_display_container.name)
	
	if not title or not god_deck_info or not outcome_label or not capture_total or not defense_total:
		push_error("Required UI nodes not found!")
		print("Missing nodes:")
		print("  title: ", title != null)
		print("  god_deck_info: ", god_deck_info != null)
		print("  outcome_label: ", outcome_label != null)
		print("  capture_total: ", capture_total != null)
		print("  defense_total: ", defense_total != null)
		return
	
	# Connect buttons
	if new_run_button:
		new_run_button.pressed.connect(_on_new_run_button_pressed)
		print("Connected new_run_button")
	else:
		print("Warning: new_run_button not found")
		
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
		print("Connected main_menu_button")
	else:
		print("Warning: main_menu_button not found")
	
	print("All nodes found successfully!")
	
	# Set up left panel content
	setup_left_panel_content(title, god_deck_info, outcome_label, capture_total, defense_total)
	
	# Set up right panel with card displays
	setup_card_displays_panel(card_display_container)

func setup_left_panel_content(title_node: Label, god_deck_node: Label, outcome_node: Label, capture_node: Label, defense_node: Label):
	print("\n=== Setting up left panel content ===")
	
	# Set title
	title_node.text = "Run Complete"
	
	# Get deck name for display
	var deck_name = get_deck_name()
	god_deck_node.text = god_name + " - " + deck_name
	god_deck_node.add_theme_font_size_override("font_size", 18)
	god_deck_node.add_theme_color_override("font_color", Color("#DDDDDD"))
	
	# Set outcome
	if victory:
		outcome_node.text = "Victory!"
		outcome_node.add_theme_color_override("font_color", Color("#4A8A4A"))
	else:
		outcome_node.text = "Defeat"
		outcome_node.add_theme_color_override("font_color", Color("#8A4A4A"))
	
	outcome_node.add_theme_font_size_override("font_size", 24)
	
	# Set up experience totals
	if has_node("/root/RunExperienceTrackerAutoload"):
		var tracker = get_node("/root/RunExperienceTrackerAutoload")
		var totals = tracker.get_total_experience()
		
		print("Experience totals: ", totals)
		
		# Use unified experience display
		capture_node.text = "⚡ Total Experience Gained: " + str(totals["total_exp"])
		capture_node.add_theme_font_size_override("font_size", 16)
		capture_node.add_theme_color_override("font_color", Color("#FFD700"))
		
		# Hide defense total since we're using unified system
		defense_node.visible = false
	else:
		print("Warning: RunExperienceTrackerAutoload not found")
		capture_node.text = "⚡ Experience data unavailable"
		defense_node.visible = false
	
	print("Left panel content setup complete")

func get_deck_name() -> String:
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	var collection: GodCardCollection = load(collection_path)
	if collection and deck_index < collection.decks.size():
		return collection.decks[deck_index].deck_name
	return "Unknown Deck"

func setup_card_displays_panel(container: VBoxContainer):
	print("\n=== Setting up card displays panel ===")
	print("Container: ", container.name if container else "null")
	
	# Clear any existing content
	if container:
		for child in container.get_children():
			child.queue_free()
		print("Cleared existing children from container")
	else:
		print("ERROR: Container is null!")
		return
	
	# Check required autoloads
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	
	if not tracker:
		print("ERROR: RunExperienceTrackerAutoload not found")
		var error_label = Label.new()
		error_label.text = "RunExperienceTrackerAutoload not available"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		error_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(error_label)
		return
	
	if not global_tracker:
		print("ERROR: GlobalProgressTrackerAutoload not found")
		var error_label = Label.new()
		error_label.text = "GlobalProgressTrackerAutoload not available"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		error_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(error_label)
		return
	
	# Get experience data
	var all_exp = tracker.get_all_experience()
	print("All experience data: ", all_exp)
	
	if all_exp.is_empty():
		print("No experience data found")
		var no_exp_label = Label.new()
		no_exp_label.text = "No experience data found for this run"
		no_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_exp_label.add_theme_color_override("font_color", Color("#888888"))
		container.add_child(no_exp_label)
		return
	
	# Load collection
	var collection_path = "res://Resources/Collections/" + god_name + ".tres"
	print("Loading collection from: ", collection_path)
	
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		print("ERROR: Failed to load collection: ", collection_path)
		var error_label = Label.new()
		error_label.text = "Failed to load " + god_name + " collection"
		error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		error_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(error_label)
		return
	
	print("Collection loaded successfully with ", collection.cards.size(), " cards")
	
	# Track if we have any cards with experience
	var cards_with_exp = 0
	
	# Create card displays for all cards that gained experience
	for card_index in all_exp:
		var run_exp_data = all_exp[card_index]
		
		print("Processing card index: ", card_index, " with exp data: ", run_exp_data)
		
		# Skip cards with no experience gain
		if run_exp_data.get("total_exp", 0) <= 0:
			print("  Skipping card with no experience")
			continue
		
		# Get card data
		if card_index >= collection.cards.size():
			print("  ERROR: Card index ", card_index, " out of bounds (collection has ", collection.cards.size(), " cards)")
			continue
			
		var card = collection.cards[card_index]
		if not card:
			print("  ERROR: Card at index ", card_index, " is null")
			continue
		
		print("  Creating display for: ", card.card_name)
		
		# Get total experience data - UNIFIED VERSION
		var before_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
		var before_total = before_exp_data["total_exp"]
		var total_gain = run_exp_data["total_exp"]
		var after_total = before_total + total_gain
		
		print("    Before total: ", before_total, ", Gain: ", total_gain, ", After total: ", after_total)
		
		# Create card display similar to apollo.gd deck preview style
		var card_container = create_apollo_style_card_display(
			card, 
			card_index,
			before_total, 
			after_total,
			total_gain
		)
		
		container.add_child(card_container)
		cards_with_exp += 1
		
		print("    Added card container for: ", card.card_name)
	
	# If no cards had experience, show a message
	if cards_with_exp == 0:
		print("No cards gained experience this run")
		var no_exp_label = Label.new()
		no_exp_label.text = "No experience gained this run"
		no_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_exp_label.add_theme_color_override("font_color", Color("#888888"))
		container.add_child(no_exp_label)
	
	print("Card displays panel setup complete! Created ", cards_with_exp, " displays")

func create_apollo_style_card_display(card: CardResource, card_index: int, before_total: int, after_total: int, total_gain: int) -> Control:
	print("Creating card display for: ", card.card_name)
	
	# Main container for this card (similar to apollo.gd)
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 120)
	
	# Create a style for the panel (similar to apollo.gd)
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
	
	# Margin container for padding (similar to apollo.gd)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card_panel.add_child(margin)
	
	# Main horizontal layout (similar to apollo.gd)
	var h_container = HBoxContainer.new()
	margin.add_child(h_container)
	
	# Left side - Card info (similar to apollo.gd)
	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_container.add_child(left_side)
	
	# Get current level for this card (handle different gods properly)
	var current_level = 1
	if god_name == "Mnemosyne":
		# Mnemosyne uses consciousness level
		var memory_manager = get_node_or_null("/root/MemoryJournalManagerAutoload")
		if memory_manager:
			var mnemosyne_data = memory_manager.get_mnemosyne_memory()
			current_level = mnemosyne_data.get("consciousness_level", 1)
	else:
		# Other gods use experience-based levels
		var progress_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
		if progress_tracker:
			current_level = progress_tracker.get_card_level(god_name, card_index)
	
	print("  Current level for ", card.card_name, ": ", current_level)
	
	# Card name with level indicator (similar to apollo.gd)
	var name_label = Label.new()
	name_label.text = card.card_name + " (Lv." + str(current_level) + ")"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	left_side.add_child(name_label)
	
	# Card values using effective values for current level (similar to apollo.gd)
	var effective_values = card.get_effective_values(current_level)
	var values_container = HBoxContainer.new()
	left_side.add_child(values_container)
	
	var directions = ["N", "E", "S", "W"]
	for i in range(4):
		var dir_label = Label.new()
		dir_label.text = directions[i] + ":" + str(effective_values[i])
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
	
	# Right side - Experience info (similar to apollo.gd but focused on run results)
	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_side.custom_minimum_size.x = 200
	h_container.add_child(right_side)
	
	# Experience gained this run
	var run_exp_title = Label.new()
	run_exp_title.text = "Experience Gained"
	run_exp_title.add_theme_font_size_override("font_size", 14)
	run_exp_title.add_theme_color_override("font_color", Color("#CCCCCC"))
	run_exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(run_exp_title)
	
	var run_exp_container = VBoxContainer.new()
	right_side.add_child(run_exp_container)
	
	# Show unified experience gained
	var total_exp_label = Label.new()
	total_exp_label.text = "⚡ +" + str(total_gain)
	total_exp_label.add_theme_font_size_override("font_size", 16)
	total_exp_label.add_theme_color_override("font_color", Color("#FFD700"))
	total_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_exp_container.add_child(total_exp_label)
	
	# Show level progression
	var before_level = ExperienceHelpers.calculate_level(before_total)
	var after_level = ExperienceHelpers.calculate_level(after_total)
	
	var progression_label = Label.new()
	if after_level > before_level:
		progression_label.text = "Lv." + str(before_level) + " → Lv." + str(after_level) + " 🎉"
		progression_label.add_theme_color_override("font_color", Color("#00FF00"))
	else:
		var before_progress = ExperienceHelpers.calculate_progress(before_total)
		var after_progress = ExperienceHelpers.calculate_progress(after_total)
		progression_label.text = "Lv." + str(before_level) + " (" + str(before_progress) + "→" + str(after_progress) + "/50)"
		progression_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	
	progression_label.add_theme_font_size_override("font_size", 10)
	progression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_exp_container.add_child(progression_label)
	
	print("  Card display created successfully")
	return card_panel

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
	var tracker = get_node_or_null("/root/RunExperienceTrackerAutoload")
	var global_tracker = get_node_or_null("/root/GlobalProgressTrackerAutoload")
	
	if not tracker or not global_tracker:
		print("Missing trackers for saving progress")
		return
		
	var run_exp = tracker.get_all_experience()
	
	if run_exp.size() > 0:
		global_tracker.add_run_experience(god_name, run_exp)
		print("Saved run experience to global progress for ", god_name)
	else:
		print("No run experience to save")
