# res://Resources/Abilities/cloak_of_night_ability.gd
class_name CloakOfNightAbility
extends CardAbility

func _init():
	ability_name = "Cloak of Night"
	description = "On play enemy cards are not visible for 2 turns."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var game_manager = context.get("game_manager")
	
	if not game_manager:
		print("CloakOfNightAbility: Missing game_manager in context")
		return false
	
	print("CloakOfNightAbility: Activating cloak of night effect")
	
	# Activate the cloak of night in the game manager
	game_manager.activate_cloak_of_night_ability()
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
