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

var original_rotation: float = 0.0  # Store the card's fan rotation when in hand

# Animation
var hover_tween: Tween
var selection_tween: Tween

# Card data and state
var card_data: CardResource
var is_selected: bool = false
var card_level: int = 1
var god_name: String = ""
var card_index: int = -1
var is_in_hand: bool = true

# Hover sound timer
var hover_timer: Timer = null
var hover_delay: float = 0.15  # 150ms delay before playing sound

# Selection styles
var selected_style: StyleBoxFlat
var default_style: StyleBoxFlat

func _ready():
	# Create selection styles
	create_selection_styles()
	
	# Create hover timer
	hover_timer = Timer.new()
	hover_timer.wait_time = hover_delay
	hover_timer.one_shot = true
	add_child(hover_timer)
	
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
	



func setup(card: CardResource, level: int = 1, god: String = "", index: int = -1, is_opponent_card: bool = false):
	card_data = card
	card_level = level
	god_name = god
	card_index = index
	
	print("CardDisplay setup - Card: ", card.card_name, " Level: ", level, " God: ", god, " Index: ", index, " Opponent: ", is_opponent_card)
	
	# Store whether this is an opponent card for display purposes
	set_meta("is_opponent_card", is_opponent_card)
	
	update_display()

func update_display():
	if not card_data:
		print("CardDisplay: No card data available")
		return
	
	var values_to_use = card_data.values.duplicate()
	
	# Apply Hermes visual inversion if this is an opponent card
	var is_opponent_card = get_meta("is_opponent_card", false)
	if is_opponent_card:
		# Get the battle manager to check if visual inversion is active
		var battle_manager = get_tree().get_first_node_in_group("battle_manager")
		if battle_manager and battle_manager.has_method("get_display_value_for_opponent_card"):
			for i in range(values_to_use.size()):
				values_to_use[i] = battle_manager.get_display_value_for_opponent_card(values_to_use[i])
			print("Applied Hermes visual inversion to opponent card: ", card_data.card_name, " - display values: ", values_to_use)
	
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

func select():
	if not is_selected:  
		SoundManagerAutoload.play_on_card_click()
		play_selection_bounce()
	is_selected = true
	if panel and selected_style:
		panel.add_theme_stylebox_override("panel", selected_style)
	
	# Bring card to front by moving it to the end of parent's children
	if get_parent():
		get_parent().move_child(self, -1)
	
	# Straighten out the card when selected (remove fan rotation)
	if is_in_hand:
		rotation = 0.0

func deselect():
	print("DESELECT called on card: ", card_data.card_name if card_data else "Unknown", " | Current scale: ", scale)
	is_selected = false
	if panel and default_style:
		panel.add_theme_stylebox_override("panel", default_style)
	
	# Return to normal size smoothly
	if selection_tween:
		print("  Killing existing selection tween")
		selection_tween.kill()
	
	selection_tween = create_tween()
	selection_tween.set_parallel(true)
	selection_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Restore fan rotation when deselected if in hand
	if is_in_hand:
		selection_tween.tween_property(self, "rotation", original_rotation, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	print("  Started deselect tween to scale: ", Vector2.ONE)

# Handle mouse enter
func _on_panel_mouse_entered():
	if card_data:
		# Start timer for delayed sound
		if is_in_hand and hover_timer:
			hover_timer.start()
			# Connect timeout signal only once
			if not hover_timer.timeout.is_connected(_play_hover_sound):
				hover_timer.timeout.connect(_play_hover_sound)
		
		emit_signal("card_hovered", card_data)

# Handle mouse exit
func _on_panel_mouse_exited():
	# Cancel hover sound if mouse exits before timer completes
	if hover_timer:
		hover_timer.stop()
	
	emit_signal("card_unhovered")

# Get the card's resource data
func get_card_data() -> CardResource:
	return card_data


func apply_special_style(style: StyleBoxFlat):
	if panel:
		panel.add_theme_stylebox_override("panel", style)

func restore_default_style():
	if panel:
		panel.remove_theme_stylebox_override("panel")

# Play hover sound (called by timer)
func _play_hover_sound():
	SoundManagerAutoload.play_on_card_hover()

# Play bounce effect when card is selected
func play_selection_bounce():
	# Stop any existing animation
	if selection_tween:
		selection_tween.kill()
	
	selection_tween = create_tween()
	
	# Squash: briefly smaller (0.95x)
	selection_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Stretch: bounce to larger size (1.15x for selected cards)
	selection_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
