# res://Scripts/boss_victory_tracker.gd
extends Node
class_name BossVictoryTracker

signal boss_defeated(boss_name: String)
signal new_ability_unlocked(card_name: String, ability_name: String)

# Boss victory flags - these persist across runs
var boss_victories: Dictionary = {
	"apollo_boss_defeated": false,
	"hermes_boss_defeated": false,
	"athena_boss_defeated": false,
	"artemis_boss_defeated": false,
	"ares_boss_defeated": false,
	"hades_boss_defeated": false
}

var save_path: String = "user://boss_victories.save"

func _ready():
	print("BossVictoryTracker initialized")
	load_boss_victories()

# Mark a boss as defeated
func mark_boss_defeated(boss_name: String):
	var victory_key = boss_name.to_lower() + "_boss_defeated"
	
	if victory_key in boss_victories:
		if not boss_victories[victory_key]:
			boss_victories[victory_key] = true
			print("Boss victory recorded: ", boss_name)
			emit_signal("boss_defeated", boss_name)
			
			# Check for ability unlocks
			check_ability_unlocks(victory_key)
			
			save_boss_victories()
		else:
			print("Boss ", boss_name, " was already defeated")
	else:
		print("Warning: Unknown boss name: ", boss_name)

# Check if a specific boss has been defeated
func is_boss_defeated(boss_name: String) -> bool:
	var victory_key = boss_name.to_lower() + "_boss_defeated"
	return boss_victories.get(victory_key, false)

# Get all defeated bosses
func get_defeated_bosses() -> Array[String]:
	var defeated = []
	for key in boss_victories.keys():
		if boss_victories[key]:
			var boss_name = key.replace("_boss_defeated", "").capitalize()
			defeated.append(boss_name)
	return defeated

# Get all boss victory flags (for external systems to check)
func get_boss_victory_flags() -> Dictionary:
	return boss_victories.duplicate()

# Check for ability unlocks when a boss is defeated
func check_ability_unlocks(victory_key: String):
	# Get the Mnemosyne tracker to check for ability unlocks
	var mnemosyne_tracker = get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	if not mnemosyne_tracker:
		print("Warning: MnemosyneProgressTrackerAutoload not found")
		return
	
	# Let the Mnemosyne tracker handle ability unlock notifications
	if mnemosyne_tracker.has_method("check_boss_ability_unlocks"):
		mnemosyne_tracker.check_boss_ability_unlocks(victory_key)

# Save boss victories to disk
func save_boss_victories():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(boss_victories)
		save_file.close()
		print("Boss victories saved")
	else:
		print("Failed to save boss victories!")

# Load boss victories from disk
func load_boss_victories():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			boss_victories = save_file.get_var()
			save_file.close()
			print("Boss victories loaded: ", get_defeated_bosses())
		else:
			print("Failed to load boss victories!")
	else:
		print("No boss victories save found, starting fresh")

# Debug function
func debug_boss_state():
	print("=== BOSS VICTORY TRACKER DEBUG ===")
	for key in boss_victories.keys():
		print(key, ": ", boss_victories[key])
	print("Defeated bosses: ", get_defeated_bosses())
	print("=====================================")

# Reset all boss victories (for testing)
func reset_all_victories():
	for key in boss_victories.keys():
		boss_victories[key] = false
	save_boss_victories()
	print("All boss victories reset")
