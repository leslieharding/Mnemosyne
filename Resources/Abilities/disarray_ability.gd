# res://Resources/Abilities/disarray_ability.gd
class_name DisarrayAbility
extends CardAbility

func _init():
	ability_name = "Disarray"
	description = "Your opponents next card also attacks friendly cards as well as enemies"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("DisarrayAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("DisarrayAbility: Missing required context data")
		return false
	
	print("DisarrayAbility activated! ", placed_card.card_name, " will cause the opponent's next card to attack both friendlies and enemies")
	
	# Set the disarray flag in the game manager
	game_manager.set_disarray_active(true)
	
	print("Disarray effect is now active - next opponent card will attack both friendly and enemy cards")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
