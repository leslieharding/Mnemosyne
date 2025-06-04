# res://Scripts/journal_button.gd
extends Button
class_name JournalButton

# Journal instance
var journal_instance: MemoryJournalUI = null

# Notification indicator
var notification_indicator: Control = null
var has_notifications: bool = false

# Animation
var hover_tween: Tween
var notification_tween: Tween

func _ready():
	# Set up button appearance first
	setup_button_style()
	
	# Connect signals
	pressed.connect(_on_journal_button_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set up notification indicator
	setup_notification_indicator()
	
	# Connect to memory manager for notifications
	if has_node("/root/MemoryJournalManagerAutoload"):
		var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
		memory_manager.new_memory_formed.connect(_on_new_memory_formed)
		memory_manager.memory_level_increased.connect(_on_memory_level_increased)
	
	
	
	print("Journal button ready - Position: ", position, " Size: ", size, " Visible: ", visible)

func setup_button_style():
	# Set button properties
	custom_minimum_size = Vector2(60, 60)
	text = "📖"  # Memory book emoji
	tooltip_text = "Memory Journal\n\nRecord of Mnemosyne's growing awareness"
	
	# Create custom style
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#4A3A5A")  # Purple theme for memory
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#7A6A8A")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Create hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = Color("#5A4A6A")
	hover_style.border_color = Color("#8A7A9A")
	
	# Apply styles
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", hover_style)
	
	# Font styling
	add_theme_font_size_override("font_size", 24)

func setup_notification_indicator():
	# Create notification dot
	notification_indicator = ColorRect.new()
	notification_indicator.color = Color("#FF6A6A")  # Bright red
	notification_indicator.size = Vector2(12, 12)
	notification_indicator.position = Vector2(45, 5)  # Top-right corner
	notification_indicator.visible = false
	
	# Make it circular (approximately)
	var circle_style = StyleBoxFlat.new()
	circle_style.bg_color = Color("#FF6A6A")
	circle_style.corner_radius_top_left = 6
	circle_style.corner_radius_top_right = 6
	circle_style.corner_radius_bottom_left = 6
	circle_style.corner_radius_bottom_right = 6
	
	notification_indicator.add_theme_stylebox_override("panel", circle_style)
	add_child(notification_indicator)

func _on_journal_button_pressed():
	# Create journal if it doesn't exist
	if not journal_instance:
		journal_instance = preload("res://Scenes/MemoryJournal.tscn").instantiate()
		get_tree().current_scene.add_child(journal_instance)
		journal_instance.journal_closed.connect(_on_journal_closed)
	
	# Show journal
	journal_instance.show_journal()
	
	# Hide notifications when opened
	hide_notification()

func _on_journal_closed():
	# Journal was closed, could update state here
	pass

func _on_mouse_entered():
	# Hover animation
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	# Return to normal size
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)

func _on_new_memory_formed(memory_type: String, subject: String):
	show_notification()

func _on_memory_level_increased(memory_type: String, subject: String, new_level: int):
	show_notification()

func show_notification():
	if has_notifications:
		return  # Already showing
	
	has_notifications = true
	notification_indicator.visible = true
	
	# Pulse animation
	if notification_tween:
		notification_tween.kill()
	
	notification_tween = create_tween()
	notification_tween.set_loops()
	notification_tween.tween_property(notification_indicator, "scale", Vector2(1.2, 1.2), 0.5)
	notification_tween.tween_property(notification_indicator, "scale", Vector2.ONE, 0.5)

func hide_notification():
	has_notifications = false
	notification_indicator.visible = false
	
	if notification_tween:
		notification_tween.kill()
