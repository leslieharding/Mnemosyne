class_name CardLevelHelper

static func get_card_current_level(card_index: int, god_name: String) -> int:
	# Special case for Mnemosyne - use the new tracker system
	if god_name == "Mnemosyne":
		return get_mnemosyne_card_level(card_index)
	
	# Regular god cards - use experience-based level
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if not scene_tree:
		print("Warning: SceneTree not available, returning level 1")
		return 1
		
	var global_tracker = scene_tree.get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not global_tracker:
		return 1
	
	var exp_data = global_tracker.get_card_total_experience(god_name, card_index)
	var total_exp = exp_data["capture_exp"] + exp_data["defense_exp"]
	return ExperienceHelpers.calculate_level(total_exp)

static func get_mnemosyne_card_level(card_index: int = -1) -> int:
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if not scene_tree:
		print("Warning: SceneTree not available, returning level 1")
		return 1
		
	var tracker = scene_tree.get_node_or_null("/root/MnemosyneProgressTrackerAutoload")
	if tracker:
		# If card_index is provided, return upgrade count for that specific card
		# Otherwise return overall progression level (for backward compatibility)
		if card_index >= 0:
			return tracker.get_card_upgrade_count(card_index) + 1  # +1 because level starts at 1
		else:
			return tracker.get_current_level() + 1  # +1 because level starts at 1
	return 1
