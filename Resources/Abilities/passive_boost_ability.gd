# res://Resources/Abilities/passive_boost_ability.gd
class_name PassiveBoostAbility
extends CardAbility

@export var boost_amount: int = 1

func _init():
	ability_name = "Divine Inspiration"
	description = "While on the board, all other friendly cards gain +1 to all stats"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var boosting_card = context.get("boosting_card")
	var boosting_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("PassiveBoostAbility: Action = ", action, " for card at position ", boosting_position)
	
	if not boosting_card or boosting_position == -1 or not game_manager:
		print("PassiveBoostAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_boost(boosting_position, game_manager)
		"remove":
			return remove_boost(boosting_position, game_manager)
		_:
			print("PassiveBoostAbility: Unknown action: ", action)
			return false

func apply_boost(boosting_position: int, game_manager) -> bool:
	print("PassiveBoostAbility: Applying boost from position ", boosting_position)
	
	var boosting_owner = game_manager.get_owner_at_position(boosting_position)
	var boosted_count = 0
	
	# Boost all other friendly cards on the board
	for i in range(game_manager.grid_ownership.size()):
		if i == boosting_position:  # Skip the boosting card itself
			continue
			
		var card_owner = game_manager.get_owner_at_position(i)
		if card_owner == boosting_owner and game_manager.grid_occupied[i]:
			var card = game_manager.get_card_at_position(i)
			if card:
				# Apply boost to all directions
				for direction in range(4):
					card.values[direction] += boost_amount
				
				print("  Boosted ", card.card_name, " at position ", i, " by +", boost_amount)
				boosted_count += 1
				
				# Update visual display
				game_manager.update_card_display(i, card)
	
	if boosted_count > 0:
		print(ability_name, " activated! Boosted ", boosted_count, " friendly cards by +", boost_amount)
	else:
		print(ability_name, " had no effect - no other friendly cards on board")
	
	return boosted_count > 0

func remove_boost(boosting_position: int, game_manager) -> bool:
	print("PassiveBoostAbility: Removing boost from position ", boosting_position)
	
	var boosting_owner = game_manager.get_owner_at_position(boosting_position)
	var deboosted_count = 0
	
	# Remove boost from all other friendly cards on the board
	for i in range(game_manager.grid_ownership.size()):
		if i == boosting_position:  # Skip the boosting card itself
			continue
			
		var card_owner = game_manager.get_owner_at_position(i)
		if card_owner == boosting_owner and game_manager.grid_occupied[i]:
			var card = game_manager.get_card_at_position(i)
			if card:
				# Remove boost from all directions
				for direction in range(4):
					card.values[direction] -= boost_amount
					# Ensure values don't go below 1
					card.values[direction] = max(1, card.values[direction])
				
				print("  Removed boost from ", card.card_name, " at position ", i, " by -", boost_amount)
				deboosted_count += 1
				
				# Update visual display
				game_manager.update_card_display(i, card)
	
	if deboosted_count > 0:
		print(ability_name, " deactivated! Removed boost from ", deboosted_count, " friendly cards")
	
	return deboosted_count > 0

func can_execute(context: Dictionary) -> bool:
	return true
