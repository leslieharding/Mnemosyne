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

# Also add this debug function to memory_journal_manager.gd to help troubleshoot:

# Add this debug function to Scripts/memory_journal_manager.gd at the end of the class:



# Replace the create_enemy_list_button function in Scripts/memory_journal.gd (around lines 200-250)

# Replace the create_enemy_list_button function in Scripts/memory_journal.gd (around lines 200-250)

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

# Refresh gods tab content (unchanged from original)
func refresh_gods_tab():
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var god_memories = memory_manager.get_all_god_memories()
	
	# Get the god list container
	var god_list = gods_tab.get_node("LeftPanel/ScrollContainer/GodList")
	
	# Clear existing content
	for child in god_list.get_children():
		child.queue_free()
	
	# Add each god as a simple button
	for god_name in god_memories:
		var god_data = god_memories[god_name]
		var button = Button.new()
		button.text = god_name + "\nLevel: " + str(god_data["memory_level"]) + " (" + str(god_data["battles_fought"]) + " battles)"
		button.custom_minimum_size = Vector2(200, 60)
		god_list.add_child(button)
		
		# Connect to show details
		button.pressed.connect(_on_god_selected.bind(god_name, god_data))

# Handle god selection
func _on_god_selected(god_name: String, god_data: Dictionary):
	var details_panel = gods_tab.get_node("RightPanel")
	
	# Clear existing content
	for child in details_panel.get_children():
		child.queue_free()
	
	# Create simple details display
	var details_label = Label.new()
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	
	details_label.text = god_name + "\n\n"
	details_label.text += "Mastery Level: " + memory_manager.get_god_memory_description(god_data["memory_level"]) + "\n"
	details_label.text += "Battles Fought: " + str(god_data["battles_fought"]) + "\n"
	details_label.text += "Decks Discovered: " + str(god_data["decks_discovered"].size()) + "\n"
	details_label.text += "First Used: " + god_data["first_used"] + "\n"
	details_label.text += "Last Used: " + god_data["last_used"]
	
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_panel.add_child(details_label)

# Refresh Mnemosyne tab content (unchanged from original)
func refresh_mnemosyne_tab():
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var mnemosyne_data = memory_manager.get_mnemosyne_memory()
	
	# Get the content container
	var content_area = mnemosyne_tab.get_node("ScrollContainer/ContentVBox")
	
	# Clear existing content
	for child in content_area.get_children():
		child.queue_free()
	
	# Add consciousness level info
	var consciousness_label = Label.new()
	consciousness_label.text = "Consciousness Level: " + memory_manager.get_consciousness_description(mnemosyne_data["consciousness_level"]) + "\n\n"
	consciousness_label.text += "Total Battles: " + str(mnemosyne_data["total_battles"]) + "\n"
	consciousness_label.text += "Victories: " + str(mnemosyne_data["total_victories"]) + "\n"
	consciousness_label.text += "Defeats: " + str(mnemosyne_data["total_defeats"]) + "\n"
	
	if mnemosyne_data["total_battles"] > 0:
		var win_rate = float(mnemosyne_data["total_victories"]) / float(mnemosyne_data["total_battles"]) * 100
		consciousness_label.text += "Win Rate: " + str(round(win_rate)) + "%\n\n"
	
	consciousness_label.text += "Gods Encountered: " + str(mnemosyne_data["gods_encountered"].size()) + "\n"
	consciousness_label.text += "Memory Fragments: " + str(mnemosyne_data["memory_fragments"])
	
	consciousness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_area.add_child(consciousness_label)
