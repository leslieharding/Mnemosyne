# res://Resources/Abilities/pierce_ability.gd
class_name PierceAbility
extends CardAbility

func _init():
	ability_name = "Pierce"
	description = "This unit's attack range is 2, but can only attack through occupied squares."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("PierceAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("PierceAbility: Missing required context data")
		return false
	
	# Get the owner of the piercing card
	var pierce_owner = game_manager.get_owner_at_position(grid_position)
	
	# Store original ownership to check if card gets captured during execution
	var original_pierce_owner = pierce_owner
	
	var total_captures = 0
	
	# Check all 4 directions
	for direction in range(4):
		print("PierceAbility: Checking direction ", direction, " (", get_direction_name(direction), ")")
		
		# Get adjacent position (1 square away)
		var adjacent_pos = get_position_in_direction(grid_position, direction, 1, game_manager)
		if adjacent_pos == -1:
			print("  No adjacent position in direction ", direction)
			continue
		
		# Check if adjacent position has an enemy card
		if not game_manager.grid_occupied[adjacent_pos]:
			print("  Adjacent position ", adjacent_pos, " is empty - cannot pierce through")
			continue
		
		var adjacent_card = game_manager.get_card_at_position(adjacent_pos)
		var adjacent_owner = game_manager.get_owner_at_position(adjacent_pos)
		
		if adjacent_owner == pierce_owner:
			print("  Adjacent card is friendly - cannot pierce through")
			continue
		
		print("  Found enemy adjacent card: ", adjacent_card.card_name, " at position ", adjacent_pos)
		
		# Simulate combat with adjacent card first
		var pierce_attack_value = placed_card.values[direction]
		var adjacent_defense_direction = get_opposite_direction(direction)
		var adjacent_defense_value = adjacent_card.values[adjacent_defense_direction]
		
		print("  Adjacent combat: Pierce ", pierce_attack_value, " vs Adjacent ", adjacent_defense_value)
		
		# Check if Pierce would win against adjacent
		var would_capture_adjacent = pierce_attack_value > adjacent_defense_value
		
		# Now check for 2nd position (2 squares away)
		var distant_pos = get_position_in_direction(grid_position, direction, 2, game_manager)
		var would_capture_distant = false
		
		if distant_pos != -1 and game_manager.grid_occupied[distant_pos]:
			var distant_card = game_manager.get_card_at_position(distant_pos)
			var distant_owner = game_manager.get_owner_at_position(distant_pos)
			
			if distant_owner != pierce_owner:  # It's an enemy
				print("  Found distant enemy card: ", distant_card.card_name, " at position ", distant_pos)
				
				# Simulate combat with distant card
				var distant_defense_direction = get_opposite_direction(direction)
				var distant_defense_value = distant_card.values[distant_defense_direction]
				
				print("  Distant combat: Pierce ", pierce_attack_value, " vs Distant ", distant_defense_value)
				
				would_capture_distant = pierce_attack_value > distant_defense_value
			else:
				print("  Distant card is friendly - no combat")
		else:
			print("  No valid distant target in direction ", direction)
		
		# Now execute actual combats in sequence if Pierce would win
		if would_capture_adjacent:
			print("  Executing combat against adjacent card...")
			total_captures += execute_pierce_combat(grid_position, adjacent_pos, direction, placed_card, adjacent_card, game_manager)
			
			# Check if Pierce card still exists and has same ownership
			var current_pierce_owner = game_manager.get_owner_at_position(grid_position)
			if current_pierce_owner != original_pierce_owner:
				print("  Pierce card ownership changed - stopping execution")
				break
			
			# If we captured adjacent and there's a distant target we'd win against
			if would_capture_distant and distant_pos != -1:
				print("  Executing combat against distant card...")
				total_captures += execute_pierce_combat(grid_position, distant_pos, direction, placed_card, game_manager.get_card_at_position(distant_pos), game_manager)
				
				# Check ownership again
				current_pierce_owner = game_manager.get_owner_at_position(grid_position)
				if current_pierce_owner != original_pierce_owner:
					print("  Pierce card ownership changed - stopping execution")
					break
		elif would_capture_distant and distant_pos != -1:
			print("  Would not capture adjacent, but would capture distant - executing distant combat only...")
			total_captures += execute_pierce_combat(grid_position, distant_pos, direction, placed_card, game_manager.get_card_at_position(distant_pos), game_manager)
			
			# Check ownership
			var current_pierce_owner = game_manager.get_owner_at_position(grid_position)
			if current_pierce_owner != original_pierce_owner:
				print("  Pierce card ownership changed - stopping execution")
				break
	
	if total_captures > 0:
		print("PierceAbility activated! ", placed_card.card_name, " captured ", total_captures, " cards with pierce range")
		return true
	else:
		print("PierceAbility had no effect - no captures made")
		return false

func execute_pierce_combat(attacker_pos: int, defender_pos: int, direction: int, attacker_card: CardResource, defender_card: CardResource, game_manager) -> int:
	"""Execute a single pierce combat and return 1 if capture occurred, 0 if not"""
	
	# Use the game manager's existing combat resolution system
	var pierce_attack_value = attacker_card.values[direction]
	var defense_direction = get_opposite_direction(direction)
	var defense_value = defender_card.values[defense_direction]
	
	print("    Combat: ", attacker_card.card_name, " (", pierce_attack_value, ") vs ", defender_card.card_name, " (", defense_value, ")")
	
	if pierce_attack_value > defense_value:
		# Check for cheat death / survival BEFORE capturing
		var cheat_death_prevented = game_manager.check_for_cheat_death(defender_pos, defender_card, attacker_pos, attacker_card)
		
		if cheat_death_prevented:
			print("    Capture prevented by Survival/Cheat Death!")
			return 0
		
		# Execute the capture using game manager's ownership change method
		var attacking_owner = game_manager.get_owner_at_position(attacker_pos)
		game_manager.set_card_ownership(defender_pos, attacking_owner)
		
		# Update board visuals to show the capture
		game_manager.update_board_visuals()
		
		print("    Capture successful!")
		return 1
	else:
		print("    Combat failed - no capture")
		return 0

func get_position_in_direction(grid_position: int, direction: int, distance: int, game_manager) -> int:
	"""Get position that is 'distance' squares away in the specified direction"""
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	match direction:
		0: # North
			var target_y = grid_y - distance
			if target_y >= 0:
				return target_y * grid_size + grid_x
		1: # East
			var target_x = grid_x + distance
			if target_x < grid_size:
				return grid_y * grid_size + target_x
		2: # South
			var target_y = grid_y + distance
			if target_y < grid_size:
				return target_y * grid_size + grid_x
		3: # West
			var target_x = grid_x - distance
			if target_x >= 0:
				return grid_y * grid_size + target_x
	
	return -1  # Out of bounds

func get_opposite_direction(direction: int) -> int:
	"""Get the opposite direction (for defense calculations)"""
	match direction:
		0: return 2  # North -> South
		1: return 3  # East -> West
		2: return 0  # South -> North
		3: return 1  # West -> East
		_: return -1

func get_direction_name(direction: int) -> String:
	match direction:
		0: return "North"
		1: return "East"
		2: return "South"
		3: return "West"
		_: return "Unknown"

func can_execute(context: Dictionary) -> bool:
	return true
