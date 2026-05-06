# res://Scripts/tune_modal.gd
extends Control
class_name TuneModal

signal tune_confirmed(deltas: Array)

const DIRECTION_NAMES = ["North", "East", "South", "West"]
const MAX_POINTS = 4

var base_values: Array = []
var deltas: Array = [0, 0, 0, 0]
var points_remaining: int = MAX_POINTS
var selected_direction: int = 0

var card_name_label: Label
var points_label: Label
var direction_buttons: Array = []
var plus_button: Button
var minus_button: Button

func _ready():
	build_ui()

func setup(card: CardResource, _card_index: int):
	base_values = card.values.duplicate()
	card_name_label.text = card.card_name
	update_display()

func build_ui():
	# Full-screen dimmer
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	# Main panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(320, 420)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "TUNE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# Card name
	card_name_label = Label.new()
	card_name_label.text = ""
	card_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_name_label.add_theme_font_size_override("font_size", 16)
	card_name_label.add_theme_color_override("font_color", Color("#AADDFF"))
	vbox.add_child(card_name_label)

	# Points remaining
	points_label = Label.new()
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(points_label)

	vbox.add_child(HSeparator.new())

	# One button per direction - clicking selects that direction
	for i in range(4):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_direction_selected.bind(i))
		vbox.add_child(btn)
		direction_buttons.append(btn)

	vbox.add_child(HSeparator.new())

	# +/- row
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	minus_button = Button.new()
	minus_button.text = "  −  "
	minus_button.custom_minimum_size = Vector2(80, 48)
	minus_button.add_theme_font_size_override("font_size", 24)
	minus_button.pressed.connect(_on_minus_pressed)
	hbox.add_child(minus_button)

	plus_button = Button.new()
	plus_button.text = "  +  "
	plus_button.custom_minimum_size = Vector2(80, 48)
	plus_button.add_theme_font_size_override("font_size", 24)
	plus_button.pressed.connect(_on_plus_pressed)
	hbox.add_child(plus_button)

	# Confirm button
	var confirm_button = Button.new()
	confirm_button.text = "Confirm"
	confirm_button.custom_minimum_size = Vector2(0, 44)
	confirm_button.add_theme_font_size_override("font_size", 18)
	confirm_button.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_button)

func _on_direction_selected(index: int):
	selected_direction = index
	update_display()

func _on_plus_pressed():
	if points_remaining <= 0:
		return
	deltas[selected_direction] += 1
	points_remaining -= 1
	update_display()

func _on_minus_pressed():
	if points_remaining <= 0:
		return
	var current_value = base_values[selected_direction] + deltas[selected_direction]
	if current_value <= 0:
		return  # Floor at 0
	deltas[selected_direction] -= 1
	points_remaining -= 1
	update_display()

func update_display():
	points_label.text = "Points remaining: " + str(points_remaining)

	for i in range(4):
		if i >= direction_buttons.size():
			break
		var current = (base_values[i] + deltas[i]) if base_values.size() > i else 0
		var delta_text = ""
		if deltas[i] > 0:
			delta_text = " (+%d)" % deltas[i]
		elif deltas[i] < 0:
			delta_text = " (%d)" % deltas[i]
		direction_buttons[i].text = "%s: %d%s" % [DIRECTION_NAMES[i], current, delta_text]
		# Highlight the selected direction
		direction_buttons[i].modulate = Color("#FFD700") if i == selected_direction else Color.WHITE

func _on_confirm_pressed():
	print("TuneModal: Confirmed with deltas ", deltas)
	emit_signal("tune_confirmed", deltas)
	queue_free()
