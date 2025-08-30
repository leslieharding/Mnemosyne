# res://Resources/Abilities/dancer_ability.gd
class_name DancerAbility
extends CardAbility

func _init():
	ability_name = "Dancer"
	description = "After first playing this, dance to another slot."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("DancerAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("DancerAbility: Missing required context data")
		return false
	
	# Check if card still belongs to original owner (toxic capture check)
	var current_owner = game_manager.get_owner_at_position(grid_position)
	var placing_owner = context.get("placing_owner", current_owner)
	
	if current_owner != placing_owner:
		print("DancerAbility: Card ownership changed due to toxic capture - dance cancelled")
		return false
	
	print("DancerAbility activated! ", placed_card.card_name, " can now dance to another slot")
	
	# Enable dance mode in the game manager
	game_manager.start_dance_mode(grid_position, current_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
