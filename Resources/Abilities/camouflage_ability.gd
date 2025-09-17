# res://Resources/Abilities/camouflage_ability.gd
class_name CamouflageAbility
extends CardAbility

func _init():
	ability_name = "Camouflage"
	description = "On play this card is hidden for one turn, if the opponent tries to play a card in the same slot it is captured"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("CamouflageAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("CamouflageAbility: Missing required context data")
		return false
	
	# Get the owner of the camouflaging card
	var camouflage_owner = game_manager.get_owner_at_position(grid_position)
	
	print("CamouflageAbility activated! ", placed_card.card_name, " is now camouflaged at position ", grid_position)
	
	# Enable camouflage mode in the game manager
	game_manager.start_camouflage_mode(grid_position, camouflage_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
