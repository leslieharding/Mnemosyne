# res://Scripts/main_level_manager.gd
extends Node
class_name MainLevelManager

signal main_level_up(new_level: int)
signal main_exp_gained(amount: int, new_total: int)

# ── Tuning constants ─────────────────────────────────────────
# Exp required to REACH each level (index 0 = level 1 baseline, not reachable)
# Edit these values freely - the system reads from the array at runtime
const XP_THRESHOLDS: Array[int] = [
	0,     # Level 1  (starting level)
	50,    # Level 2
	120,   # Level 3
	220,   # Level 4
	360,   # Level 5
	550,   # Level 6
	800,   # Level 7
	1120,  # Level 8
	1520,  # Level 9
	2000   # Level 10
]

# Multiplier applied to all XP gains at each level (index 0 = level 1)
# 1.0 = no change, 1.5 = 50% bonus, etc.
const MULTIPLIERS: Array[float] = [
	1.0,   # Level 1
	1.05,  # Level 2
	1.10,  # Level 3
	1.15,  # Level 4
	1.25,  # Level 5
	1.40,  # Level 6
	1.60,  # Level 7
	1.85,  # Level 8
	2.15,  # Level 9
	2.50   # Level 10
]

# Base exp awards for events - adjust these values as needed
const EXP_WIN: int = 10
const EXP_LOSS: int = 5
const EXP_CARD_LEVEL_UP: int = 8  # Per level gained, not per card

const MAX_LEVEL: int = 10

# ── State ─────────────────────────────────────────────────────
var main_level: int = 1
var main_exp: int = 0

var save_path: String = "user://main_level.save"

# ── Lifecycle ─────────────────────────────────────────────────
func _ready():
	load_data()

# ── Core API ──────────────────────────────────────────────────

# Add exp to the main level. Call this from any event site.
func add_main_exp(amount: int):
	if main_level >= MAX_LEVEL:
		return

	main_exp += amount
	emit_signal("main_exp_gained", amount, main_exp)
	print("MainLevel: +", amount, " exp (total: ", main_exp, ", level: ", main_level, ")")

	_check_level_up()
	save_data()

# Apply the current level's multiplier to a base XP value and return floored int.
# Use this at every site where card or bestiary XP is awarded.
func apply_xp(base_amount: int) -> int:
	return floori(base_amount * get_multiplier())

# Returns the multiplier for the current level
func get_multiplier() -> float:
	var index = clamp(main_level - 1, 0, MULTIPLIERS.size() - 1)
	return MULTIPLIERS[index]

# Returns exp needed to reach the next level (0 if at max)
func get_exp_to_next_level() -> int:
	if main_level >= MAX_LEVEL:
		return 0
	return XP_THRESHOLDS[main_level] - main_exp

# Returns progress through current level as 0.0–1.0
func get_level_progress_pct() -> float:
	if main_level >= MAX_LEVEL:
		return 1.0
	var prev_threshold = XP_THRESHOLDS[main_level - 1]
	var next_threshold = XP_THRESHOLDS[main_level]
	var span = next_threshold - prev_threshold
	if span <= 0:
		return 1.0
	return float(main_exp - prev_threshold) / float(span)

# ── Internal ──────────────────────────────────────────────────

func _check_level_up():
	while main_level < MAX_LEVEL and main_exp >= XP_THRESHOLDS[main_level]:
		main_level += 1
		emit_signal("main_level_up", main_level)
		print("MainLevel: LEVEL UP → Level ", main_level, " (multiplier now ", get_multiplier(), "x)")

# ── Save / Load ───────────────────────────────────────────────

func save_data():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var({"main_level": main_level, "main_exp": main_exp})
		save_file.close()
	else:
		print("MainLevelManager: Failed to save!")

func load_data():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var data = save_file.get_var()
			save_file.close()
			main_level = data.get("main_level", 1)
			main_exp = data.get("main_exp", 0)
			print("MainLevelManager: Loaded - Level ", main_level, ", Exp ", main_exp)
	else:
		print("MainLevelManager: No save found, starting fresh")

# Called by new game confirmation - wipes all progress
func reset():
	main_level = 1
	main_exp = 0
	save_data()
	print("MainLevelManager: Reset to Level 1")
