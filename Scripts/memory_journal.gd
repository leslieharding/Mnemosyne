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
	# Wait one frame to ensure all @onready variables are initialized
	await get_tree().process_frame
	
	# Verify all required nodes exist before proceeding
	if not close_button:
		push_error("MemoryJournal: close_button not found!")
		return
	if not main_panel:
		push_error("MemoryJournal: main_panel not found!")
		return
	if not title_label:
		push_error("MemoryJournal: title_label not found!")
		return
	
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
	
	# Always default to Bestiary tab (index 0)
	tab_container.current_tab = 0
	
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

func update_header():
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	# Check if UI nodes exist before trying to update them
	if not title_label or not summary_label:
		print("MemoryJournal: Header labels not found, skipping header update")
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var summary = memory_manager.get_memory_summary()
	
	title_label.text = "Mnemosyne's Memory Journal"
	
	# Remove consciousness description - just show basic stats
	summary_label.text = str(summary["enemies_encountered"]) + " Enemies • " + str(summary["gods_experienced"]) + " Gods"


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
	var details_panel = bestiary_tab.get_node("ScrollContainer/RightPanel")
	
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
	
	# NEW: Add indicator for rich content availability
	var content_indicator = ""
	if memory_manager.has_custom_god_content(god_name):
		content_indicator = " ✦"  # Special symbol for rich content
	
	button.text = god_name + content_indicator + "\n" + level_desc + "\n" + battles_info + " • " + decks_info
	
	# Create a style based on mastery level
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# Enhanced color scheme - brighter for gods with rich content
	var has_custom_content = memory_manager.has_custom_god_content(god_name)
	var brightness_multiplier = 1.3 if has_custom_content else 1.0
	
	# Color based on mastery level with brightness enhancement
	match god_data["memory_level"]:
		0: # Unfamiliar - dark gray
			var base_color = Color("#2A2A2A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#444444") * brightness_multiplier
		1: # Novice - light blue
			var base_color = Color("#1A2A4A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#2A4A6A") * brightness_multiplier
		2: # Practiced - blue
			var base_color = Color("#2A3A5A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#4A5A7A") * brightness_multiplier
		3: # Skilled - green
			var base_color = Color("#2A4A2A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#4A6A4A") * brightness_multiplier
		4: # Expert - gold
			var base_color = Color("#4A4A2A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#6A6A2A") * brightness_multiplier
		5: # Divine Mastery - purple
			var base_color = Color("#4A2A4A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#6A4A6A") * brightness_multiplier
		_: # Eternal Bond - bright gold
			var base_color = Color("#5A5A2A") * brightness_multiplier
			style.bg_color = base_color
			style.border_color = Color("#8A8A4A") * brightness_multiplier
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	# Apply styles
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	
	# Enhanced text styling for gods with rich content
	var text_color = Color("#EEEEEE") if has_custom_content else Color("#DDDDDD")
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_font_size_override("font_size", 12)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	return button

# Handle god selection
func _on_god_selected(god_name: String, god_data: Dictionary):
	var details_panel = gods_tab.get_node("ScrollContainer/RightPanel")
	
	# Clear existing content
	for child in details_panel.get_children():
		child.queue_free()
	
	# Use the simpler display function that works directly with god_data
	# This avoids the complex god content manager which might have data structure issues
	create_detailed_god_display(details_panel, god_name, god_data)

func create_enhanced_god_display(container: Control, info: Dictionary):
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	
	# === HEADER SECTION ===
	var header_container = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = info["name"]
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color("#FFD700"))  # Divine gold
	header_container.add_child(name_label)
	
	var mastery_label = Label.new()
	mastery_label.text = "Mastery Level: " + str(info["mastery_level"]) + " (" + info["mastery_description"] + ")"
	mastery_label.add_theme_font_size_override("font_size", 16)
	mastery_label.add_theme_color_override("font_color", Color("#DDA0DD"))  # Plum purple
	header_container.add_child(mastery_label)
	
	var battles_label = Label.new()
	battles_label.text = "Battles Fought Together: " + str(info["battles_fought"])
	battles_label.add_theme_font_size_override("font_size", 12)
	battles_label.add_theme_color_override("font_color", Color("#BBBBBB"))
	header_container.add_child(battles_label)
	
	main_vbox.add_child(header_container)
	
	# === DIVINE LORE SECTION === (Always visible)
	var separator1 = HSeparator.new()
	main_vbox.add_child(separator1)
	
	var lore_container = VBoxContainer.new()
	
	var lore_title = Label.new()
	lore_title.text = "Divine Lore"
	lore_title.add_theme_font_size_override("font_size", 20)
	lore_title.add_theme_color_override("font_color", Color("#87CEEB"))  # Sky blue
	lore_container.add_child(lore_title)
	
	var lore_label = Label.new()
	lore_label.text = info["description"]
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.add_theme_font_size_override("font_size", 14)
	lore_label.add_theme_color_override("font_color", Color("#DDDDDD"))
	lore_container.add_child(lore_label)
	
	main_vbox.add_child(lore_container)
	
	
	
	# === DIVINE INSIGHTS SECTION === (Level 4+)
	if "divine_insights" in info["visible_content"] and info["divine_insights"] != "":
		var separator3 = HSeparator.new()
		main_vbox.add_child(separator3)
		
		var insights_container = VBoxContainer.new()
		
		var insights_title = Label.new()
		insights_title.text = "Divine Insights"
		insights_title.add_theme_font_size_override("font_size", 18)
		insights_title.add_theme_color_override("font_color", Color("#9370DB"))  # Medium purple
		insights_container.add_child(insights_title)
		
		var insights_label = Label.new()
		insights_label.text = info["divine_insights"]
		insights_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		insights_label.add_theme_font_size_override("font_size", 13)
		insights_label.add_theme_color_override("font_color", Color("#E6E6FA"))  # Lavender
		insights_container.add_child(insights_label)
		
		main_vbox.add_child(insights_container)
	
	# === SACRED STATISTICS SECTION ===
	var separator4 = HSeparator.new()
	main_vbox.add_child(separator4)
	
	var stats_container = VBoxContainer.new()
	
	var stats_title = Label.new()
	stats_title.text = "Sacred Statistics"
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_title.add_theme_color_override("font_color", Color("#98FB98"))  # Pale green
	stats_container.add_child(stats_title)
	
	var first_used_label = Label.new()
	first_used_label.text = "First Divine Connection: " + info.get("first_used", "Unknown")
	first_used_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	stats_container.add_child(first_used_label)
	
	var last_used_label = Label.new()
	last_used_label.text = "Last Communion: " + info.get("last_used", "Unknown")
	last_used_label.add_theme_color_override("font_color", Color("#AAAAAA"))
	stats_container.add_child(last_used_label)
	
	main_vbox.add_child(stats_container)
	
	# === DISCOVERED MANIFESTATIONS SECTION ===
	var separator5 = HSeparator.new()
	main_vbox.add_child(separator5)
	
	var decks_container = VBoxContainer.new()
	
	var decks_title = Label.new()
	var deck_count = info.get("decks_discovered", []).size()
	decks_title.text = "Divine Manifestations Discovered (" + str(deck_count) + ")"
	decks_title.add_theme_font_size_override("font_size", 16)
	decks_title.add_theme_color_override("font_color", Color("#FFA500"))  # Orange
	decks_container.add_child(decks_title)
	
	if deck_count > 0:
		for deck_name in info.get("decks_discovered", []):
			var deck_label = Label.new()
			deck_label.text = "• " + deck_name
			deck_label.add_theme_color_override("font_color", Color("#DDD"))
			deck_label.add_theme_font_size_override("font_size", 12)
			decks_container.add_child(deck_label)
	else:
		var no_decks_label = Label.new()
		no_decks_label.text = "No manifestations discovered yet. Continue your divine communion to unlock their various forms."
		no_decks_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_decks_label.add_theme_color_override("font_color", Color("#999999"))
		no_decks_label.add_theme_font_size_override("font_size", 12)
		decks_container.add_child(no_decks_label)
	
	main_vbox.add_child(decks_container)
	
	# === PROGRESSION HINTS === (For lower mastery levels)
	if info["mastery_level"] < 5:  # Not at Divine Mastery yet
		var separator6 = HSeparator.new()
		main_vbox.add_child(separator6)
		
		var progression_container = VBoxContainer.new()
		
		var progression_title = Label.new()
		progression_title.text = "Path to Greater Understanding"
		progression_title.add_theme_font_size_override("font_size", 14)
		progression_title.add_theme_color_override("font_color", Color("#FFE4B5"))  # Moccasin
		progression_container.add_child(progression_title)
		
		var hint_text = get_progression_hint(info["mastery_level"])
		var hint_label = Label.new()
		hint_label.text = hint_text
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.add_theme_color_override("font_color", Color("#BBBBBB"))
		hint_label.add_theme_font_size_override("font_size", 11)
		progression_container.add_child(hint_label)
		
		main_vbox.add_child(progression_container)
	
	# Add main container to the details panel
	container.add_child(main_vbox)

func get_progression_hint(mastery_level: int) -> String:
	match mastery_level:
		0:
			return "Fight more battles with this god to begin understanding their divine nature."
		1:
			return "Continue your communion to unlock tactical insights. (Need 5 total battles)"
		2:
			return "Deepen your understanding through combat to reveal divine wisdom. (Need 15 total battles)"
		3:
			return "Approach expert mastery to unlock profound insights. (Need 30 total battles)"
		4:
			return "You are close to achieving perfect divine harmony. (Need 50 total battles)"
		_:
			return "You have transcended mortal limitations in understanding this deity."

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

func refresh_mnemosyne_tab():
	print("=== REFRESHING MNEMOSYNE TAB WITH NEW PROGRESSION DISPLAY ===")
	
	# Get the card container
	var card_container = mnemosyne_tab.get_node("CardContainer")
	if not card_container:
		print("ERROR: Could not find CardContainer")
		return
	
	# Clear existing cards
	for child in card_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Load and display Mnemosyne deck with progression
	populate_mnemosyne_cards_with_progression(card_container)
	
	print("Mnemosyne tab refresh complete!")

func populate_mnemosyne_cards_with_progression(container: VBoxContainer):
	print("Loading Mnemosyne deck with progression display...")
	
	# Load Mnemosyne collection first
	var collection_path = "res://Resources/Collections/Mnemosyne.tres"
	if not ResourceLoader.exists(collection_path):
		print("ERROR: Mnemosyne collection not found at: ", collection_path)
		var error_label = Label.new()
		error_label.text = "Mnemosyne collection not found!"
		error_label.add_theme_color_override("font_color", Color.RED)
		container.add_child(error_label)
		return
	
	var collection: GodCardCollection = load(collection_path)
	if not collection:
		print("ERROR: Failed to load Mnemosyne collection")
		return
	
	# Get the Mnemosyne deck
	var mnemosyne_deck = collection.get_deck(0)
	print("Loaded Mnemosyne deck with ", mnemosyne_deck.size(), " cards")
	
	if mnemosyne_deck.is_empty():
		var no_cards_label = Label.new()
		no_cards_label.text = "No memory cards found in Mnemosyne's collection."
		no_cards_label.add_theme_color_override("font_color", Color("#888888"))
		container.add_child(no_cards_label)
		return
	
	# Try to get the tracker - but don't fail if it's not available
	var tracker = get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	var has_progression = tracker != null
	
	
	
	# Create card displays showing current values (either base or progressed)
	for i in range(mnemosyne_deck.size()):
		var card = mnemosyne_deck[i]
		if not card:
			continue
		
		# Get current values - use tracker progression if available, otherwise base values
		var current_values: Array[int]
		if has_progression:
			current_values = tracker.get_card_values(i)
		else:
			current_values = [1, 1, 1, 1]  # Base values
		
		# Get upgrade count if tracker is available
		var upgrade_count = 0
		if has_progression:
			upgrade_count = tracker.get_card_upgrade_count(i)
		
		# Create a simple card info panel
		var card_panel = create_mnemosyne_card_panel(card.card_name, current_values, upgrade_count)
		container.add_child(card_panel)
		
		print("Added Mnemosyne card: ", card.card_name, " with values ", current_values, " (", upgrade_count, " upgrades)")


func create_mnemosyne_card_panel(card_name: String, values: Array[int], upgrade_count: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)  # Increased height for abilities
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A1A2A")
	style.border_color = Color("#6A4A6A")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	# Margin container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	
	# Main layout - horizontal container to put abilities to the right
	var main_container = HBoxContainer.new()
	main_container.add_theme_constant_override("separation", 20)
	margin.add_child(main_container)
	
	# Left side: Card info and stats
	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(left_side)
	
	# Card name and upgrade info
	var name_section = VBoxContainer.new()
	left_side.add_child(name_section)
	
	var name_label = Label.new()
	name_label.text = card_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDA0DD"))
	name_section.add_child(name_label)
	
	if upgrade_count > 0:
		var upgrade_label = Label.new()
		upgrade_label.text = "+" + str(upgrade_count) + " upgrades"
		upgrade_label.add_theme_font_size_override("font_size", 10)
		upgrade_label.add_theme_color_override("font_color", Color("#FFD700"))
		name_section.add_child(upgrade_label)
	
	# Stats section
	var stats_container = HBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 10)
	left_side.add_child(stats_container)
	
	var stat_names = ["N", "E", "S", "W"]
	var stat_colors = [Color("#87CEEB"), Color("#FFB74D"), Color("#FF7043"), Color("#66BB6A")]
	
	for i in range(4):
		var stat_vbox = VBoxContainer.new()
		stat_vbox.custom_minimum_size.x = 30
		
		var stat_name = Label.new()
		stat_name.text = stat_names[i]
		stat_name.add_theme_font_size_override("font_size", 10)
		stat_name.add_theme_color_override("font_color", stat_colors[i])
		stat_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_vbox.add_child(stat_name)
		
		var stat_value = Label.new()
		stat_value.text = str(values[i])
		stat_value.add_theme_font_size_override("font_size", 14)
		stat_value.add_theme_color_override("font_color", Color("#FFD700"))
		stat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_vbox.add_child(stat_value)
		
		stats_container.add_child(stat_vbox)
	
	# Right side: Abilities section
	var abilities_section = VBoxContainer.new()
	abilities_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abilities_section.custom_minimum_size.x = 250  # Ensure abilities have enough space
	main_container.add_child(abilities_section)
	
	var abilities_label = Label.new()
	abilities_label.text = "Abilities:"
	abilities_label.add_theme_font_size_override("font_size", 12)
	abilities_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	abilities_section.add_child(abilities_label)
	
	var abilities_container = VBoxContainer.new()
	abilities_section.add_child(abilities_container)
	
	# Get the card index from name
	var card_index = get_card_index_from_name(card_name)
	
	# Get tracker for boss abilities
	var tracker = get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	if tracker and card_index >= 0:
		var ability_info = tracker.get_all_potential_abilities_for_card(card_index)
		
		if ability_info.size() > 0:
			for info in ability_info:
				var ability_row = create_ability_display(info)
				abilities_container.add_child(ability_row)
		else:
			var no_abilities = Label.new()
			no_abilities.text = "No special abilities available"
			no_abilities.add_theme_font_size_override("font_size", 10)
			no_abilities.add_theme_color_override("font_color", Color("#888888"))
			abilities_container.add_child(no_abilities)
	else:
		var loading_label = Label.new()
		loading_label.text = "Loading abilities..."
		loading_label.add_theme_font_size_override("font_size", 10)
		loading_label.add_theme_color_override("font_color", Color("#888888"))
		abilities_container.add_child(loading_label)
	
	return panel




func get_card_index_from_name(card_name: String) -> int:
	match card_name:
		"Clio": return 0
		"Euterpe": return 1
		"Terpsichore": return 2
		"Thalia": return 3
		"Melpomene": return 4
		_: return -1


func create_ability_display(ability_info: Dictionary) -> Control:
	var ability_row = HBoxContainer.new()
	ability_row.add_theme_constant_override("separation", 10)
	
	# Status icon
	var status_label = Label.new()
	if ability_info["is_unlocked"]:
		status_label.text = "✓"
		status_label.add_theme_color_override("font_color", Color("#00FF00"))
	else:
		status_label.text = "✗"
		status_label.add_theme_color_override("font_color", Color("#FF6666"))
	status_label.add_theme_font_size_override("font_size", 12)
	ability_row.add_child(status_label)
	
	# Ability name and description
	var ability_info_container = VBoxContainer.new()
	ability_info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_row.add_child(ability_info_container)
	
	var ability_name = Label.new()
	var ability = ability_info["ability"]
	
	# Show hidden info for locked abilities
	if ability_info["is_unlocked"]:
		ability_name.text = ability.ability_name
		ability_name.add_theme_color_override("font_color", Color("#FFD700"))
	else:
		ability_name.text = "??????"
		ability_name.add_theme_color_override("font_color", Color("#888888"))
	
	ability_name.add_theme_font_size_override("font_size", 11)
	ability_info_container.add_child(ability_name)
	
	var ability_desc = Label.new()
	if ability_info["is_unlocked"]:
		ability_desc.text = ability.description
	else:
		ability_desc.text = "This card's ability is not yet unlocked"
	
	ability_desc.add_theme_font_size_override("font_size", 9)
	ability_desc.add_theme_color_override("font_color", Color("#AAAAAA"))
	ability_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_info_container.add_child(ability_desc)
	
	return ability_row

func create_compact_card_display(card: CardResource) -> Control:
	# Main panel for the card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(500, 80)
	
	# Mnemosyne purple theme
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2A1A2A")
	style.border_color = Color("#6A4A6A")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	card_panel.add_theme_stylebox_override("panel", style)
	
	# Margin for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card_panel.add_child(margin)
	
	# Main horizontal layout
	var h_container = HBoxContainer.new()
	h_container.add_theme_constant_override("separation", 20)
	margin.add_child(h_container)
	
	# Left side - Card name and description
	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_container.add_child(left_side)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#DDA0DD"))
	left_side.add_child(name_label)
	
	# Description (truncated)
	var desc_label = Label.new()
	var description = card.description
	if description.length() > 80:
		description = description.substr(0, 77) + "..."
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color("#CCCCCC"))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_side.add_child(desc_label)
	
	# Right side - Power values
	var values_container = HBoxContainer.new()
	values_container.add_theme_constant_override("separation", 15)
	h_container.add_child(values_container)
	
	var directions = ["N", "E", "S", "W"]
	var direction_colors = [Color("#87CEEB"), Color("#FFB74D"), Color("#FF7043"), Color("#66BB6A")]
	
	for i in range(4):
		var value_container = VBoxContainer.new()
		value_container.custom_minimum_size.x = 25
		
		var dir_label = Label.new()
		dir_label.text = directions[i]
		dir_label.add_theme_color_override("font_color", direction_colors[i])
		dir_label.add_theme_font_size_override("font_size", 10)
		dir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_container.add_child(dir_label)
		
		var value_label = Label.new()
		value_label.text = str(card.values[i])
		value_label.add_theme_color_override("font_color", Color.WHITE)
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_container.add_child(value_label)
		
		values_container.add_child(value_container)
	
	return card_panel
