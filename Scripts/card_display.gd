# res://Scripts/card_display.gd
extends Node2D
class_name CardDisplay

# References to child nodes - FIXED to match actual scene structure
@onready var panel = $Panel
@onready var card_name_label = $Panel/MarginContainer/VBoxContainer/CardNameLabel
@onready var north_value = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/NorthPower
@onready var east_value = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/EastPower
@onready var south_value = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/SouthPower
@onready var west_value = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/WestPower

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
	
	# Set the card name
	card_name_label.text = card.card_name
	
	# Set the directional values [Up, Right, Down, Left]
	north_value.text = str(card.values[0])  # Up/North
	east_value.text = str(card.values[1])   # Right/East
	south_value.text = str(card.values[2])  # Down/South
	west_value.text = str(card.values[3])   # Left/West
	
	# Check for defensive counter ability and show visual cue
	setup_defensive_counter_visual_cue()

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
		create_defensive_counter_shield()

# Create the shield icon for defensive counter cards
func create_defensive_counter_shield():
	# Create a label for the shield icon
	var shield_label = Label.new()
	shield_label.text = "🛡️"  # Shield emoji (same as defense experience icon)
	shield_label.name = "DefensiveCounterShield"
	shield_label.add_theme_font_size_override("font_size", 16)
	shield_label.add_theme_color_override("font_color", Color("#87CEEB"))  # Sky blue like defense exp
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shield_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shield_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get panel size for positioning (same positioning logic as stat nullify arrow)
	var panel_size = panel.size if panel.size != Vector2.ZERO else panel.custom_minimum_size
	
	# Position in top-right corner of the card (same as stat nullify arrow)
	shield_label.position = Vector2(panel_size.x - 25, 5)  # 25px from right edge, 5px from top
	shield_label.size = Vector2(20, 20)  # Small square area for the shield
	
	# Add to the panel with high z-index so it appears on top
	panel.add_child(shield_label)
	shield_label.z_index = 10
	
	# Store reference for cleanup
	defensive_counter_overlay = shield_label
	
	print("Added defensive counter shield icon to ", card_data.card_name)

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
