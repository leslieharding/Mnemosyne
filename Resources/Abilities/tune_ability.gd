# res://Resources/Abilities/tune_ability.gd
class_name TuneAbility
extends CardAbility

func _init():
	ability_name = "Tune"
	description = "Increase or decrease up to 4 stats of a card in hand."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false

	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")

	print("TuneAbility: Starting execution for card at position ", grid_position)

	if not placed_card or grid_position == -1 or not game_manager:
		print("TuneAbility: Missing required context data")
		return false

	game_manager.tune_pending = true

	return true

func can_execute(context: Dictionary) -> bool:
	return true
