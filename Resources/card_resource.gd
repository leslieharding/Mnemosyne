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

# Convenience methods
func get_effective_values(level: int) -> Array[int]:
	return get_level_data(level).values.duplicate()

func get_effective_abilities(level: int) -> Array[CardAbility]:
	return get_level_data(level).abilities.duplicate()

func get_effective_description(level: int) -> String:
	var level_desc = get_level_data(level).description
	return level_desc if level_desc != "" else description

# Check if card has a specific ability type at given level
func has_ability_type(trigger_type: CardAbility.TriggerType, level: int = 1) -> bool:
	var available_abilities = get_effective_abilities(level)
	for ability in available_abilities:
		if ability.trigger_condition == trigger_type:
			return true
	return false

# Get all available abilities for a specific level
func get_available_abilities(level: int = 1) -> Array[CardAbility]:
	return get_effective_abilities(level)

# Execute abilities of a specific trigger type
func execute_abilities(trigger_type: CardAbility.TriggerType, context: Dictionary, level: int = 1):
	var available_abilities = get_effective_abilities(level)
	for ability in available_abilities:
		if ability.trigger_condition == trigger_type:
			print("Executing ability: ", ability.ability_name, " for ", card_name)
			ability.execute(context)
