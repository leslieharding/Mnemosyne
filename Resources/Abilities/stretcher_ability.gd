# res://Resources/Abilities/stretcher_ability.gd
class_name StretcherAbility
extends CardAbility

func _init():
	ability_name = "The Stretcher"
	description = "After combat, this card either stretches you to fit, or cuts you to size"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("StretcherAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("StretcherAbility: Missing required context data")
		return false
	
	var stretcher_owner = game_manager.get_owner_at_position(grid_position)
	var total_cards_modified = 0
	
	# Check all 4 orthogonal directions
	var directions = [
		{"index": 0, "name": "North"},
		{"index": 1, "name": "East"},
		{"index": 2, "name": "South"},
		{"index": 3, "name": "West"}
	]
	
	for direction in directions:
		var adjacent_pos = get_adjacent_position(grid_position, direction.index, game_manager.grid_size)
		
		if adjacent_pos == -1:
			continue
		
		if not game_manager.grid_occupied[adjacent_pos]:
			continue
		
		var adjacent_owner = game_manager.get_owner_at_position(adjacent_pos)
		# Skip empty slots, but process ALL enemy cards (including just-captured ones)
		if adjacent_owner == game_manager.Owner.NONE:
			continue
		
		# Only affect enemy cards (not friendly cards)
		if adjacent_owner == stretcher_owner:
			continue
		
		var adjacent_card = game_manager.get_card_at_position(adjacent_pos)
		if not adjacent_card:
			continue
		
		print("  Processing adjacent enemy at position ", adjacent_pos, " in direction ", direction.name)
		
		# Pass the direction index so only that facing stat is modified
		var modifications_made = stretch_or_cut_card(placed_card, adjacent_card, direction.index, adjacent_pos, game_manager)
		
		if modifications_made:
			total_cards_modified += 1
	
	if total_cards_modified > 0:
		# Update all affected card displays
		game_manager.update_board_visuals()
		print("StretcherAbility activated! Modified ", total_cards_modified, " adjacent enemy cards")
		return true
	else:
		print("StretcherAbility had no effect - no adjacent enemies to modify")
		return false

func stretch_or_cut_card(stretcher_card: CardResource, target_card: CardResource, direction_from_stretcher: int, target_position: int, game_manager) -> bool:
	"""
	Modify target card's stat that faces the stretcher to match stretcher's corresponding stat
	direction_from_stretcher: which direction the target is from the stretcher (0=N, 1=E, 2=S, 3=W)
	Returns true if any modifications were made
	"""
	
	# Calculate which direction on the target card faces the stretcher
	# If stretcher is North of target (direction 0), target's South stat (direction 2) faces it
	var target_facing_direction = (direction_from_stretcher + 2) % 4
	
	var stretcher_value = stretcher_card.values[direction_from_stretcher]
	var target_value = target_card.values[target_facing_direction]
	
	print("    Stretcher's ", get_direction_name(direction_from_stretcher), " stat: ", stretcher_value)
	print("    Target's ", get_direction_name(target_facing_direction), " stat (facing stretcher): ", target_value)
	
	var modifications_made = false
	
	if target_value < stretcher_value:
		# Stretch up
		target_card.values[target_facing_direction] = stretcher_value
		print("      Stretched up to ", stretcher_value)
		modifications_made = true
	elif target_value > stretcher_value:
		# Cut down
		target_card.values[target_facing_direction] = stretcher_value
		print("      Cut down to ", stretcher_value)
		modifications_made = true
	else:
		print("      Unchanged (already matches)")
	
	if modifications_made:
		print("    Target new stats: ", target_card.values)
		
		# Update the card display at this position
		var slot = game_manager.grid_slots[target_position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = target_card
				child.update_display()
				print("    Updated CardDisplay visual for modified card")
				break
	
	return modifications_made

func get_adjacent_position(grid_position: int, direction: int, grid_size: int) -> int:
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	match direction:
		0: # North
			if grid_y > 0:
				return (grid_y - 1) * grid_size + grid_x
		1: # East
			if grid_x < grid_size - 1:
				return grid_y * grid_size + (grid_x + 1)
		2: # South
			if grid_y < grid_size - 1:
				return (grid_y + 1) * grid_size + grid_x
		3: # West
			if grid_x > 0:
				return grid_y * grid_size + (grid_x - 1)
	
	return -1

func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func can_execute(context: Dictionary) -> bool:
	return true
