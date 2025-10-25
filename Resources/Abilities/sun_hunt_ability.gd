# res://Resources/Abilities/sun_hunt_ability.gd
class_name SunHuntAbility
extends CardAbility

func _init():
	ability_name = "Sun Hunt"
	description = "This card has double attack effectiveness when attacking an enemy in a sun spot"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SunHuntAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SunHuntAbility: Missing required context data")
		return false
	
	# Check if sun power is active
	if game_manager.active_deck_power != DeckDefinition.DeckPowerType.SUN_POWER:
		print("SunHuntAbility: No sun power active")
		return false
	
	# Check for darkness shroud (which would negate sun effects)
	if game_manager.darkness_shroud_active:
		print("SunHuntAbility: Darkness shroud blocks sun hunt")
		return false
	
	print("SunHuntAbility: Sun Hunt ready - will check adjacent enemies for sun spot placement")
	
	# Check all four adjacent positions for enemy cards in sun spots
	var adjacent_offsets = [
		-3,  # North
		1,   # East
		3,   # South
		-1   # West
	]
	
	var hunted_enemies = []
	
	for i in range(adjacent_offsets.size()):
		var adjacent_pos = grid_position + adjacent_offsets[i]
		
		# Skip if out of bounds
		if adjacent_pos < 0 or adjacent_pos >= 9:
			continue
		
		# Skip if wrapping around grid edges
		if i == 1 and grid_position % 3 == 2:  # East wrap
			continue
		if i == 3 and grid_position % 3 == 0:  # West wrap
			continue
		
		# Check if enemy card exists at this position
		if not game_manager.grid_occupied[adjacent_pos]:
			continue
		
		if game_manager.grid_ownership[adjacent_pos] != game_manager.Owner.OPPONENT:
			continue
		
		# Check if this enemy is in a sun spot
		if adjacent_pos in game_manager.sunlit_positions:
			hunted_enemies.append(adjacent_pos)
			print("🌟 SUN HUNT TARGET FOUND! Enemy at position ", adjacent_pos, " is in a sun spot")
	
	# If we found any hunted enemies, apply doubled damage
	if not hunted_enemies.is_empty():
		print("☀️ SUN HUNT ACTIVATED! Doubling attack values for targets in sun spots")
		
		# Get the direction indices that correspond to the hunted enemies
		for enemy_pos in hunted_enemies:
			var offset = enemy_pos - grid_position
			var direction_index = -1
			
			if offset == -3:
				direction_index = 0  # North
			elif offset == 1:
				direction_index = 1  # East
			elif offset == 3:
				direction_index = 2  # South
			elif offset == -1:
				direction_index = 3  # West
			
			if direction_index != -1:
				var original_value = placed_card.values[direction_index]
				placed_card.values[direction_index] *= 2
				print("Sun Hunt: Doubled ", ["North", "East", "South", "West"][direction_index], 
					  " attack from ", original_value, " to ", placed_card.values[direction_index])
		
		# Update the visual display
		var slot = game_manager.grid_slots[grid_position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = placed_card
				child.update_display()
				print("SunHuntAbility: Updated CardDisplay visual for sun hunting card")
				break
		
		return true
	else:
		print("SunHuntAbility: No adjacent enemies in sun spots found")
		return false

func can_execute(context: Dictionary) -> bool:
	return true
