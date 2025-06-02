# res://Resources/deck_definition.gd
class_name DeckDefinition
extends Resource

@export var deck_name: String
@export var deck_description: String
# Store indices into the cards array instead of references
@export var card_indices: Array[int]  # 5 indices pointing to cards in the god's card collection

# Unlock conditions
@export var is_starter_deck: bool = false  # If true, always unlocked
@export var required_capture_exp: int = 0  # Total capture exp needed to unlock
@export var required_defense_exp: int = 0  # Total defense exp needed to unlock

# Check if this deck is unlocked for a specific god
func is_unlocked(god_name: String) -> bool:
	# Starter decks are always unlocked
	if is_starter_deck:
		return true
	
	# Check experience requirements through Engine singleton
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if scene_tree and scene_tree.has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = scene_tree.get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress(god_name)
		
		# Calculate total experience across all cards for this god
		var total_capture_exp = 0
		var total_defense_exp = 0
		
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			total_capture_exp += card_exp.get("capture_exp", 0)
			total_defense_exp += card_exp.get("defense_exp", 0)
		
		# Check if requirements are met
		var capture_met = required_capture_exp == 0 or total_capture_exp >= required_capture_exp
		var defense_met = required_defense_exp == 0 or total_defense_exp >= required_defense_exp
		
		return capture_met and defense_met
	
	# If no progress tracker, assume unlocked (fallback)
	return true

# Get unlock status description for UI
func get_unlock_description(god_name: String) -> String:
	if is_starter_deck:
		return "Starter Deck - Always Available"
	
	if is_unlocked(god_name):
		return "Unlocked"
	
	# Build requirements string
	var requirements: Array[String] = []
	
	if required_capture_exp > 0:
		var current_capture = get_current_capture_exp(god_name)
		requirements.append("Capture XP: " + str(current_capture) + "/" + str(required_capture_exp))
	
	if required_defense_exp > 0:
		var current_defense = get_current_defense_exp(god_name)
		requirements.append("Defense XP: " + str(current_defense) + "/" + str(required_defense_exp))
	
	return "Requires: " + " & ".join(requirements)

# Helper to get current capture experience
func get_current_capture_exp(god_name: String) -> int:
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if scene_tree and scene_tree.has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = scene_tree.get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress(god_name)
		
		var total = 0
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			total += card_exp.get("capture_exp", 0)
		return total
	return 0

# Helper to get current defense experience
func get_current_defense_exp(god_name: String) -> int:
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if scene_tree and scene_tree.has_node("/root/GlobalProgressTrackerAutoload"):
		var progress_tracker = scene_tree.get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress(god_name)
		
		var total = 0
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			total += card_exp.get("defense_exp", 0)
		return total
	return 0
