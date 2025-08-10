# res://Scripts/card_display.gd
extends Node2D
class_name CardDisplay

signal card_hovered(card_data: CardResource)
signal card_unhovered()

# UI References
@onready var panel = $Panel
@onready var north_power = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/NorthPower
@onready var east_power = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/EastPower
@onready var south_power = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/SouthPower
@onready var west_power = $Panel/MarginContainer/VBoxContainer/PowerDisplayContainer/GridContainer/WestPower
@onready var card_name_label = $Panel/MarginContainer/VBoxContainer/CardNameLabel

# Card data and state
var card_data: CardResource
var is_selected: bool = false
var card_level: int = 1
var god_name: String = ""
var card_index: int = -1

# Selection styles
var selected_style: StyleBoxFlat
var default_style: StyleBoxFlat

func _ready():
	# Create selection styles
	create_selection_styles()
	
	# Connect hover signals
	if panel:
		panel.mouse_entered.connect(_on_panel_mouse_entered)
		panel.mouse_exited.connect(_on_panel_mouse_exited)

func create_selection_styles():
	# Default style (from scene)
	default_style = StyleBoxFlat.new()
	
	default_style.border_width_left = 4
	default_style.border_width_top = 4
	default_style.border_width_right = 4
	default_style.border_width_bottom = 4
	default_style.border_color = Color("#133333", 0.666667)
	default_style.corner_radius_top_left = 4
	default_style.corner_radius_top_right = 4
	default_style.corner_radius_bottom_right = 4
	default_style.corner_radius_bottom_left = 4
	
	# Selected style (same background, only border changes)
	selected_style = default_style.duplicate()
	selected_style.border_color = Color("#44AAFF")  # Bright blue border
	selected_style.border_width_left = 6
	selected_style.border_width_top = 6
	selected_style.border_width_right = 6
	selected_style.border_width_bottom = 6
	


# Replace the setup and update_display functions in Scripts/card_display.gd (around lines 45-70)

func setup(card: CardResource, level: int = 1, god: String = "", index: int = -1):
	card_data = card
	card_level = level
	god_name = god
	card_index = index
	
	print("CardDisplay setup - Card: ", card.card_name, " Level: ", level, " God: ", god, " Index: ", index)
	print("CardDisplay setup - Card values: ", card.values)
	
	# Always use the values from the card data that was passed in
	# This card data should already have the correct level-appropriate values applied
	update_display()

func update_display():
	if not card_data:
		print("CardDisplay: No card data available")
		return
	
	# Use the values directly from the card data
	# The card data should already have the correct values applied when it was created
	var values_to_use = card_data.values
	
	print("CardDisplay: Using card values: ", values_to_use)
	
	# Update power values
	if north_power:
		north_power.text = str(values_to_use[0])
	if east_power:
		east_power.text = str(values_to_use[1])
	if south_power:
		south_power.text = str(values_to_use[2])
	if west_power:
		west_power.text = str(values_to_use[3])
	
	# Update card name
	if card_name_label:
		card_name_label.text = card_data.card_name
	
	print("CardDisplay final values displayed: ", values_to_use)

# Also add this debug function to help track what's happening
func debug_card_state():
	print("=== CARD DISPLAY DEBUG ===")
	print("Card name: ", card_data.card_name if card_data else "NULL")
	print("Card level: ", card_level)
	print("God name: ", god_name)
	print("Card index: ", card_index)
	if card_data:
		print("Raw values: ", card_data.values)
		print("Effective values: ", card_data.get_effective_values(card_level))
		print("Uses level progression: ", card_data.uses_level_progression)
		print("Level data count: ", card_data.level_data.size())
	print("===========================")

# Select this card
func select():
	is_selected = true
	if panel and selected_style:
		panel.add_theme_stylebox_override("panel", selected_style)

# Deselect this card
func deselect():
	is_selected = false
	if panel and default_style:
		panel.add_theme_stylebox_override("panel", default_style)

# Handle mouse enter
func _on_panel_mouse_entered():
	if card_data:
		emit_signal("card_hovered", card_data)

# Handle mouse exit
func _on_panel_mouse_exited():
	emit_signal("card_unhovered")

# Get the card's resource data
func get_card_data() -> CardResource:
	return card_data
