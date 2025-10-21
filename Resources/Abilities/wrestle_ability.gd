# res://Resources/Abilities/wrestle_ability.gd
class_name WrestleAbility
extends CardAbility

func _init():
	ability_name = "Wrestle"
	description = "If this card cannot beat you in direct combat, it will also fight your other values, best out of 3 wins."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("WrestleAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("WrestleAbility: Missing required context data")
		return false
	
	var wrestling_owner = game_manager.get_owner_at_position(grid_position)
	var total_wrestle_captures = 0
	
	# Check all 4 orthogonal directions
	var directions = [
		{"index": 0, "name": "North", "opposite": 2},
		{"index": 1, "name": "East", "opposite": 3},
		{"index": 2, "name": "South", "opposite": 0},
		{"index": 3, "name": "West", "opposite": 1}
	]
	
	for direction in directions:
		var adjacent_pos = get_adjacent_position(grid_position, direction.index, game_manager.grid_size)
		
		if adjacent_pos == -1:
			continue
		
		if not game_manager.grid_occupied[adjacent_pos]:
			continue
		
		var adjacent_owner = game_manager.get_owner_at_position(adjacent_pos)
		if adjacent_owner == game_manager.Owner.NONE or adjacent_owner == wrestling_owner:
			continue
		
		var adjacent_card = game_manager.get_card_at_position(adjacent_pos)
		if not adjacent_card:
			continue
		
		# Check normal combat
		var wrestle_attack = placed_card.values[direction.index]
		var enemy_defense = adjacent_card.values[direction.opposite]
		
		print("  Direction ", direction.name, ": Wrestle ", wrestle_attack, " vs Enemy ", enemy_defense)
		
		# If normal combat would win, don't trigger wrestle
		if wrestle_attack > enemy_defense:
			print("    Normal combat wins - Wrestle doesn't trigger")
			continue
		
		# Normal combat fails (loss or tie) - trigger wrestle
		print("    Normal combat fails - WRESTLE TRIGGERED!")
		
		if attempt_wrestle_capture(placed_card, adjacent_card, direction.index, game_manager):
			# Capture the enemy card
			game_manager.set_card_ownership(adjacent_pos, wrestling_owner)
			total_wrestle_captures += 1
			print("    WRESTLE SUCCESSFUL! Captured enemy at position ", adjacent_pos)
		else:
			print("    Wrestle failed - enemy survives")
	
	if total_wrestle_captures > 0:
		game_manager.update_board_visuals()
		print("WrestleAbility activated! ", placed_card.card_name, " captured ", total_wrestle_captures, " cards via wrestling")
		return true
	else:
		print("WrestleAbility had no effect - no wrestle captures made")
		return false

func attempt_wrestle_capture(wrestle_card: CardResource, enemy_card: CardResource, lost_direction: int, game_manager) -> bool:
	"""
	Best of 3 comparison using the OTHER 3 directions
	Returns true if wrestle card wins 2+ comparisons
	"""
	
	# Get the 3 other directions (exclude the one that lost)
	var all_directions = [0, 1, 2, 3]
	var wrestle_directions = []
	for dir in all_directions:
		if dir != lost_direction:
			wrestle_directions.append(dir)
	
	var wrestle_wins = 0
	
	print("      Best of 3 wrestle comparisons:")
	for dir in wrestle_directions:
		var opposite_dir = get_opposite_direction(dir)
		var wrestle_value = wrestle_card.values[dir]
		var enemy_value = enemy_card.values[opposite_dir]
		
		var direction_name = get_direction_name(dir)
		var enemy_direction_name = get_direction_name(opposite_dir)
		
		if wrestle_value > enemy_value:
			wrestle_wins += 1
			print("        Wrestle ", direction_name, " (", wrestle_value, ") > Enemy ", enemy_direction_name, " (", enemy_value, ") - Wrestle wins! (", wrestle_wins, "/2)")
		else:
			print("        Wrestle ", direction_name, " (", wrestle_value, ") <= Enemy ", enemy_direction_name, " (", enemy_value, ") - Enemy wins")
		
		# Early exit if wrestle already won 2/3
		if wrestle_wins >= 2:
			print("      Wrestle wins 2/3 - capture successful!")
			return true
	
	print("      Wrestle only won ", wrestle_wins, "/3 - capture failed")
	return false

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

func get_opposite_direction(direction: int) -> int:
	match direction:
		0: return 2  # North -> South
		1: return 3  # East -> West
		2: return 0  # South -> North
		3: return 1  # West -> East
		_: return 0

func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func can_execute(context: Dictionary) -> bool:
	return true
