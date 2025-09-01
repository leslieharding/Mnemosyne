# res://Resources/Abilities/corruption_ability.gd
class_name CorruptionAbility
extends CardAbility

func _init():
	ability_name = "Corruption"
	description = "Decreases the stats of adjacent enemies by 1 at the start of each turn if still owned by the enemy"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var corrupting_card = context.get("boosting_card")
	var corrupting_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("CorruptionAbility: Action = ", action, " for card at position ", corrupting_position)
	
	if not corrupting_card or corrupting_position == -1 or not game_manager:
		print("CorruptionAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_corruption(corrupting_position, corrupting_card, game_manager)
		"remove":
			return remove_corruption(corrupting_position, corrupting_card, game_manager)
		"turn_start":
			return process_corruption_turn(corrupting_position, corrupting_card, game_manager)
		_:
			print("CorruptionAbility: Unknown action: ", action)
			return false

func apply_corruption(position: int, card: CardResource, game_manager) -> bool:
	print("Corruption started for ", card.card_name, " at position ", position)
	
	# Only activate corruption for opponent-owned cards
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner == game_manager.Owner.OPPONENT:
		# Mark this card as having corruption active
		card.set_meta("corruption_active", true)
		print("Corruption activated for opponent-owned card")
	else:
		# Mark corruption as inactive for player-owned cards
		card.set_meta("corruption_active", false)
		print("Corruption NOT activated for player-owned card")
	
	return true

func remove_corruption(position: int, card: CardResource, game_manager) -> bool:
	print("Corruption ended for ", card.card_name, " at position ", position)
	
	# Mark corruption as inactive
	card.set_meta("corruption_active", false)
	
	return true

func process_corruption_turn(position: int, card: CardResource, game_manager) -> bool:
	# Check if card is owned by opponent (this is the primary requirement)
	var card_owner = game_manager.get_owner_at_position(position)
	if card_owner != game_manager.Owner.OPPONENT:
		print("CorruptionAbility: Card not owned by opponent - deactivating corruption")
		card.set_meta("corruption_active", false)
		return false
	
	# If owned by opponent but corruption is inactive, reactivate it (handles re-capture scenario)
	if not card.has_meta("corruption_active") or not card.get_meta("corruption_active", false):
		print("CorruptionAbility: Reactivating corruption for opponent-owned card (possibly re-captured)")
		card.set_meta("corruption_active", true)
	
	print("CorruptionAbility: Processing corruption turn for ", card.card_name, " at position ", position)
	
	# Find all orthogonally adjacent enemy (player) cards
	var corrupted_targets = get_adjacent_player_cards(position, game_manager)
	
	if corrupted_targets.is_empty():
		print("CorruptionAbility: No adjacent player cards to corrupt")
		return false
	
	# Apply -1 to all stats of each adjacent player card
	var corruption_count = 0
	for target_position in corrupted_targets:
		var target_card = game_manager.get_card_at_position(target_position)
		if target_card:
			print("CorruptionAbility: Corrupting ", target_card.card_name, " at position ", target_position)
			print("Stats before corruption: ", target_card.values)
			
			# Reduce all 4 stats by 1, but don't go below 0
			for i in range(target_card.values.size()):
				target_card.values[i] = max(0, target_card.values[i] - 1)
			
			print("Stats after corruption: ", target_card.values)
			corruption_count += 1
			
			# Update the visual display to show the new stats
			if game_manager.has_method("update_card_display"):
				game_manager.update_card_display(target_position, target_card)
	
	if corruption_count > 0:
		print("CorruptionAbility activated! ", card.card_name, " corrupted ", corruption_count, " adjacent enemy cards")
		return true
	else:
		print("CorruptionAbility had no effect - no valid targets found")
		return false

func get_adjacent_player_cards(grid_position: int, game_manager) -> Array[int]:
	var adjacent_player_cards: Array[int] = []
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
				
				# Only target player-owned cards (enemies from corruption card's perspective)
				if adjacent_owner == game_manager.Owner.PLAYER:
					adjacent_player_cards.append(adj_index)
					print("CorruptionAbility: Found player card at position ", adj_index, " (", dir_info.name, ")")
	
	return adjacent_player_cards

func can_execute(context: Dictionary) -> bool:
	return true
