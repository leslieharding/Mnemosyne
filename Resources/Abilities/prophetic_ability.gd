# res://Resources/Abilities/prophetic_ability.gd
class_name PropheticAbility
extends CardAbility

func _init():
	ability_name = "Prophetic"
	description = "On play glimpse your opponents hand"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var game_manager = context.get("game_manager")
	if not game_manager:
		print("PropheticAbility: Missing game manager in context")
		return false
	
	print("PropheticAbility activated! Opening opponent hand viewer...")
	
	# Call the game manager to show the opponent's hand modal
	game_manager.show_opponent_hand_modal()
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
