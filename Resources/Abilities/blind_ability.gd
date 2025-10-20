# res://Resources/Abilities/blind_ability.gd
class_name BlindAbility
extends CardAbility

func _init():
	ability_name = "Blind"
	description = "This card attacks friends and foes alike"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("BlindAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("BlindAbility: Missing required context data")
		return false
	
	print("BlindAbility activated! ", placed_card.card_name, " will attack both friendly and enemy cards")
	
	# Mark this card as confused (will attack both friendlies and enemies)
	# This reuses the same metadata flag that Disarray uses
	placed_card.set_meta("disarray_confused", true)
	
	print("Blind effect applied - card will attack all adjacent cards regardless of ownership")
	print("DEBUG BLIND: Card metadata set - has_meta: ", placed_card.has_meta("disarray_confused"), " value: ", placed_card.get_meta("disarray_confused"))
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
