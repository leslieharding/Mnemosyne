# res://Resources/Abilities/core_ability.gd
class_name CoreAbility
extends CardAbility

func _init():
	ability_name = "Core"
	description = "If played in the central slot it gains +2 stats."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("CoreAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("CoreAbility: Missing required context data")
		return false
	
	# Check if the card was placed in the central slot (position 4 in 3x3 grid)
	if grid_position != 4:
		print("CoreAbility: Card not placed in central slot (position 4), no bonus applied")
		return false
	
	print("CoreAbility: Card placed in central slot - applying +2 to all stats")
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Apply +2 boost to all directional stats
	placed_card.values[0] += 2  # North
	placed_card.values[1] += 2  # East
	placed_card.values[2] += 2  # South
	placed_card.values[3] += 2  # West
	
	print("CoreAbility: Stats boosted from ", original_values, " to ", placed_card.values)
	print(ability_name, " activated! ", placed_card.card_name, " gained +2 to all stats for being in the central position!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
