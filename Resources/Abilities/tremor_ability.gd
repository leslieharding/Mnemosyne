# res://Resources/Abilities/tremor_ability.gd
class_name TremorAbility
extends CardAbility

func _init():
	ability_name = "Tremors"
	description = "After placement, this card causes tremors in adjacent empty spaces for 2 turns, capturing any cards in those zones on turn start"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TremorAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("TremorAbility: Missing required context data")
		return false
	
	# Get the owner of the tremor card
	var tremor_owner = game_manager.get_owner_at_position(grid_position)
	
	# Find all empty orthogonal adjacent positions
	var tremor_zones = get_empty_adjacent_positions(grid_position, game_manager)
	
	if tremor_zones.is_empty():
		print("TremorAbility: No empty adjacent positions for tremors")
		return false
	
	# Register tremors in the game manager's tremor tracking system
	game_manager.register_tremors(grid_position, tremor_zones, tremor_owner, 2)  # 2 turns of tremors
	
	print("TremorAbility activated! ", placed_card.card_name, " will cause tremors in ", tremor_zones.size(), " zones for 2 turns")
	print("Tremor zones: ", tremor_zones)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

# Get empty orthogonal adjacent positions
func get_empty_adjacent_positions(grid_position: int, game_manager) -> Array[int]:
	var empty_positions: Array[int] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Check 4 orthogonal directions
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
		
		# Check if adjacent position is within bounds and empty
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if not game_manager.grid_occupied[adj_index]:
				empty_positions.append(adj_index)
				print("TremorAbility: Marked empty position ", adj_index, " (", dir_info.name, ") for tremors")
	
	return empty_positions
