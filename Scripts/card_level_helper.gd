class_name CardLevelHelper

static func get_card_current_level(card_index: int, god_name: String) -> int:
	# Special case for Mnemosyne - use consciousness level
	if god_name == "Mnemosyne":
		return get_mnemosyne_card_level()
	
	# Regular god cards - use experience-based level
	# Get the scene tree and current scene
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		print("Warning: Could not access SceneTree in CardLevelHelper")
		return 1
	
	var current_scene = scene_tree.current_scene
	if not current_scene:
		print("Warning: No current scene in CardLevelHelper")
		return 1
	
	var global_tracker = current_scene.get_node_or_null("/root/GlobalProgressTrackerAutoload")
	if not global_tracker:
		print("Warning: GlobalProgressTrackerAutoload not found in CardLevelHelper")
		return 1
	
	var exp_data = global_tracker.get_card_total_experience(god_name, card_index)
	var total_exp = exp_data["capture_exp"] + exp_data["defense_exp"]
	return ExperienceHelpers.calculate_level(total_exp)

static func get_mnemosyne_card_level() -> int:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return 1
	
	var current_scene = scene_tree.current_scene
	if not current_scene:
		return 1
		
	var memory_manager = current_scene.get_node_or_null("/root/MemoryJournalManagerAutoload")
	if memory_manager:
		var mnemosyne_data = memory_manager.get_mnemosyne_memory()
		return mnemosyne_data.get("consciousness_level", 1)
	return 1
