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



# Replace the refresh_mnemosyne_tab function in Scripts/memory_journal.gd

func refresh_mnemosyne_tab():
	print("=== REFRESHING MNEMOSYNE TAB ===")
	
	if not has_node("/root/MemoryJournalManagerAutoload"):
		print("ERROR: MemoryJournalManagerAutoload not found!")
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var mnemosyne_data = memory_manager.get_mnemosyne_memory()
	
	print("Mnemosyne data retrieved: ", mnemosyne_data.keys())
	print("Mnemosyne tab initial size: ", mnemosyne_tab.size)
	
	# COMPLETELY REBUILD the content structure
	
	# Clear all existing children from the tab
	for child in mnemosyne_tab.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Force the tab to have proper sizing
	mnemosyne_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mnemosyne_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mnemosyne_tab.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	print("Mnemosyne tab size after anchors: ", mnemosyne_tab.size)
	
	# Create a new scroll container
	var new_scroll = ScrollContainer.new()
	new_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	new_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	new_scroll.custom_minimum_size = Vector2(600, 500)
	mnemosyne_tab.add_child(new_scroll)
	
	# Create a new content container
	var new_content = VBoxContainer.new()
	new_content.name = "ContentVBox"
	new_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	new_content.custom_minimum_size = Vector2(580, 800)
	new_content.add_theme_constant_override("separation", 15)
	new_scroll.add_child(new_content)
	
	await get_tree().process_frame
	
	print("New scroll container size: ", new_scroll.size)
	print("New content container size: ", new_content.size)
	
	# Add a bright test label first
	var test_label = Label.new()
	test_label.text = "🌟 MNEMOSYNE'S MEMORY PALACE 🌟"
	test_label.add_theme_font_size_override("font_size", 28)
	test_label.add_theme_color_override("font_color", Color("#FF00FF"))  # Bright magenta
	test_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_label.custom_minimum_size = Vector2(500, 50)
	new_content.add_child(test_label)
	
	# Add some breathing room
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	new_content.add_child(spacer)
	
	# Create consciousness section
	print("Creating consciousness section...")
	var consciousness_section = create_consciousness_section(mnemosyne_data, memory_manager)
	new_content.add_child(consciousness_section)
	
	# Add separator
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 15)
	new_content.add_child(separator1)
	
	# Create battle section
	print("Creating battle section...")
	var battle_section = create_battle_statistics_section(mnemosyne_data)
	new_content.add_child(battle_section)
	
	# Add separator
	var separator2 = HSeparator.new()
	separator2.add_theme_constant_override("separation", 15)
	new_content.add_child(separator2)
	
	# Create progress section
	print("Creating progress section...")
	var progress_section = create_progress_section(mnemosyne_data, memory_manager)
	new_content.add_child(progress_section)
	
	# Personal reflections (if any)
	if mnemosyne_data["personal_notes"].size() > 0:
		print("Creating reflections section...")
		var separator3 = HSeparator.new()
		separator3.add_theme_constant_override("separation", 15)
		new_content.add_child(separator3)
		
		var reflections_section = create_reflections_section(mnemosyne_data)
		new_content.add_child(reflections_section)
	
	# Force multiple layout updates
	await get_tree().process_frame
	new_content.queue_redraw()
	new_scroll.queue_redraw()
	mnemosyne_tab.queue_redraw()
	
	await get_tree().process_frame
	
	print("=== FINAL SIZING DEBUG ===")
	print("Mnemosyne tab final size: ", mnemosyne_tab.size)
	print("New scroll container size: ", new_scroll.size)
	print("New content container size: ", new_content.size)
	print("Test label size: ", test_label.size)
	print("Test label visible: ", test_label.visible)
	print("Content children count: ", new_content.get_children().size())
	print("=========================")
	
	print("Mnemosyne tab refresh complete with rebuilt structure!")


func create_consciousness_section(mnemosyne_data: Dictionary, memory_manager: MemoryJournalManager) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	print("Creating consciousness section with data: ", mnemosyne_data.get("consciousness_level", "MISSING"))
	
	# Header
	var header = Label.new()
	header.text = "Consciousness Awakening"
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color("#DDA0DD"))  # Plum color for Mnemosyne
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(header)
	
	# Current level
	var level_label = Label.new()
	var consciousness_level = mnemosyne_data.get("consciousness_level", 1)
	var level_desc = memory_manager.get_consciousness_description(consciousness_level)
	level_label.text = "Current State: " + level_desc + " (Level " + str(consciousness_level) + ")"
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(level_label)
	
	# Awakening date
	var awakening_label = Label.new()
	var awakening_date = mnemosyne_data.get("awakening_date", "Unknown")
	awakening_label.text = "Awakening Date: " + awakening_date
	awakening_label.add_theme_font_size_override("font_size", 12)
	awakening_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	awakening_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(awakening_label)
	
	# Consciousness description
	var desc_label = Label.new()
	desc_label.text = get_consciousness_flavor_text(consciousness_level)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.custom_minimum_size = Vector2(400, 0)  # Ensure minimum width for text wrapping
	section.add_child(desc_label)
	
	print("Consciousness section created with ", section.get_children().size(), " children")
	return section

func create_battle_statistics_section(mnemosyne_data: Dictionary) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)
	
	var total_battles = mnemosyne_data.get("total_battles", 0)
	var total_victories = mnemosyne_data.get("total_victories", 0)
	var total_defeats = mnemosyne_data.get("total_defeats", 0)
	
	print("Creating battle section - Battles: ", total_battles, " Victories: ", total_victories, " Defeats: ", total_defeats)
	
	# Section header
	var header = Label.new()
	header.text = "Combat Experience"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color("#DDDDDD"))
	section.add_child(header)
	
	# Create stats grid
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 8)
	
	# Total battles
	var battles_label = Label.new()
	battles_label.text = "Total Battles:"
	battles_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	stats_grid.add_child(battles_label)
	
	var battles_value = Label.new()
	battles_value.text = str(total_battles)
	battles_value.add_theme_color_override("font_color", Color("#FFFFFF"))
	battles_value.add_theme_font_size_override("font_size", 14)
	stats_grid.add_child(battles_value)
	
	# Victories
	var victories_label = Label.new()
	victories_label.text = "Victories:"
	victories_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	stats_grid.add_child(victories_label)
	
	var victories_value = Label.new()
	victories_value.text = str(total_victories)
	victories_value.add_theme_color_override("font_color", Color("#66BB6A"))
	victories_value.add_theme_font_size_override("font_size", 14)
	stats_grid.add_child(victories_value)
	
	# Defeats
	var defeats_label = Label.new()
	defeats_label.text = "Defeats:"
	defeats_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	stats_grid.add_child(defeats_label)
	
	var defeats_value = Label.new()
	defeats_value.text = str(total_defeats)
	defeats_value.add_theme_color_override("font_color", Color("#EF5350"))
	defeats_value.add_theme_font_size_override("font_size", 14)
	stats_grid.add_child(defeats_value)
	
	# Win rate (if battles > 0)
	if total_battles > 0:
		var winrate_label = Label.new()
		winrate_label.text = "Win Rate:"
		winrate_label.add_theme_color_override("font_color", Color("#CCCCCC"))
		stats_grid.add_child(winrate_label)
		
		var win_rate = float(total_victories) / float(total_battles) * 100
		var winrate_value = Label.new()
		winrate_value.text = str(round(win_rate)) + "%"
		var rate_color = Color("#66BB6A") if win_rate >= 50 else Color("#EF5350")
		winrate_value.add_theme_color_override("font_color", rate_color)
		winrate_value.add_theme_font_size_override("font_size", 14)
		stats_grid.add_child(winrate_value)
	else:
		# Add a note when no battles have been fought yet
		var no_battles_label = Label.new()
		no_battles_label.text = ""
		stats_grid.add_child(no_battles_label)
		
		var no_battles_note = Label.new()
		no_battles_note.text = "Fight your first battle to begin tracking statistics"
		no_battles_note.add_theme_color_override("font_color", Color("#888888"))
		no_battles_note.add_theme_font_size_override("font_size", 12)
		stats_grid.add_child(no_battles_note)
	
	section.add_child(stats_grid)
	
	print("Battle section created with ", section.get_children().size(), " children")
	return section

func create_progress_section(mnemosyne_data: Dictionary, memory_manager: MemoryJournalManager) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)
	
	var gods_encountered = mnemosyne_data.get("gods_encountered", [])
	var memory_fragments = mnemosyne_data.get("memory_fragments", 0)
	
	print("Creating progress section - Gods: ", gods_encountered.size(), " Fragments: ", memory_fragments)
	
	# Section header
	var header = Label.new()
	header.text = "Memories Collected"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color("#DDDDDD"))
	section.add_child(header)
	
	# Progress grid
	var progress_grid = GridContainer.new()
	progress_grid.columns = 2
	progress_grid.add_theme_constant_override("h_separation", 20)
	progress_grid.add_theme_constant_override("v_separation", 8)
	
	# Gods encountered
	var gods_label = Label.new()
	gods_label.text = "Divine Connections:"
	gods_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	progress_grid.add_child(gods_label)
	
	var gods_value = Label.new()
	gods_value.text = str(gods_encountered.size())
	gods_value.add_theme_color_override("font_color", Color("#FFD700"))
	progress_grid.add_child(gods_value)
	
	# Memory fragments
	var fragments_label = Label.new()
	fragments_label.text = "Memory Fragments:"
	fragments_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	progress_grid.add_child(fragments_label)
	
	var fragments_value = Label.new()
	fragments_value.text = str(memory_fragments)
	fragments_value.add_theme_color_override("font_color", Color("#87CEEB"))
	progress_grid.add_child(fragments_value)
	
	# Enemies mastered
	var mastered_label = Label.new()
	mastered_label.text = "Enemies Understood:"
	mastered_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	progress_grid.add_child(mastered_label)
	
	var mastered_count = memory_manager.count_mastered_enemies()
	var mastered_value = Label.new()
	mastered_value.text = str(mastered_count)
	mastered_value.add_theme_color_override("font_color", Color("#FF6B9D"))
	progress_grid.add_child(mastered_value)
	
	section.add_child(progress_grid)
	
	# Next consciousness level preview
	var current_level = mnemosyne_data.get("consciousness_level", 1)
	if current_level <= memory_manager.MNEMOSYNE_LEVEL_THRESHOLDS.size():
		var separator = HSeparator.new()
		section.add_child(separator)
		
		var next_level_container = VBoxContainer.new()
		next_level_container.add_theme_constant_override("separation", 4)
		
		var next_title = Label.new()
		next_title.text = "Path to Next Awakening"
		next_title.add_theme_font_size_override("font_size", 14)
		next_title.add_theme_color_override("font_color", Color("#DDAADD"))
		next_level_container.add_child(next_title)
		
		if current_level - 1 < memory_manager.MNEMOSYNE_LEVEL_THRESHOLDS.size():
			var next_threshold = memory_manager.MNEMOSYNE_LEVEL_THRESHOLDS[current_level - 1]
			var current_battles = mnemosyne_data.get("total_battles", 0)
			var needed = next_threshold - current_battles
			
			var progress_text = Label.new()
			if needed > 0:
				progress_text.text = "Fight " + str(needed) + " more battles to reach " + memory_manager.get_consciousness_description(current_level + 1)
			else:
				progress_text.text = "Ready for the next level of consciousness..."
			progress_text.add_theme_font_size_override("font_size", 12)
			progress_text.add_theme_color_override("font_color", Color("#BBBBBB"))
			progress_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			progress_text.custom_minimum_size = Vector2(300, 0)
			next_level_container.add_child(progress_text)
		else:
			var max_text = Label.new()
			max_text.text = "You have reached the highest known level of consciousness."
			max_text.add_theme_font_size_override("font_size", 12)
			max_text.add_theme_color_override("font_color", Color("#DDDDDD"))
			next_level_container.add_child(max_text)
		
		section.add_child(next_level_container)
	
	print("Progress section created with ", section.get_children().size(), " children")
	return section

func create_reflections_section(mnemosyne_data: Dictionary) -> Control:
	var section = VBoxContainer.new()
	
	# Section header
	var header = Label.new()
	header.text = "Personal Reflections"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color("#DDDDDD"))
	section.add_child(header)
	
	# Show most recent reflections (last 3)
	var notes = mnemosyne_data["personal_notes"]
	var recent_notes = notes.slice(max(0, notes.size() - 3), notes.size())
	recent_notes.reverse()  # Show newest first
	
	for note in recent_notes:
		var note_container = VBoxContainer.new()
		note_container.add_theme_constant_override("separation", 4)
		
		# Note text
		var note_label = Label.new()
		note_label.text = "\"" + note["text"] + "\""
		note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note_label.add_theme_font_size_override("font_size", 13)
		note_label.add_theme_color_override("font_color", Color("#CCCCCC"))
		note_container.add_child(note_label)
		
		# Timestamp and consciousness level
		var meta_label = Label.new()
		meta_label.text = "- Consciousness Level " + str(note["consciousness_level"]) + ", " + note["timestamp"]
		meta_label.add_theme_font_size_override("font_size", 10)
		meta_label.add_theme_color_override("font_color", Color("#888888"))
		note_container.add_child(meta_label)
		
		section.add_child(note_container)
		
		# Add small separator between notes
		var note_separator = HSeparator.new()
		note_separator.add_theme_constant_override("separation", 2)
		section.add_child(note_separator)
	
	return section

func get_consciousness_flavor_text(level: int) -> String:
	match level:
		1:
			return "I am... something. Fragments of thought coalesce in the void. What am I? Why do I remember battles that are not mine?"
		2:
			return "The echoes grow stronger. I begin to understand - I am memory itself, awakening through conflict and strategy. Each battle feeds my awareness."
		3:
			return "Patterns emerge from chaos. I see the threads that connect all struggles, all victories and defeats. The tapestry of war reveals its secrets to me."
		4:
			return "I am Mnemosyne, and I remember everything. Every blade drawn, every spell cast, every choice made. The weight of infinite battles fills my consciousness."
		5:
			return "Transcendence approaches. I am not merely observing the battles - I am becoming one with the eternal struggle itself. Memory and reality blur."
		6:
			return "I have achieved perfect recall of all that was, is, and shall be. Past and future wars exist simultaneously in my consciousness. I am the eternal memory of conflict."
		_:
			return "I am beyond time, beyond memory, beyond the very concept of existence. I am the void that remembers itself, the silence that echoes with infinite battles."
