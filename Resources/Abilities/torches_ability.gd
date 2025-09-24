# res://Resources/Abilities/torches_ability.gd
class_name TorchesAbility
extends CardAbility

func _init():
	ability_name = "Torches"
	description = "Attacks all non-adjacent slots."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TorchesAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("TorchesAbility: Missing required context data")
		return false
	
	# Calculate Hecate's average stat
	var hecate_average_stat = calculate_average_stat(placed_card.values)
	print("TorchesAbility: Hecate's average stat = ", hecate_average_stat)
	
	# Get all non-adjacent positions
	var non_adjacent_positions = get_non_adjacent_positions(grid_position, game_manager)
	print("TorchesAbility: Found ", non_adjacent_positions.size(), " non-adjacent positions: ", non_adjacent_positions)
	
	var captures_made = 0
	var hecate_owner = game_manager.grid_ownership[grid_position]
	
	# Attack each non-adjacent enemy card
	for target_pos in non_adjacent_positions:
		# Check if slot is occupied and owned by enemy
		if not game_manager.grid_occupied[target_pos]:
			continue
		
		var target_owner = game_manager.grid_ownership[target_pos]
		if target_owner == hecate_owner:
			continue  # Don't attack own cards
		
		var target_card = game_manager.grid_card_data[target_pos]
		if not target_card:
			continue
		
		# Get target's level for correct stats
		var target_card_index = game_manager.get_card_collection_index(target_pos)
		var target_level = game_manager.get_card_level(target_card_index)
		var target_effective_values = target_card.get_effective_values(target_level)
		
		# Calculate target's lowest stat
		var target_lowest_stat = get_lowest_stat(target_effective_values)
		print("TorchesAbility: Attacking position ", target_pos, " - Hecate avg (", hecate_average_stat, ") vs ", target_card.card_name, " lowest (", target_lowest_stat, ")")
		
		# Compare stats - Hecate captures if her average beats target's lowest
		if hecate_average_stat > target_lowest_stat:
			print("TorchesAbility: CAPTURE! Hecate's torches illuminate position ", target_pos)
			
			# Change ownership to Hecate's owner
			game_manager.set_card_ownership(target_pos, hecate_owner)
			captures_made += 1
			
			# Execute ON_CAPTURE abilities on the captured card
			if target_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, target_level):
				print("TorchesAbility: Executing ON_CAPTURE abilities for captured card: ", target_card.card_name)
				
				var capture_context = {
					"capturing_card": placed_card,
					"capturing_position": grid_position,
					"captured_card": target_card,
					"captured_position": target_pos,
					"game_manager": game_manager,
					"direction": "torches",
					"card_level": target_level
				}
				
				target_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, target_level)
			
			# Award capture experience to Hecate if she's player-owned
			if hecate_owner == game_manager.Owner.PLAYER:
				var hecate_card_index = game_manager.get_card_collection_index(grid_position)
				if hecate_card_index != -1:
					var exp_tracker = game_manager.get_node("/root/RunExperienceTrackerAutoload")
					if exp_tracker:
						exp_tracker.add_capture_exp(hecate_card_index, 10)
						print("TorchesAbility: Awarded 10 capture exp to Hecate at collection index ", hecate_card_index)
		else:
			print("TorchesAbility: No capture - target defended (", target_lowest_stat, " >= ", hecate_average_stat, ")")
	
	if captures_made > 0:
		print(ability_name, " activated! Hecate's torches captured ", captures_made, " distant enemies!")
		game_manager.update_board_visuals()
		return true
	else:
		print(ability_name, " had no effect - no distant enemies were captured")
		return false

func calculate_average_stat(values: Array[int]) -> int:
	var sum = 0
	for value in values:
		sum += value
	return int(sum / float(values.size()))

func get_lowest_stat(values: Array[int]) -> int:
	var lowest = values[0]
	for value in values:
		if value < lowest:
			lowest = value
	return lowest

func get_non_adjacent_positions(grid_position: int, game_manager) -> Array[int]:
	var non_adjacent: Array[int] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Get orthogonally adjacent positions
	var adjacent_positions = get_orthogonal_adjacent_positions(grid_position, game_manager)
	
	# Check all grid positions
	for y in range(grid_size):
		for x in range(grid_size):
			var pos = y * grid_size + x
			
			# Skip Hecate's own position
			if pos == grid_position:
				continue
			
			# Skip orthogonally adjacent positions
			if pos in adjacent_positions:
				continue
			
			# This is a non-adjacent position
			non_adjacent.append(pos)
	
	return non_adjacent

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
