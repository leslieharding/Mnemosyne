# res://Scripts/MnemosyneProgressTracker.gd
extends Node

signal mnemosyne_card_upgraded(card_index: int, stat_index: int, new_value: int)
signal mnemosyne_level_increased(new_level: int)
signal mnemosyne_ability_unlocked(card_index: int, ability_name: String)

# Save data
var progression_data: Dictionary = {
	"current_level": 0,  # Total upgrades applied
	"god_contributions": {},  # "god_deck" -> contribution_count
	"applied_upgrades": []  # Array of upgrade dictionaries for history
}

# Configuration
const MAX_CONTRIBUTIONS_PER_DECK = 25
const BASE_CARD_VALUES = [1, 1, 1, 1]  # N, E, S, W
const MNEMOSYNE_CARD_COUNT = 5

# Boss ability mappings - predefined abilities unlocked by defeating specific bosses
# This is where you define which abilities each card gets when bosses are defeated
var card_boss_abilities: Dictionary = {
	0: {  # Clio (History Muse)
		"apollo_boss_defeated": preload("res://Resources/Abilities/core.tres"),
		"athena_boss_defeated": preload("res://Resources/Abilities/core.tres")
	},
	1: {  # Euterpe (Music Muse)  
		"hermes_boss_defeated": preload("res://Resources/Abilities/core.tres"),
		"apollo_boss_defeated": preload("res://Resources/Abilities/core.tres")
	},
	2: {  # Terpsichore (Dance Muse)
		"hermes_boss_defeated": preload("res://Resources/Abilities/core.tres"),
		"ares_boss_defeated": preload("res://Resources/Abilities/core.tres")
	},
	3: {  # Thalia (Comedy Muse)
		"apollo_boss_defeated": preload("res://Resources/Abilities/core.tres"),
		"artemis_boss_defeated": preload("res://Resources/Abilities/core.tres")
	},
	4: {  # Melpomene (Tragedy Muse)
		"hades_boss_defeated": preload("res://Resources/Abilities/core.tres"),
		"athena_boss_defeated": preload("res://Resources/Abilities/core.tres")
	}
}

# Card name mapping for reference
const CARD_NAMES = ["Clio", "Euterpe", "Terpsichore", "Thalia", "Melpomene"]

var progression_map: Dictionary = {
	1: {"card_index": 2, "stat_index": 3},   # Terpsichore West
	3: {"card_index": 4, "stat_index": 3},   # Melpomene East
	5: {"card_index": 0, "stat_index": 2},   # Clio South
	7: {"card_index": 1, "stat_index": 0},   # Euterpe North
	9: {"card_index": 3, "stat_index": 2},   # Thalia South
	11: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	13: {"card_index": 4, "stat_index": 2},  # Melpomene South
	15: {"card_index": 1, "stat_index": 1},  # Euterpe East
	17: {"card_index": 0, "stat_index": 0},  # Clio North
	19: {"card_index": 3, "stat_index": 1},  # Thalia East
	21: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	23: {"card_index": 4, "stat_index": 1},  # Melpomene West
	25: {"card_index": 1, "stat_index": 2},  # Euterpe South
	27: {"card_index": 0, "stat_index": 2},  # Clio South
	29: {"card_index": 3, "stat_index": 1},  # Thalia East
	31: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	33: {"card_index": 4, "stat_index": 3},  # Melpomene East
	35: {"card_index": 1, "stat_index": 0},  # Euterpe North
	37: {"card_index": 0, "stat_index": 3},  # Clio East
	39: {"card_index": 3, "stat_index": 2},  # Thalia South
	41: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	43: {"card_index": 4, "stat_index": 2},  # Melpomene South
	45: {"card_index": 1, "stat_index": 1},  # Euterpe East
	47: {"card_index": 0, "stat_index": 0},  # Clio North
	49: {"card_index": 3, "stat_index": 1},  # Thalia East
	51: {"card_index": 2, "stat_index": 2},  # Terpsichore South
	53: {"card_index": 4, "stat_index": 3},  # Melpomene East
	55: {"card_index": 1, "stat_index": 2},  # Euterpe South
	57: {"card_index": 0, "stat_index": 2},  # Clio South
	59: {"card_index": 3, "stat_index": 2},  # Thalia South
	61: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	63: {"card_index": 4, "stat_index": 1},  # Melpomene West
	65: {"card_index": 1, "stat_index": 0},  # Euterpe North
	67: {"card_index": 0, "stat_index": 0},  # Clio North
	69: {"card_index": 3, "stat_index": 1},  # Thalia East
	71: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	73: {"card_index": 4, "stat_index": 2},  # Melpomene South
	75: {"card_index": 1, "stat_index": 1},  # Euterpe East
	77: {"card_index": 0, "stat_index": 2},  # Clio South
	79: {"card_index": 3, "stat_index": 2},  # Thalia South
	81: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	83: {"card_index": 4, "stat_index": 3},  # Melpomene East
	85: {"card_index": 1, "stat_index": 0},  # Euterpe North
	87: {"card_index": 0, "stat_index": 0},  # Clio North
	89: {"card_index": 3, "stat_index": 1},  # Thalia East
	91: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	93: {"card_index": 4, "stat_index": 1},  # Melpomene West
	95: {"card_index": 1, "stat_index": 2},  # Euterpe South
	97: {"card_index": 0, "stat_index": 3},  # Clio East
	99: {"card_index": 3, "stat_index": 2},  # Thalia South
	101: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	103: {"card_index": 4, "stat_index": 2},  # Melpomene South
	105: {"card_index": 1, "stat_index": 0},  # Euterpe North
	107: {"card_index": 0, "stat_index": 2},  # Clio South
	109: {"card_index": 3, "stat_index": 1},  # Thalia East
	111: {"card_index": 2, "stat_index": 2},  # Terpsichore South
	113: {"card_index": 4, "stat_index": 1},  # Melpomene West
	115: {"card_index": 1, "stat_index": 1},  # Euterpe East
	117: {"card_index": 0, "stat_index": 0},  # Clio North
	119: {"card_index": 3, "stat_index": 2},  # Thalia South
	121: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	123: {"card_index": 4, "stat_index": 3},  # Melpomene East
	125: {"card_index": 1, "stat_index": 0},  # Euterpe North
	127: {"card_index": 0, "stat_index": 2},  # Clio South
	129: {"card_index": 3, "stat_index": 2},  # Thalia South
	131: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	133: {"card_index": 4, "stat_index": 2},  # Melpomene South
	135: {"card_index": 1, "stat_index": 2},  # Euterpe South
	137: {"card_index": 0, "stat_index": 3},  # Clio East
	139: {"card_index": 3, "stat_index": 1},  # Thalia East
	141: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	143: {"card_index": 4, "stat_index": 1},  # Melpomene West
	145: {"card_index": 1, "stat_index": 1},  # Euterpe East
	147: {"card_index": 0, "stat_index": 0},  # Clio North
	149: {"card_index": 3, "stat_index": 2},  # Thalia South
	151: {"card_index": 2, "stat_index": 2},  # Terpsichore South
	153: {"card_index": 4, "stat_index": 3},  # Melpomene East
	155: {"card_index": 1, "stat_index": 0},  # Euterpe North
	157: {"card_index": 0, "stat_index": 3},  # Clio East
	159: {"card_index": 3, "stat_index": 2},  # Thalia South
	161: {"card_index": 2, "stat_index": 2},  # Terpsichore South
	163: {"card_index": 4, "stat_index": 2},  # Melpomene South
	165: {"card_index": 1, "stat_index": 2},  # Euterpe South
	167: {"card_index": 0, "stat_index": 0},  # Clio North
	169: {"card_index": 3, "stat_index": 1},  # Thalia East
	171: {"card_index": 2, "stat_index": 0},  # Terpsichore North
	173: {"card_index": 4, "stat_index": 1},  # Melpomene West
	175: {"card_index": 1, "stat_index": 1},  # Euterpe East
	177: {"card_index": 0, "stat_index": 2},  # Clio South
	179: {"card_index": 3, "stat_index": 2},  # Thalia South
	181: {"card_index": 4, "stat_index": 3},  # Melpomene East
	183: {"card_index": 1, "stat_index": 2},  # Euterpe South
	185: {"card_index": 0, "stat_index": 3},  # Clio East
	187: {"card_index": 3, "stat_index": 0},  # Thalia North
	189: {"card_index": 4, "stat_index": 2},  # Melpomene South
	191: {"card_index": 1, "stat_index": 0},  # Euterpe North
	193: {"card_index": 0, "stat_index": 0},  # Clio North
	195: {"card_index": 3, "stat_index": 1},  # Thalia East
	197: {"card_index": 4, "stat_index": 3},  # Melpomene East
	199: {"card_index": 1, "stat_index": 1},  # Euterpe East
	201: {"card_index": 0, "stat_index": 2},  # Clio South
	203: {"card_index": 3, "stat_index": 3},  # Thalia West
	205: {"card_index": 4, "stat_index": 2},  # Melpomene South
	207: {"card_index": 1, "stat_index": 2},  # Euterpe South
	209: {"card_index": 0, "stat_index": 3},  # Clio East
	211: {"card_index": 3, "stat_index": 0},  # Thalia North
	213: {"card_index": 4, "stat_index": 1},  # Melpomene West
	215: {"card_index": 4, "stat_index": 3},  # Melpomene East
	217: {"card_index": 4, "stat_index": 3},  # Melpomene East
	219: {"card_index": 4, "stat_index": 2},  # Melpomene South
	221: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	223: {"card_index": 2, "stat_index": 3},  # Terpsichore West
	225: {"card_index": 2, "stat_index": 3},  # Terpsichore West
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

# === BOSS ABILITY SYSTEM ===

# Called by BossVictoryTracker when a boss is defeated
func check_boss_ability_unlocks(victory_key: String):
	debug_boss_victory(victory_key)
	var unlocked_any = false
	
	# Check each card for abilities unlocked by this boss victory
	for card_index in card_boss_abilities.keys():
		if victory_key in card_boss_abilities[card_index]:
			var ability = card_boss_abilities[card_index][victory_key]
			var card_name = CARD_NAMES[card_index]
			
			# SAFETY CHECK: Ensure ability is valid and has required properties
			if not ability:
				print("Warning: Null ability found for card ", card_index, " victory key ", victory_key)
				continue
			
			# Check if ability has the ability_name property (it should be a CardAbility resource)
			if not ability.has_method("execute") or not "ability_name" in ability:
				print("Warning: Invalid ability resource for card ", card_index, " victory key ", victory_key)
				print("  Ability type: ", typeof(ability))
				print("  Ability string: ", str(ability))
				continue
			
			print("Ability unlocked! ", card_name, " gained: ", ability.ability_name)
			emit_signal("mnemosyne_ability_unlocked", card_index, ability.ability_name)
			unlocked_any = true
	
	if unlocked_any:
		print("Boss victory unlocked new Mnemosyne abilities!")

# Get all unlocked abilities for a specific card
func get_unlocked_abilities_for_card(card_index: int) -> Array[CardAbility]:
	var unlocked_abilities: Array[CardAbility] = []
	
	if not card_index in card_boss_abilities:
		return unlocked_abilities
	
	# Get boss victory tracker
	var boss_tracker = get_node_or_null("/root/BossVictoryTrackerAutoload")
	if not boss_tracker:
		print("Warning: BossVictoryTrackerAutoload not found")
		return unlocked_abilities
	
	var victory_flags = boss_tracker.get_boss_victory_flags()
	
	# Check each potential ability for this card
	for victory_key in card_boss_abilities[card_index].keys():
		if victory_flags.get(victory_key, false):
			var ability = card_boss_abilities[card_index][victory_key]
			unlocked_abilities.append(ability)
			print("Card ", card_index, " has unlocked ability: ", ability.ability_name)
	
	return unlocked_abilities

# Get all abilities for a card (both locked and unlocked) with their unlock status
func get_all_potential_abilities_for_card(card_index: int) -> Array[Dictionary]:
	var ability_info: Array[Dictionary] = []
	
	if not card_index in card_boss_abilities:
		return ability_info
	
	# Get boss victory tracker
	var boss_tracker = get_node_or_null("/root/BossVictoryTrackerAutoload")
	var victory_flags = {}
	if boss_tracker:
		victory_flags = boss_tracker.get_boss_victory_flags()
	
	# Check each potential ability for this card
	for victory_key in card_boss_abilities[card_index].keys():
		var ability = card_boss_abilities[card_index][victory_key]
		
		# SAFETY CHECK: Validate ability resource
		if not ability:
			print("Warning: Null ability found for card ", card_index, " victory key ", victory_key)
			continue
		
		# Ensure this is a valid CardAbility resource
		if not ability.has_method("execute") or not "ability_name" in ability:
			print("Warning: Invalid ability resource for card ", card_index, " victory key ", victory_key)
			print("  Ability type: ", typeof(ability))
			continue
		
		var is_unlocked = victory_flags.get(victory_key, false)
		var boss_name = victory_key.replace("_boss_defeated", "").capitalize()
		
		ability_info.append({
			"ability": ability,
			"is_unlocked": is_unlocked,
			"required_boss": boss_name,
			"victory_key": victory_key
		})
	
	return ability_info

# Check if a card has any unlocked abilities
func has_unlocked_abilities(card_index: int) -> bool:
	return get_unlocked_abilities_for_card(card_index).size() > 0

# === CARD VALUE CALCULATION ===

func get_card_values(card_index: int) -> Array[int]:
	if card_index < 0 or card_index >= MNEMOSYNE_CARD_COUNT:
		print("Warning: Invalid Mnemosyne card index: ", card_index)
		var base_values: Array[int] = [1, 1, 1, 1]
		return base_values
	
	var values: Array[int] = [1, 1, 1, 1]  # Start with base values
	
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
			"card_name": CARD_NAMES[upgrade["card_index"]]
		}
	return {}

func get_progression_summary() -> String:
	var current = get_current_level()
	var max_level = get_max_possible_level()
	var summary = "Mnemosyne Memory Level: " + str(current) + "/" + str(max_level)
	
	if current < max_level:
		var next_info = get_next_upgrade_info()
		if not next_info.is_empty():
			var stat_names = ["North", "East", "South", "West"]
			summary += "\nNext: " + next_info["card_name"] + " " + stat_names[next_info["stat_index"]]
	else:
		summary += "\n(Maximum level reached)"
	
	return summary

# === PERSISTENCE ===

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
			progression_data = save_file.get_var()
			save_file.close()
			print("Mnemosyne progression loaded")
		else:
			print("Failed to load Mnemosyne progression!")
	else:
		print("No Mnemosyne progression save found, starting fresh")

# === DEBUG FUNCTIONS ===

func debug_progression_state():
	print("=== MNEMOSYNE PROGRESSION DEBUG ===")
	print("Current level: ", get_current_level())
	print("Applied upgrades: ", progression_data["applied_upgrades"].size())
	print("God contributions: ", progression_data["god_contributions"])
	
	for i in range(MNEMOSYNE_CARD_COUNT):
		var values = get_card_values(i)
		var upgrades = get_card_upgrade_count(i)
		var abilities = get_unlocked_abilities_for_card(i)
		print("Card ", i, " (", CARD_NAMES[i], "): ", values, " (", upgrades, " upgrades, ", abilities.size(), " abilities)")
	
	print("====================================")

func reset_progression():
	progression_data = {
		"current_level": 0,
		"god_contributions": {},
		"applied_upgrades": []
	}
	save_progression_data()
	print("Mnemosyne progression reset")


func debug_boss_victory(victory_key: String):
	print("=== DEBUG BOSS VICTORY: ", victory_key, " ===")
	print("Checking cards for abilities...")
	
	for card_index in card_boss_abilities.keys():
		print("Card ", card_index, " (", CARD_NAMES[card_index], "):")
		print("  Available victory keys: ", card_boss_abilities[card_index].keys())
		
		if victory_key in card_boss_abilities[card_index]:
			var ability = card_boss_abilities[card_index][victory_key]
			print("  MATCH FOUND! Ability: ", ability)
			if ability:
				print("  Ability name: ", ability.ability_name if "ability_name" in ability else "NO NAME PROPERTY")
				print("  Has execute method: ", ability.has_method("execute"))
			else:
				print("  ERROR: Ability is null!")
		else:
			print("  No match for ", victory_key)
	print("=====================================")
