# res://Scripts/cutscene.gd
extends Control

# UI References
@onready var background = $Background
@onready var left_speaker_panel = $MainContainer/SpeakerArea/LeftSpeaker
@onready var right_speaker_panel = $MainContainer/SpeakerArea/RightSpeaker
@onready var left_name_label = $MainContainer/SpeakerArea/LeftSpeaker/MarginContainer/VBoxContainer/Label
@onready var right_name_label = $MainContainer/SpeakerArea/RightSpeaker/MarginContainer/VBoxContainer/Label
@onready var left_portrait_area = $MainContainer/SpeakerArea/LeftSpeaker/MarginContainer/VBoxContainer/PortraitArea
@onready var right_portrait_area = $MainContainer/SpeakerArea/RightSpeaker/MarginContainer/VBoxContainer/PortraitArea
@onready var dialogue_area = $MainContainer/DialogueArea
@onready var speaker_name_label = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/SpeakerNameLabel
@onready var dialogue_text_wrapper = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/DialogueTextWrapper
@onready var dialogue_text = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/DialogueTextWrapper/DialogueText
@onready var advance_indicator = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/HBoxContainer/AdvanceIndicator
@onready var skip_indicator = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/HBoxContainer/SkipIndicator
@onready var back_button = $MainContainer/DialogueArea/MarginContainer/VBoxContainer/HBoxContainer/BackButton

# Cutscene data
var cutscene_data: CutsceneData
var current_line_index: int = 0
var is_advancing: bool = false

# Typewriter effect variables
var typewriter_speed: float = 0.03
var typewriter_tween: Tween
var is_typing: bool = false
var full_text: String = ""
var current_visible_chars: int = 0

var fade_tween: Tween

# History navigation
var furthest_line_index: int = 0

# Speaker panel styles
var active_speaker_style: StyleBoxFlat
var inactive_speaker_style: StyleBoxFlat


func _ready():
	if get_tree().has_meta("cutscene_data"):
		cutscene_data = get_tree().get_meta("cutscene_data")
		get_tree().remove_meta("cutscene_data")
	else:
		print("No cutscene data found, returning to previous scene")
		return_to_previous_scene()
		return

	await get_tree().process_frame

	if advance_indicator:
		advance_indicator.add_theme_color_override("default_color", Color.WHITE)
		advance_indicator.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		advance_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if skip_indicator:
		skip_indicator.add_theme_color_override("default_color", Color.WHITE)
		skip_indicator.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		skip_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	setup_cutscene()

	dialogue_area.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_area.gui_input.connect(_on_dialogue_area_gui_input)
	back_button.pressed.connect(_on_back_pressed)

	set_process_input(true)

	show_current_line()


func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if is_typing:
			complete_typewriter_instantly()
		else:
			advance_dialogue()
	elif event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()


func setup_cutscene():
	if not cutscene_data:
		return
	background.color = cutscene_data.background_color
	create_speaker_styles()
	setup_character_panels()


func create_speaker_styles():
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


func _on_dialogue_area_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_pos = event.position
			print("Click detected at: ", click_pos)
			print("Dialogue area size: ", dialogue_area.size)
			print("Is typing: ", is_typing)

			if click_pos.x < dialogue_area.size.x * 0.2 and click_pos.y > dialogue_area.size.y * 0.7:
				print("Skip area clicked")
				_on_skip_pressed()
			else:
				print("Advance area clicked")
				if is_typing:
					complete_typewriter_instantly()
				else:
					advance_dialogue()


func setup_character_panels():
	left_speaker_panel.visible = false
	right_speaker_panel.visible = false
	left_name_label.text = ""
	right_name_label.text = ""

	for character in cutscene_data.participants:
		if character.default_position == "left":
			setup_speaker_panel(left_speaker_panel, left_name_label, left_portrait_area, character)
		else:
			setup_speaker_panel(right_speaker_panel, right_name_label, right_portrait_area, character)


func setup_speaker_panel(panel: PanelContainer, name_label: Label, portrait_area: Control, character: Character):
	panel.visible = true
	name_label.text = character.character_name
	name_label.add_theme_color_override("font_color", character.character_color)

	panel.add_theme_stylebox_override("panel", inactive_speaker_style)

	for child in portrait_area.get_children():
		child.queue_free()

	print("Setting up panel for: ", character.character_name)
	print("Portrait texture: ", character.portrait_texture)

	if character.portrait_texture:
		print("Creating portrait TextureRect")
		var portrait = TextureRect.new()
		portrait.texture = character.portrait_texture
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(400, 400)
		portrait.set_anchors_preset(Control.PRESET_CENTER)
		portrait.grow_horizontal = Control.GROW_DIRECTION_BOTH
		portrait.grow_vertical = Control.GROW_DIRECTION_BOTH

		var BreathingConfig = preload("res://Scripts/portrait_breathing_config.gd")
		if BreathingConfig.has_breathing(character.character_name):
			var params = BreathingConfig.get_params(character.character_name)
			var breathing_shader = load("res://Shaders/portrait_breathing.gdshader")
			var shader_material = ShaderMaterial.new()
			shader_material.shader = breathing_shader
			shader_material.set_shader_parameter("face_center", params["face_center"])
			shader_material.set_shader_parameter("face_radius", params["face_radius"])
			shader_material.set_shader_parameter("breath_speed", params["breath_speed"])
			shader_material.set_shader_parameter("breath_strength_min", params["breath_strength_min"])
			shader_material.set_shader_parameter("breath_strength_max", params["breath_strength_max"])
			shader_material.set_shader_parameter("variation_speed", params["variation_speed"])
			portrait.material = shader_material
			print("Applied breathing shader to %s" % character.character_name)

		portrait_area.add_child(portrait)
		print("Portrait added to portrait_area")
	else:
		print("No portrait texture available for ", character.character_name)


func show_current_line():
	if current_line_index >= cutscene_data.dialogue_lines.size():
		finish_cutscene()
		return

	var current_line = cutscene_data.dialogue_lines[current_line_index]
	var speaker_character = cutscene_data.get_character(current_line.speaker_id)

	if not speaker_character:
		print("Speaker not found: ", current_line.speaker_id)
		advance_dialogue()
		return

	speaker_name_label.text = speaker_character.character_name
	speaker_name_label.add_theme_color_override("font_color", speaker_character.character_color)

	update_speaker_highlighting(current_line, speaker_character)

	back_button.visible = current_line_index > 0

	if current_line_index < furthest_line_index:
		show_line_instantly(current_line.text)
	else:
		start_typewriter_effect(current_line.text)


func start_typewriter_effect(text: String):
	if typewriter_tween:
		typewriter_tween.kill()

	var current_line = cutscene_data.dialogue_lines[current_line_index]
	if current_line.tone != "":
		SoundManagerAutoload.play(current_line.tone)

	if current_line.parsed_segments.size() > 0:
		start_advanced_typewriter(current_line)
	else:
		start_simple_typewriter(text, current_line.typing_speed_multiplier)


func start_simple_typewriter(text: String, speed_mult: float = 1.0):
	animate_line_in()
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
	animate_line_in()
	is_typing = true

	full_text = dialogue_line.get_clean_text()
	dialogue_text.text = full_text
	dialogue_text.visible_characters = 0
	current_visible_chars = 0

	typewriter_tween = create_tween()

	if dialogue_line.pre_line_delay > 0:
		typewriter_tween.tween_interval(dialogue_line.pre_line_delay)

	var char_position = 0

	for segment in dialogue_line.parsed_segments:
		if segment.pause_before > 0:
			typewriter_tween.tween_interval(segment.pause_before)

		if segment.text.length() > 0:
			var segment_start = char_position
			var segment_end = char_position + segment.text.length()

			var segment_speed = segment.speed * dialogue_line.typing_speed_multiplier
			var segment_duration = segment.text.length() * typewriter_speed / segment_speed

			typewriter_tween.tween_method(
				update_visible_characters,
				segment_start,
				segment_end,
				segment_duration
			)

			char_position = segment_end

		if segment.pause_after > 0:
			typewriter_tween.tween_interval(segment.pause_after)

	if dialogue_line.post_line_delay > 0:
		typewriter_tween.tween_interval(dialogue_line.post_line_delay)

	typewriter_tween.tween_callback(complete_typewriter)


func update_visible_characters(visible_count: int):
	current_visible_chars = visible_count
	dialogue_text.visible_characters = visible_count


func complete_typewriter():
	is_typing = false
	current_visible_chars = full_text.length()
	dialogue_text.visible_characters = -1


func complete_typewriter_instantly():
	if typewriter_tween:
		typewriter_tween.kill()
	if fade_tween:      
		fade_tween.kill()  
	dialogue_text.modulate.a = 1.0  

	SoundManagerAutoload.play_dialogue_complete()

	is_typing = false
	current_visible_chars = full_text.length()
	dialogue_text.visible_characters = -1
	dialogue_text.text = full_text


func show_line_instantly(text: String) -> void:
	if typewriter_tween:
		typewriter_tween.kill()
	is_typing = false
	full_text = text
	dialogue_text.text = full_text
	dialogue_text.visible_characters = -1
	current_visible_chars = full_text.length()


func update_speaker_highlighting(line: DialogueLine, speaker: Character):
	left_speaker_panel.add_theme_stylebox_override("panel", inactive_speaker_style)
	right_speaker_panel.add_theme_stylebox_override("panel", inactive_speaker_style)
	left_speaker_panel.modulate.a = 0.7
	right_speaker_panel.modulate.a = 0.7

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

	if not is_typing:
		await animate_line_out()
	else:
		complete_typewriter_instantly()
		await animate_line_out()

	current_line_index += 1
	if current_line_index > furthest_line_index:
		furthest_line_index = current_line_index

	show_current_line()
	is_advancing = false

func _on_back_pressed() -> void:
	if current_line_index <= 0:
		return
	if is_typing:
		complete_typewriter_instantly()
		return
	current_line_index -= 1
	show_current_line()


func finish_cutscene():
	print("Cutscene finished")
	return_to_previous_scene()


func return_to_previous_scene():
	if has_node("/root/CutsceneManagerAutoload"):
		get_node("/root/CutsceneManagerAutoload").return_to_previous_scene()
	else:
		TransitionManagerAutoload.change_scene_to("res://Scenes/MainMenu.tscn")


func _on_skip_pressed():
	var confirm_dialog = AcceptDialog.new()
	confirm_dialog.dialog_text = "Skip this cutscene?"
	confirm_dialog.title = "Skip Cutscene"
	confirm_dialog.add_cancel_button("Cancel")
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()
	confirm_dialog.confirmed.connect(_on_skip_confirmed.bind(confirm_dialog))
	confirm_dialog.canceled.connect(_on_skip_canceled.bind(confirm_dialog))


func _on_skip_confirmed(dialog: AcceptDialog):
	SoundManagerAutoload.play_dialogue_skip()
	dialog.queue_free()
	finish_cutscene()


func _on_skip_canceled(dialog: AcceptDialog):
	dialog.queue_free()


func set_typewriter_speed(speed: float):
	typewriter_speed = speed


func get_typewriter_speed() -> float:
	return typewriter_speed

func animate_line_out() -> void:
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_text, "modulate:a", 0.0, 0.3)
	await fade_tween.finished


func animate_line_in() -> void:
	dialogue_text.modulate.a = 0.0
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(dialogue_text, "modulate:a", 1.0, 1.0)
