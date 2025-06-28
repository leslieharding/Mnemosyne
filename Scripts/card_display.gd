# res://Scripts/card_display.gd
extends Node2D
class_name CardDisplay

# References to child nodes
@onready var panel = $Panel
@onready var card_name_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var north_value = $Panel/MarginContainer/VBoxContainer/North
@onready var east_value = $Panel/MarginContainer/VBoxContainer/HBoxContainer/East
@onready var south_value = $Panel/MarginContainer/VBoxContainer/South
@onready var west_value = $Panel/MarginContainer/VBoxContainer/HBoxContainer/West

signal card_hovered(card_data: CardResource)
signal card_unhovered()

# Style properties
var default_style: StyleBoxFlat
var selected_style: StyleBoxFlat
var is_selected: bool = false

# Card data
var card_data: CardResource

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
