# res://Resources/Abilities/charm_ability.gd
class_name CharmAbility
extends CardAbility

func _init():
	ability_name = "Charm"
	description = "On play this card draws in distant enemies then attacks them."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("CharmAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("CharmAbility: Missing required context data")
		return false
	
	var charm_owner = game_manager.get_owner_at_position(grid_position)
	var charmed_enemies = find_charmable_enemies(grid_position, game_manager, charm_owner)
	
	if charmed_enemies.is_empty():
		print("CharmAbility: No enemies found to charm")
		return false
	
	print("CharmAbility: Found ", charmed_enemies.size(), " enemies to charm")
	
	# Move each charmed enemy to adjacent position and resolve combat
	var total_movements = 0
	for charm_data in charmed_enemies:
		if execute_charm_movement(charm_data, game_manager):
			total_movements += 1
	
	if total_movements > 0:
		print("CharmAbility activated! ", placed_card.card_name, " charmed ", total_movements, " enemies into combat")
		return true
	else:
		print("CharmAbility had no effect - no enemies could be moved")
		return false

func find_charmable_enemies(grid_position: int, game_manager, charm_owner) -> Array[Dictionary]:
	var charmable_enemies: Array[Dictionary] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	
	# Check all 4 orthogonal directions
	var directions = [
		{"dx": 0, "dy": -1, "direction": 0, "name": "North"},   # North
		{"dx": 1, "dy": 0, "direction": 1, "name": "East"},    # East
		{"dx": 0, "dy": 1, "direction": 2, "name": "South"},   # South
		{"dx": -1, "dy": 0, "direction": 3, "name": "West"}    # West
	]
	
	for dir_info in directions:
		# Check position 1 space away (gap position)
		var gap_x = grid_x + dir_info.dx
		var gap_y = grid_y + dir_info.dy
		var gap_index = gap_y * grid_size + gap_x
		
		# Check position 2 spaces away (enemy position)
		var enemy_x = grid_x + (dir_info.dx * 2)
		var enemy_y = grid_y + (dir_info.dy * 2)
		var enemy_index = enemy_y * grid_size + enemy_x
		
		# Validate positions are within bounds
		if (gap_x >= 0 and gap_x < grid_size and gap_y >= 0 and gap_y < grid_size and \
			enemy_x >= 0 and enemy_x < grid_size and enemy_y >= 0 and enemy_y < grid_size):
			
			# Check if gap position is empty and enemy position has an enemy card
			if not game_manager.grid_occupied[gap_index] and game_manager.grid_occupied[enemy_index]:
				var enemy_owner = game_manager.get_owner_at_position(enemy_index)
				
				# Only charm enemy cards (different owner and not neutral)
				if enemy_owner != game_manager.Owner.NONE and enemy_owner != charm_owner:
					var enemy_card = game_manager.get_card_at_position(enemy_index)
					
					if enemy_card:
						var charm_data = {
							"enemy_position": enemy_index,
							"enemy_card": enemy_card,
							"gap_position": gap_index,
							"charm_position": grid_position,
							"direction": dir_info.direction,
							"direction_name": dir_info.name
						}
						
						charmable_enemies.append(charm_data)
						print("CharmAbility: Found charmable enemy ", enemy_card.card_name, " at position ", enemy_index, " (", dir_info.name, ")")
	
	return charmable_enemies

func execute_charm_movement(charm_data: Dictionary, game_manager) -> bool:
	var enemy_position = charm_data.enemy_position
	var gap_position = charm_data.gap_position
	var enemy_card = charm_data.enemy_card
	var direction_name = charm_data.direction_name
	
	print("CharmAbility: Moving ", enemy_card.card_name, " from position ", enemy_position, " to ", gap_position, " (", direction_name, ")")
	
	# Get the visual card display before we move data structures
	var card_display = game_manager.get_card_display_at_position(enemy_position)
	if not card_display:
		print("CharmAbility: No card display found at enemy position ", enemy_position)
		return false
	
	# Get enemy data before moving
	var enemy_owner = game_manager.get_owner_at_position(enemy_position)
	
	# Update grid_to_collection_index mapping if it exists
	var collection_index = -1
	if "grid_to_collection_index" in game_manager:
		collection_index = game_manager.grid_to_collection_index.get(enemy_position, -1)
		if collection_index != -1:
			game_manager.grid_to_collection_index[gap_position] = collection_index
			game_manager.grid_to_collection_index.erase(enemy_position)
	
	# Update data structures
	# Clear source position
	game_manager.grid_occupied[enemy_position] = false
	game_manager.grid_ownership[enemy_position] = game_manager.Owner.NONE
	game_manager.grid_card_data[enemy_position] = null
	
	# Set target position
	game_manager.grid_occupied[gap_position] = true
	game_manager.grid_ownership[gap_position] = enemy_owner
	game_manager.grid_card_data[gap_position] = enemy_card
	
	# Move the visual display
	var source_slot = game_manager.grid_slots[enemy_position]
	var target_slot = game_manager.grid_slots[gap_position]
	
	# Remove card display from source slot
	source_slot.remove_child(card_display)
	
	# Add card display to target slot
	target_slot.add_child(card_display)
	
	# Apply correct styling to target slot based on owner
	if enemy_owner == game_manager.Owner.PLAYER:
		target_slot.add_theme_stylebox_override("panel", game_manager.player_card_style)
	else:
		target_slot.add_theme_stylebox_override("panel", game_manager.opponent_card_style)
	
	# Clear styling from source slot (reset to default)
	source_slot.add_theme_stylebox_override("panel", game_manager.default_grid_style)
	
	print("CharmAbility: Successfully moved card data structures and visual display")
	
	# Now resolve combat between charm card and the moved enemy
	var charm_position = charm_data.charm_position
	var charm_card = game_manager.get_card_at_position(charm_position)
	var charm_owner = game_manager.get_owner_at_position(charm_position)
	var direction = charm_data.direction
	
	# Calculate combat values
	var charm_attack = charm_card.values[direction]
	var enemy_defense = enemy_card.values[get_opposite_direction(direction)]
	
	print("CharmAbility Combat: ", charm_card.card_name, " (", charm_attack, ") vs ", enemy_card.card_name, " (", enemy_defense, ")")
	
	if charm_attack > enemy_defense:
		# Charm card wins - capture the enemy
		game_manager.set_card_ownership(gap_position, charm_owner)
		print("CharmAbility: ", charm_card.card_name, " successfully charmed and captured ", enemy_card.card_name, "!")
		
		# Update visuals again to show ownership change
		game_manager.update_board_visuals()
	else:
		print("CharmAbility: ", charm_card.card_name, " failed to capture ", enemy_card.card_name, " but enemy was still moved")
	
	return true

func get_opposite_direction(direction: int) -> int:
	"""Get the opposite direction for combat calculations"""
	match direction:
		0: return 2  # North -> South
		1: return 3  # East -> West
		2: return 0  # South -> North
		3: return 1  # West -> East
		_: return -1

func can_execute(context: Dictionary) -> bool:
	return true
