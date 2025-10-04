# res://Resources/Abilities/second_chance_ability.gd
class_name SecondChanceAbility
extends CardAbility

func _init():
	ability_name = "Second Chance"
	description = "The first time this battle this card is captured return it to your hand"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var game_manager = context.get("game_manager")
	
	# Mark as used
	captured_card.set_meta("second_chance_used", true)
	
	# Just set the flag - don't touch the board
	game_manager.set_meta("second_chance_prevented_" + str(captured_position), true)
	
	print("Second Chance activated! Card will return to hand.")
	
	return true

func can_execute(context: Dictionary) -> bool:
	var captured_card = context.get("captured_card")
	if not captured_card:
		return false
	
	if not is_instance_valid(captured_card):
		return false
	
	# Can only execute if not already used
	return not (captured_card.has_meta("second_chance_used") and captured_card.get_meta("second_chance_used"))
