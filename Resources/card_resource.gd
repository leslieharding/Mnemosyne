# res://Resources/card_resource.gd
class_name CardResource
extends Resource

# Main CardResource fields
@export var card_name: String
@export var card_texture: Texture2D

# Legacy fields (for backward compatibility)
@export var values: Array[int] = [1, 1, 1, 1]  # [Up, Right, Down, Left]
@export_multiline var description: String = ""
@export var abilities: Array[CardAbility] = []

# NEW: Level progression data
@export var level_data: Array[LevelData] = []
@export var uses_level_progression: bool = false

# Get data for specific level
func get_level_data(level: int) -> LevelData:
	if not uses_level_progression or level_data.is_empty():
		# Fallback to legacy data
		var fallback = LevelData.new()
		fallback.level = level
		fallback.values = values.duplicate()
		fallback.abilities = abilities.duplicate()
		fallback.description = description
		return fallback
	
	# Find exact level match
	for data in level_data:
		if data.level == level:
			return data
	
	# If no exact match, return highest available level <= requested level
	var best_match: LevelData = null
	for data in level_data:
		if data.level <= level:
			if not best_match or data.level > best_match.level:
				best_match = data
	
	return best_match if best_match else level_data[0]

func get_effective_values(level: int) -> Array[int]:
	# Check if this is a Mnemosyne card and use tracker values instead
	if should_use_mnemosyne_tracker():
		return get_mnemosyne_values()
	
	return get_level_data(level).values.duplicate()

func get_effective_abilities(level: int) -> Array[CardAbility]:
	return get_level_data(level).abilities.duplicate()

func get_effective_description(level: int) -> String:
	var level_desc = get_level_data(level).description
	return level_desc if level_desc != "" else description

# Check if card has abilities of a specific type at given level
func has_ability_type(trigger_type: CardAbility.TriggerType, level: int = 0) -> bool:
	var abilities = get_effective_abilities(level)
	for ability in abilities:
		if ability.trigger_condition == trigger_type:
			return true
	return false

# Get all available abilities for a specific level
func get_available_abilities(level: int = 0) -> Array[CardAbility]:
	return get_effective_abilities(level)

# Execute abilities of a specific type
func execute_abilities(trigger_type: CardAbility.TriggerType, context: Dictionary, level: int = 0):
	var abilities = get_effective_abilities(level)
	for ability in abilities:
		if ability.trigger_condition == trigger_type:
			print("Executing ability: ", ability.ability_name, " (", ability.description, ")")
			ability.execute(context)


func should_use_mnemosyne_tracker() -> bool:
	# Check if we're dealing with a Mnemosyne card by looking for the tracker
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if not scene_tree:
		return false
	
	var tracker = scene_tree.get_node_or_null("/root/MnemosyneProgressTracker")
	if not tracker:
		return false
	
	# Check if this is a Mnemosyne card (based on card names)
	var mnemosyne_cards = ["Clio", "Euterpe", "Terpsichore", "Thalia", "Melpomene"]
	return card_name in mnemosyne_cards

# NEW: Get values from Mnemosyne tracker
func get_mnemosyne_values() -> Array[int]:
	var scene_tree = Engine.get_singleton("SceneTree") as SceneTree
	if not scene_tree:
		return [1, 1, 1, 1]
	
	var tracker = scene_tree.get_node_or_null("/root/MnemosyneProgressTracker")
	if not tracker:
		return [1, 1, 1, 1]
	
	# Map card names to indices
	var card_index = -1
	match card_name:
		"Clio": card_index = 0
		"Euterpe": card_index = 1
		"Terpsichore": card_index = 2
		"Thalia": card_index = 3
		"Melpomene": card_index = 4
		_: return [1, 1, 1, 1]
	
	return tracker.get_card_values(card_index)
