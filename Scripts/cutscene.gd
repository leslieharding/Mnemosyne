# res://Scripts/cutscene.gd
extends Control

# UI References - corrected to match actual scene structure
@onready var background = $Background
@onready var left_speaker_panel = $MainContainer/SpeakerArea/LeftSpeaker
@onready var right_speaker_panel = $MainContainer/SpeakerArea/RightSpeaker
@onready var left_name_label = $MainContainer/SpeakerArea/LeftSpeaker/MarginContainer/VBoxContainer/Label
@onready var right_name_label = $MainContainer/SpeakerArea/RightSpeaker/MarginContainer/VBoxContainer/Label
@onready var left_portrait_area = $MainContainer/SpeakerArea/LeftSpeaker/MarginContainer/VBoxContainer/PortraitArea
@onready var right_portrait_area = $MainContainer/SpeakerArea/RightSpeaker/MarginContainer/VBoxContainer/PortraitArea
@onready var dialogue_area = $MainContainer/DialogueArea
@onready var speaker_name_label = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/SpeakerNameLabel
@onready var dialogue_text = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/DialogueText
@onready var skip_button = $MainContainer/Controls/SkipButton
@onready var advance_button = $MainContainer/Controls/AdvanceButton

# Cutscene data
var cutscene_data: CutsceneData
var current_line_index: int = 0
var is_advancing: bool = false

# Typewriter effect variables
var typewriter_speed: float = 0.03  # Seconds per character
var typewriter_tween: Tween
var is_typing: bool = false
var full_text: String = ""
var current_visible_chars: int = 0

# Speaker panel styles
var active_speaker_style: StyleBoxFlat
var inactive_speaker_style: StyleBoxFlat

func _ready():
	# Load cutscene data from meta
	if get_tree().has_meta("cutscene_data"):
		cutscene_data = get_tree().get_meta("cutscene_data")
		get_tree().remove_meta("cutscene_data")  # Clean up
	else:
		print("No cutscene data found, returning to previous scene")
		return_to_previous_scene()
		return
	
	# Wait one frame to ensure all @onready variables are initialized
	await get_tree().process_frame
	
	# Set up the cutscene
	setup_cutscene()
	
	# Connect signals
	advance_button.pressed.connect(_on_advance_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Set up input handling for keyboard
	set_process_input(true)
	
	# Show first line
	show_current_line()

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if is_typing:
			# If currently typing, complete the text immediately
			complete_typewriter_instantly()
		else:
			# If not typing, advance to next line
			advance_dialogue()
	elif event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()

func setup_cutscene():
	if not cutscene_data:
		return
	
	# Set background color
	background.color = cutscene_data.background_color
	
	# Create speaker panel styles
	create_speaker_styles()
	
	# Set up character panels
	setup_character_panels()

func create_speaker_styles():
	# Active speaker style (highlighted)
	active_speaker_style = StyleBoxFlat.new()
	active_speaker_style.bg_color = Color("#3A3A3A")
	active_speaker_style.border_width_left = 3
	active_speaker_style.border_width_top = 3
	active_speaker_style.border_width_right = 3
	active_speaker_style.border_width_bottom = 3
	active_speaker_style.border_color = Color("#DDDDDD")
	active_speaker_style.corner_radius_top_left = 8
	active_speaker_style.corner_radius_top_right = 8
	active_speaker_style.corner_radius_bottom_left = 8
	active_speaker_style.corner_radius_bottom_right = 8
	
	# Inactive speaker style (dimmed)
	inactive_speaker_style = StyleBoxFlat.new()
	inactive_speaker_style.bg_color = Color("#2A2A2A")
	inactive_speaker_style.border_width_left = 2
	inactive_speaker_style.border_width_top = 2
	inactive_speaker_style.border_width_right = 2
	inactive_speaker_style.border_width_bottom = 2
	inactive_speaker_style.border_color = Color("#555555")
	inactive_speaker_style.corner_radius_top_left = 8
	inactive_speaker_style.corner_radius_top_right = 8
	inactive_speaker_style.corner_radius_bottom_left = 8
	inactive_speaker_style.corner_radius_bottom_right = 8

func setup_character_panels():
	# Initially hide both panels
	left_speaker_panel.visible = false
	right_speaker_panel.visible = false
	left_name_label.text = ""
	right_name_label.text = ""
	
	# Set up panels based on participants
	for character in cutscene_data.participants:
		if character.default_position == "left":
			setup_speaker_panel(left_speaker_panel, left_name_label, left_portrait_area, character)
		else:
			setup_speaker_panel(right_speaker_panel, right_name_label, right_portrait_area, character)

func setup_speaker_panel(panel: PanelContainer, name_label: Label, portrait_area: Control, character: Character):
	panel.visible = true
	name_label.text = character.character_name
	name_label.add_theme_color_override("font_color", character.character_color)
	
	# Set initial style to inactive
	panel.add_theme_stylebox_override("panel", inactive_speaker_style)
	
	# Add portrait if available (future enhancement)
	if character.portrait_texture:
		var portrait = TextureRect.new()
		portrait.texture = character.portrait_texture
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_area.add_child(portrait)

func show_current_line():
	if current_line_index >= cutscene_data.dialogue_lines.size():
		# Cutscene finished
		finish_cutscene()
		return
	
	var current_line = cutscene_data.dialogue_lines[current_line_index]
	var speaker_character = cutscene_data.get_character(current_line.speaker_id)
	
	if not speaker_character:
		print("Speaker not found: ", current_line.speaker_id)
		advance_dialogue()
		return
	
	# Update speaker name
	speaker_name_label.text = speaker_character.character_name
	speaker_name_label.add_theme_color_override("font_color", speaker_character.character_color)
	
	# Update speaker panel highlighting
	update_speaker_highlighting(current_line, speaker_character)
	
	# Start typewriter effect for dialogue text
	start_typewriter_effect(current_line.text)

func start_typewriter_effect(text: String):
	# Stop any existing typewriter effect
	if typewriter_tween:
		typewriter_tween.kill()
	
	# Get the current dialogue line
	var current_line = cutscene_data.dialogue_lines[current_line_index]
	
	# Use parsed segments if available
	if current_line.parsed_segments.size() > 0:
		start_advanced_typewriter(current_line)
	else:
		# Fallback to simple typewriter
		start_simple_typewriter(text, current_line.typing_speed_multiplier)

func start_simple_typewriter(text: String, speed_mult: float = 1.0):
	full_text = text
	current_visible_chars = 0
	is_typing = true
	
	dialogue_text.visible_characters = 0
	dialogue_text.text = full_text
	
	typewriter_tween = create_tween()
	
	var total_duration = full_text.length() * typewriter_speed / speed_mult
	
	typewriter_tween.tween_method(
		update_visible_characters,
		0,
		full_text.length(),
		total_duration
	).set_ease(Tween.EASE_IN_OUT)
	
	typewriter_tween.tween_callback(complete_typewriter)

func start_advanced_typewriter(dialogue_line: DialogueLine):
	is_typing = true
	
	# Get clean text for display
	full_text = dialogue_line.get_clean_text()
	dialogue_text.text = full_text
	dialogue_text.visible_characters = 0
	current_visible_chars = 0
	
	# Create the tween
	typewriter_tween = create_tween()
	
	# Add pre-line delay if specified
	if dialogue_line.pre_line_delay > 0:
		typewriter_tween.tween_interval(dialogue_line.pre_line_delay)
	
	var char_position = 0
	
	# Process each segment
	for segment in dialogue_line.parsed_segments:
		# Add pause before segment if specified
		if segment.pause_before > 0:
			typewriter_tween.tween_interval(segment.pause_before)
		
		# Type out the segment text
		if segment.text.length() > 0:
			var segment_start = char_position
			var segment_end = char_position + segment.text.length()
			
			# Calculate duration based on segment speed and line speed multiplier
			var segment_speed = segment.speed * dialogue_line.typing_speed_multiplier
			var segment_duration = segment.text.length() * typewriter_speed / segment_speed
			
			# Tween the visible characters for this segment
			typewriter_tween.tween_method(
				update_visible_characters,
				segment_start,
				segment_end,
				segment_duration
			)
			
			char_position = segment_end
		
		# Add pause after segment if specified
		if segment.pause_after > 0:
			typewriter_tween.tween_interval(segment.pause_after)
	
	# Add post-line delay if specified
	if dialogue_line.post_line_delay > 0:
		typewriter_tween.tween_interval(dialogue_line.post_line_delay)
	
	# Mark as complete when done
	typewriter_tween.tween_callback(complete_typewriter)

func update_visible_characters(visible_count: int):
	current_visible_chars = visible_count
	dialogue_text.visible_characters = visible_count

func complete_typewriter():
	is_typing = false
	current_visible_chars = full_text.length()
	dialogue_text.visible_characters = -1  # Show all characters

func complete_typewriter_instantly():
	if typewriter_tween:
		typewriter_tween.kill()
	
	is_typing = false
	current_visible_chars = full_text.length()
	dialogue_text.visible_characters = -1  # Show all characters
	dialogue_text.text = full_text

func update_speaker_highlighting(line: DialogueLine, speaker: Character):
	# Reset both panels to inactive
	left_speaker_panel.add_theme_stylebox_override("panel", inactive_speaker_style)
	right_speaker_panel.add_theme_stylebox_override("panel", inactive_speaker_style)
	left_speaker_panel.modulate.a = 0.7
	right_speaker_panel.modulate.a = 0.7
	
	# Determine which panel should be active
	var speaker_position = cutscene_data.get_speaker_position(line)
	
	if speaker_position == "left" and left_speaker_panel.visible:
		left_speaker_panel.add_theme_stylebox_override("panel", active_speaker_style)
		left_speaker_panel.modulate.a = 1.0
	elif speaker_position == "right" and right_speaker_panel.visible:
		right_speaker_panel.add_theme_stylebox_override("panel", active_speaker_style)
		right_speaker_panel.modulate.a = 1.0

func advance_dialogue():
	if is_advancing:
		return
	
	is_advancing = true
	current_line_index += 1
	
	# Small delay to prevent rapid clicking
	await get_tree().create_timer(0.1).timeout
	
	show_current_line()
	is_advancing = false

func finish_cutscene():
	print("Cutscene finished")
	return_to_previous_scene()

func return_to_previous_scene():
	# Use the cutscene manager to return to previous scene
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").return_to_previous_scene()
	else:
		TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")

# Signal handlers
func _on_advance_pressed():
	if is_typing:
		complete_typewriter_instantly()
	else:
		advance_dialogue()

func _on_skip_pressed():
	# Ask for confirmation before skipping
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Skip this cutscene?"
	confirm_dialog.title = "Skip Cutscene"
	
	# Add cancel button
	confirm_dialog.add_cancel_button("Cancel")
	
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()
	
	# Connect signals
	confirm_dialog.confirmed.connect(_on_skip_confirmed.bind(confirm_dialog))
	confirm_dialog.canceled.connect(_on_skip_canceled.bind(confirm_dialog))

func _on_skip_confirmed(dialog: AcceptDialog):
	dialog.queue_free()
	finish_cutscene()

func _on_skip_canceled(dialog: AcceptDialog):
	dialog.queue_free()

# Optional: Add functions to customize typewriter speed
func set_typewriter_speed(speed: float):
	typewriter_speed = speed

func get_typewriter_speed() -> float:
	return typewriter_speed
