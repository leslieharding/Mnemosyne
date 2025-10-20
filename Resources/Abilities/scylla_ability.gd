# res://Resources/Abilities/scylla_ability.gd
class_name ScyllaAbility
extends CardAbility

func _init():
	ability_name = "Six Heads"
	description = "On play randomly reduce 6 enemy stats by 1"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("ScyllaAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("ScyllaAbility: Missing required context data")
		return false
	
	# Determine who played Scylla to identify enemies
	var scylla_owner = game_manager.get_owner_at_position(grid_position)
	var enemy_owner = game_manager.Owner.OPPONENT if scylla_owner == game_manager.Owner.PLAYER else game_manager.Owner.PLAYER
	
	# Find all enemy cards on the board
	var enemy_positions = []
	for i in range(game_manager.grid_occupied.size()):
		if game_manager.grid_occupied[i] and game_manager.grid_ownership[i] == enemy_owner:
			enemy_positions.append(i)
	
	print("ScyllaAbility: Found ", enemy_positions.size(), " enemy cards on the board")
	
	# If no enemies on board, ability does nothing
	if enemy_positions.is_empty():
		print("ScyllaAbility: No enemy cards to target - ability has no effect")
		return true
	
	print("ScyllaAbility activated! Scylla's six heads strike!")
	
	# Perform 6 strikes
	for strike in range(6):
		# Pick a random enemy card
		var random_enemy_index = randi() % enemy_positions.size()
		var target_position = enemy_positions[random_enemy_index]
		var target_card = game_manager.get_card_at_position(target_position)
		
		if not target_card:
			print("ScyllaAbility: Warning - no card found at position ", target_position)
			continue
		
		# Pick a random stat (0=North, 1=East, 2=South, 3=West)
		var random_stat = randi() % 4
		var stat_names = ["North", "East", "South", "West"]
		
		# Store original value
		var original_value = target_card.values[random_stat]
		
		# Reduce by 1, minimum 0
		target_card.values[random_stat] = max(0, target_card.values[random_stat] - 1)
		
		print("ScyllaAbility: Strike ", strike + 1, "/6 - Hit ", target_card.card_name, " at position ", target_position, 
			  " - ", stat_names[random_stat], " reduced from ", original_value, " to ", target_card.values[random_stat])
		
		# Update the visual display for this card
		var slot = game_manager.grid_slots[target_position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = target_card
				child.update_display()
				break
	
	print("ScyllaAbility: All 6 strikes complete!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
