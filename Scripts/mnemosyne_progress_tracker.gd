# res://Scripts/MnemosyneProgressTracker.gd
extends Node

signal mnemosyne_card_upgraded(card_index: int, stat_index: int, new_value: int)
signal mnemosyne_level_increased(new_level: int)

# Save data
var progression_data: Dictionary = {
	"current_level": 0,  # Total upgrades applied
	"god_contributions": {},  # "god_deck" -> contribution_count
	"applied_upgrades": []  # Array of upgrade dictionaries for history
}

# Configuration
const MAX_CONTRIBUTIONS_PER_DECK = 10
const BASE_CARD_VALUES = [1, 1, 1, 1]  # N, E, S, W
const MNEMOSYNE_CARD_COUNT = 5

# Progression map - defines order of upgrades
# You can easily modify this to change upgrade progression
var progression_map: Dictionary = {
	1: {"card_index": 0, "stat_index": 0},   # Clio North
	2: {"card_index": 1, "stat_index": 1},   # Euterpe East
	3: {"card_index": 0, "stat_index": 2},   # Clio South
	4: {"card_index": 2, "stat_index": 3},   # Terpsichore West
	5: {"card_index": 1, "stat_index": 0},   # Euterpe North
	6: {"card_index": 3, "stat_index": 1},   # Thalia East
	7: {"card_index": 0, "stat_index": 1},   # Clio East
	8: {"card_index": 2, "stat_index": 2},   # Terpsichore South
	9: {"card_index": 4, "stat_index": 0},   # Melpomene North
	10: {"card_index": 1, "stat_index": 2},  # Euterpe South
	# Add more levels as needed - this gives each card 2 upgrades to start
}

var save_path: String = "user://mnemosyne_progress.save"

func _ready():
	load_progression_data()
	print("MnemosyneProgressTracker initialized - Level: ", progression_data["current_level"])

# === MAIN PROGRESSION FUNCTIONS ===

func can_contribute(god_name: String, deck_index: int) -> bool:
	var deck_key = god_name + "_deck_" + str(deck_index)
	var current_contributions = progression_data["god_contributions"].get(deck_key, 0)
	return current_contributions < MAX_CONTRIBUTIONS_PER_DECK

func get_contribution_count(god_name: String, deck_index: int) -> int:
	var deck_key = god_name + "_deck_" + str(deck_index)
	return progression_data["god_contributions"].get(deck_key, 0)

func get_remaining_contributions(god_name: String, deck_index: int) -> int:
	return MAX_CONTRIBUTIONS_PER_DECK - get_contribution_count(god_name, deck_index)

func apply_contribution(god_name: String, deck_index: int) -> bool:
	if not can_contribute(god_name, deck_index):
		print("Cannot contribute - deck limit reached for ", god_name, " deck ", deck_index)
		return false
	
	var deck_key = god_name + "_deck_" + str(deck_index)
	
	# Increment contribution count
	if not deck_key in progression_data["god_contributions"]:
		progression_data["god_contributions"][deck_key] = 0
	progression_data["god_contributions"][deck_key] += 1
	
	# Advance level
	progression_data["current_level"] += 1
	var new_level = progression_data["current_level"]
	
	# Apply the upgrade if we have a mapping for this level
	if new_level in progression_map:
		var upgrade = progression_map[new_level]
		var card_index = upgrade["card_index"]
		var stat_index = upgrade["stat_index"]
		
		# Record the upgrade
		progression_data["applied_upgrades"].append({
			"level": new_level,
			"card_index": card_index,
			"stat_index": stat_index,
			"contributing_god": god_name,
			"contributing_deck": deck_index,
			"timestamp": Time.get_datetime_string_from_system()
		})
		
		var new_stat_value = get_card_stat_value(card_index, stat_index)
		
		print("Applied Mnemosyne upgrade level ", new_level, ": Card ", card_index, " stat ", stat_index, " -> ", new_stat_value)
		
		emit_signal("mnemosyne_card_upgraded", card_index, stat_index, new_stat_value)
		emit_signal("mnemosyne_level_increased", new_level)
		
		save_progression_data()
		return true
	else:
		print("Warning: No progression mapping for level ", new_level)
		save_progression_data()
		return true

# === CARD VALUE CALCULATION ===

func get_card_values(card_index: int) -> Array[int]:
	if card_index < 0 or card_index >= MNEMOSYNE_CARD_COUNT:
		print("Warning: Invalid Mnemosyne card index: ", card_index)
		return BASE_CARD_VALUES.duplicate()
	
	var values = BASE_CARD_VALUES.duplicate()
	
	# Apply all upgrades for this card
	for upgrade in progression_data["applied_upgrades"]:
		if upgrade["card_index"] == card_index:
			var stat_index = upgrade["stat_index"]
			values[stat_index] += 1
	
	return values

func get_card_stat_value(card_index: int, stat_index: int) -> int:
	var values = get_card_values(card_index)
	return values[stat_index]

func get_card_upgrade_count(card_index: int) -> int:
	var count = 0
	for upgrade in progression_data["applied_upgrades"]:
		if upgrade["card_index"] == card_index:
			count += 1
	return count

# === PROGRESSION INFO ===

func get_current_level() -> int:
	return progression_data["current_level"]

func get_max_possible_level() -> int:
	return progression_map.keys().size()

func get_next_upgrade_info() -> Dictionary:
	var next_level = progression_data["current_level"] + 1
	if next_level in progression_map:
		var upgrade = progression_map[next_level]
		return {
			"level": next_level,
			"card_index": upgrade["card_index"],
			"stat_index": upgrade["stat_index"],
			"card_name": get_card_name(upgrade["card_index"]),
			"stat_name": get_stat_name(upgrade["stat_index"])
		}
	return {}

func get_card_name(card_index: int) -> String:
	match card_index:
		0: return "Clio"
		1: return "Euterpe"
		2: return "Terpsichore"
		3: return "Thalia"
		4: return "Melpomene"
		_: return "Unknown"

func get_stat_name(stat_index: int) -> String:
	match stat_index:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func get_all_god_contributions() -> Dictionary:
	return progression_data["god_contributions"].duplicate()

func get_progression_summary() -> String:
	var summary = "Mnemosyne Progress Level: " + str(progression_data["current_level"])
	summary += "/" + str(get_max_possible_level()) + "\n\n"
	
	summary += "Card Upgrade Counts:\n"
	for i in range(MNEMOSYNE_CARD_COUNT):
		var upgrade_count = get_card_upgrade_count(i)
		var card_name = get_card_name(i)
		var values = get_card_values(i)
		summary += "• " + card_name + ": +" + str(upgrade_count) + " upgrades " + str(values) + "\n"
	
	summary += "\nGod Contributions:\n"
	for deck_key in progression_data["god_contributions"]:
		var contributions = progression_data["god_contributions"][deck_key]
		summary += "• " + deck_key + ": " + str(contributions) + "/" + str(MAX_CONTRIBUTIONS_PER_DECK) + "\n"
	
	return summary

# === SAVE/LOAD ===

func save_progression_data():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(progression_data)
		save_file.close()
		print("Mnemosyne progression saved")
	else:
		print("Failed to save Mnemosyne progression!")

func load_progression_data():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var loaded_data = save_file.get_var()
			if loaded_data is Dictionary:
				progression_data = loaded_data
				
				# Ensure all required keys exist (for save file migration)
				if not "current_level" in progression_data:
					progression_data["current_level"] = 0
				if not "god_contributions" in progression_data:
					progression_data["god_contributions"] = {}
				if not "applied_upgrades" in progression_data:
					progression_data["applied_upgrades"] = []
				
				print("Mnemosyne progression loaded")
			save_file.close()
		else:
			print("Failed to load Mnemosyne progression!")
	else:
		print("No Mnemosyne progression save found, starting fresh")

# === DEBUG FUNCTIONS ===

func debug_print_status():
	print("=== MNEMOSYNE PROGRESS DEBUG ===")
	print("Current Level: ", progression_data["current_level"])
	print("Applied Upgrades: ", progression_data["applied_upgrades"].size())
	print("God Contributions: ", progression_data["god_contributions"])
	
	for i in range(MNEMOSYNE_CARD_COUNT):
		var values = get_card_values(i)
		print(get_card_name(i), ": ", values)

func reset_all_progress():
	progression_data = {
		"current_level": 0,
		"god_contributions": {},
		"applied_upgrades": []
	}
	save_progression_data()
	print("Mnemosyne progress reset!")
