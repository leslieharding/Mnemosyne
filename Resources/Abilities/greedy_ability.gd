# res://Resources/Abilities/greedy_ability.gd
class_name GreedyAbility
extends CardAbility

func _init():
	ability_name = "Greedy"
	description = "If still controlled at the start of opponents turn, steals 1 stat from each adjacent friendly card"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var greedy_card = context.get("boosting_card")
	var greedy_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("GreedyAbility: Action = ", action, " for card at position ", greedy_position)
	
	if not greedy_card or greedy_position == -1 or not game_manager:
		print("GreedyAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_greedy(greedy_position, greedy_card, game_manager)
		"remove":
			return remove_greedy(greedy_position, greedy_card, game_manager)
		"turn_start":
			return process_greedy_turn(greedy_position, greedy_card, game_manager)
		_:
			print("GreedyAbility: Unknown action: ", action)
			return false

func apply_greedy(position: int, card: CardResource, game_manager) -> bool:
	print("Greedy started for ", card.card_name, " at position ", position)
	
	# Only activate greedy for opponent-owned cards
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner == game_manager.Owner.OPPONENT:
		# Mark this card as having greedy active
		card.set_meta("greedy_active", true)
		print("Greedy activated for opponent-owned card")
	else:
		# Mark greedy as inactive for player-owned cards
		card.set_meta("greedy_active", false)
		print("Greedy NOT activated for player-owned card")
	
	return true

func remove_greedy(position: int, card: CardResource, game_manager) -> bool:
	print("Greedy ended for ", card.card_name, " at position ", position)
	
	# Mark greedy as inactive
	card.set_meta("greedy_active", false)
	
	return true

func process_greedy_turn(position: int, card: CardResource, game_manager) -> bool:
	# Check if card is owned by opponent (this is the primary requirement)
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner != game_manager.Owner.OPPONENT:
		print("GreedyAbility: Card not owned by opponent - deactivating greedy")
		card.set_meta("greedy_active", false)
		return false
	
	# If owned by opponent but greedy is inactive, reactivate it (handles re-capture scenario)
	if not card.has_meta("greedy_active") or not card.get_meta("greedy_active", false):
		print("GreedyAbility: Reactivating greedy for opponent-owned card (possibly re-captured)")
		card.set_meta("greedy_active", true)
	
	print("GreedyAbility: Processing greedy turn for ", card.card_name, " at position ", position)
	
	# Find all orthogonally adjacent friendly (opponent) cards
	var friendly_targets = get_adjacent_friendly_cards(position, game_manager)
	
	if friendly_targets.is_empty():
		print("GreedyAbility: No adjacent friendly cards to steal from")
		return false
	
	# Steal 1 stat from each direction of each adjacent friendly card (directional transfer)
	var total_cards_processed = 0
	var stats_gained = [0, 0, 0, 0]  # Track what greedy card gains per direction
	
	for target_position in friendly_targets:
		var target_card = game_manager.get_card_at_position(target_position)
		if target_card:
			print("GreedyAbility: Attempting to steal from ", target_card.card_name, " at position ", target_position)
			print("Stats before stealing: ", target_card.values)
			
			# Try to steal 1 from each direction, track what was actually stolen per direction
			for i in range(target_card.values.size()):
				if target_card.values[i] > 0:
					target_card.values[i] -= 1
					stats_gained[i] += 1  # Greedy gains +1 in this direction
			
			print("Stats after stealing: ", target_card.values)
			total_cards_processed += 1
			
			# Update the visual display to show the new stats
			if game_manager.has_method("update_card_display"):
				game_manager.update_card_display(target_position, target_card)
	
	# Apply stolen stats to greedy card (directional gains)
	var total_stats_gained = stats_gained[0] + stats_gained[1] + stats_gained[2] + stats_gained[3]
	if total_stats_gained > 0:
		print("GreedyAbility: Adding stolen stats to greedy card")
		print("Stats before gaining: ", card.values)
		print("Stats to gain per direction: ", stats_gained)
		
		# Add the stolen stats to corresponding directions
		for i in range(card.values.size()):
			card.values[i] += stats_gained[i]
		
		print("Stats after gaining: ", card.values)
		
		# Update the visual display for the greedy card
		if game_manager.has_method("update_card_display"):
			game_manager.update_card_display(position, card)
	
	if total_stats_gained > 0:
		print("GreedyAbility activated! ", card.card_name, " gained ", total_stats_gained, " total stat points from ", total_cards_processed, " adjacent friendly cards")
		return true
	else:
		print("GreedyAbility had no effect - no stat points available to steal")
		return false

func get_adjacent_friendly_cards(grid_position: int, game_manager) -> Array[int]:
	var adjacent_friendly_cards: Array[int] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Check all 4 orthogonal directions
	var directions = [
		{"dx": 0, "dy": -1, "name": "North"},   # North
		{"dx": 1, "dy": 0, "name": "East"},    # East
		{"dx": 0, "dy": 1, "name": "South"},   # South
		{"dx": -1, "dy": 0, "name": "West"}    # West
	]
	
	for dir_info in directions:
		var adj_x = grid_x + dir_info.dx
		var adj_y = grid_y + dir_info.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				var adjacent_owner = game_manager.get_owner_at_position(adj_index)
				
				# Only target friendly (opponent-owned) cards
				if adjacent_owner == game_manager.Owner.OPPONENT:
					adjacent_friendly_cards.append(adj_index)
					print("GreedyAbility: Found friendly card at position ", adj_index, " (", dir_info.name, ")")
	
	return adjacent_friendly_cards

func can_execute(context: Dictionary) -> bool:
	return true
