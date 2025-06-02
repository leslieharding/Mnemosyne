# res://Scripts/exp_progress_bar.gd
extends HBoxContainer
class_name ExpProgressBar

@onready var level_label = $LevelLabel
@onready var progress_bar = $ProgressContainer/ProgressBar
@onready var progress_label = $ProgressContainer/ProgressLabel

# Display modes
enum DisplayMode {
	COMPACT,    # Small, for deck selection
	DETAILED    # Larger, for summary screen
}

var current_mode: DisplayMode = DisplayMode.COMPACT
var exp_type: String = "capture"  # "capture" or "defense"

func _ready():
	setup_styling()

# Set up the progress bar with current experience
func setup_progress(xp: int, type: String = "capture", mode: DisplayMode = DisplayMode.COMPACT):
	exp_type = type
	current_mode = mode
	
	# Calculate level and progress
	var level = ExperienceHelpers.calculate_level(xp)
	var progress = ExperienceHelpers.calculate_progress(xp)
	
	# Update displays
	level_label.text = "Lv." + str(level)
	progress_bar.value = progress
	progress_label.text = str(progress) + "/" + str(ExperienceHelpers.XP_PER_LEVEL)
	
	# Apply styling based on type and mode
	setup_styling()
	
	# Adjust size based on mode
	if mode == DisplayMode.COMPACT:
		custom_minimum_size = Vector2(100, 16)
		level_label.add_theme_font_size_override("font_size", 10)
		progress_label.add_theme_font_size_override("font_size", 8)
	else:
		custom_minimum_size = Vector2(150, 24)
		level_label.add_theme_font_size_override("font_size", 14)
		progress_label.add_theme_font_size_override("font_size", 10)

# Set up colors and styling based on experience type
func setup_styling():
	var bar_style = StyleBoxFlat.new()
	var bg_style = StyleBoxFlat.new()
	
	# Background style
	bg_style.bg_color = Color("#333333")
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color("#555555")
	
	# Progress bar style based on type
	if exp_type == "capture":
		bar_style.bg_color = Color("#FFD700")  # Gold
		level_label.add_theme_color_override("font_color", Color("#FFD700"))
	else:  # defense
		bar_style.bg_color = Color("#87CEEB")  # Sky blue
		level_label.add_theme_color_override("font_color", Color("#87CEEB"))
	
	# Apply styles
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", bar_style)


# Animate progress change (useful for summary screen)
func animate_progress_change(old_xp: int, new_xp: int, duration: float = 1.0):
	var old_level = ExperienceHelpers.calculate_level(old_xp)
	var new_level = ExperienceHelpers.calculate_level(new_xp)
	var old_progress = ExperienceHelpers.calculate_progress(old_xp)
	var new_progress = ExperienceHelpers.calculate_progress(new_xp)
	
	# If level changed, we need to handle the animation differently
	if old_level != new_level:
		await animate_level_up(old_xp, new_xp, duration)
	else:
		# Simple progress animation within same level
		var tween = create_tween()
		tween.tween_method(update_progress_display, old_progress, new_progress, duration)

# Animate level up scenario
func animate_level_up(old_xp: int, new_xp: int, duration: float):
	var old_level = ExperienceHelpers.calculate_level(old_xp)
	var new_level = ExperienceHelpers.calculate_level(new_xp)
	var old_progress = ExperienceHelpers.calculate_progress(old_xp)
	var new_progress = ExperienceHelpers.calculate_progress(new_xp)
	
	# First, animate to end of current level
	var tween = create_tween()
	var time_per_level = duration / (new_level - old_level + 1)
	
	# Animate to end of current level
	tween.tween_method(update_progress_display, old_progress, ExperienceHelpers.XP_PER_LEVEL, time_per_level * 0.5)
	
	# Level up effect
	tween.tween_callback(show_level_up_effect)
	
	# Update to new level and animate to final progress
	tween.tween_callback(func(): level_label.text = "Lv." + str(new_level))
	tween.tween_method(update_progress_display, 0, new_progress, time_per_level * 0.5)

# Update progress bar and label during animation
func update_progress_display(progress_value: int):
	progress_bar.value = progress_value
	progress_label.text = str(progress_value) + "/" + str(ExperienceHelpers.XP_PER_LEVEL)

# Visual effect for level up
func show_level_up_effect():
	# Flash effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(2, 2, 2), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
