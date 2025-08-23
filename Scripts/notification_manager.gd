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

# Queue system
var notification_queue: Array[String] = []
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
	print("NotificationManager: Queuing notification: '", message, "'")
	
	# Add to queue
	notification_queue.append(message)
	
	# Start processing queue if not already showing
	if not is_showing:
		process_next_notification()

# Process the next notification in the queue
func process_next_notification():
	if notification_queue.is_empty():
		return
	
	# Get the next message from queue
	var message = notification_queue.pop_front()
	
	is_showing = true
	
	# Apply BBCode formatting to specific messages
	var formatted_message = format_message_with_bbcode(message)
	print("NotificationManager: Showing notification: '", formatted_message, "'")
	
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
	
	# Reset when done and process next
	current_tween.tween_callback(on_notification_complete)

# Called when a notification finishes
func on_notification_complete():
	is_showing = false
	modulate.a = 0.0
	
	# Process the next notification in queue (if any)
	if not notification_queue.is_empty():
		# Small delay between notifications for better UX
		await get_tree().create_timer(0.3).timeout
		process_next_notification()

# Format messages with BBCode for special effects
func format_message_with_bbcode(message: String) -> String:
	print("NotificationManager: Formatting message: ", message)
	
	# Convert to lowercase for comparison but preserve original case
	var lower_message = message.to_lower()
	
	# Handle the "feeling" message with wave and pulse effects
	if lower_message.contains("feeling") and lower_message.contains("watched"):
		print("NotificationManager: Detected 'feeling' and 'watched' in message")
		
		# Combine wave effect with color for better visibility
		message = message.replace("feeling", "[wave amp=20.0 freq=3.0][color=#9966FF]feeling[/color][/wave]")
		
		print("NotificationManager: Applied wave effect with color: ", message)
	# Handle the "knew" message with bold formatting
	elif lower_message.contains("knew") and lower_message.contains("would"):
		print("NotificationManager: Detected 'knew' and 'would' in message")
		message = message.replace("knew", "[b][color=#FF6666]knew[/color][/b]")
		print("NotificationManager: After bold formatting: ", message)
	# Handle the "know" message with bold formatting
	elif lower_message.contains("know") and lower_message.contains("watched"):
		print("NotificationManager: Detected 'know' and 'watched' in message")
		message = message.replace("know", "[b][pulse freq=1.2 color=#FFD700 ease=-4.0][color=#FFD700]know[/color][/pulse][/b]")  
		print("NotificationManager: After bold formatting: ", message)
	
	return message

# Clear all queued notifications (useful for scene transitions)
func clear_queue():
	notification_queue.clear()
	print("NotificationManager: Queue cleared")

# Get current queue size (for debugging)
func get_queue_size() -> int:
	return notification_queue.size()
