# res://Resources/Abilities/second_chance_ability.gd
class_name SecondChanceAbility
extends CardAbility

func _init():
	ability_name = "Second Chance"
	description = "The first time this battle this card is captured return it to your hand"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	# This ability is now handled entirely by try_second_chance_rescue in card_battle_manager
	# We don't need to do anything here because the check happens BEFORE capture
	# This function only exists to satisfy the ability system
	print("SecondChanceAbility.execute() called - but rescue already happened")
	return true

func can_execute(context: Dictionary) -> bool:
	var captured_card = context.get("captured_card")
	if not captured_card:
		return false
	
	if not is_instance_valid(captured_card):
		return false
	
	# Can only execute if not already used
	return not (captured_card.has_meta("second_chance_used") and captured_card.get_meta("second_chance_used"))
