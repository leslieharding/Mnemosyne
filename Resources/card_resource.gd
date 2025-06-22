# res://Resources/card_resource.gd
class_name CardResource
extends Resource

@export var card_name: String
@export var card_texture: Texture2D
@export var values: Array[int] = [1, 1, 1, 1]  # [Up, Right, Down, Left]
@export_multiline var description: String = ""
@export var abilities: Array[CardAbility] = []

# Get abilities available at a specific level
func get_available_abilities(level: int) -> Array[CardAbility]:
	var available: Array[CardAbility] = []
	for ability in abilities:
		if ability.unlock_level <= level:
			available.append(ability)
	return available

# Check if card has any abilities of a specific trigger type
func has_ability_type(trigger_type: CardAbility.TriggerType, level: int = 999) -> bool:
	var available_abilities = get_available_abilities(level)
	for ability in available_abilities:
		if ability.trigger_condition == trigger_type:
			return true
	return false

# Execute all abilities of a specific trigger type
func execute_abilities(trigger_type: CardAbility.TriggerType, context: Dictionary, level: int = 999) -> Array[bool]:
	var results: Array[bool] = []
	var available_abilities = get_available_abilities(level)
	
	for ability in available_abilities:
		if ability.trigger_condition == trigger_type:
			var success = ability.execute(context)
			results.append(success)
			if success:
				print("Executed ability: ", ability.ability_name)
	
	return results
