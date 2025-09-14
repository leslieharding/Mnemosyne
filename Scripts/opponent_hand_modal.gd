# res://Scripts/opponent_hand_modal.gd
extends Control
class_name OpponentHandModal

signal modal_closed

var card_displays: Array[CardDisplay] = []

# UI references - now pointing to inspector-created nodes
var background_panel: ColorRect
var main_container: VBoxContainer
var title_label: Label
var cards_container: HBoxContainer
var close_button: Button

func _ready():
	setup_modal_ui()

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			close_modal()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click was outside the main container
			var main_rect = main_container.get_global_rect()
			if not main_rect.has_point(event.global_position):
				close_modal()

func setup_modal_ui():
	# Get references to existing nodes created in inspector
	background_panel = $BackgroundPanel
	main_container = $MainContainer
	title_label = $MainContainer/ModalPanel/MarginContainer/ContentVBox/TitleLabel
	cards_container = $MainContainer/ModalPanel/MarginContainer/ContentVBox/CardsContainer
	close_button = $MainContainer/ModalPanel/MarginContainer/ContentVBox/CloseButton
	
	# Connect the close button
	close_button.pressed.connect(close_modal)
	
	# Enable input processing
	set_process_input(true)
	
	print("OpponentHandModal UI setup complete using inspector nodes")

func display_opponent_hand(opponent_cards: Array[CardResource]):
	# Clear existing displays
	clear_card_displays()
	
	if opponent_cards.is_empty():
		var no_cards_label = Label.new()
		no_cards_label.text = "Opponent has no cards remaining"
		no_cards_label.add_theme_font_size_override("font_size", 18)
		no_cards_label.add_theme_color_override("font_color", Color("#CCCCCC"))
		no_cards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cards_container.add_child(no_cards_label)
		return
	
	# Create card displays for each opponent card
	for i in range(opponent_cards.size()):
		var card = opponent_cards[i]
		var card_display = create_opponent_card_display(card)
		cards_container.add_child(card_display)
		card_displays.append(card_display)

func create_opponent_card_display(card: CardResource) -> Control:
	# Main container for the card
	var card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(140, 180)
	
	# Card panel
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(130, 140)
	
	# Card styling
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#3A3A3A")
	card_style.border_color = Color("#FF6B6B")  # Red border for opponent cards
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.corner_radius_bottom_right = 6
	card_panel.add_theme_stylebox_override("panel", card_style)
	
	card_container.add_child(card_panel)
	
	# Card content layout
	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 8)
	card_margin.add_theme_constant_override("margin_right", 8)
	card_margin.add_theme_constant_override("margin_top", 8)
	card_margin.add_theme_constant_override("margin_bottom", 8)
	card_panel.add_child(card_margin)
	
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	card_margin.add_child(card_vbox)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_vbox.add_child(name_label)
	
	# Stats display in a grid
	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 4)
	stats_grid.add_theme_constant_override("v_separation", 4)
	card_vbox.add_child(stats_grid)
	
	# Top row: empty, north, empty
	stats_grid.add_child(Control.new())  # Empty
	var north_label = Label.new()
	north_label.text = str(card.values[0])
	north_label.add_theme_font_size_override("font_size", 12)
	north_label.add_theme_color_override("font_color", Color("#4CAF50"))
	north_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_grid.add_child(north_label)
	stats_grid.add_child(Control.new())  # Empty
	
	# Middle row: west, center, east
	var west_label = Label.new()
	west_label.text = str(card.values[3])
	west_label.add_theme_font_size_override("font_size", 12)
	west_label.add_theme_color_override("font_color", Color("#4CAF50"))
	west_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_grid.add_child(west_label)
	
	var center_label = Label.new()
	center_label.text = "⚔"
	center_label.add_theme_font_size_override("font_size", 10)
	center_label.add_theme_color_override("font_color", Color("#FFD700"))
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_grid.add_child(center_label)
	
	var east_label = Label.new()
	east_label.text = str(card.values[1])
	east_label.add_theme_font_size_override("font_size", 12)
	east_label.add_theme_color_override("font_color", Color("#4CAF50"))
	east_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_grid.add_child(east_label)
	
	# Bottom row: empty, south, empty
	stats_grid.add_child(Control.new())  # Empty
	var south_label = Label.new()
	south_label.text = str(card.values[2])
	south_label.add_theme_font_size_override("font_size", 12)
	south_label.add_theme_color_override("font_color", Color("#4CAF50"))
	south_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_grid.add_child(south_label)
	stats_grid.add_child(Control.new())  # Empty
	
	# Abilities display
	if not card.abilities.is_empty():
		var abilities_vbox = VBoxContainer.new()
		abilities_vbox.add_theme_constant_override("separation", 4)
		card_container.add_child(abilities_vbox)
		
		# Show up to 2 abilities to avoid overflow
		var abilities_to_show = min(card.abilities.size(), 2)
		for i in range(abilities_to_show):
			var ability = card.abilities[i]
			var ability_container = VBoxContainer.new()
			ability_container.add_theme_constant_override("separation", 2)
			
			# Ability name
			var ability_name_label = Label.new()
			ability_name_label.text = ability.ability_name
			ability_name_label.add_theme_font_size_override("font_size", 10)
			ability_name_label.add_theme_color_override("font_color", Color("#FFD700"))
			ability_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ability_container.add_child(ability_name_label)
			
			# Ability description (truncated if too long)
			var ability_desc_label = Label.new()
			var desc_text = ability.description
			if desc_text.length() > 40:
				desc_text = desc_text.substr(0, 37) + "..."
			ability_desc_label.text = desc_text
			ability_desc_label.add_theme_font_size_override("font_size", 8)
			ability_desc_label.add_theme_color_override("font_color", Color("#CCCCCC"))
			ability_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ability_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ability_container.add_child(ability_desc_label)
			
			abilities_vbox.add_child(ability_container)
		
		# Show "..." if there are more abilities
		if card.abilities.size() > 2:
			var more_label = Label.new()
			more_label.text = "..."
			more_label.add_theme_font_size_override("font_size", 10)
			more_label.add_theme_color_override("font_color", Color("#888888"))
			more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			abilities_vbox.add_child(more_label)
	
	return card_container

func clear_card_displays():
	for display in card_displays:
		if is_instance_valid(display):
			display.queue_free()
	card_displays.clear()
	
	for child in cards_container.get_children():
		child.queue_free()

func close_modal():
	print("Prophetic vision ended - closing modal")
	emit_signal("modal_closed")
	queue_free()

func _exit_tree():
	set_process_input(false)
