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
	
	# Check if card has level_data - if so, use that (manual progression)
	if uses_level_progression and not level_data.is_empty():
		return get_level_data(level).values.duplicate()
	
	# Check if this card has any of the ramping abilities (Grow/Cultivate/Enrich)
	# If so, apply ability-specific stat scaling
	var scaled_values = values.duplicate()
	var has_scaling_ability = false
	
	# Check each ability to see if it provides stat scaling
	for ability in abilities:
		if ability is GrowAbility:
			var bonus = GrowAbility.get_stat_bonus_for_level(level)
			for i in range(scaled_values.size()):
				scaled_values[i] += bonus
			has_scaling_ability = true
			print("Applied Grow stat scaling: +", bonus, " at level ", level)
			break  # Only apply one scaling type
		elif ability is CultivateAbility:
			var bonus = CultivateAbility.get_stat_bonus_for_level(level)
			for i in range(scaled_values.size()):
				scaled_values[i] += bonus
			has_scaling_ability = true
			print("Applied Cultivate stat scaling: +", bonus, " at level ", level)
			break
		elif ability is EnrichAbility:
			var bonus = EnrichAbility.get_stat_bonus_for_level(level)
			for i in range(scaled_values.size()):
				scaled_values[i] += bonus
			has_scaling_ability = true
			print("Applied Enrich stat scaling: +", bonus, " at level ", level)
			break
	
	return scaled_values

# Execute abilities of a certain trigger type
func execute_abilities(trigger_type: CardAbility.TriggerType, context: Dictionary, level: int):
	var abilities_to_execute = get_effective_abilities(level)
	
	for ability in abilities_to_execute:
		if ability.trigger_condition == trigger_type:
			print("Executing ability: ", ability.ability_name)
			ability.execute(context)

# Get available abilities for a card at a given level (filters by unlock_level)
func get_available_abilities(level: int) -> Array[CardAbility]:
	return get_effective_abilities(level)

func get_effective_abilities(level: int) -> Array[CardAbility]:
	# Check if this is a Mnemosyne card and use tracker abilities
	if should_use_mnemosyne_tracker():
		return get_mnemosyne_abilities()
	
	var level_abilities = get_level_data(level).abilities
	
	# Filter abilities based on their unlock level
	var unlocked_abilities: Array[CardAbility] = []
	for ability in level_abilities:
		if ability.unlock_level <= level:
			unlocked_abilities.append(ability)
	
	return unlocked_abilities

func get_effective_description(level: int) -> String:
	return get_level_data(level).description

func has_ability_type(trigger_type: CardAbility.TriggerType, level: int) -> bool:
	var abilities_at_level = get_effective_abilities(level)
	for ability in abilities_at_level:
		if ability.trigger_condition == trigger_type:
			return true
	return false

func get_abilities_for_level(level: int) -> Array[CardAbility]:
	return get_effective_abilities(level)

# === MNEMOSYNE CARD HANDLING ===

const MNEMOSYNE_GOD_NAME = "Mnemosyne"

func should_use_mnemosyne_tracker() -> bool:
	# Check if this card is a Mnemosyne card
	# We use metadata to identify Mnemosyne cards
	return has_meta("is_mnemosyne_card") and get_meta("is_mnemosyne_card")

func get_mnemosyne_values() -> Array[int]:
	if not has_meta("mnemosyne_card_index"):
		print("Warning: Mnemosyne card missing card index metadata")
		return values.duplicate()
	
	var card_index = get_meta("mnemosyne_card_index")
	
	# Get values from MnemosyneProgressTracker
	# Note: Can't use get_node_or_null here since CardResource is not a Node
	var tracker = Engine.get_singleton("MnemosyneProgressTrackerAutoload")
	if not tracker:
		print("Warning: MnemosyneProgressTracker not found")
		return values.duplicate()
	
	return tracker.get_card_values(card_index)

func get_mnemosyne_abilities() -> Array[CardAbility]:
	if not has_meta("mnemosyne_card_index"):
		print("Warning: Mnemosyne card missing card index metadata")
		return abilities.duplicate()
	
	var card_index = get_meta("mnemosyne_card_index")
	
	# Get abilities from MnemosyneProgressTracker
	# Note: Can't use get_node_or_null here since CardResource is not a Node
	var tracker = Engine.get_singleton("MnemosyneProgressTrackerAutoload")
	if not tracker:
		print("Warning: MnemosyneProgressTracker not found")
		return abilities.duplicate()
	
	return tracker.get_unlocked_abilities_for_card(card_index)
