# res://Scripts/memory_journal_manager.gd
extends Node
class_name MemoryJournalManager

signal new_memory_formed(memory_type: String, subject: String)
signal memory_level_increased(memory_type: String, subject: String, new_level: int)

# Memory data structure
var memory_data: Dictionary = {
	"bestiary": {},
	"gods": {},
	"mnemosyne": {
		"awakening_date": "",
		"total_battles": 0,
		"total_victories": 0,
		"total_defeats": 0,
		"gods_encountered": [],
		"enemies_mastered": 0,
		"memory_fragments": 0,
		"consciousness_level": 1,
		"personal_notes": []
	}
}

var save_path: String = "user://memory_journal.save"

# Updated memory level thresholds - experience needed for each level
const BESTIARY_EXPERIENCE_THRESHOLDS = [0, 3, 8, 15, 25, 40]  # Level 0 through 5
const GOD_LEVEL_THRESHOLDS = [1, 5, 15, 30, 50]      # battles with god needed for each level
const MNEMOSYNE_LEVEL_THRESHOLDS = [10, 25, 50, 100, 200]  # total battles for consciousness levels

# Experience values
const WIN_EXPERIENCE = 2
const LOSS_EXPERIENCE = 1

func _ready():
	load_memory_data()
	
	# Initialize Mnemosyne if this is first time
	if memory_data["mnemosyne"]["awakening_date"] == "":
		memory_data["mnemosyne"]["awakening_date"] = Time.get_datetime_string_from_system()
		save_memory_data()

# === BESTIARY FUNCTIONS ===

func record_enemy_encounter(enemy_name: String, victory: bool, enemy_difficulty: int = 0):
	# Calculate experience gained
	var exp_gained = WIN_EXPERIENCE if victory else LOSS_EXPERIENCE
	
	if not enemy_name in memory_data["bestiary"]:
		memory_data["bestiary"][enemy_name] = {
			"total_experience": 0,
			"encounters": 0,
			"victories": 0,
			"defeats": 0,
			"memory_level": 0,
			"first_encountered": Time.get_datetime_string_from_system(),
			"last_encountered": "",
			"highest_difficulty": 0
		}
		emit_signal("new_memory_formed", "bestiary", enemy_name)
	
	var enemy_data = memory_data["bestiary"][enemy_name]
	
	# Update basic stats
	enemy_data["encounters"] += 1
	enemy_data["last_encountered"] = Time.get_datetime_string_from_system()
	enemy_data["highest_difficulty"] = max(enemy_data["highest_difficulty"], enemy_difficulty)
	
	if victory:
		enemy_data["victories"] += 1
	else:
		enemy_data["defeats"] += 1
	
	# Add experience and check for level up
	var old_level = enemy_data["memory_level"]
	enemy_data["total_experience"] += exp_gained
	var new_level = calculate_bestiary_memory_level(enemy_data["total_experience"])
	
	if new_level > old_level:
		enemy_data["memory_level"] = new_level
		emit_signal("memory_level_increased", "bestiary", enemy_name, new_level)
		print("Enemy memory level increased! ", enemy_name, " is now level ", new_level)
		
		# Check for conversation trigger when enemy reaches mastery level
		if new_level >= 4 and has_node("/root/ConversationManagerAutoload"):  # "Analyzed" level or higher
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			print("Triggering first_enemy_mastered conversation")
			conv_manager.trigger_conversation("first_enemy_mastered")
	
	print("Enemy encounter recorded: ", enemy_name, " (+", exp_gained, " exp, total: ", enemy_data["total_experience"], ", level: ", enemy_data["memory_level"], ")")
	
	# Update Mnemosyne's general stats
	update_mnemosyne_battle_stats(victory)
	
	save_memory_data()

# Calculate memory level based on total experience
func calculate_bestiary_memory_level(total_experience: int) -> int:
	for i in range(BESTIARY_EXPERIENCE_THRESHOLDS.size() - 1, -1, -1):
		if total_experience >= BESTIARY_EXPERIENCE_THRESHOLDS[i]:
			return i
	return 0

# Get memory level description for bestiary with experience info
func get_bestiary_memory_description(level: int) -> String:
	match level:
		0: return "Unknown"
		1: return "Glimpsed"
		2: return "Observed"
		3: return "Understood"
		4: return "Analyzed"
		5: return "Mastered"
		_: return "Transcendent"

# Get detailed enemy information based on memory level
func get_enemy_detailed_info(enemy_name: String) -> Dictionary:
	if not enemy_name in memory_data["bestiary"]:
		return {}
	
	var enemy_data = memory_data["bestiary"][enemy_name]
	var level = enemy_data["memory_level"]
	var result = {
		"name": enemy_name,
		"memory_level": level,
		"memory_description": get_bestiary_memory_description(level),
		"total_experience": enemy_data["total_experience"],
		"encounters": enemy_data["encounters"],
		"victories": enemy_data["victories"],
		"defeats": enemy_data["defeats"]
	}
	
	# Add information based on memory level
	match level:
		0:
			result["description"] = "A mysterious adversary shrouded in uncertainty."
			result["visible_stats"] = []
		1:
			result["description"] = "You've caught glimpses of this foe in battle."
			result["visible_stats"] = ["encounters"]
		2:
			result["description"] = "Combat patterns begin to emerge from observation."
			result["visible_stats"] = ["encounters", "victories", "defeats"]
			if enemy_data["encounters"] > 0:
				var win_rate = round(float(enemy_data["victories"]) / float(enemy_data["encounters"]) * 100)
				result["win_rate"] = win_rate
		3:
			result["description"] = "You understand this enemy's basic tactics and tendencies."
			result["visible_stats"] = ["encounters", "victories", "defeats", "win_rate", "difficulty"]
			result["tactical_note"] = get_tactical_note_for_level(enemy_data, 3)
		4:
			result["description"] = "Deep analysis reveals this opponent's strengths and weaknesses."
			result["visible_stats"] = ["encounters", "victories", "defeats", "win_rate", "difficulty", "weaknesses"]
			result["tactical_note"] = get_tactical_note_for_level(enemy_data, 4)
			result["weakness_hint"] = get_weakness_hint(enemy_data)
		5:
			result["description"] = "Complete mastery: every aspect of this enemy is known to you."
			result["visible_stats"] = ["encounters", "victories", "defeats", "win_rate", "difficulty", "weaknesses", "strategy"]
			result["tactical_note"] = get_tactical_note_for_level(enemy_data, 5)
			result["weakness_hint"] = get_weakness_hint(enemy_data)
			result["optimal_strategy"] = get_optimal_strategy(enemy_data)
	
	return result

# Generate tactical notes based on memory level and win rate
func get_tactical_note_for_level(enemy_data: Dictionary, level: int) -> String:
	if enemy_data["encounters"] == 0:
		return ""
	
	var win_rate = float(enemy_data["victories"]) / float(enemy_data["encounters"])
	
	match level:
		3:
			if win_rate > 0.7:
				return "This enemy poses little threat when approached correctly."
			elif win_rate > 0.4:
				return "A balanced opponent requiring careful consideration."
			else:
				return "This foe has proven challenging - caution advised."
		4:
			if win_rate > 0.7:
				return "Weaknesses identified: exploit defensive gaps with strong directional attacks."
			elif win_rate > 0.4:
				return "Mixed results suggest this enemy adapts to different strategies."
			else:
				return "Strong defensive patterns observed - breakthrough strategies needed."
		5:
			if win_rate > 0.7:
				return "Completely understood: predictable patterns make victory assured."
			elif win_rate > 0.4:
				return "Mastered tactical analysis allows for consistent strategic victories."
			else:
				return "Even with complete knowledge, this remains a formidable opponent."
	
	return ""

# Generate weakness hints for higher memory levels
func get_weakness_hint(enemy_data: Dictionary) -> String:
	var difficulty = enemy_data.get("highest_difficulty", 0)
	match difficulty:
		0: return "Novice-level defenses can be overwhelmed with coordinated attacks."
		1: return "Moderate defensive patterns show gaps in corner positioning."
		2: return "Advanced tactics required: exploit timing windows in their card placement."
		_: return "Weakness patterns detected through extensive observation."

# Generate optimal strategy for mastery level
func get_optimal_strategy(enemy_data: Dictionary) -> String:
	var win_rate = float(enemy_data["victories"]) / float(enemy_data["encounters"]) if enemy_data["encounters"] > 0 else 0
	
	if win_rate > 0.7:
		return "Maintain aggressive positioning and exploit their predictable defensive responses."
	elif win_rate > 0.4:
		return "Balanced approach: adapt strategy based on their opening moves and card placement."
	else:
		return "Defensive strategy recommended: weather their initial assault, then counter-attack systematically."

# Get enemy memory data
func get_enemy_memory(enemy_name: String) -> Dictionary:
	if enemy_name in memory_data["bestiary"]:
		return memory_data["bestiary"][enemy_name]
	return {}

# Get all encountered enemies
func get_all_enemy_memories() -> Dictionary:
	return memory_data["bestiary"]

# === GOD FUNCTIONS === (unchanged from original)

# Record experience with a god
func record_god_experience(god_name: String, battles_fought: int = 1, deck_used: String = ""):
	if not god_name in memory_data["gods"]:
		memory_data["gods"][god_name] = {
			"battles_fought": 0,
			"memory_level": 0,
			"first_used": Time.get_datetime_string_from_system(),
			"last_used": "",
			"decks_discovered": [],
			"synergies_learned": [],
			"mastery_insights": [],
			"favorite_deck": "",
			"total_experience_gained": 0
		}
		
		# Add to Mnemosyne's encountered gods list
		if not god_name in memory_data["mnemosyne"]["gods_encountered"]:
			memory_data["mnemosyne"]["gods_encountered"].append(god_name)
		
		emit_signal("new_memory_formed", "gods", god_name)
	
	var god_data = memory_data["gods"][god_name]
	god_data["battles_fought"] += battles_fought
	god_data["last_used"] = Time.get_datetime_string_from_system()
	
	# Track deck usage
	if deck_used != "" and not deck_used in god_data["decks_discovered"]:
		god_data["decks_discovered"].append(deck_used)
	
	# Check for memory level increase
	var old_level = god_data["memory_level"]
	var new_level = calculate_god_memory_level(god_data["battles_fought"])
	if new_level > old_level:
		god_data["memory_level"] = new_level
		emit_signal("memory_level_increased", "gods", god_name, new_level)
	
	save_memory_data()

# Calculate god memory level based on battles fought
func calculate_god_memory_level(battles: int) -> int:
	for i in range(GOD_LEVEL_THRESHOLDS.size()):
		if battles < GOD_LEVEL_THRESHOLDS[i]:
			return i
	return GOD_LEVEL_THRESHOLDS.size()

# Get memory level description for gods
func get_god_memory_description(level: int) -> String:
	match level:
		0: return "Unfamiliar"
		1: return "Novice"
		2: return "Practiced"
		3: return "Skilled"
		4: return "Expert"
		5: return "Divine Mastery"
		_: return "Eternal Bond"

# Get god memory data
func get_god_memory(god_name: String) -> Dictionary:
	if god_name in memory_data["gods"]:
		return memory_data["gods"][god_name]
	return {}

# Get all god memories
func get_all_god_memories() -> Dictionary:
	return memory_data["gods"]

# === MNEMOSYNE FUNCTIONS === (unchanged from original)

func update_mnemosyne_battle_stats(victory: bool):
	memory_data["mnemosyne"]["total_battles"] += 1
	if victory:
		memory_data["mnemosyne"]["total_victories"] += 1
	else:
		memory_data["mnemosyne"]["total_defeats"] += 1
	
	# Check for consciousness level increase
	var old_level = memory_data["mnemosyne"]["consciousness_level"]
	var new_level = calculate_mnemosyne_consciousness_level()
	if new_level > old_level:
		memory_data["mnemosyne"]["consciousness_level"] = new_level
		emit_signal("memory_level_increased", "mnemosyne", "consciousness", new_level)
		
		# Trigger conversation for consciousness breakthrough at level 3 or higher
		if new_level >= 3 and has_node("/root/ConversationManagerAutoload"):
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			print("Triggering consciousness_breakthrough conversation")
			conv_manager.trigger_conversation("consciousness_breakthrough")
		
		# Add insight when leveling up
		add_mnemosyne_insight("My understanding deepens... I can feel my awareness expanding beyond mortal comprehension.")

# Calculate Mnemosyne's consciousness level
func calculate_mnemosyne_consciousness_level() -> int:
	var total_battles = memory_data["mnemosyne"]["total_battles"]
	for i in range(MNEMOSYNE_LEVEL_THRESHOLDS.size()):
		if total_battles < MNEMOSYNE_LEVEL_THRESHOLDS[i]:
			return i + 1
	return MNEMOSYNE_LEVEL_THRESHOLDS.size() + 1

# Add a personal note/insight for Mnemosyne
func add_mnemosyne_insight(note: String):
	var insight = {
		"text": note,
		"timestamp": Time.get_datetime_string_from_system(),
		"consciousness_level": memory_data["mnemosyne"]["consciousness_level"]
	}
	memory_data["mnemosyne"]["personal_notes"].append(insight)
	
	# Keep only the last 50 insights to prevent save bloat
	if memory_data["mnemosyne"]["personal_notes"].size() > 50:
		memory_data["mnemosyne"]["personal_notes"].pop_front()

# Add memory fragments (currency for future features)
func add_memory_fragments(amount: int):
	memory_data["mnemosyne"]["memory_fragments"] += amount

# Get Mnemosyne's full data
func get_mnemosyne_memory() -> Dictionary:
	return memory_data["mnemosyne"]

# Get consciousness level description
func get_consciousness_description(level: int) -> String:
	match level:
		1: return "Nascent Awareness"
		2: return "Growing Comprehension"
		3: return "Expanding Insight"
		4: return "Deep Understanding"
		5: return "Profound Wisdom"
		6: return "Transcendent Knowledge"
		_: return "Omniscient Memory"

# === SAVE/LOAD FUNCTIONS === (unchanged from original)

# Save memory data to disk
func save_memory_data():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(memory_data)
		save_file.close()
		print("Memory journal saved")
	else:
		print("Failed to save memory journal!")

# Load memory data from disk
func load_memory_data():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			memory_data = save_file.get_var()
			save_file.close()
			print("Memory journal loaded")
		else:
			print("Failed to load memory journal!")
	else:
		print("No memory journal save found, starting fresh")

# Clear all memory data (for testing or new game+)
func clear_all_memories():
	memory_data = {
		"bestiary": {},
		"gods": {},
		"mnemosyne": {
			"awakening_date": Time.get_datetime_string_from_system(),
			"total_battles": 0,
			"total_victories": 0,
			"total_defeats": 0,
			"gods_encountered": [],
			"enemies_mastered": 0,
			"memory_fragments": 0,
			"consciousness_level": 1,
			"personal_notes": []
		}
	}
	save_memory_data()

# === UTILITY FUNCTIONS ===

# Check if there are any new memories to highlight
func has_new_memories() -> bool:
	# This could be expanded to track "unviewed" memories
	return false

# Get summary statistics for UI display
func get_memory_summary() -> Dictionary:
	return {
		"enemies_encountered": memory_data["bestiary"].size(),
		"enemies_mastered": count_mastered_enemies(),
		"gods_experienced": memory_data["gods"].size(),
		"consciousness_level": memory_data["mnemosyne"]["consciousness_level"],
		"total_battles": memory_data["mnemosyne"]["total_battles"],
		"memory_fragments": memory_data["mnemosyne"]["memory_fragments"]
	}

# Count enemies that have reached mastery level
func count_mastered_enemies() -> int:
	var count = 0
	for enemy_data in memory_data["bestiary"].values():
		if enemy_data["memory_level"] >= 4:  # Analyzed or higher
			count += 1
	return count
	
	
# Add this at the end of Scripts/memory_journal_manager.gd
func debug_memory_state():
	print("=== MEMORY MANAGER DEBUG ===")
	print("Save path: ", save_path)
	print("Memory data structure: ", memory_data.keys())
	print("Bestiary entries: ", memory_data["bestiary"].size())
	
	for enemy_name in memory_data["bestiary"]:
		var enemy_data = memory_data["bestiary"][enemy_name]
		print("Enemy: ", enemy_name)
		print("  Total Experience: ", enemy_data["total_experience"])
		print("  Memory Level: ", enemy_data["memory_level"])
		print("  Encounters: ", enemy_data["encounters"])
		print("  Victories: ", enemy_data["victories"])
		print("  Defeats: ", enemy_data["defeats"])
	
	print("===========================")	
