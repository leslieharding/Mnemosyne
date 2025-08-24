# res://Resources/Abilities/symmetry_ability.gd
class_name SymmetryAbility
extends CardAbility

func _init():
	ability_name = "Symmetry"
	description = "If you are fighting atleast two enemies and the sum of the attacking stats versus defending stats is exactly the same, they are captured"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("SymmetryAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("SymmetryAbility: Missing required context data")
		return false
	
	# Find all adjacent enemy combat pairs
	var combat_pairs = find_adjacent_combat_pairs(placed_card, grid_position, game_manager)
	
	if combat_pairs.size() < 2:
		print("SymmetryAbility: Only ", combat_pairs.size(), " adjacent enemies found - need at least 2")
		return false
	
	# Check if all pairs have the same sum
	if not all_pairs_have_same_sum(combat_pairs):
		print("SymmetryAbility: Combat pair sums are not all equal - no symmetry")
		return false
	
	print("SymmetryAbility activated! All ", combat_pairs.size(), " combat pairs have equal sums - capturing all enemies!")
	
	# Capture all enemy cards that were part of the symmetry
	for pair_data in combat_pairs:
		capture_symmetry_target(pair_data, placed_card, grid_position, game_manager)
	
	return true

func find_adjacent_combat_pairs(attacking_card: CardResource, grid_position: int, game_manager) -> Array[Dictionary]:
	var combat_pairs: Array[Dictionary] = []
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	var attacking_owner = game_manager.get_owner_at_position(grid_position)
	
	# Check all 4 adjacent positions
	var directions = [
		{"dx": 0, "dy": -1, "my_value_index": 0, "their_value_index": 2, "name": "North"},
		{"dx": 1, "dy": 0, "my_value_index": 1, "their_value_index": 3, "name": "East"},
		{"dx": 0, "dy": 1, "my_value_index": 2, "their_value_index": 0, "name": "South"},
		{"dx": -1, "dy": 0, "my_value_index": 3, "their_value_index": 1, "name": "West"}
	]
	
	for direction in directions:
		var adj_x = grid_x + direction.dx
		var adj_y = grid_y + direction.dy
		var adj_index = adj_y * grid_size + adj_x
		
		# Check if adjacent position is within bounds and occupied
		if adj_x >= 0 and adj_x < grid_size and adj_y >= 0 and adj_y < grid_size:
			if game_manager.grid_occupied[adj_index]:
				var adjacent_owner = game_manager.get_owner_at_position(adj_index)
				
				# Only consider enemy cards
				if adjacent_owner != game_manager.Owner.NONE and adjacent_owner != attacking_owner:
					var adjacent_card = game_manager.get_card_at_position(adj_index)
					
					if not adjacent_card:
						continue
					
					var my_attack_value = attacking_card.values[direction.my_value_index]
					var their_defense_value = adjacent_card.values[direction.their_value_index]
					var combat_sum = my_attack_value + their_defense_value
					
					print("SymmetryAbility: ", direction.name, " - Attack ", my_attack_value, " + Defense ", their_defense_value, " = ", combat_sum)
					
					combat_pairs.append({
						"position": adj_index,
						"card": adjacent_card,
						"direction": direction.name,
						"attack_value": my_attack_value,
						"defense_value": their_defense_value,
						"combat_sum": combat_sum
					})
	
	return combat_pairs

func all_pairs_have_same_sum(combat_pairs: Array[Dictionary]) -> bool:
	if combat_pairs.is_empty():
		return false
	
	# Get the sum from the first pair as the reference
	var reference_sum = combat_pairs[0].combat_sum
	
	# Check if all other pairs have the same sum
	for pair in combat_pairs:
		if pair.combat_sum != reference_sum:
			print("SymmetryAbility: Sum mismatch - ", pair.combat_sum, " != ", reference_sum)
			return false
	
	print("SymmetryAbility: All pairs have matching sum: ", reference_sum)
	return true

func capture_symmetry_target(pair_data: Dictionary, attacking_card: CardResource, attacker_position: int, game_manager):
	var target_position = pair_data.position
	var target_card = pair_data.card
	var attacking_owner = game_manager.get_owner_at_position(attacker_position)
	
	print("SymmetryAbility: Capturing ", target_card.card_name, " at position ", target_position, " through symmetry")
	
	# Change ownership to the attacking player
	game_manager.set_card_ownership(target_position, attacking_owner)
	
	# Show visual effect for symmetry capture
	var target_card_display = game_manager.get_card_display_at_position(target_position)
	if target_card_display and game_manager.visual_effects_manager:
		if game_manager.visual_effects_manager.has_method("show_symmetry_capture_flash"):
			game_manager.visual_effects_manager.show_symmetry_capture_flash(target_card_display)
		else:
			# Fallback to regular capture flash with symmetry color
			game_manager.visual_effects_manager.flash_card_edge(target_card_display, "all", Color("#00FFFF"))  # Cyan color for symmetry
	
	# Award experience for symmetry capture
	if attacking_owner == game_manager.Owner.PLAYER:
		var attacking_card_index = game_manager.get_card_collection_index(attacker_position)
		if attacking_card_index != -1:
			var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(attacking_card_index, 15)  # Bonus exp for symmetry capture
				print("Symmetry capture awarded 15 exp to card at collection index ", attacking_card_index)
	
	# Execute ON_CAPTURE abilities on the captured card
	var target_card_collection_index = game_manager.get_card_collection_index(target_position)
	var target_card_level = game_manager.get_card_level(target_card_collection_index)
	
	if target_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, target_card_level):
		print("SymmetryAbility: Executing ON_CAPTURE abilities for symmetry-captured card: ", target_card.card_name)
		
		var capture_context = {
			"capturing_card": attacking_card,
			"capturing_position": attacker_position,
			"captured_card": target_card,
			"captured_position": target_position,
			"game_manager": game_manager,
			"direction": pair_data.direction,
			"card_level": target_card_level
		}
		
		target_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, target_card_level)

func can_execute(context: Dictionary) -> bool:
	return true
