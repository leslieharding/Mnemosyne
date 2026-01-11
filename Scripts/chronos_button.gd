# res://Scripts/chronos_button.gd
extends Button
class_name ChronosButton

# Visual colors
@export var unlocked_color: Color = Color("#8B0000")  # Dark red for Chronos
@export var locked_color: Color = Color("#3A3A3A")  # Gray for locked
@export var border_color_offset: Color = Color(0.2, 0.2, 0.2, 0)
@export var pulse_enabled: bool = true
@export var pulse_intensity: float = 0.3

# Visual states
var unlocked_style: StyleBoxFlat
var locked_style: StyleBoxFlat

# Animation
var pulse_tween: Tween

func _ready():
	# Create button styles
	create_button_styles()
	
	# Connect button press
	pressed.connect(_on_chronos_button_pressed)
	
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
	
	# Unlocked style
	unlocked_style = base_style.duplicate()
	unlocked_style.bg_color = unlocked_color
	unlocked_style.border_color = unlocked_color + border_color_offset
	
	# Locked style
	locked_style = base_style.duplicate()
	locked_style.bg_color = locked_color
	locked_style.border_color = locked_color + border_color_offset

func update_button_state():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		print("ERROR: GlobalProgressTrackerAutoload not found!")
		visible = false
		return
	
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	
	# Check state
	var is_visible = progress_tracker.chronos_rechallenge_visible
	var is_unlocked = progress_tracker.chronos_rechallenge_unlocked
	
	print("Chronos button - visible: ", is_visible, ", unlocked: ", is_unlocked)
	
	if not is_visible:
		# State 1: Hidden
		visible = false
	elif not is_unlocked:
		# State 2: Visible but disabled
		visible = true
		disabled = true
		modulate.a = 0.6
		text = "Challenge Chronos (Locked)"
		add_theme_stylebox_override("normal", locked_style)
		add_theme_stylebox_override("hover", locked_style)
		add_theme_stylebox_override("pressed", locked_style)
		stop_pulse_animation()
	else:
		# State 3: Active
		visible = true
		disabled = false
		modulate.a = 1.0
		text = "Challenge Chronos"
		add_theme_stylebox_override("normal", unlocked_style)
		add_theme_stylebox_override("hover", unlocked_style)
		add_theme_stylebox_override("pressed", unlocked_style)
		start_pulse_animation()

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

func _on_chronos_button_pressed():
	if not has_node("/root/GlobalProgressTrackerAutoload"):
		return
	
	var progress_tracker = get_node("/root/GlobalProgressTrackerAutoload")
	
	# Verify button is actually unlocked
	if not progress_tracker.chronos_rechallenge_unlocked:
		print("Chronos challenge not unlocked yet")
		return
	
	print("Starting Chronos challenge battle")
	
	# Set up battle parameters
	var params = {
		"is_chronos_challenge": true,
		"god": "Mnemosyne",
		"deck_index": 0,
		"enemy_name": "Chronos",
		"enemy_difficulty": 0
	}
	
	get_tree().set_meta("scene_params", params)
	TransitionManagerAutoload.change_scene_to("res://Scenes/CardBattle.tscn")
