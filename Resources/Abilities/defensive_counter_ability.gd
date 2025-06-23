# res://Resources/Abilities/defensive_counter_ability.gd
class_name DefensiveCounterAbility
extends CardAbility

func _init():
	trigger_condition = TriggerType.ON_DEFEND

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the defending card and attacker information
	var defending_card = context.get("defending_card")
	var defending_position = context.get("defending_position", -1)
	var attacking_card = context.get("attacking_card")
	var attacking_position = context.get("attacking_position", -1)
	var game_manager = context.get("game_manager")
	var direction = context.get("direction", -1)  # Direction of the attack
	
	print("DefensiveCounterAbility: Starting execution for ", defending_card.card_name, " at position ", defending_position)
	
	if not defending_card or defending_position == -1 or not attacking_card or attacking_position == -1 or not game_manager:
		print("DefensiveCounterAbility: Missing required context data")
		return false
	
	# The defense was successful if we're here, so capture the attacking card
	print("DefensiveCounterAbility: Successful defense! Capturing attacking card at position ", attacking_position)
	
	# Change ownership of the attacking card to the defending player
	var defending_owner = game_manager.get_owner_at_position(defending_position)
	game_manager.set_card_ownership(attacking_position, defending_owner)
	
	print(ability_name, " activated! ", defending_card.card_name, " captured the attacking ", attacking_card.card_name, "!")
	
	# Award bonus experience for successful counter-capture
	if defending_owner == game_manager.Owner.PLAYER:
		var defending_card_index = game_manager.get_card_collection_index(defending_position)
		if defending_card_index != -1:
			# Use the game_manager to access the experience tracker
			if game_manager.has_node("/root/RunExperienceTrackerAutoload"):
				game_manager.get_node("/root/RunExperienceTrackerAutoload").add_capture_exp(defending_card_index, 15)  # Bonus exp for counter-capture
	
	return true

func can_execute(context: Dictionary) -> bool:
	# Basic check - could add more conditions here
	return true
