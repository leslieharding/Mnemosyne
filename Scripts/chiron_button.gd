# res://Scripts/chiron_button.gd
extends Button
class_name ChironButton

# Export these so they can be set in the inspector
@export var story_color: Color = Color("#6A4A2A")  # Gold/orange for story
@export var milestone_color: Color = Color("#4A6A4A")  # Green for milestone  
@export var disabled_color: Color = Color("#3A3A3A")  # Gray for disabled
@export var border_color_offset: Color = Color(0.2, 0.2, 0.2, 0)  # Lighter border
@export var pulse_enabled: bool = true
@export var pulse_intensity: float = 0.3  # How much to pulse (0.0 to 1.0)

# Visual states
var default_style: StyleBoxFlat
var story_style: StyleBoxFlat
var milestone_style: StyleBoxFlat
var disabled_style: StyleBoxFlat

# Animation
var pulse_tween: Tween

func _ready():
	# Create styles based on exported colors
	create_button_styles()
	
	# Connect to conversation manager
	if has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		conv_manager.new_conversation_available.connect(_on_new_conversation_available)
	
	# Connect button press
	pressed.connect(_on_chiron_button_pressed)
	
	# Update initial state
	update_button_state()

func create_button_styles():
	# Base style template
	var base_style = StyleBoxFlat.new()
	base_style.border_width_left = 2
	base_style.border_width_top = 2
	base_style.border_width_right = 2
	base_style.border_width_bottom = 2
	base_style.corner_radius_top_left = 6
	base_style.corner_radius_top_right = 6
	base_style.corner_radius_bottom_left = 6
	base_style.corner_radius_bottom_right = 6
	
	# Story style (important conversations)
	story_style = base_style.duplicate()
	story_style.bg_color = story_color
	story_style.border_color = story_color + border_color_offset
	
	# Milestone style (regular conversations)
	milestone_style = base_style.duplicate()
	milestone_style.bg_color = milestone_color
	milestone_style.border_color = milestone_color + border_color_offset
	
	# Disabled style
	disabled_style = base_style.duplicate()
	disabled_style.bg_color = disabled_color
	disabled_style.border_color = disabled_color + border_color_offset

func update_button_state():
	if not has_node("/root/ConversationManagerAutoload"):
		disabled = true
		return
	
	var conv_manager = get_node("/root/ConversationManagerAutoload")
	var button_state = conv_manager.get_conversation_button_state()
	
	if not button_state["available"]:
		# No conversations available
		disabled = true
		modulate.a = 0.6
		text = "Speak with Chiron"
		add_theme_stylebox_override("normal", disabled_style)
		add_theme_stylebox_override("hover", disabled_style)
		add_theme_stylebox_override("pressed", disabled_style)
		stop_pulse_animation()
	else:
		# Conversations available
		disabled = false
		modulate.a = 1.0
		text = button_state["text"]
		
		if button_state["priority"] == "STORY":
			# Story conversation - use gold style and pulse
			add_theme_stylebox_override("normal", story_style)
			add_theme_stylebox_override("hover", story_style)
			add_theme_stylebox_override("pressed", story_style)
			start_pulse_animation()
		else:
			# Milestone conversation - use default style
			add_theme_stylebox_override("normal", milestone_style)
			add_theme_stylebox_override("hover", milestone_style)
			add_theme_stylebox_override("pressed", milestone_style)
			stop_pulse_animation()

func start_pulse_animation():
	if not pulse_enabled:
		return
		
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	var max_alpha = 1.0 + pulse_intensity
	var min_alpha = 1.0 - (pulse_intensity * 0.3)
	pulse_tween.tween_property(self, "modulate:a", max_alpha, 0.8).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(self, "modulate:a", min_alpha, 0.8).set_ease(Tween.EASE_IN_OUT)

func stop_pulse_animation():
	if pulse_tween:
		pulse_tween.kill()
	modulate.a = 1.0

func _on_new_conversation_available(conversation_id: String, priority: String):
	print("ChironButton: New conversation available - ", conversation_id, " (", priority, ")")
	update_button_state()

func _on_chiron_button_pressed():
	if not has_node("/root/ConversationManagerAutoload"):
		return
	
	var conv_manager = get_node("/root/ConversationManagerAutoload")
	var next_conv = conv_manager.get_next_conversation()
	
	if next_conv.is_empty():
		print("No conversations available")
		return
	
	var conv_id = next_conv["id"]
	var conv_data = next_conv["data"]
	
	print("Starting conversation: ", conv_id)
	
	# Mark as shown
	conv_manager.mark_conversation_shown(conv_id)
	
	# Mark that we've shown a conversation this run (disable further conversations)
	conv_manager.set_conversation_shown_this_run()
	
	# Create and start the conversation cutscene
	start_chiron_conversation(conv_id, conv_data)
	
	# Update button state after conversation is marked as shown
	update_button_state()

func start_chiron_conversation(conv_id: String, conv_data: Dictionary):
	# Create a simple Chiron conversation
	# For now, we'll create a basic cutscene structure
	if has_node("/root/CutsceneManagerAutoload"):
		var cutscene_manager = get_node("/root/CutsceneManagerAutoload")
		
		# Create characters
		var mnemosyne = Character.new("Mnemosyne", Color("#DDA0DD"), null, "left")
		var chiron = Character.new("Chiron", Color("#FFD700"), null, "right")
		
		# Create simple dialogue based on conversation
		var dialogue_lines: Array[DialogueLine] = []
		dialogue_lines.append(DialogueLine.new("Chiron", conv_data["description"]))
		dialogue_lines.append(DialogueLine.new("Mnemosyne", "I understand, wise centaur. Your words give me much to consider."))
		dialogue_lines.append(DialogueLine.new("Chiron", "Take these lessons with you into battle, young titaness."))
		
		# Create and play the cutscene
		var cutscene_data = CutsceneData.new("chiron_" + conv_id, [mnemosyne, chiron], dialogue_lines)
		cutscene_manager.add_cutscene(cutscene_data)
		cutscene_manager.play_cutscene("chiron_" + conv_id)
	else:
		print("CutsceneManager not available, showing simple dialog")
		# Fallback: show a simple dialog
		var dialog = AcceptDialog.new()
		dialog.dialog_text = "Chiron says: \"" + conv_data["description"] + "\""
		dialog.title = "Wisdom from Chiron"
		get_tree().current_scene.add_child(dialog)
		dialog.popup_centered()
		dialog.confirmed.connect(func(): dialog.queue_free())
