# res://Resources/card_resource.gd
class_name CardResource
extends Resource

# Inner class for level data (no class_name declaration)
class LevelData extends Resource:
	@export var level: int = 1
	@export var values: Array[int] = [1, 1, 1, 1]  # [Up, Right, Down, Left]
	@export var abilities: Array[CardAbility] = []
	@export_multiline var description: String = ""  # Level-specific description if needed

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

# ... rest of existing methods stay the same ...
