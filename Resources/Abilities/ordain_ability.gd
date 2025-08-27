# res://Resources/Abilities/ordain_ability.gd
class_name OrdainAbility
extends CardAbility

func _init():
	ability_name = "Ordain"
	description = "On play, choose an empty slot. If you play a card in that slot next turn it gains +2 to all stats."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("OrdainAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("OrdainAbility: Missing required context data")
		return false
	
	# Get the owner of the ordaining card
	var ordainer_owner = game_manager.get_owner_at_position(grid_position)
	
	print("OrdainAbility activated! ", placed_card.card_name, " can now ordain a target slot")
	
	# Enable ordain mode in the game manager
	game_manager.start_ordain_mode(grid_position, ordainer_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
