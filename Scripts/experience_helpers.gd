# res://Scripts/experience_helpers.gd
class_name ExperienceHelpers
extends RefCounted

# Configuration
const XP_PER_LEVEL: int = 50

# Calculate level from experience points
static func calculate_level(xp: int) -> int:
	return xp / XP_PER_LEVEL

# Calculate progress within current level (0-49)
static func calculate_progress(xp: int) -> int:
	return xp % XP_PER_LEVEL

# Calculate progress as percentage (0.0-1.0)
static func calculate_progress_percentage(xp: int) -> float:
	var progress = calculate_progress(xp)
	return float(progress) / float(XP_PER_LEVEL)

# Get minimum XP needed for a specific level
static func get_xp_for_level(level: int) -> int:
	return level * XP_PER_LEVEL

# Get XP needed to reach next level
static func get_xp_to_next_level(xp: int) -> int:
	var current_level = calculate_level(xp)
	var next_level_xp = get_xp_for_level(current_level + 1)
	return next_level_xp - xp

# Get formatted level string for display
static func format_level_display(xp: int, show_progress: bool = true) -> String:
	var level = calculate_level(xp)
	if not show_progress:
		return "Lv." + str(level)
	
	var progress = calculate_progress(xp)
	return "Lv." + str(level) + " (" + str(progress) + "/" + str(XP_PER_LEVEL) + ")"

# Check if XP gain will result in level up
static func will_level_up(current_xp: int, xp_gain: int) -> bool:
	var current_level = calculate_level(current_xp)
	var new_level = calculate_level(current_xp + xp_gain)
	return new_level > current_level

# Get number of levels gained from XP increase
static func levels_gained(old_xp: int, new_xp: int) -> int:
	var old_level = calculate_level(old_xp)
	var new_level = calculate_level(new_xp)
	return new_level - old_level
