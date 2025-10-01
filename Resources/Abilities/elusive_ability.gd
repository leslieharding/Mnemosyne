# res://Resources/Abilities/elusive_ability.gd
class_name ElusiveAbility
extends CardAbility

func _init():
	ability_name = "Elusive"
	description = "This card evades capture (it would take coordination to catch this)"
	trigger_condition = TriggerType.ON_DEFEND

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get context information
	var defending_card = context.get("defending_card")
	var defending_position = context.get("defending_position", -1)
	var attacking_card = context.get("attacking_card")
	var game_manager = context.get("game_manager")
	
	print("ElusiveAbility: Starting execution for ", defending_card.card_name if defending_card else "unknown card", " at position ", defending_position)
	
	# Safety checks
	if not defending_card or defending_position == -1 or not game_manager:
		print("ElusiveAbility: Missing required context data")
		return false
	
	# Check if coordination power is active (Artemis can coordinate to catch the Hind)
	if game_manager.is_coordination_active:
		print("ElusiveAbility: Coordination is active - Hind can be captured!")
		return false
	
	# Set flag in game manager to prevent capture for this specific position
	game_manager.set_meta("cheat_death_prevented_" + str(defending_position), true)
	
	print(ability_name, " activated! ", defending_card.card_name, " evaded capture!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	var defending_card = context.get("defending_card")
	if not defending_card:
		return false
	
	# Unlike cheat death, this can always execute (infinite charges)
	return true
