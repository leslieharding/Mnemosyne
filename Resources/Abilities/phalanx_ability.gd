# res://Resources/Abilities/phalanx_ability.gd
class_name PhalanxAbility
extends CardAbility

func _init():
	ability_name = "Phalanx"
	description = "On play if you own all 3 cards in a row or column, boost the formations stats by 2"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("PhalanxAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("PhalanxAbility: Missing required context data")
		return false
	
	# Get the owner of the phalanx card
	var phalanx_owner = game_manager.get_owner_at_position(grid_position)
	
	# Find all complete rows and columns owned by the same player
	var complete_formations = find_complete_formations(grid_position, phalanx_owner, game_manager)
	
	if complete_formations.is_empty():
		print("PhalanxAbility: No complete formations found")
		return false
	
	# Apply +2 bonus to all cards in complete formations (avoiding double-buffing)
	var boosted_positions = {}  # Track which positions have been boosted
	var total_formations = complete_formations.size()
	
	for formation in complete_formations:
		print("PhalanxAbility: Boosting ", formation.type, " formation: ", formation.positions)
		
		for pos in formation.positions:
			# Only boost each position once, even if it's in multiple formations
			if not boosted_positions.has(pos):
				var card_at_pos = game_manager.get_card_at_position(pos)
				if card_at_pos:
					# Store original values for logging
					var original_values = card_at_pos.values.duplicate()
					
					# Apply +2 boost to all directional stats
					card_at_pos.values[0] += 2  # North
					card_at_pos.values[1] += 2  # East
					card_at_pos.values[2] += 2  # South
					card_at_pos.values[3] += 2  # West
					
					print("PhalanxAbility: Boosted card at position ", pos, " from ", original_values, " to ", card_at_pos.values)
					
					# Update the visual display
					if game_manager.has_method("update_card_display"):
						game_manager.update_card_display(pos, card_at_pos)
					
					boosted_positions[pos] = true
	
	# Success message
	var formation_types = []
	for formation in complete_formations:
		formation_types.append(formation.type)
	
	print(ability_name, " activated! ", placed_card.card_name, " completed ", total_formations, " formation(s): ", formation_types)
	print("Boosted ", boosted_positions.size(), " cards with +2 to all stats!")
	
	return true

func find_complete_formations(grid_position: int, owner, game_manager) -> Array:
	var formations = []
	var grid_size = game_manager.grid_size  # Should be 3 for 3x3 grid
	
	# Get x,y coordinates of the placed card
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	print("PhalanxAbility: Checking formations for position ", grid_position, " (", grid_x, ",", grid_y, ")")
	
	# Check the row this card is in
	var row_positions = get_row_positions(grid_y, grid_size)
	if is_formation_complete(row_positions, owner, game_manager):
		formations.append({
			"type": "row",
			"positions": row_positions
		})
		print("PhalanxAbility: Found complete row ", grid_y, ": ", row_positions)
	
	# Check the column this card is in  
	var column_positions = get_column_positions(grid_x, grid_size)
	if is_formation_complete(column_positions, owner, game_manager):
		formations.append({
			"type": "column", 
			"positions": column_positions
		})
		print("PhalanxAbility: Found complete column ", grid_x, ": ", column_positions)
	
	return formations

func get_row_positions(row_y: int, grid_size: int) -> Array[int]:
	var positions: Array[int] = []
	for x in range(grid_size):
		positions.append(row_y * grid_size + x)
	return positions

func get_column_positions(col_x: int, grid_size: int) -> Array[int]:
	var positions: Array[int] = []
	for y in range(grid_size):
		positions.append(y * grid_size + col_x)
	return positions

func is_formation_complete(positions: Array[int], owner, game_manager) -> bool:
	# Check if all positions in the formation are occupied and owned by the same player
	for pos in positions:
		# Check if position is occupied
		if not game_manager.grid_occupied[pos]:
			print("PhalanxAbility: Position ", pos, " is not occupied")
			return false
		
		# Check if position is owned by the correct player
		var position_owner = game_manager.get_owner_at_position(pos)
		if position_owner != owner:
			print("PhalanxAbility: Position ", pos, " owned by ", position_owner, " but need ", owner)
			return false
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
