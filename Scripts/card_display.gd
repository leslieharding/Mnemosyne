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
	default_style.bg_color = Color("#581033", 1.0)
	default_style.border_width_left = 4
	default_style.border_width_top = 4
	default_style.border_width_right = 4
	default_style.border_width_bottom = 4
	default_style.border_color = Color("#133333", 0.666667)
	default_style.corner_radius_top_left = 4
	default_style.corner_radius_top_right = 4
	default_style.corner_radius_bottom_right = 4
	default_style.corner_radius_bottom_left = 4
	
	# Selected style (brighter border)
	selected_style = default_style.duplicate()
	selected_style.border_color = Color("#44AAFF")  # Bright blue
	selected_style.border_width_left = 6
	selected_style.border_width_top = 6
	selected_style.border_width_right = 6
	selected_style.border_width_bottom = 6

# Set up the card display with card data
func setup(card: CardResource):
	if not card:
		print("CardDisplay: Warning - no card data provided")
		return
	
	card_data = card
	
	# Wait for @onready variables to be initialized
	if not north_power:
		await ready
	
	# Update display elements
	update_display()

# Update all display elements with current card data
func update_display():
	if not card_data:
		return
	
	# Update power values
	if north_power:
		north_power.text = str(card_data.values[0])
	if east_power:
		east_power.text = str(card_data.values[1])
	if south_power:
		south_power.text = str(card_data.values[2])
	if west_power:
		west_power.text = str(card_data.values[3])
	
	# Update card name
	if card_name_label:
		card_name_label.text = card_data.card_name

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
