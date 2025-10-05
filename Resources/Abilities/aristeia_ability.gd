# res://Resources/Abilities/aristeia_ability.gd
class_name AristeiaAbility
extends CardAbility

func _init():
	ability_name = "Aristeia"
	description = "If you capture atleast one enemy, you can move and fight again"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	var captures_made = context.get("captures_made", 0)
	
	if not placed_card or grid_position == -1 or not game_manager:
		return false
	
	# Only trigger if at least one capture was made
	if captures_made <= 0:
		print("AristeiaAbility: No captures made - ability does not trigger")
		return false
	
	# Check if card still belongs to original owner (toxic check)
	var current_owner = game_manager.get_owner_at_position(grid_position)
	var placing_owner = context.get("placing_owner", current_owner)
	
	if current_owner != placing_owner:
		print("AristeiaAbility: Ownership changed - aristeia cancelled")
		return false
	
	print("AristeiaAbility activated! ", placed_card.card_name, " can move again!")
	game_manager.start_aristeia_mode(grid_position, current_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
