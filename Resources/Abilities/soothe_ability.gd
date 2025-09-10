# res://Resources/Abilities/soothe_ability.gd
class_name SootheAbility
extends CardAbility

func _init():
	ability_name = "Soothe"
	description = "Reduces the strength of the next card played by your opponent by 1."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SootheAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SootheAbility: Missing required context data")
		return false
	
	print("SootheAbility activated! ", placed_card.card_name, " will soothe the opponent's next card")
	
	# Set the soothe flag in the game manager
	game_manager.set_soothe_active(true)
	
	print("Soothe effect is now active - next opponent card will have stats reduced by 1")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
