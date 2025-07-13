# res://Scripts/global_progress_tracker.gd
extends Node
class_name GlobalProgressTracker

# Structure: {god_name: {card_index: {capture_exp: X, defense_exp: Y}}}
var progress_data: Dictionary = {}
var save_path: String = "user://card_progress.save"

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
		save_file.store_var(progress_data)
		save_file.close()
		print("Progress saved to ", save_path)
	else:
		print("Failed to save progress!")

# Load progress from disk
func load_progress():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			progress_data = save_file.get_var()
			save_file.close()
			print("Progress loaded from ", save_path)
			print("Current progress data: ", progress_data)
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
