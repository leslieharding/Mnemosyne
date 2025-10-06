# res://Resources/Abilities/volley_ability.gd
class_name VolleyAbility
extends CardAbility

func _init():
	ability_name = "Volley"
	description = "At the start of your next 3 turns, this card fires an arrow in the selected direction."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("VolleyAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("VolleyAbility: Missing required context data")
		return false
	
	# Get the owner of the volley card
	var volley_owner = game_manager.get_owner_at_position(grid_position)
	
	print("VolleyAbility activated! ", placed_card.card_name, " will show direction modal AFTER combat")
	
	# FIXED: Use call_deferred to show modal AFTER the current placement/combat completes
	game_manager.call_deferred("show_volley_direction_modal", grid_position, volley_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
