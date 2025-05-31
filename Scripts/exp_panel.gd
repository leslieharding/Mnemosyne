# res://Scripts/exp_panel.gd
extends Control
class_name ExpPanel

@onready var card_container = $PanelContainer/MarginContainer/VBoxContainer/CardContainer
@onready var collapse_button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CollapseButton
@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/TitleLabel

var is_collapsed: bool = false
var card_displays: Dictionary = {}  # card_index -> mini card display

func _ready():
	# Connect to the experience tracker
	if RunExperienceTracker:
		RunExperienceTracker.experience_updated.connect(_on_experience_updated)
	
	# Connect collapse button
	collapse_button.pressed.connect(_on_collapse_toggled)
	
	# Initialize display
	refresh_display()

# Set up the panel with the current deck
func setup_deck(deck: Array[CardResource], deck_indices: Array[int]):
	# Clear existing displays
	for child in card_container.get_children():
		child.queue_free()
	card_displays.clear()
	
	# Create mini card display for each card
	for i in range(deck.size()):
		var card = deck[i]
		var card_index = deck_indices[i]
		
		var mini_display = create_mini_card_display(card, card_index)
		card_container.add_child(mini_display)
		card_displays[card_index] = mini_display

# Create a mini card display
func create_mini_card_display(card: CardResource, card_index: int) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(80, 60)
	
	# Card name (abbreviated)
	var name_label = Label.new()
	name_label.text = card.card_name.substr(0, 8) + "..." if card.card_name.length() > 8 else card.card_name
	name_label.add_theme_font_size_override("font_size", 10)
	container.add_child(name_label)
	
	# Experience displays
	var exp_container = VBoxContainer.new()
	
	# Capture exp
	var capture_label = Label.new()
	capture_label.text = "⚔️ +0"
	capture_label.add_theme_color_override("font_color", Color("#FFD700"))  # Gold
	capture_label.add_theme_font_size_override("font_size", 12)
	capture_label.name = "CaptureExp"
	exp_container.add_child(capture_label)
	
	# Defense exp
	var defense_label = Label.new()
	defense_label.text = "🛡️ +0"
	defense_label.add_theme_color_override("font_color", Color("#87CEEB"))  # Sky blue
	defense_label.add_theme_font_size_override("font_size", 12)
	defense_label.name = "DefenseExp"
	exp_container.add_child(defense_label)
	
	container.add_child(exp_container)
	
	return container

# Update experience display
func _on_experience_updated(card_index: int, exp_type: String, amount: int):
	if not card_index in card_displays:
		return
	
	var display = card_displays[card_index]
	var exp_data = RunExperienceTracker.get_card_experience(card_index)
	
	# Update the appropriate label
	var capture_label = display.get_node("VBoxContainer/CaptureExp")
	var defense_label = display.get_node("VBoxContainer/DefenseExp")
	
	if capture_label:
		capture_label.text = "⚔️ +" + str(exp_data["capture_exp"])
	if defense_label:
		defense_label.text = "🛡️ +" + str(exp_data["defense_exp"])
	
	# Add a pulse animation to the updated stat
	var label_to_pulse = capture_label if exp_type == "capture" else defense_label
	if label_to_pulse:
		var tween = create_tween()
		tween.tween_property(label_to_pulse, "modulate", Color(2, 2, 2), 0.2)
		tween.tween_property(label_to_pulse, "modulate", Color.WHITE, 0.3)

# Toggle collapse state
func _on_collapse_toggled():
	is_collapsed = !is_collapsed
	card_container.visible = !is_collapsed
	collapse_button.text = "▼" if !is_collapsed else "▶"
	
	# Update title with total exp when collapsed
	if is_collapsed:
		var totals = RunExperienceTracker.get_total_experience()
		title_label.text = "Experience (⚔️ " + str(totals["capture_exp"]) + " | 🛡️ " + str(totals["defense_exp"]) + ")"
	else:
		title_label.text = "Experience"

# Refresh the entire display
func refresh_display():
	if RunExperienceTracker:
		for card_index in card_displays:
			_on_experience_updated(card_index, "", 0)
