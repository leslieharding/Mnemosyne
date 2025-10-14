# res://Resources/Abilities/silence_ability.gd
class_name SilenceAbility
extends CardAbility

func _init():
	ability_name = "Silence"
	description = "The next card played has its abilities removed."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SilenceAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SilenceAbility: Missing required context data")
		return false
	
	print("SilenceAbility activated! ", placed_card.card_name, " will silence the next card played")
	
	# Set the silence flag in the game manager
	game_manager.set_silence_active(true)
	
	print("Silence effect is now active - next card will have all abilities removed")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
