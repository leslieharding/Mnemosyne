# res://Resources/Abilities/race_ability.gd
class_name RaceAbility
extends CardAbility

# Adjustable delay for movement speed (in seconds)
var movement_delay: float = 0.5

func _init():
	ability_name = "Race"
	description = "When played this card it races to every empty slot getting more tired with every step."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("RaceAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("RaceAbility: Missing required context data")
		return false
	
	# Find all empty slots in numerical order
	var empty_slots = find_empty_slots_in_order(game_manager)
	
	if empty_slots.is_empty():
		print("RaceAbility: No empty slots found to race to")
		return false
	
	# Check if this is an AI opponent card - if so, it should always start from the lowest empty slot
	var card_owner = game_manager.get_owner_at_position(grid_position)
	var actual_starting_position = grid_position
	
	if card_owner == game_manager.Owner.OPPONENT:
		# AI opponent should always race starting from the numerically lowest empty slot
		var lowest_empty_slot = empty_slots[0]  # First slot in the sorted empty slots array
		
		if grid_position != lowest_empty_slot:
			print("RaceAbility: Moving AI card from slot ", grid_position, " to lowest empty slot ", lowest_empty_slot)
			# Use the game manager's proper move function
			game_manager.execute_race_move(grid_position, lowest_empty_slot, placed_card, card_owner)
			actual_starting_position = lowest_empty_slot
			# Update the empty slots list since we just occupied the lowest one
			empty_slots = find_empty_slots_in_order(game_manager)
	
	print("RaceAbility: Found ", empty_slots.size(), " empty slots to race through")
	
	# Start race mode to prevent turn switching and execute the sequence
	game_manager.start_race_mode(actual_starting_position, card_owner, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true

func find_empty_slots_in_order(game_manager) -> Array[int]:
	"""Find all empty slots in numerical order (0, 1, 2, 3, 4, 5, 6, 7, 8)"""
	var empty_slots: Array[int] = []
	
	# Check all 9 grid positions in order
	for i in range(9):
		if not game_manager.grid_occupied[i]:
			empty_slots.append(i)
	
	return empty_slots

func execute_race_sequence(starting_position: int, empty_slots: Array[int], racing_card: CardResource, game_manager):
	"""Execute the race through all empty slots with movement and combat"""
	var current_position = starting_position
	var movements_made = 0
	
	print("RaceAbility: Starting race sequence from position ", starting_position)
	
	# Race through each empty slot that comes AFTER the starting position
	for target_slot in empty_slots:
		# Skip the starting position and any slots before it (no backtracking)
		if target_slot <= starting_position:
			continue
		
		print("RaceAbility: Moving from slot ", current_position, " to slot ", target_slot)
		
		# Reduce power by 1 for each movement
		reduce_card_power(racing_card, 1)
		movements_made += 1
		print("RaceAbility: Card power reduced by 1 after ", movements_made, " movements")
		
		# Use the game manager's proper move function instead of simple_move_card
		game_manager.execute_race_move(current_position, target_slot, racing_card, game_manager.get_owner_at_position(current_position))
		current_position = target_slot
		
		# Update the visual display with new stats
		game_manager.update_card_display(current_position, racing_card)
		
		# Resolve combat at this position
		var captures = game_manager.resolve_combat(current_position, game_manager.get_owner_at_position(current_position), racing_card)
		if captures > 0:
			print("RaceAbility: Captured ", captures, " cards at position ", current_position)
		
		# Add delay between movements
		if movement_delay > 0:
			await game_manager.get_tree().create_timer(movement_delay).timeout
	
	print("RaceAbility: Race completed! Final position: ", current_position, " after ", movements_made, " movements")

func simple_move_card(from_position: int, to_position: int, card_data: CardResource, game_manager):
	"""Simple card move using existing game manager systems"""
	
	# Get card owner
	var card_owner = game_manager.grid_ownership[from_position]
	
	# Update grid_to_collection_index mapping if it exists
	if "grid_to_collection_index" in game_manager:
		var collection_index = game_manager.grid_to_collection_index.get(from_position, -1)
		if collection_index != -1:
			game_manager.grid_to_collection_index[to_position] = collection_index
			game_manager.grid_to_collection_index.erase(from_position)
	
	# Clear source position
	game_manager.grid_occupied[from_position] = false
	game_manager.grid_ownership[from_position] = game_manager.Owner.NONE
	game_manager.grid_card_data[from_position] = null
	
	# Set target position
	game_manager.grid_occupied[to_position] = true
	game_manager.grid_ownership[to_position] = card_owner
	game_manager.grid_card_data[to_position] = card_data
	
	# Let the game manager handle the visual updates
	game_manager.update_card_display(to_position, card_data)
	
	# Apply styling to target slot
	var to_slot = game_manager.grid_slots[to_position]
	if card_owner == game_manager.Owner.PLAYER:
		to_slot.add_theme_stylebox_override("panel", game_manager.player_card_style)
	else:
		to_slot.add_theme_stylebox_override("panel", game_manager.opponent_card_style)
	
	print("RaceAbility: Successfully moved card from slot ", from_position, " to slot ", to_position)

func reduce_card_power(card_data: CardResource, reduction_amount: int):
	"""Reduce all directional stats by the specified amount"""
	for i in range(card_data.values.size()):
		card_data.values[i] = max(0, card_data.values[i] - reduction_amount)
	
	print("RaceAbility: Reduced card stats by ", reduction_amount, ". New values: ", card_data.values)
