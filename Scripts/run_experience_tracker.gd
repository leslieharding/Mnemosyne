# res://Scripts/run_experience_tracker.gd
extends Node
class_name RunExperienceTracker

signal experience_updated(card_index: int, exp_type: String, amount: int)
signal run_completed()

# Track experience gained during current run
# Structure: {card_index: {"capture_exp": 0, "defense_exp": 0}}
var run_experience: Dictionary = {}

# Track which cards are in the current deck (by their collection index)
var current_deck_indices: Array[int] = []

func _ready():
	# Make this an autoload singleton
	pass

# Initialize for a new run with the deck's card indices
func start_new_run(deck_indices: Array[int]):
	run_experience.clear()
	current_deck_indices = deck_indices
	
	# Initialize all cards in deck with 0 exp
	for index in deck_indices:
		run_experience[index] = {
			"capture_exp": 0,
			"defense_exp": 0
		}
	
	print("Started new run with cards: ", deck_indices)

# Add capture experience
func add_capture_exp(card_index: int, amount: int):
	if not card_index in run_experience:
		print("Warning: Card index ", card_index, " not in current run!")
		return
	
	run_experience[card_index]["capture_exp"] += amount
	emit_signal("experience_updated", card_index, "capture", amount)
	print("Card ", card_index, " gained ", amount, " capture exp. Total: ", run_experience[card_index]["capture_exp"])

# Add defense experience
func add_defense_exp(card_index: int, amount: int):
	if not card_index in run_experience:
		print("Warning: Card index ", card_index, " not in current run!")
		return
	
	run_experience[card_index]["defense_exp"] += amount
	emit_signal("experience_updated", card_index, "defense", amount)
	print("Card ", card_index, " gained ", amount, " defense exp. Total: ", run_experience[card_index]["defense_exp"])

# Get experience for a specific card
func get_card_experience(card_index: int) -> Dictionary:
	if card_index in run_experience:
		return run_experience[card_index]
	return {"capture_exp": 0, "defense_exp": 0}

# Get total experience gained this run
func get_total_experience() -> Dictionary:
	var total = {"capture_exp": 0, "defense_exp": 0}
	for card_data in run_experience.values():
		total["capture_exp"] += card_data["capture_exp"]
		total["defense_exp"] += card_data["defense_exp"]
	return total

# Get all run experience data
func get_all_experience() -> Dictionary:
	return run_experience

# Clear run data (call when run ends or is abandoned)
func clear_run():
	run_experience.clear()
	current_deck_indices.clear()
