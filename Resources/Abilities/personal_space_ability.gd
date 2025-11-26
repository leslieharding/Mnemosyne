# res://Resources/Abilities/personal_space_ability.gd
class_name PersonalSpaceAbility
extends CardAbility

func _init():
	ability_name = "Personal Space"
	description = "Gains +2 to all stats for each empty adjacent space, loses -1 to all stats for each adjacent card"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("PersonalSpaceAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("PersonalSpaceAbility: Missing required context data")
		return false
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Count empty and occupied adjacent spaces
	var empty_count = 0
	var occupied_count = 0
	
	var adjacent_info = check_adjacent_spaces(grid_position, game_manager)
	empty_count = adjacent_info.empty
	occupied_count = adjacent_info.occupied
	
	print("PersonalSpaceAbility: Found ", empty_count, " empty spaces and ", occupied_count, " occupied spaces")
	
	# Calculate net stat change
	var stat_change = (empty_count * 2) - occupied_count
	
	print("PersonalSpaceAbility: Net stat change = (+", empty_count * 2, " from empty) - (", occupied_count, " from occupied) = ", stat_change)
	
	# Apply the stat change to all directions (minimum 0)
	placed_card.values[0] = max(0, placed_card.values[0] + stat_change)  # North
	placed_card.values[1] = max(0, placed_card.values[1] + stat_change)  # East
	placed_card.values[2] = max(0, placed_card.values[2] + stat_change)  # South
	placed_card.values[3] = max(0, placed_card.values[3] + stat_change)  # West
	
	print("PersonalSpaceAbility: Stats changed from ", original_values, " to ", placed_card.values)
	print(ability_name, " activated! ", placed_card.card_name, " adjusted stats by ", stat_change, " (", empty_count, " empty spaces, ", occupied_count, " occupied)")
	
	# Update the visual display
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card
			child.update_display()
			print("PersonalSpaceAbility: Updated CardDisplay visual")
			break
	
	return true

func check_adjacent_spaces(grid_position: int, game_manager) -> Dictionary:
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	var empty_count = 0
	var occupied_count = 0
	
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
		
		# Check if adjacent position is within bounds
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				occupied_count += 1
				print("  ", dir_info.name, " (pos ", adj_index, "): OCCUPIED")
			else:
				empty_count += 1
				print("  ", dir_info.name, " (pos ", adj_index, "): EMPTY")
		else:
			print("  ", dir_info.name, ": OUT OF BOUNDS")
	
	return {"empty": empty_count, "occupied": occupied_count}

func can_execute(context: Dictionary) -> bool:
	return true
