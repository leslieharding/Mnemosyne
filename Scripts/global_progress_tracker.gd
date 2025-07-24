# res://Scripts/global_progress_tracker.gd
extends Node
class_name GlobalProgressTracker

# Structure: {god_name: {card_index: {capture_exp: X, defense_exp: Y}}}
var progress_data: Dictionary = {}
var save_path: String = "user://card_progress.save"

# NEW: God unlock tracking
var unlocked_gods: Array[String] = ["Apollo"]  # Apollo starts unlocked
var god_unlock_conditions: Dictionary = {
	"Hermes": {
		"type": "boss_defeated",
		"boss_name": "?????",
		"description": "Defeat the mysterious final boss"
	},
	"Aphrodite": {
	"type": "couples_united",
	"required_count": 2,
	"description": "Unite 2 couples"
}
}


var couple_definitions = {
	"Phaeton": "Cygnus",
	"Cygnus": "Phaeton", 
	"Orpheus": "Euridyce",
	"Euridyce": "Orpheus"
}

var couples_united: Array[String] = []  # Track which couples have been united

func _ready():
	load_progress()

# Check if there's any progress data saved
func has_any_progress() -> bool:
	for god_name in progress_data:
		var god_progress = progress_data[god_name]
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			if card_exp["capture_exp"] > 0 or card_exp["defense_exp"] > 0:
				return true
	return false



# Add experience from a completed run
# Replace this entire function in Scripts/global_progress_tracker.gd (around lines 15-35)

func add_run_experience(god_name: String, run_experience: Dictionary):
	# Ensure the god exists in our data
	if not god_name in progress_data:
		progress_data[god_name] = {}
	
	# Add each card's experience
	for card_index in run_experience:
		var card_exp = run_experience[card_index]
		
		# Ensure this card exists in our data
		if not card_index in progress_data[god_name]:
			progress_data[god_name][card_index] = {
				"capture_exp": 0,
				"defense_exp": 0
			}
		
		# Add the experience
		progress_data[god_name][card_index]["capture_exp"] += card_exp["capture_exp"]
		progress_data[god_name][card_index]["defense_exp"] += card_exp["defense_exp"]
	
	print("Added run experience for ", god_name, ": ", run_experience)
	
	# Check for conversation triggers based on experience gained
	if has_node("/root/ConversationManagerAutoload"):
		var conv_manager = get_node("/root/ConversationManagerAutoload")
		
		# Calculate total experience gained this run
		var total_run_exp = 0
		for card_exp in run_experience.values():
			total_run_exp += card_exp["capture_exp"] + card_exp["defense_exp"]
		
		# Check for Apollo mastery conversation (when significant experience is gained)
		if god_name == "Apollo" and total_run_exp >= 30:
			print("Triggering apollo_mastery conversation")
			conv_manager.trigger_conversation("apollo_mastery")
		
		# Check if any card reached a high level for first deck unlock conversation
		for card_index in progress_data[god_name]:
			var card_data = progress_data[god_name][card_index]
			var total_card_exp = card_data["capture_exp"] + card_data["defense_exp"]
			if total_card_exp >= 100:  # Arbitrary threshold for "significant progress"
				print("Triggering first_deck_unlock conversation")
				conv_manager.trigger_conversation("first_deck_unlock")
				break  # Only trigger once
	
	save_progress()

# Get total experience for a specific card
func get_card_total_experience(god_name: String, card_index: int) -> Dictionary:
	if god_name in progress_data and card_index in progress_data[god_name]:
		return progress_data[god_name][card_index].duplicate()
	return {"capture_exp": 0, "defense_exp": 0}

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
			"unlocked_gods": unlocked_gods
		}
		save_file.store_var(save_data)
		save_file.close()
		print("Progress saved to ", save_path)
	else:
		print("Failed to save progress!")

# Load progress from disk
func load_progress():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var loaded_data = save_file.get_var()
			
			# Handle both old and new save formats
			if loaded_data is Dictionary and loaded_data.has("progress_data"):
				# New format with god unlocks
				progress_data = loaded_data.get("progress_data", {})
				unlocked_gods = loaded_data.get("unlocked_gods", ["Apollo"])
			else:
				# Old format - just progress data
				progress_data = loaded_data if loaded_data is Dictionary else {}
				unlocked_gods = ["Apollo"]  # Default to just Apollo
			
			save_file.close()
			print("Progress loaded from ", save_path)
			print("Unlocked gods: ", unlocked_gods)
		else:
			print("Failed to load progress!")
	else:
		print("No save file found, starting fresh")

# Clear all progress (for testing or reset)
func clear_all_progress():
	progress_data.clear()
	save_progress()

# Clear progress for a specific god
func clear_god_progress(god_name: String):
	if god_name in progress_data:
		progress_data.erase(god_name)
		save_progress()



# === GOD UNLOCK FUNCTIONS ===

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

# Check if a specific unlock condition is met
func check_unlock_condition(condition: Dictionary) -> bool:
	match condition.get("type", ""):
		"boss_defeated":
			return check_boss_defeated(condition.get("boss_name", ""))
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

# Get progress text for unlock conditions
func get_unlock_progress_text(condition: Dictionary) -> String:
	match condition.get("type", ""):
		"boss_defeated":
			var boss_name = condition.get("boss_name", "")
			if check_boss_defeated(boss_name):
				return " ✓"
			else:
				return " (Not yet defeated)"
		_:
			return ""


func record_couple_union(card1_name: String, card2_name: String):
	# Create a consistent couple identifier (alphabetical order)
	var couple_names = [card1_name, card2_name]
	couple_names.sort()
	var couple_id = couple_names[0] + " & " + couple_names[1]
	
	# Only record if not already recorded
	if not couple_id in couples_united:
		couples_united.append(couple_id)
		print("Love blooms! ", couple_id, " have been united!")
		
		# Show notification
		if get_tree().current_scene.has_method("show_notification"):
			get_tree().current_scene.show_notification("💕 " + couple_id + " united! 💕")
		
		# Check for Aphrodite unlock
		check_aphrodite_unlock()
		
		save_progress()

func check_aphrodite_unlock():
	if couples_united.size() >= 2 and not is_god_unlocked("Aphrodite"):
		unlock_god("Aphrodite")
		
		# Trigger special conversation
		if has_node("/root/ConversationManagerAutoload"):
			var conv_manager = get_node("/root/ConversationManagerAutoload")
			conv_manager.trigger_conversation("aphrodite_unlocked")
