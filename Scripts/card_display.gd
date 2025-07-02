# res://Scripts/card_display.gd
extends Node2D
class_name CardDisplay

# References to child nodes
@onready var panel = $Panel
@onready var card_name_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var north_value = $Panel/MarginContainer/PowerDisplayContainer/GridContainer/NorthPower
@onready var east_value = $Panel/MarginContainer/PowerDisplayContainer/GridContainer/EastPower
@onready var south_value = $Panel/MarginContainer/PowerDisplayContainer/GridContainer/SouthPower
@onready var west_value = $Panel/MarginContainer/PowerDisplayContainer/GridContainer/WestPower

signal card_hovered(card_data: CardResource)
signal card_unhovered()

# Style properties
var default_style: StyleBoxFlat
var selected_style: StyleBoxFlat
var is_selected: bool = false

# Card data
var card_data: CardResource

# Defensive counter visual indicator
var defensive_counter_overlay: Control = null

func _ready():
	# Connect the panel's gui_input signal to our method
	panel.gui_input.connect(_on_panel_gui_input)
	
	# Connect hover signals
	panel.mouse_entered.connect(_on_mouse_entered)
	panel.mouse_exited.connect(_on_mouse_exited)
	
	# Store the default style
	default_style = panel.get_theme_stylebox("panel").duplicate()
	
	# Create the selected style (brighter blue)
	selected_style = default_style.duplicate()
	selected_style.border_color = Color("#4499EE")  # Brighter blue
	selected_style.border_width_top = 4
	selected_style.border_width_right = 4
	selected_style.border_width_bottom = 4
	selected_style.border_width_left = 4

func _on_mouse_entered():
	if card_data:
		emit_signal("card_hovered", card_data)

func _on_mouse_exited():
	emit_signal("card_unhovered")

# Configure the card with data
func setup(card: CardResource):
	card_data = card
	
	# Set the card information
	card_name_label.text = card.card_name
	
	# Set the directional values [Up, Right, Down, Left]
	north_value.text = str(card.values[0])  # Up/North
	east_value.text = str(card.values[1])   # Right/East
	south_value.text = str(card.values[2])  # Down/South
	west_value.text = str(card.values[3])   # Left/West
	
	# Check for defensive counter ability and show visual cue
	setup_defensive_counter_visual_cue()

# New function to handle defensive counter visual cue
func setup_defensive_counter_visual_cue():
	# Remove existing overlay if it exists
	if defensive_counter_overlay:
		defensive_counter_overlay.queue_free()
		defensive_counter_overlay = null
	
	# Check if card has defensive counter ability
	if not card_data:
		return
	
	var has_defensive_counter = false
	for ability in card_data.abilities:
		if ability.trigger_condition == CardAbility.TriggerType.ON_DEFEND:
			has_defensive_counter = true
			break
	
	# Add visual cue if card has defensive counter
	if has_defensive_counter:
		create_defensive_counter_overlay()

# Create the grey inner border overlay for defensive counter cards
func create_defensive_counter_overlay():
	# Create a container that matches the panel size
	defensive_counter_overlay = Control.new()
	defensive_counter_overlay.name = "DefensiveCounterOverlay"
	defensive_counter_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	defensive_counter_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create the grey inner border rectangles
	var border_thickness = 3
	var border_color = Color("#666666", 0.8)  # Semi-transparent grey
	
	# Get panel size for positioning
	var panel_size = panel.size if panel.size != Vector2.ZERO else panel.custom_minimum_size
	
	# Create four border rectangles (inner border, so inset by existing border width)
	var inset = 4  # Inset from the existing colored border
	
	# Top border
	var top_border = ColorRect.new()
	top_border.color = border_color
	top_border.position = Vector2(inset, inset)
	top_border.size = Vector2(panel_size.x - (inset * 2), border_thickness)
	defensive_counter_overlay.add_child(top_border)
	
	# Bottom border
	var bottom_border = ColorRect.new()
	bottom_border.color = border_color
	bottom_border.position = Vector2(inset, panel_size.y - inset - border_thickness)
	bottom_border.size = Vector2(panel_size.x - (inset * 2), border_thickness)
	defensive_counter_overlay.add_child(bottom_border)
	
	# Left border
	var left_border = ColorRect.new()
	left_border.color = border_color
	left_border.position = Vector2(inset, inset)
	left_border.size = Vector2(border_thickness, panel_size.y - (inset * 2))
	defensive_counter_overlay.add_child(left_border)
	
	# Right border
	var right_border = ColorRect.new()
	right_border.color = border_color
	right_border.position = Vector2(panel_size.x - inset - border_thickness, inset)
	right_border.size = Vector2(border_thickness, panel_size.y - (inset * 2))
	defensive_counter_overlay.add_child(right_border)
	
	# Add overlay to the panel with high z-index so it appears on top
	panel.add_child(defensive_counter_overlay)
	defensive_counter_overlay.z_index = 10
	
	print("Added defensive counter visual cue to ", card_data.card_name)

# Selection methods
func select():
	is_selected = true
	panel.add_theme_stylebox_override("panel", selected_style)

func deselect():
	is_selected = false
	panel.add_theme_stylebox_override("panel", default_style)

# Handle panel input
func _on_panel_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_card()
			get_viewport().set_input_as_handled()

# Signal to parent when card is selected
func select_card():
	# Get the parent (likely a container)
	var parent = get_parent()
	
	# Check if parent has the select_card method
	if parent.has_method("select_card"):
		parent.select_card(self)
	else:
		# Fallback if the parent doesn't have the method
		# Just select this card visually
		if not is_selected:
			# Deselect any siblings if they're CardDisplay nodes
			for sibling in parent.get_children():
				if sibling is CardDisplay and sibling != self and sibling.is_selected:
					sibling.deselect()
			
			# Select this card
			select()
			print("Selected card: ", card_data.card_name if card_data else "No card data")
