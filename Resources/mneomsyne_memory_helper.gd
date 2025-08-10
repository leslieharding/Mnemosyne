# Helper script to auto-generate uniform Mnemosyne progression
class_name MnemosyneLevelHelper

static func create_uniform_progression(base_stats: Array[int], max_level: int = 10) -> Array[CardResource.LevelData]:
	var progression: Array[CardResource.LevelData] = []
	
	for level in range(1, max_level + 1):
		var level_data = CardResource.LevelData.new()
		level_data.level = level
		level_data.values = [
			base_stats[0] + (level - 1),
			base_stats[1] + (level - 1), 
			base_stats[2] + (level - 1),
			base_stats[3] + (level - 1)
		]
		level_data.abilities = []  # No abilities for basic progression
		level_data.description = ""  # Use base description
		progression.append(level_data)
	
	return progression
