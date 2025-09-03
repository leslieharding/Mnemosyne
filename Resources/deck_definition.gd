# res://Resources/deck_definition.gd
class_name DeckDefinition
extends Resource

# Deck power types
enum DeckPowerType {
	NONE,
	SUN_POWER,
	PROPHECY_POWER,
	MISDIRECTION_POWER
}

@export var deck_name: String
@export var deck_description: String
# Store indices into the cards array instead of references
@export var card_indices: Array[int]  # 5 indices pointing to cards in the god's card collection

# Unlock conditions
@export var is_starter_deck: bool = false  # If true, always unlocked
@export var required_capture_exp: int = 0  # Total capture exp needed to unlock
@export var required_defense_exp: int = 0  # Total defense exp needed to unlock

# NEW: Deck power system
@export var deck_power_type: DeckPowerType = DeckPowerType.NONE
@export var power_config: Dictionary = {}  # For any power-specific configuration

# Check if this deck is unlocked for a specific god
func is_unlocked(god_name: String, god_progress: Dictionary = {}) -> bool:
	# Starter decks are always unlocked
	if is_starter_deck:
		return true
	
	# If no progress data passed, try to get it (fallback)
	var progress_data = god_progress
	if progress_data.is_empty():
		# This is a fallback - ideally the caller should pass the data
		return false
	
	# Calculate total experience across all cards for this god
	var total_exp = 0
	
	for card_index in progress_data:
		var card_exp = progress_data[card_index]
		# Handle both old and new formats
		if card_exp.has("total_exp"):
			total_exp += card_exp.get("total_exp", 0)
		else:
			# Fallback for old format
			total_exp += card_exp.get("capture_exp", 0) + card_exp.get("defense_exp", 0)
	
	# For unified experience, we'll use total experience thresholds
	# Convert old separate requirements to unified requirements
	var required_total_exp = required_capture_exp + required_defense_exp
	
	# Check if requirements are met
	var exp_met = required_total_exp == 0 or total_exp >= required_total_exp
	
	return exp_met

# Get unlock status description for UI
func get_unlock_description(god_name: String) -> String:
	if is_starter_deck:
		return "Starter Deck - Always Available"
	
	if is_unlocked(god_name):
		return "Unlocked"
	
	# Build requirements string for unified experience
	var requirements: Array[String] = []
	
	var required_total_exp = required_capture_exp + required_defense_exp
	if required_total_exp > 0:
		var current_total = get_current_total_exp(god_name)
		requirements.append("Total XP: " + str(current_total) + "/" + str(required_total_exp))
	
	return "Requires: " + " & ".join(requirements) if requirements.size() > 0 else "No requirements"

func get_power_description() -> String:
	match deck_power_type:
		DeckPowerType.SUN_POWER:
			return "☀️ Solar Blessing: 3 random grid spaces are bathed in sunlight, granting +1 to all stats for your cards placed there"
		DeckPowerType.PROPHECY_POWER:
			return "🔮 Divine Prophecy: You always go first in battle"
		DeckPowerType.MISDIRECTION_POWER:
			return "🃏 Misdirection: Once per battle, right-click an enemy card to invert its stat values"
		DeckPowerType.NONE:
			return ""
		_:
			return ""

# Helper to get current capture experience
func get_current_total_exp(god_name: String) -> int:
	print("DEBUG get_current_total_exp called for: ", god_name)
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	print("SceneTree found: ", scene_tree != null)
	if scene_tree and scene_tree.has_node("/root/GlobalProgressTrackerAutoload"):
		print("GlobalProgressTrackerAutoload found")
		var progress_tracker = scene_tree.get_node("/root/GlobalProgressTrackerAutoload")
		var god_progress = progress_tracker.get_god_progress(god_name)
		print("God progress entries: ", god_progress.size())
		
		var total = 0
		for card_index in god_progress:
			var card_exp = god_progress[card_index]
			var total_exp = card_exp.get("total_exp", 0)
			print("Card ", card_index, " total exp: ", total_exp)
			total += total_exp
		print("Total experience calculated: ", total)
		return total
	else:
		print("GlobalProgressTrackerAutoload NOT found")
	return 0
