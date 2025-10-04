# res://Resources/Abilities/aristeia_ability.gd
class_name AristeiaAbility
extends CardAbility

func _init():
	ability_name = "Aristeia"
	description = "If you capture, you can move and fight again"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	var captures_made = context.get("captures_made", -1)
	
	# CRITICAL: Only execute if captures_made is explicitly provided
	# This prevents execution during the general ON_PLAY phase (before combat)
	if captures_made == -1:
		print("AristeiaAbility: Skipping - not in post-combat phase (captures_made not provided)")
		return false
	
	print("AristeiaAbility: Starting execution for card at position ", grid_position)
	print("  Captures made: ", captures_made)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("AristeiaAbility: Missing required context data")
		return false
	
	# Check if card still belongs to original owner (toxic capture check)
	var current_owner = game_manager.get_owner_at_position(grid_position)
	var placing_owner = context.get("placing_owner", current_owner)
	
	if current_owner != placing_owner:
		print("AristeiaAbility: Card ownership changed due to toxic capture - aristeia cancelled")
		return false
	
	# Check if any captures were made
	if captures_made <= 0:
		print("AristeiaAbility: No captures made - ability does not trigger")
		return false
	
	print("AristeiaAbility activated! ", placed_card.card_name, " captured ", captures_made, " enemies and can move again!")
	
	# Enable aristeia mode in the game manager
	game_manager.start_aristeia_mode(grid_position, current_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
