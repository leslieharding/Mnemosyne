# res://Resources/Abilities/trojan_horse_reversal_ability.gd
class_name TrojanHorseReversalAbility
extends CardAbility

func _init():
	ability_name = "Its just a horse"
	description = "When this horse would be captured, capture the attacking card instead, then remove the horse."
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var defending_card = context.get("defending_card")
	var attacking_card = context.get("attacking_card")
	var defending_position = context.get("defending_position", -1)
	var attacking_position = context.get("attacking_position", -1)
	var game_manager = context.get("game_manager")
	var attacking_owner = context.get("attacking_owner")
	
	# Add null checks to prevent crashes
	if not defending_card:
		print("TrojanHorseReversalAbility: defending_card is null!")
		return false
	if not attacking_card:
		print("TrojanHorseReversalAbility: attacking_card is null!")
		return false
	
	print("TrojanHorseReversalAbility: Trap triggered!")
	print("  Attacking card: ", attacking_card.card_name, " at position ", attacking_position)
	print("  Defending horse: ", defending_card.card_name, " at position ", defending_position)
	
	if attacking_position == -1 or defending_position == -1 or not game_manager:
		print("TrojanHorseReversalAbility: Missing required context data")
		return false
	
	# Reverse the capture: instead of horse being captured, capture the attacking card
	print("TrojanHorseReversalAbility: Reversing capture - attacking card will be captured instead!")
	
	# Change ownership of the attacking card to the player (horse owner)
	game_manager.set_card_ownership(attacking_position, game_manager.Owner.PLAYER)
	
	# Execute ON_CAPTURE abilities on the captured attacking card
	var attacking_card_collection_index = game_manager.get_card_collection_index(attacking_position)
	var attacking_card_level = 1  # Default level
	if attacking_card_collection_index != -1:
		attacking_card_level = game_manager.get_card_level(attacking_card_collection_index)
	
	if attacking_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, attacking_card_level):
		print("TrojanHorseReversalAbility: Executing ON_CAPTURE abilities for captured attacking card: ", attacking_card.card_name)
		
		var capture_context = {
			"capturing_card": defending_card,  # The horse "captures" the attacker
			"capturing_position": defending_position,
			"captured_card": attacking_card,
			"captured_position": attacking_position,
			"game_manager": game_manager,
			"direction": "trojan_reversal",
			"card_level": attacking_card_level
		}
		
		attacking_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, attacking_card_level)
	
	# Remove the trojan horse from the board after the reversal
	print("TrojanHorseReversalAbility: Removing trojan horse from board")
	game_manager.remove_trojan_horse(defending_position)
	
	# Update board visuals to reflect the changes
	game_manager.update_board_visuals()
	
	print("TrojanHorseReversalAbility: Trap executed successfully! The ", attacking_card.card_name, " fell for the trojan horse!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	# Remove the would_be_captured check since we'll handle this in the battle manager
	return true
