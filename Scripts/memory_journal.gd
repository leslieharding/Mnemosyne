# res://Scripts/memory_journal_ui.gd
extends Control
class_name MemoryJournalUI

signal journal_closed()

# UI References - these will be connected automatically by the scene structure
@onready var main_panel = $MainPanel
@onready var tab_container = $MainPanel/VBox/TabContainer
@onready var close_button = $MainPanel/VBox/Header/CloseButton
@onready var title_label = $MainPanel/VBox/Header/TitleLabel
@onready var summary_label = $MainPanel/VBox/Header/SummaryLabel

# Tab references
@onready var bestiary_tab = $MainPanel/VBox/TabContainer/Bestiary
@onready var gods_tab = $MainPanel/VBox/TabContainer/Gods
@onready var mnemosyne_tab = $MainPanel/VBox/TabContainer/Mnemosyne

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

# Refresh bestiary tab content
func refresh_bestiary_tab():
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var enemy_memories = memory_manager.get_all_enemy_memories()
	
	# Get the enemy list container
	var enemy_list = bestiary_tab.get_node("LeftPanel/ScrollContainer/EnemyList")
	
	# Clear existing content
	for child in enemy_list.get_children():
		child.queue_free()
	
	# Add each enemy as a simple button
	for enemy_name in enemy_memories:
		var enemy_data = enemy_memories[enemy_name]
		var button = Button.new()
		button.text = enemy_name + "\nLevel: " + str(enemy_data["memory_level"]) + " (" + str(enemy_data["encounters"]) + " encounters)"
		button.custom_minimum_size = Vector2(200, 60)
		enemy_list.add_child(button)
		
		# Connect to show details (simplified for now)
		button.pressed.connect(_on_enemy_selected.bind(enemy_name, enemy_data))

# Handle enemy selection in bestiary
func _on_enemy_selected(enemy_name: String, enemy_data: Dictionary):
	var details_panel = bestiary_tab.get_node("RightPanel")
	
	# Clear existing content
	for child in details_panel.get_children():
		child.queue_free()
	
	# Create simple details display
	var details_label = Label.new()
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	
	details_label.text = enemy_name + "\n\n"
	details_label.text += "Memory Level: " + memory_manager.get_bestiary_memory_description(enemy_data["memory_level"]) + "\n"
	details_label.text += "Encounters: " + str(enemy_data["encounters"]) + "\n"
	details_label.text += "Victories: " + str(enemy_data["victories"]) + "\n"
	details_label.text += "Defeats: " + str(enemy_data["defeats"]) + "\n"
	if enemy_data["encounters"] > 0:
		var win_rate = round(float(enemy_data["victories"]) / float(enemy_data["encounters"]) * 100)
		details_label.text += "Win Rate: " + str(win_rate) + "%"
	
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_panel.add_child(details_label)

# Refresh gods tab content
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

# Refresh Mnemosyne tab content
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
