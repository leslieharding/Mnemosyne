# res://Scripts/notification_manager.gd
extends Control
class_name NotificationManager

# UI References
@onready var panel = $Panel
@onready var message_label = $Panel/MarginContainer/MessageLabel

# Animation settings
const SLIDE_DURATION: float = 0.8
const DISPLAY_DURATION: float = 3.0
const FADE_DURATION: float = 0.6

# State tracking
var is_showing: bool = false
var current_tween: Tween

func _ready():
	# Start hidden with zero alpha
	modulate.a = 0.0
	visible = true

# Show a notification message
func show_notification(message: String):
	# Don't show if already showing a notification
	if is_showing:
		print("NotificationManager: Already showing notification, skipping")
		return
	
	is_showing = true
	message_label.text = message
	
	# Kill any existing tween
	if current_tween:
		current_tween.kill()
	
	# Create fade-in animation
	current_tween = create_tween()
	
	# Fade in
	current_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	
	# Hold for display duration
	current_tween.tween_interval(DISPLAY_DURATION)
	
	# Fade out
	current_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN)
	
	# Reset when done
	current_tween.tween_callback(reset_notification)

# Reset the notification to ready state
func reset_notification():
	is_showing = false
	modulate.a = 0.0
