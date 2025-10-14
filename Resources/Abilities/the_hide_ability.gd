# res://Resources/Abilities/the_hide_ability.gd
class_name TheHideAbility
extends CardAbility

func _init():
	ability_name = "The Hide"
	description = "This card can only be captured if surrounded"
	trigger_condition = TriggerType.ON_DEFEND

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get context information
	var defending_card = context.get("defending_card")
	var defending_position = context.get("defending_position", -1)
	var attacking_card = context.get("attacking_card")
	var attacking_position = context.get("attacking_position", -1)
	var game_manager = context.get("game_manager")
	
	print("TheHideAbility: Starting execution for ", defending_card.card_name if defending_card else "unknown card", " at position ", defending_position)
	
	# Safety checks
	if not defending_card or defending_position == -1 or not game_manager:
		print("TheHideAbility: Missing required context data")
		return false
	
	# Check if the Nemean Lion is fully surrounded
	var is_surrounded = check_if_surrounded(defending_position, attacking_position, game_manager)
	
	if is_surrounded:
		print("TheHideAbility: Nemean Lion is SURROUNDED - can be captured!")
		return false  # Allow capture to proceed
	else:
		print("TheHideAbility: Nemean Lion is NOT surrounded - hide prevents capture!")
		
		# Set flag in game manager to prevent capture for this specific position
		game_manager.set_meta("cheat_death_prevented_" + str(defending_position), true)
		
		print(ability_name, " activated! ", defending_card.card_name, "'s impenetrable hide prevented capture!")
		return true

func check_if_surrounded(defending_position: int, attacking_position: int, game_manager) -> bool:
	"""
	Check if all orthogonal adjacent slots are filled.
	The attacking card counts as filling a slot since it will occupy that position.
	"""
	var grid_size = game_manager.grid_size
	var grid_x = defending_position % grid_size
	var grid_y = defending_position / grid_size
	
	var total_adjacent_slots = 0
	var filled_slots = 0
	
	# Check all 4 orthogonal directions
	var directions = [
		{"dx": 0, "dy": -1, "name": "North"},   # North
		{"dx": 1, "dy": 0, "name": "East"},     # East
		{"dx": 0, "dy": 1, "name": "South"},    # South
		{"dx": -1, "dy": 0, "name": "West"}     # West
	]
	
	for dir_info in directions:
		var adj_x = grid_x + dir_info.dx
		var adj_y = grid_y + dir_info.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds (board edges don't count as adjacent slots)
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			total_adjacent_slots += 1
			
			# Check if this slot is filled
			# Either it's already occupied OR it's the attacking position
			if game_manager.grid_occupied[adj_index] or adj_index == attacking_position:
				filled_slots += 1
				print("TheHideAbility: ", dir_info.name, " (pos ", adj_index, "): FILLED")
			else:
				print("TheHideAbility: ", dir_info.name, " (pos ", adj_index, "): EMPTY")
		else:
			print("TheHideAbility: ", dir_info.name, ": OUT OF BOUNDS (doesn't count)")
	
	print("TheHideAbility: Filled slots: ", filled_slots, " / ", total_adjacent_slots)
	
	# The Lion is surrounded if ALL adjacent slots are filled
	return filled_slots == total_adjacent_slots

func can_execute(context: Dictionary) -> bool:
	var defending_card = context.get("defending_card")
	if not defending_card:
		return false
	
	# This ability always checks (no usage limit like Cheat Death)
	return true
