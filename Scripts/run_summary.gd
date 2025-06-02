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
	
	# Let's debug the scene tree
	print("Scene tree structure:")
	print_tree_pretty()
	
	# Try to set up UI after a delay
	await get_tree().create_timer(0.1).timeout
	setup_ui_safely()

func debug_print_tree(node: Node = self, indent: String = ""):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		debug_print_tree(child, indent + "  ")

func setup_ui_safely():
	print("\n=== Setting up UI ===")
	
	# Debug each node access
	print("Looking for VBoxContainer...")
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		push_error("VBoxContainer not found!")
		return
	print("VBoxContainer found")
	
	print("Looking for Title...")
	var title = vbox.get_node_or_null("Title")
	if not title:
		push_error("Title not found in VBoxContainer!")
		# Let's see what's actually in VBoxContainer
		print("Children of VBoxContainer:")
		for child in vbox.get_children():
			print("  - " + child.name + " (" + child.get_class() + ")")
		return
	print("Title found")
	
	print("Looking for ResultLabel...")
	var result = vbox.get_node_or_null("ResultLabel")
	if not result:
		push_error("ResultLabel not found!")
		return
	print("ResultLabel found")
	
	print("Looking for TotalExpContainer...")
	var total_exp_container = vbox.get_node_or_null("TotalExpContainer")
	if not total_exp_container:
		push_error("TotalExpContainer not found!")
		return
	print("TotalExpContainer found")
	
	print("Looking for CaptureTotal...")
	var capture_total = total_exp_container.get_node_or_null("CaptureTotal")
	if not capture_total:
		push_error("CaptureTotal not found!")
		return
	print("CaptureTotal found")
	
	print("Looking for DefenseTotal...")
	var defense_total = total_exp_container.get_node_or_null("DefenseTotal")
	if not defense_total:
		push_error("DefenseTotal not found!")
		return
	print("DefenseTotal found")
	
	print("Looking for ScrollContainer...")
	var scroll_container = vbox.get_node_or_null("ScrollContainer")
	if not scroll_container:
		push_error("ScrollContainer not found!")
		return
	print("ScrollContainer found")
	
	print("Looking for CardDetailsContainer...")
	var card_details = scroll_container.get_node_or_null("CardDetailsContainer")
	if not card_details:
		push_error("CardDetailsContainer not found!")
		return
	print("CardDetailsContainer found")
	
	print("\n=== All nodes found successfully! ===")
	
	# NOW we can safely set text
	print("Setting title text...")
	title.text = god_name + " - Run Summary"
	print("Title text set successfully")
	
	print("Setting result text...")
	if victory:
		result.text = "Victory!"
		result.add_theme_color_override("font_color", Color("#4A8A4A"))
	else:
		result.text = "Defeat"
		result.add_theme_color_override("font_color", Color("#8A4A4A"))
	print("Result text set successfully")
	
	print("Setting up experience summary...")
	setup_experience_summary(capture_total, defense_total, card_details)

func setup_experience_summary(capture_total_node: Label, defense_total_node: Label, card_details_node: VBoxContainer):
	print("\n=== Setting up experience summary ===")
	
	# Check autoloads
	if not has_node("/root/RunExperienceTrackerAutoload"):
		print("ERROR: RunExperienceTrackerAutoload not found")
		return
	print("RunExperienceTrackerAutoload found")
	
	# Get experience data from the tracker
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	var all_exp = tracker.get_all_experience()
	var totals = tracker.get_total_experience()
	
	print("Total experience - Capture: " + str(totals["capture_exp"]) + ", Defense: " + str(totals["defense_exp"]))
	
	# Set totals safely
	print("Setting capture total text...")
	capture_total_node.text = "⚔️ Total Capture: " + str(totals["capture_exp"])
	print("Capture total set")
	
	print("Setting defense total text...")
	defense_total_node.text = "🛡️ Total Defense: " + str(totals["defense_exp"])
	print("Defense total set")
	
	# Load the god's collection to get card names
	var collection_path = "res://Resources/Collections/" + god_name.to_lower() + ".tres"
	print("Loading collection from: " + collection_path)
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		print("Failed to load collection at: " + collection_path)
		return
	print("Collection loaded successfully")
	
	# Get global progress for before/after comparison
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		print("ERROR: GlobalProgressTrackerAutoload not found")
		return
	print("GlobalProgressTrackerAutoload found")
		
	var global_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	
	print("\nCreating card displays...")
	# Create detailed view for each card that gained experience
	for card_index in all_exp:
		var run_exp_data = all_exp[card_index]
		
		# Skip cards with no experience
		if run_exp_data["capture_exp"] == 0 and run_exp_data["defense_exp"] == 0:
			continue
		
		print("Processing card index: " + str(card_index))
		
		# Get card data
		var card = collection.cards[card_index] if card_index < collection.cards.size() else null
		if not card:
			print("Card not found at index: " + str(card_index))
			continue
		
		print("Card name: " + card.card_name)
		
		# Get total experience (this is the "before" state since global hasn't been updated yet)
		var before_exp_data = global_tracker.get_card_total_experience(god_name, card_index)
		var before_capture = before_exp_data["capture_exp"]
		var before_defense = before_exp_data["defense_exp"]
		
		# Calculate "after" experience (before + this run's gains)
		var after_capture = before_capture + run_exp_data["capture_exp"]
		var after_defense = before_defense + run_exp_data["defense_exp"]
		
		# Create a container for this card
		var card_container = await create_detailed_card_exp_display(
			card, 
			before_capture, after_capture,
			before_defense, after_defense,
			run_exp_data["capture_exp"], run_exp_data["defense_exp"]
		)
		card_details_node.add_child(card_container)
		
		# Add separator
		var separator = HSeparator.new()
		card_details_node.add_child(separator)
	
	print("\n=== Experience summary setup complete ===")

func create_detailed_card_exp_display(
	card: CardResource, 
	before_capture: int, after_capture: int,
	before_defense: int, after_defense: int,
	capture_gain: int, defense_gain: int
) -> Control:
	print("Creating detailed display for: ", card.card_name)
	print("  Capture: ", before_capture, " -> ", after_capture, " (gain: ", capture_gain, ")")
	print("  Defense: ", before_defense, " -> ", after_defense, " (gain: ", defense_gain, ")")
	
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 120)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	container.add_child(name_label)
	print("  Card name label added successfully")
	
	# Experience gained summary
	var summary_container = HBoxContainer.new()
	
	if capture_gain > 0:
		var capture_gain_label = Label.new()
		capture_gain_label.text = "⚔️ +" + str(capture_gain) + " Capture XP"
		capture_gain_label.add_theme_color_override("font_color", Color("#FFD700"))
		capture_gain_label.add_theme_font_size_override("font_size", 14)
		summary_container.add_child(capture_gain_label)
		print("  Capture gain label added")
	
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
		print("  Defense gain label added")
	
	container.add_child(summary_container)
	print("  Summary container added")
	
	# Progress bars container
	var progress_container = HBoxContainer.new()
	container.add_child(progress_container)
	print("  Progress container added")
	
	# Capture progress (if any experience gained)
	if capture_gain > 0:
		print("  Creating capture progress section...")
		var capture_section = VBoxContainer.new()
		capture_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var capture_title = Label.new()
		capture_title.text = "Capture Progress"
		capture_title.add_theme_font_size_override("font_size", 12)
		capture_title.add_theme_color_override("font_color", Color("#FFD700"))
		capture_section.add_child(capture_title)
		print("    Capture title added")
		
		# Try to load the ExpProgressBar scene
		print("    Loading ExpProgressBar scene...")
		var exp_bar_scene = preload("res://Scenes/ExpProgressBar.tscn")
		if not exp_bar_scene:
			print("    ERROR: Failed to preload ExpProgressBar scene!")
			return container
		print("    ExpProgressBar scene loaded successfully")
		
		# Before state
		print("    Creating before capture bar...")
		var before_capture_bar = exp_bar_scene.instantiate()
		if not before_capture_bar:
			print("    ERROR: Failed to instantiate before capture bar!")
			return container
		print("    Before capture bar instantiated")
		
		# Add to tree first, then setup
		capture_section.add_child(before_capture_bar)
		print("    Before capture bar added to tree")
		
		# Wait a frame to ensure it's properly in the tree
		await get_tree().process_frame
		
		# Now setup
		print("    Setting up before capture bar with XP: ", before_capture)
		before_capture_bar.setup_progress(before_capture, "capture", ExpProgressBar.DisplayMode.DETAILED)
		print("    Before capture bar setup complete")
		
		# Arrow
		var arrow_label = Label.new()
		arrow_label.text = "↓"
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_label.add_theme_font_size_override("font_size", 16)
		capture_section.add_child(arrow_label)
		print("    Arrow label added")
		
		# After state (will be animated)
		print("    Creating after capture bar...")
		var after_capture_bar = exp_bar_scene.instantiate()
		if not after_capture_bar:
			print("    ERROR: Failed to instantiate after capture bar!")
			return container
		
		capture_section.add_child(after_capture_bar)
		print("    After capture bar added to tree")
		
		# Wait a frame
		await get_tree().process_frame
		
		print("    Setting up after capture bar with XP: ", before_capture)
		after_capture_bar.setup_progress(before_capture, "capture", ExpProgressBar.DisplayMode.DETAILED)
		print("    After capture bar setup complete")
		
		# Schedule animation
		call_deferred("animate_progress_bar", after_capture_bar, before_capture, after_capture)
		
		progress_container.add_child(capture_section)
		print("    Capture section added to progress container")
	
	# Spacer between progress bars
	if capture_gain > 0 and defense_gain > 0:
		var spacer = VSeparator.new()
		progress_container.add_child(spacer)
		print("  Spacer added between progress bars")
	
	# Defense progress (if any experience gained)
	if defense_gain > 0:
		print("  Creating defense progress section...")
		var defense_section = VBoxContainer.new()
		defense_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var defense_title = Label.new()
		defense_title.text = "Defense Progress"
		defense_title.add_theme_font_size_override("font_size", 12)
		defense_title.add_theme_color_override("font_color", Color("#87CEEB"))
		defense_section.add_child(defense_title)
		print("    Defense title added")
		
		# Try to load the ExpProgressBar scene
		print("    Loading ExpProgressBar scene for defense...")
		var exp_bar_scene = preload("res://Scenes/ExpProgressBar.tscn")
		if not exp_bar_scene:
			print("    ERROR: Failed to preload ExpProgressBar scene for defense!")
			return container
		
		# Before state
		print("    Creating before defense bar...")
		var before_defense_bar = exp_bar_scene.instantiate()
		if not before_defense_bar:
			print("    ERROR: Failed to instantiate before defense bar!")
			return container
		
		defense_section.add_child(before_defense_bar)
		await get_tree().process_frame
		
		print("    Setting up before defense bar with XP: ", before_defense)
		before_defense_bar.setup_progress(before_defense, "defense", ExpProgressBar.DisplayMode.DETAILED)
		print("    Before defense bar setup complete")
		
		# Arrow
		var arrow_label = Label.new()
		arrow_label.text = "↓"
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow_label.add_theme_font_size_override("font_size", 16)
		defense_section.add_child(arrow_label)
		
		# After state (will be animated)
		print("    Creating after defense bar...")
		var after_defense_bar = exp_bar_scene.instantiate()
		if not after_defense_bar:
			print("    ERROR: Failed to instantiate after defense bar!")
			return container
		
		defense_section.add_child(after_defense_bar)
		await get_tree().process_frame
		
		print("    Setting up after defense bar with XP: ", before_defense)
		after_defense_bar.setup_progress(before_defense, "defense", ExpProgressBar.DisplayMode.DETAILED)
		print("    After defense bar setup complete")
		
		# Schedule animation
		call_deferred("animate_progress_bar", after_defense_bar, before_defense, after_defense)
		
		progress_container.add_child(defense_section)
		print("    Defense section added to progress container")
	
	print("Card display creation complete for: ", card.card_name)
	return container

func animate_progress_bar(progress_bar: ExpProgressBar, old_xp: int, new_xp: int):
	# Add a small delay so the UI settles first
	await get_tree().create_timer(0.5).timeout
	progress_bar.animate_progress_change(old_xp, new_xp, 1.5)

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
	if has_node("/root/RunExperienceTrackerAutoload"):
		get_node("/root/RunExperienceTrackerAutoload").clear_run()
	# Go to main menu
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

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
