# res://Resources/Abilities/treachery_ability.gd
class_name TreacheryAbility
extends CardAbility

func _init():
	ability_name = "Treachery"
	description = "One captured enemy will try and attack an ally"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TreacheryAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("TreacheryAbility: Missing required context data")
		return false
	
	var treachery_owner = game_manager.get_owner_at_position(grid_position)
	
	# First, resolve normal combat to see what gets captured
	var initial_captures = perform_treachery_combat(placed_card, grid_position, treachery_owner, game_manager)
	
	if initial_captures.is_empty():
		print("TreacheryAbility: No enemies captured - ability has no effect")
		return false
	
	print("TreacheryAbility: ", initial_captures.size(), " enemies captured through normal combat")
	
	# Randomly select ONE captured card to become treacherous
	var treacherous_position = initial_captures[randi() % initial_captures.size()]
	var treacherous_card = game_manager.get_card_at_position(treacherous_position)
	
	print("TreacheryAbility: ", treacherous_card.card_name, " at position ", treacherous_position, " becomes treacherous!")
	
	# The treacherous card attacks adjacent enemies
	var treachery_captures = perform_treacherous_attacks(treacherous_card, treacherous_position, treachery_owner, game_manager)
	
	if treachery_captures > 0:
		print("TreacheryAbility activated! ", treacherous_card.card_name, " treacherously captured ", treachery_captures, " additional enemies!")
		game_manager.update_board_visuals()
		return true
	else:
		print("TreacheryAbility activated but treacherous card couldn't capture any adjacent enemies")
		return true  # Still return true since the normal combat succeeded

func perform_treachery_combat(attacking_card: CardResource, grid_position: int, attacking_owner, game_manager) -> Array[int]:
	"""Perform normal combat and return positions of captured enemies"""
	var captured_positions: Array[int] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Check all 4 adjacent positions for normal combat
	var directions = [
		{"dx": 0, "dy": -1, "attack_index": 0, "defense_index": 2, "name": "North"},  # North
		{"dx": 1, "dy": 0, "attack_index": 1, "defense_index": 3, "name": "East"},   # East
		{"dx": 0, "dy": 1, "attack_index": 2, "defense_index": 0, "name": "South"},  # South
		{"dx": -1, "dy": 0, "attack_index": 3, "defense_index": 1, "name": "West"}   # West
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				var adjacent_owner = game_manager.get_owner_at_position(adj_index)
				
				# Only attack enemy cards
				if adjacent_owner != game_manager.Owner.NONE and adjacent_owner != attacking_owner:
					var adjacent_card = game_manager.get_card_at_position(adj_index)
					
					if not adjacent_card:
						continue
					
					var attack_value = attacking_card.values[direction.attack_index]
					var defense_value = adjacent_card.values[direction.defense_index]
					
					print("TreacheryAbility: Normal combat ", direction.name, " - ", attacking_card.card_name, " (", attack_value, ") vs ", adjacent_card.card_name, " (", defense_value, ")")
					
					# Check if attack wins
					if attack_value > defense_value:
						print("TreacheryAbility: Normal combat successful - capturing ", adjacent_card.card_name)
						
						# Capture the enemy card
						game_manager.set_card_ownership(adj_index, attacking_owner)
						captured_positions.append(adj_index)
						
						# Execute ON_CAPTURE abilities on the captured card
						execute_capture_abilities(adjacent_card, adj_index, attacking_card, grid_position, game_manager)
	
	return captured_positions

func perform_treacherous_attacks(treacherous_card: CardResource, treacherous_position: int, treachery_owner, game_manager) -> int:
	"""Make the treacherous card attack its adjacent enemies"""
	var captures_made = 0
	var grid_size = game_manager.grid_size
	var grid_x = treacherous_position % grid_size
	var grid_y = treacherous_position / grid_size
	
	# Check all 4 adjacent positions for treacherous attacks
	var directions = [
		{"dx": 0, "dy": -1, "attack_index": 0, "defense_index": 2, "name": "North"},  # North
		{"dx": 1, "dy": 0, "attack_index": 1, "defense_index": 3, "name": "East"},   # East
		{"dx": 0, "dy": 1, "attack_index": 2, "defense_index": 0, "name": "South"},  # South
		{"dx": -1, "dy": 0, "attack_index": 3, "defense_index": 1, "name": "West"}   # West
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				var adjacent_owner = game_manager.get_owner_at_position(adj_index)
				
				# Only attack enemy cards (from the treacherous card's new owner perspective)
				if adjacent_owner != game_manager.Owner.NONE and adjacent_owner != treachery_owner:
					var adjacent_card = game_manager.get_card_at_position(adj_index)
					
					if not adjacent_card:
						continue
					
					var attack_value = treacherous_card.values[direction.attack_index]
					var defense_value = adjacent_card.values[direction.defense_index]
					
					print("TreacheryAbility: Treacherous attack ", direction.name, " - ", treacherous_card.card_name, " (", attack_value, ") vs ", adjacent_card.card_name, " (", defense_value, ")")
					
					# Check if treacherous attack wins
					if attack_value > defense_value:
						print("TreacheryAbility: Treacherous attack successful - capturing ", adjacent_card.card_name)
						
						# Capture the enemy card
						game_manager.set_card_ownership(adj_index, treachery_owner)
						captures_made += 1
						
						# Execute ON_CAPTURE abilities on the captured card
						execute_capture_abilities(adjacent_card, adj_index, treacherous_card, treacherous_position, game_manager)
	
	return captures_made

func execute_capture_abilities(captured_card: CardResource, captured_position: int, capturing_card: CardResource, capturing_position: int, game_manager):
	"""Execute ON_CAPTURE abilities for captured cards"""
	var card_collection_index = game_manager.get_card_collection_index(captured_position)
	var card_level = game_manager.get_card_level(card_collection_index)
	
	if captured_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, card_level):
		print("TreacheryAbility: Executing ON_CAPTURE abilities for captured card: ", captured_card.card_name)
		
		var capture_context = {
			"capturing_card": capturing_card,
			"capturing_position": capturing_position,
			"captured_card": captured_card,
			"captured_position": captured_position,
			"game_manager": game_manager,
			"direction": "treachery",
			"card_level": card_level
		}
		
		captured_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, card_level)

func can_execute(context: Dictionary) -> bool:
	return true
