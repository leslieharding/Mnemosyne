extends Node
class_name MemoryJournalManager

signal new_memory_formed(memory_type: String, subject: String)
signal memory_level_increased(memory_type: String, subject: String, new_level: int)

# Content managers
var bestiary_content: BestiaryContentManager
var god_content: GodContentManager  # NEW

# Memory data structure (unchanged)
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
		
		"personal_notes": []
	}
}

var save_path: String = "user://memory_journal.save"

# Updated memory level thresholds - experience needed for each level
const BESTIARY_EXPERIENCE_THRESHOLDS = [0, 3, 8, 15, 25, 40]  # Level 0 through 5
const GOD_LEVEL_THRESHOLDS = [1, 5, 15, 30, 50]      # battles with god needed for each level

# Experience values
const WIN_EXPERIENCE = 2
const LOSS_EXPERIENCE = 3

func _ready():
	# Initialize both content managers
	bestiary_content = BestiaryContentManager.new()
	god_content = GodContentManager.new()  # NEW
	print("BestiaryContentManager initialized with ", bestiary_content.get_available_enemies().size(), " enemy profiles")
	print("GodContentManager initialized with ", god_content.get_available_gods().size(), " god profiles")  # NEW
	
	load_memory_data()
	
	# Initialize Mnemosyne if this is first time
	if memory_data["mnemosyne"]["awakening_date"] == "":
		memory_data["mnemosyne"]["awakening_date"] = Time.get_datetime_string_from_system()
		save_memory_data()

# === BESTIARY FUNCTIONS === (unchanged)

func record_enemy_encounter(enemy_name: String, victory: bool, enemy_difficulty: int = 0):
	# Calculate experience gained
	var base_exp = WIN_EXPERIENCE if victory else LOSS_EXPERIENCE
	var exp_gained = MainLevelAutoload.apply_xp(base_exp)
	
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
		if new_level >= 4 and has_node("/root/ConversationManagerAutoload"):
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

# Get memory level description for bestiary using content manager
func get_bestiary_memory_description(level: int) -> String:
	return bestiary_content.get_memory_level_description(level)

# Get detailed enemy information using BestiaryContentManager
func get_enemy_detailed_info(enemy_name: String) -> Dictionary:
	if not enemy_name in memory_data["bestiary"]:
		return {}
	
	var enemy_data = memory_data["bestiary"][enemy_name]
	
	# Use the BestiaryContentManager to get rich, enemy-specific content
	var detailed_info = bestiary_content.get_enemy_profile(
		enemy_name,
		enemy_data["memory_level"],
		enemy_data["encounters"],
		enemy_data["victories"]
	)
	
	# Add our statistical data that the content manager doesn't track
	detailed_info["first_encountered"] = enemy_data["first_encountered"]
	detailed_info["last_encountered"] = enemy_data["last_encountered"]
	detailed_info["highest_difficulty"] = enemy_data["highest_difficulty"]
	
	return detailed_info

# Check if enemy has custom content available
func has_custom_enemy_content(enemy_name: String) -> bool:
	return bestiary_content.has_enemy_profile(enemy_name)

# Get enemy memory data
func get_enemy_memory(enemy_name: String) -> Dictionary:
	if enemy_name in memory_data["bestiary"]:
		return memory_data["bestiary"][enemy_name]
	return {}

# Get all encountered enemies
func get_all_enemy_memories() -> Dictionary:
	return memory_data["bestiary"]

# === GOD FUNCTIONS === (ENHANCED WITH GOD CONTENT MANAGER)

# Record experience with a god - ENHANCED
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
			"total_experience_gained": 0,
			"achievements": {}  # NEW: For future achievement tracking
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
		print("New deck discovered for ", god_name, ": ", deck_used)
		
		# Future: Record deck discovery achievement
		# god_content.record_god_achievement(god_name, "deck_discovered", deck_used)
	
	# Check for memory level increase
	var old_level = god_data["memory_level"]
	var new_level = calculate_god_memory_level(god_data["battles_fought"])
	if new_level > old_level:
		god_data["memory_level"] = new_level
		emit_signal("memory_level_increased", "gods", god_name, new_level)
		print("God mastery level increased! ", god_name, " is now level ", new_level, " (", get_god_memory_description(new_level), ")")
		
		# Future: Record mastery level achievement
		# god_content.record_god_achievement(god_name, "mastery_level", new_level)
	
	save_memory_data()

# ENHANCED: Get detailed god information using GodContentManager
func get_god_detailed_info(god_name: String) -> Dictionary:
	if not god_name in memory_data["gods"]:
		return {}
	
	var god_data = memory_data["gods"][god_name]
	var achievements = god_data.get("achievements", {})
	
	# Use the GodContentManager to get rich, god-specific content
	var detailed_info = god_content.get_god_profile(
		god_name,
		god_data["memory_level"],
		god_data["battles_fought"],
		achievements
	)
	
	# Add our statistical data that the content manager doesn't track
	detailed_info["first_used"] = god_data["first_used"]
	detailed_info["last_used"] = god_data["last_used"]
	detailed_info["decks_discovered"] = god_data["decks_discovered"]
	detailed_info["synergies_learned"] = god_data["synergies_learned"]
	
	return detailed_info

# Calculate god memory level based on battles fought (unchanged)
func calculate_god_memory_level(battles: int) -> int:
	for i in range(GOD_LEVEL_THRESHOLDS.size()):
		if battles < GOD_LEVEL_THRESHOLDS[i]:
			return i
	return GOD_LEVEL_THRESHOLDS.size()

# Get memory level description for gods (unchanged)
func get_god_memory_description(level: int) -> String:
	match level:
		0: return "Unfamiliar"
		1: return "Novice"
		2: return "Practiced"
		3: return "Skilled"
		4: return "Expert"
		5: return "Divine Mastery"
		_: return "Eternal Bond"

# NEW: Check if god has custom content available
func has_custom_god_content(god_name: String) -> bool:
	return god_content.has_god_profile(god_name)

# Get god memory data (unchanged)
func get_god_memory(god_name: String) -> Dictionary:
	if god_name in memory_data["gods"]:
		return memory_data["gods"][god_name]
	return {}

# Get all god memories (unchanged)
func get_all_god_memories() -> Dictionary:
	return memory_data["gods"]

# NEW: Future achievement recording methods (examples)
func record_god_achievement(god_name: String, achievement_type: String, value: Variant = true):
	if not god_name in memory_data["gods"]:
		return
	
	var god_data = memory_data["gods"][god_name]
	if not "achievements" in god_data:
		god_data["achievements"] = {}
	
	god_data["achievements"][achievement_type] = value
	god_content.record_god_achievement(god_name, achievement_type, value)
	
	print("Achievement recorded for ", god_name, ": ", achievement_type, " = ", value)
	save_memory_data()

func update_mnemosyne_battle_stats(victory: bool):
	memory_data["mnemosyne"]["total_battles"] += 1
	if victory:
		memory_data["mnemosyne"]["total_victories"] += 1
	else:
		memory_data["mnemosyne"]["total_defeats"] += 1
	
	save_memory_data()
	
	
# Add a personal note/insight for Mnemosyne (unchanged)
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



# Get Mnemosyne's full data (unchanged)
func get_mnemosyne_memory() -> Dictionary:
	return memory_data["mnemosyne"]



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

# Clear all memory data (unchanged)
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
			
			
			"personal_notes": []
		}
	}
	save_memory_data()

# === UTILITY FUNCTIONS === (mostly unchanged)

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
		
	}

# Count enemies that have reached mastery level
func count_mastered_enemies() -> int:
	var count = 0
	for enemy_data in memory_data["bestiary"].values():
		if enemy_data["memory_level"] >= 4:  # Analyzed or higher
			count += 1
	return count

# Get enemies with custom content for special highlighting
func get_enemies_with_custom_content() -> Array[String]:
	return bestiary_content.get_available_enemies()

# NEW: Get gods with custom content for special highlighting
func get_gods_with_custom_content() -> Array[String]:
	return god_content.get_available_gods()

# ENHANCED: Debug function that includes both content managers
func debug_memory_state():
	print("=== MEMORY MANAGER DEBUG ===")
	print("Save path: ", save_path)
	print("Memory data structure: ", memory_data.keys())
	print("Bestiary entries: ", memory_data["bestiary"].size())
	print("God entries: ", memory_data["gods"].size())
	print("Enemies with custom content: ", bestiary_content.get_available_enemies().size())
	print("Gods with custom content: ", god_content.get_available_gods().size())  # NEW
	print("Available enemy profiles: ", bestiary_content.get_available_enemies())
	print("Available god profiles: ", god_content.get_available_gods())  # NEW
	
	for enemy_name in memory_data["bestiary"]:
		var enemy_data = memory_data["bestiary"][enemy_name]
		var has_custom = bestiary_content.has_enemy_profile(enemy_name)
		print("Enemy: ", enemy_name, " (Custom content: ", has_custom, ")")
		print("  Total Experience: ", enemy_data["total_experience"])
		print("  Memory Level: ", enemy_data["memory_level"])
	
	# NEW: Debug god data
	for god_name in memory_data["gods"]:
		var god_data = memory_data["gods"][god_name]
		var has_custom = god_content.has_god_profile(god_name)
		print("God: ", god_name, " (Custom content: ", has_custom, ")")
		print("  Battles Fought: ", god_data["battles_fought"])
		print("  Mastery Level: ", god_data["memory_level"])
		print("  Decks Discovered: ", god_data["decks_discovered"].size())
	
	print("===========================")
