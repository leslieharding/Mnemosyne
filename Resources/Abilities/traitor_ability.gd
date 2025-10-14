# res://Resources/Abilities/traitor_ability.gd
class_name TraitorAbility
extends CardAbility

func _init():
	ability_name = "Traitor"
	description = "When this card is captured it also betrays one adjacent card from its old team"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var capturing_card = context.get("capturing_card")
	var capturing_position = context.get("capturing_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TraitorAbility: Starting execution for captured card at position ", captured_position)
	
	if not captured_card or captured_position == -1 or not game_manager:
		print("TraitorAbility: Missing required context data")
		return false
	
	# Get the new owner (the capturer) from the capturing card's position
	# The traitor's position has already been changed, so we check the capturer instead
	var new_owner = game_manager.get_owner_at_position(capturing_position)
	
	# Get adjacent positions
	var adjacent_positions = get_orthogonal_adjacent_positions(captured_position, game_manager)
	
	# Find all adjacent enemy cards (cards that belong to the old owner, not the new owner)
	var enemy_adjacent_cards: Array[int] = []
	
	for adj_pos in adjacent_positions:
		if game_manager.grid_occupied[adj_pos]:
			var adj_owner = game_manager.get_owner_at_position(adj_pos)
			
			# Enemy cards are those NOT owned by the new owner and not NONE
			if adj_owner != game_manager.Owner.NONE and adj_owner != new_owner:
				enemy_adjacent_cards.append(adj_pos)
				print("TraitorAbility: Found enemy card at position ", adj_pos)
	
	# If no enemy cards adjacent, ability does nothing
	if enemy_adjacent_cards.is_empty():
		print("TraitorAbility: No adjacent enemy cards to betray")
		return false
	
	# Randomly select one enemy card to convert
	var target_position = enemy_adjacent_cards[randi() % enemy_adjacent_cards.size()]
	var target_card = game_manager.get_card_at_position(target_position)
	
	print("TraitorAbility: Betraying card at position ", target_position, " - ", target_card.card_name)
	
	# Convert the selected card to the new owner
	game_manager.set_card_ownership(target_position, new_owner)
	
	# Execute ON_CAPTURE abilities on the betrayed card
	var target_card_collection_index = game_manager.get_card_collection_index(target_position)
	var target_card_level = game_manager.get_card_level(target_card_collection_index)
	
	if target_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, target_card_level):
		print("TraitorAbility: Executing ON_CAPTURE abilities for betrayed card: ", target_card.card_name)
		
		var betrayal_context = {
			"capturing_card": captured_card,
			"capturing_position": captured_position,
			"captured_card": target_card,
			"captured_position": target_position,
			"game_manager": game_manager,
			"direction": "traitor",
			"card_level": target_card_level
		}
		
		target_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, betrayal_context, target_card_level)
	
	print(ability_name, " activated! ", captured_card.card_name, " betrayed ", target_card.card_name, " to the enemy!")
	
	# Update board visuals
	game_manager.update_board_visuals()
	
	return true

func get_orthogonal_adjacent_positions(grid_position: int, game_manager) -> Array[int]:
	var adjacent_positions: Array[int] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Check all 4 orthogonal directions
	var directions = [
		{"dx": 0, "dy": -1},  # North
		{"dx": 1, "dy": 0},   # East
		{"dx": 0, "dy": 1},   # South
		{"dx": -1, "dy": 0}   # West
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			adjacent_positions.append(adj_index)
	
	return adjacent_positions

func can_execute(context: Dictionary) -> bool:
	return true
