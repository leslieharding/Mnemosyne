# res://Scripts/boss_loss_tracker.gd
extends Node
class_name BossLossTracker

signal boss_loss_recorded(boss_name: String, loss_count: int)

# Boss loss counters - persist across runs
var boss_losses: Dictionary = {
	"Apollo": 0,
	"Hermes": 0,
	"Artemis": 0,
	"Demeter": 0,
	"Ares": 0,
	"Hades": 0
}

# Track which deck was used for first Apollo boss victory
var apollo_first_victory_deck_index: int = -1  # -1 means no victory yet

var save_path: String = "user://boss_losses.save"

func _ready():
	print("BossLossTracker initialized")
	load_boss_losses()

# Record a loss against a specific boss
func record_boss_loss(boss_name: String):
	if boss_name in boss_losses:
		boss_losses[boss_name] += 1
		print("Boss loss recorded: ", boss_name, " (total losses: ", boss_losses[boss_name], ")")
		emit_signal("boss_loss_recorded", boss_name, boss_losses[boss_name])
		save_boss_losses()
	else:
		print("Warning: Unknown boss name: ", boss_name)

# Get loss count for a specific boss
func get_boss_loss_count(boss_name: String) -> int:
	return boss_losses.get(boss_name, 0)

# Record Apollo boss victory with deck tracking
func record_apollo_victory(deck_index: int):
	if apollo_first_victory_deck_index == -1:
		# First victory - record which deck was used
		apollo_first_victory_deck_index = deck_index
		print("First Apollo boss victory recorded with deck index: ", deck_index)
		save_boss_losses()

# Get which deck was used for first Apollo victory
func get_apollo_first_victory_deck() -> int:
	return apollo_first_victory_deck_index

# Check if this is a different Apollo deck than first victory
func is_different_apollo_deck(deck_index: int) -> bool:
	if apollo_first_victory_deck_index == -1:
		return false  # No first victory yet
	return deck_index != apollo_first_victory_deck_index

# Get all boss loss data
func get_all_boss_losses() -> Dictionary:
	return boss_losses.duplicate()

# Reset loss count for a specific boss (for testing)
func reset_boss_losses(boss_name: String):
	if boss_name in boss_losses:
		boss_losses[boss_name] = 0
		save_boss_losses()
		print("Reset losses for: ", boss_name)

# Reset all boss losses (for testing)
func reset_all_losses():
	for boss in boss_losses.keys():
		boss_losses[boss] = 0
	save_boss_losses()
	print("All boss losses reset")

# Save boss losses to disk
func save_boss_losses():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		var save_data = {
			"boss_losses": boss_losses,
			"apollo_first_victory_deck_index": apollo_first_victory_deck_index
		}
		save_file.store_var(save_data)
		save_file.close()
		print("Boss losses saved")
	else:
		print("Failed to save boss losses!")

# Load boss losses from disk
func load_boss_losses():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var save_data = save_file.get_var()
			save_file.close()
			
			# Handle both old format (just dictionary) and new format (with apollo tracking)
			if save_data is Dictionary:
				if save_data.has("boss_losses"):
					# New format
					boss_losses = save_data["boss_losses"]
					apollo_first_victory_deck_index = save_data.get("apollo_first_victory_deck_index", -1)
				else:
					# Old format - just the losses dictionary
					boss_losses = save_data
					apollo_first_victory_deck_index = -1
			
			print("Boss losses loaded: ", boss_losses)
			print("Apollo first victory deck: ", apollo_first_victory_deck_index)
		else:
			print("Failed to load boss losses!")
	else:
		print("No saved boss losses found, starting fresh")
