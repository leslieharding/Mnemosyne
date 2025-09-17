# res://Resources/Abilities/stat_boost_ability.gd
class_name StatBoostAbility
extends CardAbility

@export var boost_amount: int = 1

func _init():
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("StatBoostAbility: Starting execution for card at position ", grid_position)
	print("StatBoostAbility: Card values before boost: ", placed_card.values if placed_card else "no card")
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("StatBoostAbility: Missing required context data")
		return false
	
	# Check all 4 directions for enemy cards and boost if we find any
	var boosted_directions = []
	
	for direction in range(4):  # 0=North, 1=East, 2=South, 3=West
		var enemy_position = get_adjacent_position(grid_position, direction, game_manager)
		print("StatBoostAbility: Checking direction ", direction, " (", get_direction_name(direction), ") -> position ", enemy_position)
		
		if enemy_position == -1:
			print("  No adjacent position in this direction")
			continue
		
		var enemy_card = game_manager.get_card_at_position(enemy_position)
		var enemy_owner = game_manager.get_owner_at_position(enemy_position)
		
		print("  Found card: ", enemy_card.card_name if enemy_card else "none", " owned by: ", enemy_owner)
		
		# If there's an enemy card in this direction, boost our stat for that direction
		if enemy_card and enemy_owner == game_manager.Owner.OPPONENT:
			print("  BOOSTING direction ", direction, " from ", placed_card.values[direction], " to ", placed_card.values[direction] + boost_amount)
			placed_card.values[direction] += boost_amount
			boosted_directions.append(get_direction_name(direction))
		else:
			print("  Not an enemy card - skipping")
	
	# Print results
	if boosted_directions.size() > 0:
		print("StatBoostAbility: Card values after boost: ", placed_card.values)
		print(ability_name, " activated! ", placed_card.card_name, " gained +", boost_amount, " in directions facing enemies: ", boosted_directions)
		
		# FIXED: Update the visual display to show the new stats
		var slot = game_manager.grid_slots[grid_position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = placed_card  # Update the card data reference
				child.update_display()         # Refresh the visual display
				print("StatBoostAbility: Updated CardDisplay visual for boosted card")
				break
		
		return true
	else:
		print("StatBoostAbility: No enemies found adjacent - no boost applied")
		return false

# Helper function to get adjacent position in a given direction
func get_adjacent_position(grid_position: int, direction: int, game_manager) -> int:
	var grid_size = game_manager.grid_size  # Should be 3 for 3x3 grid
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	var new_x = grid_x
	var new_y = grid_y
	
	match direction:
		0:  # North
			new_y -= 1
		1:  # East
			new_x += 1
		2:  # South
			new_y += 1
		3:  # West
			new_x -= 1
	
	# Check bounds
	if new_x < 0 or new_x >= grid_size or new_y < 0 or new_y >= grid_size:
		return -1
	
	return new_y * grid_size + new_x

# Helper function to get direction name for logging
func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func can_execute(context: Dictionary) -> bool:
	return true
