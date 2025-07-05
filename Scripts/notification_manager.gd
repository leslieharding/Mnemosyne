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

# Show a notification message with BBCode formatting
func show_notification(message: String):
	# Don't show if already showing a notification
	if is_showing:
		print("NotificationManager: Already showing notification, skipping")
		return
	
	is_showing = true
	
	# Apply BBCode formatting to specific messages
	var formatted_message = format_message_with_bbcode(message)
	message_label.text = formatted_message
	
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

# Format messages with BBCode for special effects
func format_message_with_bbcode(message: String) -> String:
	# Handle the "feeling" message with wave and pulse effects
	if message.to_lower().contains("feeling") and message.to_lower().contains("watching"):
		# Add wave and pulse effects to the word "feeling"
		message = message.replace("feeling", "[wave amp=15 freq=3][pulse freq=2 color=#9966FF ease=-2]feeling[/pulse][/wave]")
	
	# Handle the "knew" message with bold formatting
	elif message.to_lower().contains("knew") and message.to_lower().contains("would"):
		# Make "knew" bold
		message = message.replace("knew", "[b]knew[/b]")
	
	return message

# Reset the notification to ready state
func reset_notification():
	is_showing = false
	modulate.a = 0.0
