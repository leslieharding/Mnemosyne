# res://Scripts/RunSaveManager.gd
extends Node
class_name RunSaveManager

const SAVE_PATH = "user://run_save.dat"

func _ready():
	pass

# --- PUBLIC API ---

func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_run(god: String, deck_index: int, map_data: MapData) -> bool:
	var save_data = {
		"god": god,
		"deck_index": deck_index,
		"map_data": _serialize_map_data(map_data),
		"run_experience": _get_experience_data(),
		"enrichment_data": _get_enrichment_data(),
		"stat_growth_data": _get_stat_growth_data(),
		"active_mood": GodMoodManagerAutoload.get_active_mood(),
		"optional_battle_data": _get_optional_battle_data(),
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		print("RunSaveManager: Failed to open save file for writing")
		return false
	
	file.store_var(save_data)
	file.close()
	print("RunSaveManager: Run saved successfully for ", god)
	return true

func load_run() -> Dictionary:
	if not has_saved_run():
		print("RunSaveManager: No saved run found")
		return {}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("RunSaveManager: Failed to open save file for reading")
		return {}
	
	var save_data = file.get_var()
	file.close()
	return save_data

func clear_saved_run():
	if has_saved_run():
		DirAccess.remove_absolute(SAVE_PATH)
		print("RunSaveManager: Saved run cleared")

func restore_trackers_from_save(save_data: Dictionary):
	_restore_experience_data(save_data.get("run_experience", {}))
	_restore_enrichment_data(save_data.get("enrichment_data", {}))
	_restore_stat_growth_data(save_data.get("stat_growth_data", {}))
	_restore_mood_data(save_data)
	_restore_optional_battle_data(save_data.get("optional_battle_data", {}))

func reconstruct_map_data(save_data: Dictionary) -> MapData:
	return _deserialize_map_data(save_data.get("map_data", {}))

# --- SERIALIZATION ---

func _serialize_map_data(map_data: MapData) -> Dictionary:
	var nodes_array = []
	for node in map_data.nodes:
		nodes_array.append({
			"node_id": node.node_id,
			"node_type": node.node_type,
			"position_x": node.position.x,
			"position_y": node.position.y,
			"connections": node.connections.duplicate(),
			"is_completed": node.is_completed,
			"is_available": node.is_available,
			"enemy_name": node.enemy_name,
			"enemy_difficulty": node.enemy_difficulty,
			"display_name": node.display_name,
			"description": node.description,
		})
	
	return {
		"nodes": nodes_array,
		"completed_nodes": map_data.completed_nodes.duplicate(),
		"current_layer": map_data.current_layer,
		"total_layers": map_data.total_layers,
		"layer_node_counts": map_data.layer_node_counts.duplicate(),
	}

func _deserialize_map_data(data: Dictionary) -> MapData:
	var map_data = MapData.new()
	map_data.current_layer = data.get("current_layer", 0)
	map_data.total_layers = data.get("total_layers", 4)
	
	var layer_counts = data.get("layer_node_counts", [])
	map_data.layer_node_counts.clear()
	for count in layer_counts:
		map_data.layer_node_counts.append(count)
	
	var completed = data.get("completed_nodes", [])
	map_data.completed_nodes.clear()
	for node_id in completed:
		map_data.completed_nodes.append(node_id)
	
	for node_data in data.get("nodes", []):
		var map_node = MapNode.new()
		map_node.node_id = node_data["node_id"]
		map_node.node_type = node_data["node_type"]
		map_node.position = Vector2(node_data["position_x"], node_data["position_y"])
		map_node.is_completed = node_data["is_completed"]
		map_node.is_available = node_data["is_available"]
		map_node.enemy_name = node_data["enemy_name"]
		map_node.enemy_difficulty = node_data["enemy_difficulty"]
		map_node.display_name = node_data["display_name"]
		map_node.description = node_data["description"]
		map_node.connections.clear()
		for conn in node_data["connections"]:
			map_node.connections.append(conn)
		map_data.nodes.append(map_node)
	
	return map_data

# --- TRACKER HELPERS ---

func _get_experience_data() -> Dictionary:
	if has_node("/root/RunExperienceTrackerAutoload"):
		return get_node("/root/RunExperienceTrackerAutoload").get_all_experience().duplicate(true)
	return {}

func _get_enrichment_data() -> Dictionary:
	if has_node("/root/RunEnrichmentTrackerAutoload"):
		return get_node("/root/RunEnrichmentTrackerAutoload").get_all_enrichment().duplicate(true)
	return {}

func _get_stat_growth_data() -> Dictionary:
	if has_node("/root/RunStatGrowthTrackerAutoload"):
		return get_node("/root/RunStatGrowthTrackerAutoload").get_cards_with_growth().duplicate(true)
	return {}

func _restore_experience_data(exp_data: Dictionary):
	if not has_node("/root/RunExperienceTrackerAutoload"):
		return
	var tracker = get_node("/root/RunExperienceTrackerAutoload")
	tracker.run_experience = exp_data.duplicate(true)
	# Rebuild deck indices from the keys
	tracker.current_deck_indices.clear()
	for key in exp_data.keys():
		tracker.current_deck_indices.append(int(key))
	print("RunSaveManager: Experience tracker restored with ", exp_data.size(), " cards")

func _restore_enrichment_data(enrich_data: Dictionary):
	if not has_node("/root/RunEnrichmentTrackerAutoload"):
		return
	var tracker = get_node("/root/RunEnrichmentTrackerAutoload")
	tracker.run_slot_enrichment = enrich_data.duplicate(true)
	tracker.enriched_slots.clear()
	for slot in enrich_data.keys():
		if enrich_data[slot] != 0:
			tracker.enriched_slots.append(int(slot))
	print("RunSaveManager: Enrichment tracker restored")

func _restore_stat_growth_data(growth_data: Dictionary):
	if not has_node("/root/RunStatGrowthTrackerAutoload"):
		return
	var tracker = get_node("/root/RunStatGrowthTrackerAutoload")
	tracker.run_stat_growth = growth_data.duplicate(true)
	tracker.current_deck_indices.clear()
	for key in growth_data.keys():
		tracker.current_deck_indices.append(int(key))
	print("RunSaveManager: Stat growth tracker restored")


func _restore_mood_data(save_data: Dictionary):
	var mood = save_data.get("active_mood", "")
	var god = save_data.get("god", "")
	if mood != "":
		GodMoodManagerAutoload.set_mood(god, mood)
	else:
		GodMoodManagerAutoload.clear_mood()
	print("RunSaveManager: Mood restored - ", god, " / ", mood)


func _get_optional_battle_data() -> Dictionary:
	if has_node("/root/OptionalBattleTrackerAutoload"):
		return get_node("/root/OptionalBattleTrackerAutoload").get_run_save_data()
	return {}

func _restore_optional_battle_data(data: Dictionary):
	if data.is_empty():
		print("RunSaveManager: No optional battle data to restore")
		return
	if not has_node("/root/OptionalBattleTrackerAutoload"):
		print("RunSaveManager: OptionalBattleTrackerAutoload not found")
		return
	get_node("/root/OptionalBattleTrackerAutoload").restore_from_save_data(data)
	print("RunSaveManager: Optional battle state restored")
