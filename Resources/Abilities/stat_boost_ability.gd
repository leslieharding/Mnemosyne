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
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("StatBoostAbility: Missing required context data")
		return false
	
	# Check all 4 directions for enemy cards and boost if we find any
	var boosted_directions = []
	
	for direction in range(4):  # 0=North, 1=East, 2=South, 3=West
		var enemy_position = get_adjacent_position(grid_position, direction, game_manager)
		if enemy_position == -1:
			continue
		
		var enemy_card = game_manager.get_card_at_position(enemy_position)
		var enemy_owner = game_manager.get_owner_at_position(enemy_position)
		
		# If there's an enemy card in this direction, boost our stat for that direction
		if enemy_card and enemy_owner != game_manager.Owner.NONE and enemy_owner != game_manager.Owner.PLAYER:
			placed_card.values[direction] += boost_amount
			boosted_directions.append(get_direction_name(direction))
	
	# Print results
	if boosted_directions.size() > 0:
		print(ability_name, " activated! Boosted ", " and ".join(boosted_directions), " by +", boost_amount, " each")
		return true
	else:
		print(ability_name, " had no effect - no adjacent enemies found")
		return false

func can_execute(context: Dictionary) -> bool:
	# Basic check - could add more conditions here
	return true

func get_adjacent_position(grid_position: int, direction: int, game_manager) -> int:
	var grid_size = game_manager.grid_size
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
