# res://Resources/Abilities/sanctuary_ability.gd
class_name SanctuaryAbility
extends CardAbility

func _init():
	ability_name = "Sanctuary"
	description = "On play, select a slot, playing a friendly card there will grant it cheat death."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SanctuaryAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SanctuaryAbility: Missing required context data")
		return false
	
	# Get the owner of the sanctuary card
	var sanctuary_owner = game_manager.get_owner_at_position(grid_position)
	
	print("SanctuaryAbility activated! ", placed_card.card_name, " can now sanctuary a target slot")
	
	# Enable sanctuary mode in the game manager
	game_manager.start_sanctuary_mode(grid_position, sanctuary_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
