# res://Resources/Abilities/infighting_ability.gd
class_name InfightingAbility
extends CardAbility

func _init():
	ability_name = "Infighting"
	description = "Hesitant family members could be swayed... with the right incentive."
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just captured (this card with infighting ability)
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var capturing_card = context.get("capturing_card")
	var capturing_position = context.get("capturing_position", -1)
	var game_manager = context.get("game_manager")
	
	print("InfightingAbility: Starting execution for captured card at position ", captured_position)
	
	# Safety checks
	if not captured_card:
		print("InfightingAbility: No captured card provided")
		return false
	
	if captured_position == -1:
		print("InfightingAbility: Invalid captured position")
		return false
	
	if not game_manager:
		print("InfightingAbility: No game manager provided")
		return false
	
	# Check if this card was captured by the player
	var captured_by_player = (game_manager.get_owner_at_position(captured_position) == game_manager.Owner.PLAYER)
	if not captured_by_player:
		print("InfightingAbility: Card not captured by player - no infighting effect")
		return false
	
	# Define the family members who are "for fighting" (aggressive)
	var aggressive_family_members = ["Alphenor", "Astyoche", "Sipylus"]
	
	# Check all orthogonally adjacent positions for aggressive family members
	var converted_cards = []
	var adjacent_positions = get_orthogonal_adjacent_positions(captured_position, game_manager)
	
	for adj_pos in adjacent_positions:
		if not game_manager.grid_occupied[adj_pos]:
			continue  # Empty slot
		
		var adjacent_owner = game_manager.get_owner_at_position(adj_pos)
		if adjacent_owner == game_manager.Owner.PLAYER:
			continue  # Already player's card
		
		var adjacent_card = game_manager.get_card_at_position(adj_pos)
		if not adjacent_card:
			continue  # No card data
		
		# Check if this adjacent card is one of the aggressive family members
		if adjacent_card.card_name in aggressive_family_members:
			print("InfightingAbility: Found aggressive family member ", adjacent_card.card_name, " at position ", adj_pos)
			converted_cards.append(adj_pos)
	
	# Convert all found aggressive family members to player's side
	var conversion_count = 0
	for convert_pos in converted_cards:
		var converting_card = game_manager.get_card_at_position(convert_pos)
		print("InfightingAbility: Converting ", converting_card.card_name, " to player's side due to family infighting")
		
		# Change ownership to player
		game_manager.set_card_ownership(convert_pos, game_manager.Owner.PLAYER)
		conversion_count += 1
		
		# Execute ON_CAPTURE abilities on the converted card (like other capture mechanics)
		var converting_card_collection_index = game_manager.get_card_collection_index(convert_pos)
		var converting_card_level = game_manager.get_card_level(converting_card_collection_index)
		
		if converting_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, converting_card_level):
			print("InfightingAbility: Executing ON_CAPTURE abilities for converted card: ", converting_card.card_name)
			
			var conversion_context = {
				"capturing_card": captured_card,  # The hesitant card that caused the infighting
				"capturing_position": captured_position,
				"captured_card": converting_card,  # The aggressive card being converted
				"captured_position": convert_pos,
				"game_manager": game_manager,
				"direction": "infighting",
				"card_level": converting_card_level
			}
			
			converting_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, conversion_context, converting_card_level)
	
	if conversion_count > 0:
		print(ability_name, " activated! ", captured_card.card_name, "'s hesitation turned ", conversion_count, " family members against the fight!")
		
		# Update board visuals to reflect ownership changes
		game_manager.update_board_visuals()
		
		return true
	else:
		print(ability_name, " had no effect - no adjacent aggressive family members found")
		return false

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
