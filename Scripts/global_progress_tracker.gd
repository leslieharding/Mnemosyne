# res://Scripts/global_progress_tracker.gd
extends Node
class_name GlobalProgressTracker

# Structure: {god_name: {card_index: {total_exp: X}}}
var progress_data: Dictionary = {}
var save_path: String = "user://card_progress.save"

var traps_fallen_for: int = 0  # Track trap encounters for Artemis unlock


# NEW: God unlock tracking
var unlocked_gods: Array[String] = ["Apollo"]  # Apollo starts unlocked
var god_unlock_conditions: Dictionary = {
	"Hermes": {
		"type": "boss_defeated",
		"boss_name": "?????",
		"description": "Defeat the mysterious final boss"
	},
	"Artemis": {
		"type": "traps_fallen_for",  
		"required_count": 3,         
		"description": "Fall for 3 different traps"  
	},
	"Aphrodite": {
		"type": "couples_united",
		"required_count": 2,
		"description": "Unite 2 couples by placing them adjacent on the board"
	},
	"Demeter": {
		"type": "cards_leveled",
		"required_count": 5,
		"description": "Level up 5 different cards"
	}
}

var couple_definitions = {
	"Phaeton": "Cygnus",
	"Cygnus": "Phaeton", 
	"Orpheus": "Eurydice",
	"Eurydice": "Orpheus"
}

var couples_united: Array = []  # Track which couples have been united

func _ready():
	load_progress()

# Check if there's any progress data saved
func has_any_progress() -> bool:
	for god_name in progress_data:
		var god_progress = progress_data[god_name]
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			if card_exp["total_exp"] > 0:
				return true
	return false

# Add experience from a completed run - UNIFIED VERSION
func add_run_experience(god_name: String, run_experience: Dictionary):
	# Ensure the god exists in our data
	if not god_name in progress_data:
		progress_data[god_name] = {}
	
	# Add each card's experience (combining capture + defense)
	for card_index in run_experience:
		var card_exp = run_experience[card_index]
		
		# Ensure this card exists in our data
		if not card_index in progress_data[god_name]:
			progress_data[god_name][card_index] = {
				"total_exp": 0
			}
		
		# Combine both experience types into unified pool
		var total_gained = card_exp.get("capture_exp", 0) + card_exp.get("defense_exp", 0)
		progress_data[god_name][card_index]["total_exp"] += total_gained
		
		print("Card ", card_index, " gained ", total_gained, " total exp (", card_exp.get("capture_exp", 0), " capture + ", card_exp.get("defense_exp", 0), " defense)")
	
	print("Added run experience for ", god_name, ": ", run_experience)
	
	# Check for conversation triggers based on experience gained
	if has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		
		# Calculate total experience gained this run
		var total_run_exp = 0
		for card_exp in run_experience.values():
			total_run_exp += card_exp.get("capture_exp", 0) + card_exp.get("defense_exp", 0)
		
		# Check for Apollo mastery conversation (when significant experience is gained)
		if god_name == "Apollo" and total_run_exp >= 30:
			print("Triggering apollo_mastery conversation")
			conv_manager.trigger_conversation("apollo_mastery")
		
		# Check if any card reached a high level for first deck unlock conversation
		for card_index in progress_data[god_name]:
			var card_data = progress_data[god_name][card_index]
			var total_card_exp = card_data["total_exp"]
			if total_card_exp >= 100:  # Arbitrary threshold for "significant progress"
				print("Triggering first_deck_unlock conversation")
				conv_manager.trigger_conversation("first_deck_unlock")
				break  # Only trigger once
	
	save_progress()

# Get total experience for a specific card - UNIFIED VERSION
func get_card_total_experience(god_name: String, card_index: int) -> Dictionary:
	if god_name in progress_data and card_index in progress_data[god_name]:
		var total_exp = progress_data[god_name][card_index]["total_exp"]
		# Return in old format for backward compatibility
		return {
			"capture_exp": total_exp / 2,  # Split for display purposes
			"defense_exp": total_exp / 2,
			"total_exp": total_exp
		}
	return {"capture_exp": 0, "defense_exp": 0, "total_exp": 0}

# NEW: Get card level directly
func get_card_level(god_name: String, card_index: int) -> int:
	if god_name in progress_data and card_index in progress_data[god_name]:
		var total_exp = progress_data[god_name][card_index]["total_exp"]
		return ExperienceHelpers.calculate_level(total_exp)
	return 1  # Default level is 1, not 0

# Get all card experience for a god
func get_god_progress(god_name: String) -> Dictionary:
	if god_name in progress_data:
		return progress_data[god_name].duplicate()
	return {}

# Save progress to disk
func save_progress():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		var save_data = {
			"progress_data": progress_data,
			"unlocked_gods": unlocked_gods,
			"couples_united": couples_united,
			"traps_fallen_for": traps_fallen_for  # NEW LINE
		}
		save_file.store_var(save_data)
		save_file.close()
		print("Progress saved to ", save_path)
	else:
		print("Failed to save progress!")

# Load progress from disk - with migration support
# Load progress from disk - with migration support
func load_progress():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var loaded_data = save_file.get_var()
			
			# Handle both old and new save formats
			if loaded_data is Dictionary and loaded_data.has("progress_data"):
				# New format with god unlocks
				var old_progress_data = loaded_data.get("progress_data", {})
				unlocked_gods = loaded_data.get("unlocked_gods", ["Apollo"])
				couples_united = loaded_data.get("couples_united", [])
				traps_fallen_for = loaded_data.get("traps_fallen_for", 0)  # NEW LINE
				
				# Migrate old capture_exp/defense_exp format to unified total_exp
				progress_data = migrate_experience_data(old_progress_data)
			else:
				# Very old format - just progress data
				var old_progress_data = loaded_data if loaded_data is Dictionary else {}
				unlocked_gods = ["Apollo"]  # Default to just Apollo
				couples_united = []
				traps_fallen_for = 0  # NEW LINE
				progress_data = migrate_experience_data(old_progress_data)
			
			save_file.close()
			print("Progress loaded from ", save_path)
			print("Unlocked gods: ", unlocked_gods)
			print("Couples united: ", couples_united)
			print("Traps fallen for: ", traps_fallen_for)  # NEW LINE
			
			# Save immediately to update format
			save_progress()
		else:
			print("Failed to load progress!")
	else:
		print("No save file found, starting fresh")

# Migrate old separate experience format to unified
func migrate_experience_data(old_data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = {}
	
	for god_name in old_data:
		migrated_data[god_name] = {}
		var god_progress = old_data[god_name]
		
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			
			# Convert old format to new format
			if card_exp.has("capture_exp") and card_exp.has("defense_exp"):
				# Old format - combine the experiences
				var total_exp = card_exp.get("capture_exp", 0) + card_exp.get("defense_exp", 0)
				migrated_data[god_name][card_index] = {"total_exp": total_exp}
				print("Migrated card ", card_index, " from separate exp (", card_exp.get("capture_exp", 0), "+", card_exp.get("defense_exp", 0), ") to unified (", total_exp, ")")
			elif card_exp.has("total_exp"):
				# Already new format
				migrated_data[god_name][card_index] = card_exp
			else:
				# Unknown format - start fresh
				migrated_data[god_name][card_index] = {"total_exp": 0}
	
	return migrated_data

# Clear all progress (for testing or reset)
func clear_all_progress():
	progress_data.clear()
	unlocked_gods = ["Apollo"]  # Reset to only Apollo unlocked
	couples_united = []  # Clear united couples
	traps_fallen_for = 0  # NEW LINE
	save_progress()
	print("All progress cleared - reset to Apollo only")

# Clear progress for a specific god
func clear_god_progress(god_name: String):
	if god_name in progress_data:
		progress_data.erase(god_name)
		save_progress()

# === GOD UNLOCK FUNCTIONS === (unchanged)

# Check if a god is unlocked
func is_god_unlocked(god_name: String) -> bool:
	return god_name in unlocked_gods

# Get all unlocked gods
func get_unlocked_gods() -> Array[String]:
	return unlocked_gods.duplicate()

# Check and potentially unlock gods based on current progress
func check_god_unlocks() -> Array[String]:
	var newly_unlocked: Array[String] = []
	
	for god_name in god_unlock_conditions:
		if is_god_unlocked(god_name):
			continue  # Already unlocked
		
		var condition = god_unlock_conditions[god_name]
		if check_unlock_condition(condition):
			unlock_god(god_name)
			newly_unlocked.append(god_name)
	
	return newly_unlocked

func check_unlock_condition(condition: Dictionary) -> bool:
	match condition.get("type", ""):
		"boss_defeated":
			return check_boss_defeated(condition.get("boss_name", ""))
		"couples_united":
			var required = condition.get("required_count", 2)
			return couples_united.size() >= required
		"cards_leveled":
			var required = condition.get("required_count", 5)
			return count_leveled_cards() >= required
		"traps_fallen_for":  # NEW CASE
			var required = condition.get("required_count", 3)
			return traps_fallen_for >= required
		_:
			return false

# Check if a specific boss has been defeated
func check_boss_defeated(boss_name: String) -> bool:
	if not has_node("/root/MemoryJournalManagerAutoload"):
		return false
	
	var memory_manager = get_node("/root/MemoryJournalManagerAutoload")
	var enemy_memories = memory_manager.get_all_enemy_memories()
	
	if boss_name in enemy_memories:
		var boss_data = enemy_memories[boss_name]
		return boss_data.get("victories", 0) > 0
	
	return false



# Check if enough cards have been leveled up
func count_leveled_cards() -> int:
	var leveled_count = 0
	
	# Count cards across all gods that have reached level 2 or higher
	for god_name in progress_data:
		var god_progress = progress_data[god_name]
		for card_index in god_progress:
			var card_data = god_progress[card_index]
			var card_level = ExperienceHelpers.calculate_level(card_data["total_exp"])
			if card_level >= 2:  # Level 2 or higher counts as "leveled up"
				leveled_count += 1
	
	return leveled_count


# Unlock a god
func unlock_god(god_name: String):
	if not god_name in unlocked_gods:
		unlocked_gods.append(god_name)
		save_progress()
		print("God unlocked: ", god_name)
		
		# Trigger conversation if available
		if has_node("/root/ConversationManagerAutoload"):
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			conv_manager.trigger_conversation("god_unlocked_" + god_name.to_lower())

# Get unlock condition description for a locked god
func get_god_unlock_description(god_name: String) -> String:
	if is_god_unlocked(god_name):
		return "Unlocked"
	
	if god_name in god_unlock_conditions:
		var condition = god_unlock_conditions[god_name]
		var progress = get_unlock_progress_text(condition)
		return condition.get("description", "Unknown requirement") + progress
	
	return "No unlock condition defined"

func get_unlock_progress_text(condition: Dictionary) -> String:
	match condition.get("type", ""):
		"boss_defeated":
			var boss_name = condition.get("boss_name", "")
			if check_boss_defeated(boss_name):
				return " ✓"
			else:
				return " (Not yet defeated)"
		"couples_united":
			var required = condition.get("required_count", 2)
			var current = couples_united.size()
			if current >= required:
				return " ✓"
			else:
				return " (" + str(current) + "/" + str(required) + " couples united)"
		"cards_leveled":
			var required = condition.get("required_count", 5)
			var current = count_leveled_cards()
			if current >= required:
				return " ✓"
			else:
				return " (" + str(current) + "/" + str(required) + " cards leveled)"
		"traps_fallen_for":  # NEW CASE
			var required = condition.get("required_count", 3)
			if traps_fallen_for >= required:
				return " ✓"
			else:
				return " (" + str(traps_fallen_for) + "/" + str(required) + " traps encountered)"
		_:
			return ""

func record_trap_fallen_for(trap_type: String, details: String = ""):
	traps_fallen_for += 1
	print("Player fell for trap: ", trap_type, " - ", details, " (", traps_fallen_for, "/3)")
	
	# Save progress
	save_progress()
	
	# Check for Artemis unlock
	if not is_god_unlocked("Artemis") and traps_fallen_for >= 3:
		unlock_god("Artemis")
		print("🏹 Artemis unlocked through trap encounters! 🏹")
		
		# Trigger conversation if available
		if has_node("/root/ConversationManagerAutoload"):
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			conv_manager.trigger_conversation("artemis_unlocked")

# NEW: Separate function to check if we should show the Artemis watching notification
func should_show_artemis_notification() -> bool:
	return not is_god_unlocked("Artemis")



func record_couple_union(card1_name: String, card2_name: String):
	# Create a consistent couple identifier (alphabetical order)
	var couple_names = [card1_name, card2_name]
	couple_names.sort()
	var couple_id = couple_names[0] + " & " + couple_names[1]
	
	# Only record if not already recorded (this ensures uniqueness)
	if not couple_id in couples_united:
		couples_united.append(couple_id)
		print("Love blooms! ", couple_id, " have been united!")
		
		# Show notification if available
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.has_method("show_notification"):
			current_scene.show_notification("💕 " + couple_id + " united! 💕")
		elif current_scene and "notification_manager" in current_scene:
			current_scene.notification_manager.show_notification("💕 " + couple_id + " united! 💕")
		
		# Check for Aphrodite unlock
		check_aphrodite_unlock()
		
		save_progress()
	else:
		print("Couple ", couple_id, " has already been united - no duplicate recording")

func get_couples_united_count() -> int:
	return couples_united.size()

func get_united_couples() -> Array[String]:
	var result: Array[String] = []
	for item in couples_united:
		if item is String:
			result.append(item as String)
	return result

func check_aphrodite_unlock():
	if couples_united.size() >= 2 and not is_god_unlocked("Aphrodite"):
		unlock_god("Aphrodite")
		print("Aphrodite unlocked due to ", couples_united.size(), " couples united!")
		
		# Trigger special conversation
		if has_node("/root/ConversationManagerAutoload"):
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			conv_manager.trigger_conversation("aphrodite_unlocked")
