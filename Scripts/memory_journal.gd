# res://Scripts/memory_journal.gd
extends Control
class_name MemoryJournalUI

signal journal_closed()

# UI References - these will be connected automatically by the scene structure
@onready var main_panel = $MainContainer
@onready var tab_container = $MainContainer/VBox/TabContainer
@onready var close_button = $MainContainer/VBox/Header/CloseButton
@onready var title_label = $MainContainer/VBox/Header/TitleLabel
@onready var summary_label = $MainContainer/VBox/Header/SummaryLabel

# Tab references
@onready var bestiary_tab = $MainContainer/VBox/TabContainer/Bestiary
@onready var gods_tab = $MainContainer/VBox/TabContainer/Gods
@onready var mnemosyne_tab = $MainContainer/VBox/TabContainer/Mnemosyne

# Animation
var journal_tween: Tween

func _ready():
	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	
	# Set up initial state (hidden)
	modulate.a = 0.0
	main_panel.scale = Vector2(0.8, 0.8)
	
	# Handle escape key
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		close_journal()

# Show the journal with animation
func show_journal(initial_tab: String = ""):
	visible = true
	
	# Update content before showing
	refresh_all_content()
	
	# Select initial tab if specified
	if initial_tab != "":
		match initial_tab:
			"bestiary":
				tab_container.current_tab = 0
			"gods":
				tab_container.current_tab = 1
			"mnemosyne":
				tab_container.current_tab = 2
	
	# Animate in
	if journal_tween:
		journal_tween.kill()
	
	journal_tween = create_tween()
	journal_tween.set_parallel(true)
	
	# Fade in
	journal_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Scale up from center
	journal_tween.tween_property(main_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# Close the journal with animation
func close_journal():
	if journal_tween:
		journal_tween.kill()
	
	journal_tween = create_tween()
	journal_tween.set_parallel(true)
	
	# Fade out
	journal_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Scale down
	journal_tween.tween_property(main_panel, "scale", Vector2(0.8, 0.8), 0.2).set_ease(Tween.EASE_IN)
	
	# Hide when complete
	journal_tween.tween_callback(func(): visible = false)
	
	emit_signal("journal_closed")

# Handle close button
func _on_close_pressed():
	close_journal()

# Refresh all tab content
func refresh_all_content():
	update_header()
	refresh_bestiary_tab()
	refresh_gods_tab()
	refresh_mnemosyne_tab()

# Update the header with summary info
func update_header():
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var summary = memory_manager.get_memory_summary()
	
	title_label.text = "Mnemosyne's Memory Journal"
	
	var consciousness_desc = memory_manager.get_consciousness_description(summary["consciousness_level"])
	summary_label.text = consciousness_desc + " • " + str(summary["enemies_encountered"]) + " Enemies • " + str(summary["gods_experienced"]) + " Gods"

func refresh_bestiary_tab():
	print("=== REFRESHING BESTIARY TAB ===")
	
	if not has_node("/root/MemoryJournalManagerAutoload"):
		print("ERROR: MemoryJournalManagerAutoload not found!")
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	
	# DEBUG: Call debug function
	memory_manager.debug_memory_state()
	
	var enemy_memories = memory_manager.get_all_enemy_memories()
	
	print("Enemy memories found: ", enemy_memories.size())
	for enemy_name in enemy_memories:
		print("- ", enemy_name, ": ", enemy_memories[enemy_name])
	
	# Get the enemy list container and fix sizing issues
	var left_panel = bestiary_tab.get_node("LeftPanel")
	var scroll_container = left_panel.get_node("ScrollContainer")
	var enemy_list = scroll_container.get_node("EnemyList")
	
	# Force proper sizing on the containers
	left_panel.custom_minimum_size = Vector2(250, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	scroll_container.custom_minimum_size = Vector2(0, 400)  # Set minimum height
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	enemy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	print("DEBUG: EnemyList found: ", enemy_list != null)
	if enemy_list:
		print("DEBUG: EnemyList size: ", enemy_list.size)
		print("DEBUG: EnemyList visible: ", enemy_list.visible)
		print("DEBUG: EnemyList modulate: ", enemy_list.modulate)
		print("DEBUG: ScrollContainer size: ", scroll_container.size)
		print("DEBUG: LeftPanel size: ", left_panel.size)
	
	# Clear existing content
	for child in enemy_list.get_children():
		child.queue_free()
	
	# Wait a frame to ensure children are cleared
	await get_tree().process_frame
	
	# Check if we have any enemy data
	if enemy_memories.is_empty():
		print("No enemy memories found - adding placeholder")
		var no_data_label = Label.new()
		no_data_label.text = "No enemies encountered yet.\nFight some battles to populate the bestiary!"
		no_data_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.add_theme_color_override("font_color", Color("#888888"))
		no_data_label.custom_minimum_size = Vector2(200, 60)  # Ensure minimum size
		no_data_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enemy_list.add_child(no_data_label)
		return
	
	# Sort enemies by memory level (highest first), then by total experience
	var sorted_enemies = []
	for enemy_name in enemy_memories:
		var enemy_data = enemy_memories[enemy_name]
		sorted_enemies.append({
			"name": enemy_name,
			"data": enemy_data,
			"level": enemy_data["memory_level"],
			"experience": enemy_data["total_experience"]
		})
	
	sorted_enemies.sort_custom(func(a, b): 
		if a.level != b.level:
			return a.level > b.level
		return a.experience > b.experience
	)
	
	print("Sorted enemies: ", sorted_enemies.size())
	
	# Add each enemy as an enhanced button
	for enemy_entry in sorted_enemies:
		var enemy_name = enemy_entry.name
		var enemy_data = enemy_entry.data
		print("Creating button for: ", enemy_name)
		
		var button = create_enemy_list_button(enemy_name, enemy_data, memory_manager)
		
		# DEBUG: Check button properties
		print("Button created - Text: '", button.text, "' Size: ", button.custom_minimum_size)
		print("Button parent will be: ", enemy_list.name)
		print("Enemy list children before adding: ", enemy_list.get_children().size())
		
		enemy_list.add_child(button)
		
		print("Enemy list children after adding: ", enemy_list.get_children().size())
		print("Button is visible: ", button.visible)
		print("Button modulate: ", button.modulate)
		print("Button position: ", button.position)
		print("Button size after adding: ", button.size)
		
		# Connect to show details
		button.pressed.connect(_on_enemy_selected.bind(enemy_name, enemy_data))
	
	# Force layout updates
	await get_tree().process_frame
	enemy_list.queue_redraw()
	scroll_container.queue_redraw()
	left_panel.queue_redraw()
	
	print("Bestiary refresh complete - added ", sorted_enemies.size(), " enemies")
	print("Final EnemyList size: ", enemy_list.size)
	print("Final ScrollContainer size: ", scroll_container.size)
	print("Final LeftPanel size: ", left_panel.size)
	print("Final EnemyList children: ", enemy_list.get_children().size())

func create_enemy_list_button(enemy_name: String, enemy_data: Dictionary, memory_manager: MemoryJournalManager) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(220, 80)  # Ensure minimum size
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Expand to fill container width
	
	# Create button text with level and experience info
	var level_desc = memory_manager.get_bestiary_memory_description(enemy_data["memory_level"])
	var exp_info = str(enemy_data["total_experience"]) + " exp"
	
	# Get next level threshold for progress display
	var next_threshold = ""
	var current_level = enemy_data["memory_level"]
	if current_level < memory_manager.BESTIARY_EXPERIENCE_THRESHOLDS.size() - 1:
		var next_level_exp = memory_manager.BESTIARY_EXPERIENCE_THRESHOLDS[current_level + 1]
		var progress = enemy_data["total_experience"]
		next_threshold = " (" + str(progress) + "/" + str(next_level_exp) + ")"
	else:
		next_threshold = " (MAX)"
	
	button.text = enemy_name + "\n" + level_desc + " - " + exp_info + next_threshold
	
	print("Creating button with text: ", button.text)
	print("Button size: ", button.custom_minimum_size)
	
	# Create a more visible style
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# Make sure the button is clearly visible with distinct colors
	match enemy_data["memory_level"]:
		0: # Unknown - dark gray
			style.bg_color = Color("#2A2A2A")
			style.border_color = Color("#444444")
		1: # Glimpsed - dark blue
			style.bg_color = Color("#1A2A3A")
			style.border_color = Color("#2A4A5A")
		2: # Observed - blue (this is what Shadow Acolyte should be)
			style.bg_color = Color("#2A3A4A")
			style.border_color = Color("#4A5A6A")
		3: # Understood - green
			style.bg_color = Color("#2A3A2A")
			style.border_color = Color("#4A6A4A")
		4: # Analyzed - yellow/gold
			style.bg_color = Color("#3A3A1A")
			style.border_color = Color("#6A6A2A")
		5: # Mastered - purple
			style.bg_color = Color("#3A2A3A")
			style.border_color = Color("#6A4A6A")
		_: # Transcendent - bright gold
			style.bg_color = Color("#4A4A2A")
			style.border_color = Color("#8A8A4A")
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	# Apply styles to all button states
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	
	# Ensure text is visible
	button.add_theme_color_override("font_color", Color("#DDDDDD"))
	button.add_theme_font_size_override("font_size", 12)
	
	# Set alignment - FIXED: Use 'alignment' instead of 'horizontal_alignment' for Button
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	print("Button style applied for level ", enemy_data["memory_level"], " with bg color ", style.bg_color)
	
	return button

# Handle enemy selection in bestiary with detailed information
func _on_enemy_selected(enemy_name: String, enemy_data: Dictionary):
	var details_panel = bestiary_tab.get_node("RightPanel")
	
	# Clear existing content
	for child in details_panel.get_children():
		child.queue_free()
	
	# Get detailed enemy information based on memory level
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var detailed_info = memory_manager.get_enemy_detailed_info(enemy_name)
	
	if detailed_info.is_empty():
		var error_label = Label.new()
		error_label.text = "No information available."
		details_panel.add_child(error_label)
		return
	
	# Create detailed display
	create_detailed_enemy_display(details_panel, detailed_info)

# Create a comprehensive enemy details display
func create_detailed_enemy_display(container: Control, info: Dictionary):
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	
	# Enemy name and memory level
	var header_container = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = info["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	header_container.add_child(name_label)
	
	var memory_label = Label.new()
	memory_label.text = "Memory Level: " + str(info["memory_level"]) + " (" + info["memory_description"] + ")"
	memory_label.add_theme_font_size_override("font_size", 14)
	memory_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	header_container.add_child(memory_label)
	
	var exp_label = Label.new()
	exp_label.text = "Total Experience: " + str(info["total_experience"])
	exp_label.add_theme_font_size_override("font_size", 12)
	exp_label.add_theme_color_override("font_color", Color("#888888"))
	header_container.add_child(exp_label)
	
	main_vbox.add_child(header_container)
	
	# Separator
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = info["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	main_vbox.add_child(desc_label)
	
	# Statistics (based on memory level)
	if "visible_stats" in info and info["visible_stats"].size() > 0:
		var separator2 = HSeparator.new()
		main_vbox.add_child(separator2)
		
		var stats_title = Label.new()
		stats_title.text = "Combat Statistics"
		stats_title.add_theme_font_size_override("font_size", 16)
		stats_title.add_theme_color_override("font_color", Color("#DDDDDD"))
		main_vbox.add_child(stats_title)
		
		var stats_container = VBoxContainer.new()
		
		for stat in info["visible_stats"]:
			match stat:
				"encounters":
					var encounters_label = Label.new()
					encounters_label.text = "Total Encounters: " + str(info["encounters"])
					encounters_label.add_theme_color_override("font_color", Color("#AAAAAA"))
					stats_container.add_child(encounters_label)
				"victories":
					var victories_label = Label.new()
					victories_label.text = "Victories: " + str(info["victories"])
					victories_label.add_theme_color_override("font_color", Color("#66BB6A"))
					stats_container.add_child(victories_label)
				"defeats":
					var defeats_label = Label.new()
					defeats_label.text = "Defeats: " + str(info["defeats"])
					defeats_label.add_theme_color_override("font_color", Color("#EF5350"))
					stats_container.add_child(defeats_label)
				"win_rate":
					if "win_rate" in info:
						var winrate_label = Label.new()
						winrate_label.text = "Win Rate: " + str(info["win_rate"]) + "%"
						var color = Color("#66BB6A") if info["win_rate"] >= 50 else Color("#EF5350")
						winrate_label.add_theme_color_override("font_color", color)
						stats_container.add_child(winrate_label)
		
		main_vbox.add_child(stats_container)
	
	# Tactical information (higher memory levels)
	if "tactical_note" in info and info["tactical_note"] != "":
		var separator3 = HSeparator.new()
		main_vbox.add_child(separator3)
		
		var tactical_title = Label.new()
		tactical_title.text = "Tactical Analysis"
		tactical_title.add_theme_font_size_override("font_size", 16)
		tactical_title.add_theme_color_override("font_color", Color("#DDDDDD"))
		main_vbox.add_child(tactical_title)
		
		var tactical_label = Label.new()
		tactical_label.text = info["tactical_note"]
		tactical_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tactical_label.add_theme_font_size_override("font_size", 12)
		tactical_label.add_theme_color_override("font_color", Color("#BBBBBB"))
		main_vbox.add_child(tactical_label)
	
	# Weakness hints (level 4+)
	if "weakness_hint" in info and info["weakness_hint"] != "":
		var weakness_title = Label.new()
		weakness_title.text = "Identified Weaknesses"
		weakness_title.add_theme_font_size_override("font_size", 14)
		weakness_title.add_theme_color_override("font_color", Color("#FFB74D"))
		main_vbox.add_child(weakness_title)
		
		var weakness_label = Label.new()
		weakness_label.text = info["weakness_hint"]
		weakness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		weakness_label.add_theme_font_size_override("font_size", 12)
		weakness_label.add_theme_color_override("font_color", Color("#FFB74D"))
		main_vbox.add_child(weakness_label)
	
	# Optimal strategy (level 5)
	if "optimal_strategy" in info and info["optimal_strategy"] != "":
		var strategy_title = Label.new()
		strategy_title.text = "Optimal Strategy"
		strategy_title.add_theme_font_size_override("font_size", 14)
		strategy_title.add_theme_color_override("font_color", Color("#AB47BC"))
		main_vbox.add_child(strategy_title)
		
		var strategy_label = Label.new()
		strategy_label.text = info["optimal_strategy"]
		strategy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		strategy_label.add_theme_font_size_override("font_size", 12)
		strategy_label.add_theme_color_override("font_color", Color("#AB47BC"))
		main_vbox.add_child(strategy_label)
	
	# Add main container to the details panel
	container.add_child(main_vbox)

# Refresh gods tab content
func refresh_gods_tab():
	print("=== REFRESHING GODS TAB ===")
	
	if not has_node("/root/MemoryJournalManagerAutoload"):
		print("ERROR: MemoryJournalManagerAutoload not found!")
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var god_memories = memory_manager.get_all_god_memories()
	
	# Get the god list container and fix sizing
	var left_panel = gods_tab.get_node("LeftPanel")
	var scroll_container = left_panel.get_node("ScrollContainer")
	var god_list = scroll_container.get_node("GodList")
	
	# Force proper sizing on the containers
	left_panel.custom_minimum_size = Vector2(250, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	scroll_container.custom_minimum_size = Vector2(0, 400)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	god_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	god_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Clear existing content
	for child in god_list.get_children():
		child.queue_free()
	
	# Wait a frame to ensure children are cleared
	await get_tree().process_frame
	
	# Check if we have any god data
	if god_memories.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = "No divine connections yet.\nFight battles with different gods to build mastery!"
		no_data_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_data_label.add_theme_color_override("font_color", Color("#888888"))
		no_data_label.custom_minimum_size = Vector2(200, 60)
		no_data_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		god_list.add_child(no_data_label)
		return
	
	# Sort gods by mastery level (highest first), then by battles fought
	var sorted_gods = []
	for god_name in god_memories:
		var god_data = god_memories[god_name]
		sorted_gods.append({
			"name": god_name,
			"data": god_data,
			"level": god_data["memory_level"],
			"battles": god_data["battles_fought"]
		})
	
	sorted_gods.sort_custom(func(a, b): 
		if a.level != b.level:
			return a.level > b.level
		return a.battles > b.battles
	)
	
	# Add each god as an enhanced button
	for god_entry in sorted_gods:
		var god_name = god_entry.name
		var god_data = god_entry.data
		
		var button = create_god_list_button(god_name, god_data, memory_manager)
		god_list.add_child(button)
		
		# Connect to show details
		button.pressed.connect(_on_god_selected.bind(god_name, god_data))
	
	# Force layout updates
	await get_tree().process_frame
	god_list.queue_redraw()
	scroll_container.queue_redraw()
	left_panel.queue_redraw()
	
	print("Gods tab refresh complete - added ", sorted_gods.size(), " gods")

func create_god_list_button(god_name: String, god_data: Dictionary, memory_manager: MemoryJournalManager) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(220, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create button text with mastery level and battles info
	var level_desc = memory_manager.get_god_memory_description(god_data["memory_level"])
	var battles_info = str(god_data["battles_fought"]) + " battles"
	var decks_info = str(god_data["decks_discovered"].size()) + " decks"
	
	button.text = god_name + "\n" + level_desc + "\n" + battles_info + " • " + decks_info
	
	# Create a style based on mastery level
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# Color based on mastery level
	match god_data["memory_level"]:
		0: # Unfamiliar - dark gray
			style.bg_color = Color("#2A2A2A")
			style.border_color = Color("#444444")
		1: # Novice - light blue
			style.bg_color = Color("#1A2A4A")
			style.border_color = Color("#2A4A6A")
		2: # Practiced - blue
			style.bg_color = Color("#2A3A5A")
			style.border_color = Color("#4A5A7A")
		3: # Skilled - green
			style.bg_color = Color("#2A4A2A")
			style.border_color = Color("#4A6A4A")
		4: # Expert - gold
			style.bg_color = Color("#4A4A2A")
			style.border_color = Color("#6A6A2A")
		5: # Divine Mastery - purple
			style.bg_color = Color("#4A2A4A")
			style.border_color = Color("#6A4A6A")
		_: # Eternal Bond - bright gold
			style.bg_color = Color("#5A5A2A")
			style.border_color = Color("#8A8A4A")
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	# Apply styles
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	
	# Text styling
	button.add_theme_color_override("font_color", Color("#DDDDDD"))
	button.add_theme_font_size_override("font_size", 12)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	return button

# Handle god selection
func _on_god_selected(god_name: String, god_data: Dictionary):
	var details_panel = gods_tab.get_node("RightPanel")
	
	# Clear existing content
	for child in details_panel.get_children():
		child.queue_free()
	
	# Create detailed god display
	create_detailed_god_display(details_panel, god_name, god_data)

func create_detailed_god_display(container: Control, god_name: String, god_data: Dictionary):
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	
	# God name and mastery level
	var header_container = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = god_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	header_container.add_child(name_label)
	
	var mastery_label = Label.new()
	mastery_label.text = "Mastery Level: " + str(god_data["memory_level"]) + " (" + memory_manager.get_god_memory_description(god_data["memory_level"]) + ")"
	mastery_label.add_theme_font_size_override("font_size", 16)
	mastery_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	header_container.add_child(mastery_label)
	
	main_vbox.add_child(header_container)
	
	# Separator
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)
	
	# Battle statistics
	var stats_container = VBoxContainer.new()
	
	var stats_title = Label.new()
	stats_title.text = "Divine Connection Statistics"
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_title.add_theme_color_override("font_color", Color("#CCCCCC"))
	stats_container.add_child(stats_title)
	
	var battles_label = Label.new()
	battles_label.text = "Battles Fought: " + str(god_data["battles_fought"])
	battles_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	stats_container.add_child(battles_label)
	
	var first_used_label = Label.new()
	first_used_label.text = "First Connection: " + god_data["first_used"]
	first_used_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	stats_container.add_child(first_used_label)
	
	var last_used_label = Label.new()
	last_used_label.text = "Last Used: " + god_data["last_used"]
	last_used_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	stats_container.add_child(last_used_label)
	
	main_vbox.add_child(stats_container)
	
	# Separator
	var separator2 = HSeparator.new()
	main_vbox.add_child(separator2)
	
	# Discovered decks
	var decks_container = VBoxContainer.new()
	
	var decks_title = Label.new()
	decks_title.text = "Discovered Deck Combinations (" + str(god_data["decks_discovered"].size()) + ")"
	decks_title.add_theme_font_size_override("font_size", 16)
	decks_title.add_theme_color_override("font_color", Color("#CCCCCC"))
	decks_container.add_child(decks_title)
	
	if god_data["decks_discovered"].size() > 0:
		for deck_name in god_data["decks_discovered"]:
			var deck_label = Label.new()
			deck_label.text = "• " + deck_name
			deck_label.add_theme_color_override("font_color", Color("#AAAAAA"))
			deck_label.add_theme_font_size_override("font_size", 14)
			decks_container.add_child(deck_label)
	else:
		var no_decks_label = Label.new()
		no_decks_label.text = "No deck variations discovered yet."
		no_decks_label.add_theme_color_override("font_color", Color("#888888"))
		no_decks_label.add_theme_font_size_override("font_size", 12)
		decks_container.add_child(no_decks_label)
	
	main_vbox.add_child(decks_container)
	
	# Mastery insights (for higher levels)
	if god_data["memory_level"] >= 3:
		var separator3 = HSeparator.new()
		main_vbox.add_child(separator3)
		
		var insights_container = VBoxContainer.new()
		
		var insights_title = Label.new()
		insights_title.text = "Divine Insights"
		insights_title.add_theme_font_size_override("font_size", 16)
		insights_title.add_theme_color_override("font_color", Color("#FFD700"))
		insights_container.add_child(insights_title)
		
		var insight_text = get_god_insight_text(god_name, god_data["memory_level"])
		var insight_label = Label.new()
		insight_label.text = insight_text
		insight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		insight_label.add_theme_color_override("font_color", Color("#DDDDDD"))
		insight_label.add_theme_font_size_override("font_size", 13)
		insights_container.add_child(insight_label)
		
		main_vbox.add_child(insights_container)
	
	# Add to container
	container.add_child(main_vbox)

func get_god_insight_text(god_name: String, mastery_level: int) -> String:
	match god_name:
		"Apollo":
			match mastery_level:
				3: return "The god of light and prophecy reveals patterns in enemy movements. His solar blessing enhances your ability to predict opponent strategies."
				4: return "Apollo's divine guidance flows through you. You've learned to channel his prophetic powers to anticipate multiple moves ahead."
				5: return "You have achieved perfect harmony with Apollo's essence. Light itself bends to your will in battle."
				_: return "Apollo's eternal radiance has bonded with your soul. You are one with the sun god's infinite wisdom."
		"Artemis":
			match mastery_level:
				3: return "The huntress teaches precision and patience. Your strikes become more focused and deadly."
				4: return "Artemis's wild spirit awakens within you. You move with the grace and lethality of nature itself."
				5: return "The moon goddess has accepted you as her equal. Your hunting instincts are supernaturally sharp."
				_: return "You and Artemis hunt as one eternal pack, predator and prey united in perfect balance."
		_:
			match mastery_level:
				3: return "Your connection with this deity deepens, revealing new tactical possibilities."
				4: return "Divine wisdom flows through your actions, granting enhanced combat intuition."
				5: return "You have achieved mastery over this god's domain, unlocking their full potential."
				_: return "Your bond transcends mortality, becoming one with the divine essence itself."

# NEW MNEMOSYNE DECK FUNCTIONS

func refresh_mnemosyne_tab():
	print("=== REFRESHING MNEMOSYNE TAB WITH DECK DISPLAY ===")
	
	# Use the correct paths based on the scene structure
	var left_panel = mnemosyne_tab.get_node("LeftPanel")
	var right_panel = mnemosyne_tab.get_node("RightPanel")
	
	if not left_panel or not right_panel:
		print("ERROR: Could not find basic panels")
		return
	
	var scroll_container = left_panel.get_node("ScrollContainer")
	if not scroll_container:
		print("ERROR: Could not find ScrollContainer")
		return
	
	var card_list = scroll_container.get_node("MnemosyneCardList")
	if not card_list:
		print("ERROR: Could not find MnemosyneCardList")
		return
	
	var detail_panel = right_panel.get_node("MnemosyneDetailPanel")
	if not detail_panel:
		print("ERROR: Could not find MnemosyneDetailPanel")
		return
	
	print("SUCCESS: Found all required nodes!")
	
	# FIX THE SIZING ISSUES - This is the key fix!
	left_panel.custom_minimum_size = Vector2(250, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	scroll_container.custom_minimum_size = Vector2(0, 400)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Update the left panel title
	var title_label = left_panel.get_node("Mnemosyne'sMemories")  # Note: no space in the name
	if title_label:
		title_label.text = "Mnemosyne's Memories"
		title_label.add_theme_color_override("font_color", Color("#DDA0DD"))
	
	# Clear existing cards from the list
	for child in card_list.get_children():
		child.queue_free()
	
	# Clear existing detail panel content
	for child in detail_panel.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add default message to detail panel
	var default_label = Label.new()
	default_label.text = "Select a memory card to view details"
	default_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	default_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	default_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	detail_panel.add_child(default_label)
	
	# Load and populate Mnemosyne deck
	await populate_mnemosyne_deck(card_list, detail_panel)
	
	# Force layout update after adding content
	await get_tree().process_frame
	left_panel.queue_redraw()
	scroll_container.queue_redraw()
	card_list.queue_redraw()
	
	print("Mnemosyne tab refresh complete with deck display!")

func populate_mnemosyne_deck(card_list_container: VBoxContainer, detail_panel: VBoxContainer):
	print("Loading Mnemosyne deck...")
	
	# Add debugging for container sizing
	print("DEBUG: card_list_container size: ", card_list_container.size)
	print("DEBUG: card_list_container custom_minimum_size: ", card_list_container.custom_minimum_size)
	print("DEBUG: card_list_container visible: ", card_list_container.visible)
	print("DEBUG: card_list_container children before: ", card_list_container.get_children().size())
	
	# Force proper sizing on the card list container
	card_list_container.custom_minimum_size = Vector2(230, 400)
	card_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_list_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Load Mnemosyne collection
	var collection_path = "res://Resources/Collections/Mnemosyne.tres"
	if not ResourceLoader.exists(collection_path):
		print("ERROR: Mnemosyne collection not found at: ", collection_path)
		var error_label = Label.new()
		error_label.text = "Mnemosyne collection not found!"
		error_label.add_theme_color_override("font_color", Color.RED)
		card_list_container.add_child(error_label)
		return
	
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		print("ERROR: Failed to load Mnemosyne collection")
		return
	
	# Get the Mnemosyne deck (first deck since there's only one)
	var mnemosyne_deck = collection.get_deck(0)
	print("Loaded Mnemosyne deck with ", mnemosyne_deck.size(), " cards")
	
	if mnemosyne_deck.is_empty():
		var no_cards_label = Label.new()
		no_cards_label.text = "No memory cards found in Mnemosyne's collection."
		no_cards_label.add_theme_color_override("font_color", Color("#888888"))
		card_list_container.add_child(no_cards_label)
		return
	
	# Create card displays similar to Apollo deck display
	for i in range(mnemosyne_deck.size()):
		var card = mnemosyne_deck[i]
		if not card:
			print("Skipping null card at index ", i)
			continue
		
		var card_display = create_mnemosyne_card_display(card, i)
		card_list_container.add_child(card_display)
		
		print("Created display for Mnemosyne card: ", card.card_name)
		print("  - Card display size: ", card_display.size)
		print("  - Card display custom_minimum_size: ", card_display.custom_minimum_size)
		print("  - Card display visible: ", card_display.visible)
	
	# Force layout updates
	await get_tree().process_frame
	card_list_container.queue_redraw()
	
	print("Created ", mnemosyne_deck.size(), " Mnemosyne card displays")
	print("DEBUG: card_list_container children after: ", card_list_container.get_children().size())
	print("DEBUG: card_list_container final size: ", card_list_container.size)
	
	# Test by adding a simple visible label to verify the container works
	var test_label = Label.new()
	test_label.text = "TEST: If you can see this, the container is working!"
	test_label.add_theme_color_override("font_color", Color.RED)
	test_label.add_theme_font_size_override("font_size", 16)
	card_list_container.add_child(test_label)
	print("Added test label to verify container visibility")

func create_mnemosyne_card_display(card: CardResource, card_index: int) -> Control:
	print("Creating card display for: ", card.card_name)
	
	# Main container for this card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(220, 100)  # Ensure minimum size
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create a style for the panel - using Mnemosyne's purple theme
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A1A2A")  # Dark purple background
	style.border_color = Color("#6A4A6A")  # Purple border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card_panel.add_theme_stylebox_override("panel", style)
	
	# Margin container for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card_panel.add_child(margin)
	
	# Main horizontal layout
	var h_container = HBoxContainer.new()
	margin.add_child(h_container)
	
	# Left side - Card info
	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_container.add_child(left_side)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDA0DD"))  # Light purple for Mnemosyne
	left_side.add_child(name_label)
	
	# Card description (truncated if too long)
	var desc_label = Label.new()
	var description = card.description
	if description.length() > 60:
		description = description.substr(0, 57) + "..."
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_side.add_child(desc_label)
	
	# Card values in a compact format
	var values_container = HBoxContainer.new()
	left_side.add_child(values_container)
	
	var directions = ["N", "E", "S", "W"]
	for i in range(4):
		var dir_label = Label.new()
		dir_label.text = directions[i] + ":" + str(card.values[i])
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
	
	# Right side - Memory enhancement info (placeholder for future upgrades)
	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_side.custom_minimum_size.x = 120  # Reduced to fit better
	h_container.add_child(right_side)
	
	# Enhancement title
	var enhancement_title = Label.new()
	enhancement_title.text = "Memory State"
	enhancement_title.add_theme_font_size_override("font_size", 14)
	enhancement_title.add_theme_color_override("font_color", Color("#DDA0DD"))
	enhancement_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(enhancement_title)
	
	# Base level (placeholder for future enhancement system)
	var level_label = Label.new()
	level_label.text = "Base Memory"
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(level_label)
	
	# Enhancement progress (placeholder)
	var progress_label = Label.new()
	progress_label.text = "Stable"
	progress_label.add_theme_font_size_override("font_size", 10)
	progress_label.add_theme_color_override("font_color", Color("#999999"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_side.add_child(progress_label)
	
	# Make the entire card clickable
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(220, 100)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_mnemosyne_card_selected.bind(card, card_index))
	
	# Create final container
	var container = Control.new()
	container.custom_minimum_size = Vector2(220, 100)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(button)
	container.add_child(card_panel)
	
	# Ensure everything fills properly
	button.anchors_preset = Control.PRESET_FULL_RECT
	card_panel.anchors_preset = Control.PRESET_FULL_RECT
	
	print("  - Created container with size: ", container.custom_minimum_size)
	return container

func _on_mnemosyne_card_selected(card: CardResource, card_index: int):
	print("Mnemosyne card selected: ", card_index, " - ", card.card_name)
	
	# Get the detail panel from the existing scene structure
	var detail_panel = mnemosyne_tab.get_node("RightPanel/MnemosyneDetailPanel")
	if not detail_panel:
		print("ERROR: Could not find detail panel at RightPanel/MnemosyneDetailPanel")
		# Try to debug the structure
		print("Available nodes in mnemosyne_tab:")
		for child in mnemosyne_tab.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
		return
	
	# Clear current detail panel
	for child in detail_panel.get_children():
		child.queue_free()
	
	# Wait a frame to ensure children are cleared
	await get_tree().process_frame
	
	# Create detailed card display
	create_detailed_mnemosyne_card_display(detail_panel, card, card_index)

func create_detailed_mnemosyne_card_display(container: VBoxContainer, card: CardResource, card_index: int):
	# Main container
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	
	# Card name title
	var title_label = Label.new()
	title_label.text = card.card_name
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("#DDA0DD"))  # Mnemosyne purple
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	# Separator
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)
	
	# Power values section
	var values_section = VBoxContainer.new()
	values_section.add_theme_constant_override("separation", 8)
	
	var values_title = Label.new()
	values_title.text = "Directional Power Values:"
	values_title.add_theme_font_size_override("font_size", 14)
	values_title.add_theme_color_override("font_color", Color.WHITE)
	values_section.add_child(values_title)
	
	# Create a grid for power values
	var power_grid = GridContainer.new()
	power_grid.columns = 2
	power_grid.add_theme_constant_override("h_separation", 20)
	power_grid.add_theme_constant_override("v_separation", 5)
	
	var directions = ["North", "East", "South", "West"]
	var direction_colors = [Color("#87CEEB"), Color("#FFB74D"), Color("#FF7043"), Color("#66BB6A")]
	
	for i in range(4):
		var dir_label = Label.new()
		dir_label.text = directions[i] + ":"
		dir_label.add_theme_color_override("font_color", direction_colors[i])
		dir_label.add_theme_font_size_override("font_size", 12)
		power_grid.add_child(dir_label)
		
		var value_label = Label.new()
		value_label.text = str(card.values[i])
		value_label.add_theme_color_override("font_color", Color.WHITE)
		value_label.add_theme_font_size_override("font_size", 12)
		power_grid.add_child(value_label)
	
	values_section.add_child(power_grid)
	main_vbox.add_child(values_section)
	
	# Separator
	var separator2 = HSeparator.new()
	main_vbox.add_child(separator2)
	
	# Description section
	var desc_section = VBoxContainer.new()
	desc_section.add_theme_constant_override("separation", 5)
	
	var desc_title = Label.new()
	desc_title.text = "Memory Fragment:"
	desc_title.add_theme_font_size_override("font_size", 14)
	desc_title.add_theme_color_override("font_color", Color.WHITE)
	desc_section.add_child(desc_title)
	
	var desc_label = Label.new()
	desc_label.text = card.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_section.add_child(desc_label)
	
	main_vbox.add_child(desc_section)
	
	# Abilities section
	if card.abilities.size() > 0:
		var separator3 = HSeparator.new()
		main_vbox.add_child(separator3)
		
		var abilities_section = VBoxContainer.new()
		abilities_section.add_theme_constant_override("separation", 8)
		
		var abilities_title = Label.new()
		abilities_title.text = "Special Abilities:"
		abilities_title.add_theme_font_size_override("font_size", 14)
		abilities_title.add_theme_color_override("font_color", Color.WHITE)
		abilities_section.add_child(abilities_title)
		
		for ability in card.abilities:
			var ability_container = VBoxContainer.new()
			ability_container.add_theme_constant_override("separation", 2)
			
			var ability_name = Label.new()
			ability_name.text = "• " + ability.ability_name
			ability_name.add_theme_font_size_override("font_size", 12)
			ability_name.add_theme_color_override("font_color", Color("#FFD700"))
			ability_container.add_child(ability_name)
			
			var ability_desc = Label.new()
			ability_desc.text = "  " + ability.description
			ability_desc.add_theme_font_size_override("font_size", 11)
			ability_desc.add_theme_color_override("font_color", Color("#CCCCCC"))
			ability_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ability_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ability_container.add_child(ability_desc)
			
			abilities_section.add_child(ability_container)
		
		main_vbox.add_child(abilities_section)
	else:
		# No abilities
		var separator3 = HSeparator.new()
		main_vbox.add_child(separator3)
		
		var no_abilities_label = Label.new()
		no_abilities_label.text = "No special abilities (pure memory essence)"
		no_abilities_label.add_theme_font_size_override("font_size", 11)
		no_abilities_label.add_theme_color_override("font_color", Color("#888888"))
		no_abilities_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main_vbox.add_child(no_abilities_label)
	
	# Enhancement status section (placeholder for future upgrade system)
	var separator4 = HSeparator.new()
	main_vbox.add_child(separator4)
	
	var enhancement_section = VBoxContainer.new()
	enhancement_section.add_theme_constant_override("separation", 5)
	
	var enhancement_title = Label.new()
	enhancement_title.text = "Memory Enhancement Status:"
	enhancement_title.add_theme_font_size_override("font_size", 14)
	enhancement_title.add_theme_color_override("font_color", Color("#DDA0DD"))
	enhancement_section.add_child(enhancement_title)
	
	var enhancement_status = Label.new()
	enhancement_status.text = "Base Form - Stable Memory Core\n(Future enhancements available through divine victories and consciousness expansion)"
	enhancement_status.add_theme_font_size_override("font_size", 10)
	enhancement_status.add_theme_color_override("font_color", Color("#AAAAAA"))
	enhancement_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enhancement_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enhancement_section.add_child(enhancement_status)
	
	main_vbox.add_child(enhancement_section)
	
	# Add the main container to the detail panel
	container.add_child(main_vbox)
	
	print("Updated detail panel for Mnemosyne card: ", card.card_name)

func debug_mnemosyne_containers():
	print("=== DEBUGGING MNEMOSYNE CONTAINERS ===")
	var left_panel = mnemosyne_tab.get_node("LeftPanel")
	var scroll_container = left_panel.get_node("ScrollContainer")
	var card_list = scroll_container.get_node("MnemosyneCardList")
	
	print("LeftPanel:")
	print("  - Size: ", left_panel.size)
	print("  - Custom minimum size: ", left_panel.custom_minimum_size)
	print("  - Visible: ", left_panel.visible)
	print("  - Modulate: ", left_panel.modulate)
	
	print("ScrollContainer:")
	print("  - Size: ", scroll_container.size)
	print("  - Custom minimum size: ", scroll_container.custom_minimum_size)
	print("  - Visible: ", scroll_container.visible)
	print("  - Modulate: ", scroll_container.modulate)
	print("  - Content size: ", scroll_container.get_v_scroll_bar().max_value)
	
	print("MnemosyneCardList:")
	print("  - Size: ", card_list.size)
	print("  - Custom minimum size: ", card_list.custom_minimum_size)
	print("  - Visible: ", card_list.visible)
	print("  - Modulate: ", card_list.modulate)
	print("  - Children: ", card_list.get_children().size())
	
	# Test if we can add a simple colored panel that should be visible
	var test_panel = PanelContainer.new()
	test_panel.custom_minimum_size = Vector2(200, 50)
	var test_style = StyleBoxFlat.new()
	test_style.bg_color = Color.RED
	test_panel.add_theme_stylebox_override("panel", test_style)
	
	var test_label2 = Label.new()
	test_label2.text = "BRIGHT RED TEST PANEL"
	test_label2.add_theme_color_override("font_color", Color.WHITE)
	test_label2.add_theme_font_size_override("font_size", 16)
	test_panel.add_child(test_label2)
	
	card_list.add_child(test_panel)
	print("Added bright red test panel to card list")
