# res://Resources/Abilities/bull_lover_ability.gd
class_name BullLoverAbility
extends CardAbility

func _init():
	ability_name = "Bull Lover"
	description = "If this card is adjacent to Cretan Bull when played it has double stats"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("BullLoverAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("BullLoverAbility: Missing required context data")
		return false
	
	# Check for adjacent Cretan Bull
	if not has_adjacent_cretan_bull(grid_position, game_manager):
		print("BullLoverAbility: No Cretan Bull adjacent - no boost applied")
		return false
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Double all stats
	placed_card.values[0] *= 2  # North
	placed_card.values[1] *= 2  # East
	placed_card.values[2] *= 2  # South
	placed_card.values[3] *= 2  # West
	
	print(ability_name, " activated! ", placed_card.card_name, " found her beloved bull nearby!")
	print("BullLoverAbility: Stats doubled from ", original_values, " to ", placed_card.values)
	
	# Update the visual display
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card  # Update the card data reference
			child.update_display()         # Refresh the visual display
			print("BullLoverAbility: Updated CardDisplay visual for doubled stats")
			break
	
	return true

func has_adjacent_cretan_bull(grid_position: int, game_manager) -> bool:
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Check 4 orthogonal directions
	var directions = [
		{"dx": 0, "dy": -1, "name": "North"},
		{"dx": 1, "dy": 0, "name": "East"},
		{"dx": 0, "dy": 1, "name": "South"},
		{"dx": -1, "dy": 0, "name": "West"}
	]
	
	for dir_info in directions:
		var adj_x = grid_x + dir_info.dx
		var adj_y = grid_y + dir_info.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				var adjacent_card = game_manager.get_card_at_position(adj_index)
				if adjacent_card:
					# Check if the card name is "Cretan Bull" (checking various capitalizations)
					var card_name_lower = adjacent_card.card_name.to_lower()
					if card_name_lower == "cretan bull":
						print("BullLoverAbility: Found Cretan Bull at position ", adj_index, " (", dir_info.name, ")")
						return true
	
	print("BullLoverAbility: No Cretan Bull found in adjacent positions")
	return false

func can_execute(context: Dictionary) -> bool:
	return true
