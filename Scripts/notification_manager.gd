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
	
	# Ensure we have a RichTextLabel for BBCode support
	setup_rich_text_label()

func setup_rich_text_label():
	# Check if message_label exists and is the right type
	if message_label and message_label is RichTextLabel:
		print("NotificationManager: Found RichTextLabel, enabling BBCode")
		message_label.bbcode_enabled = true
		message_label.fit_content = true
	elif message_label:
		print("NotificationManager: Converting Label to RichTextLabel")
		# Replace the existing label with a RichTextLabel
		var parent = message_label.get_parent()
		var old_label = message_label
		
		# Create new RichTextLabel
		var rich_label = RichTextLabel.new()
		rich_label.name = "MessageLabel"
		rich_label.bbcode_enabled = true
		rich_label.fit_content = true
		rich_label.text = "Notification message goes here"
		rich_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rich_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Replace the old label
		parent.remove_child(old_label)
		parent.add_child(rich_label)
		message_label = rich_label
		old_label.queue_free()
		
		print("NotificationManager: Successfully replaced with RichTextLabel")
	else:
		print("NotificationManager: Error - no message_label found")

# Show a notification message with BBCode formatting
func show_notification(message: String):
	# Don't show if already showing a notification
	if is_showing:
		print("NotificationManager: Already showing notification, skipping")
		return
	
	is_showing = true
	
	# Apply BBCode formatting to specific messages
	var formatted_message = format_message_with_bbcode(message)
	print("NotificationManager: Original message: '", message, "'")
	print("NotificationManager: Formatted message: '", formatted_message, "'")
	
	# Set the text
	if message_label is RichTextLabel:
		message_label.text = formatted_message
	else:
		# Fallback for regular Label
		message_label.text = message  # Use original message without BBCode
		print("NotificationManager: Using fallback text without BBCode")
	
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
	print("NotificationManager: Formatting message: ", message)
	
	# Convert to lowercase for comparison but preserve original case
	var lower_message = message.to_lower()
	
	# Handle the "feeling" message with wave and pulse effects
	if lower_message.contains("feeling") and lower_message.contains("watched"):
		print("NotificationManager: Detected 'feeling' and 'watched' in message")
		
		# Option 2: Pulse effect only (animated pulsing opacity)
		message = message.replace("feeling", "[pulse freq=2.0 color=#9966FF ease=-2.0]feeling[/pulse]")
		
		# Option 3: Shake effect (makes text shake)
		message = message.replace("feeling", "[shake rate=20.0 level=5]feeling[/shake]")
		
		# Option 6: Fade effect (static fade)
		message = message.replace("feeling", "[fade start=0 length=7]feeling[/fade]")
		
		# Let's start with wave effect - it should be the most visible
		message = message.replace("feeling", "[wave amp=20.0 freq=3.0]feeling[/wave]")
		
		print("NotificationManager: Applied wave effect: ", message)
	# Handle the "knew" message with bold formatting
	elif lower_message.contains("knew") and lower_message.contains("would"):
		print("NotificationManager: Detected 'knew' and 'would' in message")
		message = message.replace("knew", "[b][color=#FF6666]knew[/color][/b]")
		print("NotificationManager: After bold formatting: ", message)
	# Handle the "know" message with bold formatting
	elif lower_message.contains("know") and lower_message.contains("watched"):
		print("NotificationManager: Detected 'knew' and 'would' in message")
		message = message.replace("know", "[b][color=#FF6666]knew[/color][/b]")
		print("NotificationManager: After bold formatting: ", message)
	return message

# Reset the notification to ready state
func reset_notification():
	is_showing = false
	modulate.a = 0.0
