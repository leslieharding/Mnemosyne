# res://Resources/Abilities/extended_range_ability.gd
class_name ExtendedRangeAbility
extends CardAbility

func _init():
	ability_name = "Extended Range"
	description = "This card attacks in all 8 directions including diagonals, using averaged values for diagonal combat"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("ExtendedRangeAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("ExtendedRangeAbility: Missing required context data")
		return false
	
	# This ability modifies combat behavior, but the actual combat resolution
	# will be handled by the modified resolve_combat function in the game manager
	# We just need to mark that this card has extended range
	placed_card.set_meta("has_extended_range", true)
	
	print("ExtendedRangeAbility activated! ", placed_card.card_name, " will attack in all 8 directions")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

# Helper function to get all 8 adjacent positions (orthogonal + diagonal)
static func get_extended_adjacent_positions(grid_position: int, grid_size: int) -> Array[Dictionary]:
	var adjacent_positions: Array[Dictionary] = []
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# All 8 directions: orthogonal (0-3) + diagonal (4-7)
	var directions = [
		{"dx": 0, "dy": -1, "direction": 0, "name": "North"},        # North
		{"dx": 1, "dy": 0, "direction": 1, "name": "East"},         # East
		{"dx": 0, "dy": 1, "direction": 2, "name": "South"},        # South
		{"dx": -1, "dy": 0, "direction": 3, "name": "West"},        # West
		{"dx": 1, "dy": -1, "direction": 4, "name": "Northeast"},   # Northeast
		{"dx": 1, "dy": 1, "direction": 5, "name": "Southeast"},    # Southeast
		{"dx": -1, "dy": 1, "direction": 6, "name": "Southwest"},   # Southwest
		{"dx": -1, "dy": -1, "direction": 7, "name": "Northwest"}   # Northwest
	]
	
	for dir_info in directions:
		var adj_x = grid_x + dir_info.dx
		var adj_y = grid_y + dir_info.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			adjacent_positions.append({
				"position": adj_index,
				"direction": dir_info.direction,
				"name": dir_info.name,
				"is_diagonal": dir_info.direction >= 4
			})
	
	return adjacent_positions

# Helper function to calculate attack value for a given direction
static func get_attack_value_for_direction(card_values: Array[int], direction: int) -> int:
	match direction:
		0, 1, 2, 3: # Orthogonal directions - use direct value
			return card_values[direction]
		4: # Northeast - average North + East
			return int(ceil((card_values[0] + card_values[1]) / 2.0))
		5: # Southeast - average East + South
			return int(ceil((card_values[1] + card_values[2]) / 2.0))
		6: # Southwest - average South + West
			return int(ceil((card_values[2] + card_values[3]) / 2.0))
		7: # Northwest - average West + North
			return int(ceil((card_values[3] + card_values[0]) / 2.0))
		_:
			print("ExtendedRangeAbility: Unknown direction ", direction)
			return 1

# Helper function to calculate defense value when being attacked from a direction
static func get_defense_value_for_direction(card_values: Array[int], attacking_direction: int) -> int:
	# For defense, we need to determine which direction we're being attacked FROM
	# and use the appropriate defensive values
	match attacking_direction:
		0: # Being attacked from North - defend with South
			return card_values[2]
		1: # Being attacked from East - defend with West
			return card_values[3]
		2: # Being attacked from South - defend with North
			return card_values[0]
		3: # Being attacked from West - defend with East
			return card_values[1]
		4: # Being attacked from Northeast - defend with Southwest (average South + West)
			return int(ceil((card_values[2] + card_values[3]) / 2.0))
		5: # Being attacked from Southeast - defend with Northwest (average North + West)
			return int(ceil((card_values[0] + card_values[3]) / 2.0))
		6: # Being attacked from Southwest - defend with Northeast (average North + East)
			return int(ceil((card_values[0] + card_values[1]) / 2.0))
		7: # Being attacked from Northwest - defend with Southeast (average East + South)
			return int(ceil((card_values[1] + card_values[2]) / 2.0))
		_:
			print("ExtendedRangeAbility: Unknown attacking direction ", attacking_direction)
			return 1
