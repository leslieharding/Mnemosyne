# res://Resources/Abilities/harmony_ability.gd
class_name HarmonyAbility
extends CardAbility

func _init():
	ability_name = "Harmony"
	description = "If at least two defending enemies have the same stats as me they are both captured"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("HarmonyAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("HarmonyAbility: Missing required context data")
		return false
	
	# Find all adjacent enemies that would result in draws
	var harmony_targets = find_harmony_targets(placed_card, grid_position, game_manager)
	
	if harmony_targets.size() < 2:
		print("HarmonyAbility: Only ", harmony_targets.size(), " harmony targets found - need at least 2")
		return false
	
	print("HarmonyAbility activated! Found ", harmony_targets.size(), " enemies with matching stats - capturing all!")
	
	# Capture all harmony targets
	for target_data in harmony_targets:
		capture_harmony_target(target_data, placed_card, grid_position, game_manager)
	
	return true

func find_harmony_targets(attacking_card: CardResource, grid_position: int, game_manager) -> Array[Dictionary]:
	var harmony_targets: Array[Dictionary] = []
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
					
					print("HarmonyAbility: Checking ", direction.name, " - My ", my_attack_value, " vs Their ", their_defense_value)
					
					# Check for exact match (draw condition)
					if my_attack_value == their_defense_value:
						print("HarmonyAbility: Found harmony target at ", adj_index, " - ", adjacent_card.card_name)
						harmony_targets.append({
							"position": adj_index,
							"card": adjacent_card,
							"direction": direction.name,
							"attack_value": my_attack_value,
							"defense_value": their_defense_value
						})
	
	return harmony_targets

func capture_harmony_target(target_data: Dictionary, attacking_card: CardResource, attacker_position: int, game_manager):
	var target_position = target_data.position
	var target_card = target_data.card
	var attacking_owner = game_manager.get_owner_at_position(attacker_position)
	
	print("HarmonyAbility: Capturing ", target_card.card_name, " at position ", target_position, " through harmony")
	
	# Change ownership to the attacking player
	game_manager.set_card_ownership(target_position, attacking_owner)
	
	# Show visual effect for harmony capture (optional - will fall back gracefully if method doesn't exist)
	var target_card_display = game_manager.get_card_display_at_position(target_position)
	if target_card_display and game_manager.visual_effects_manager:
		if game_manager.visual_effects_manager.has_method("show_harmony_capture_flash"):
			game_manager.visual_effects_manager.show_harmony_capture_flash(target_card_display)
		else:
			# Fallback to regular capture flash with harmony color
			game_manager.visual_effects_manager.flash_card_edge(target_card_display, "all", Color("#FFD700"))  # Gold color for harmony
	
	# Award experience for harmony capture
	if attacking_owner == game_manager.Owner.PLAYER:
		var attacking_card_index = game_manager.get_card_collection_index(attacker_position)
		if attacking_card_index != -1:
			var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(attacking_card_index, 12)  # Bonus exp for harmony capture
				print("Harmony capture awarded 12 exp to card at collection index ", attacking_card_index)
	
	# Execute ON_CAPTURE abilities on the captured card
	var target_card_collection_index = game_manager.get_card_collection_index(target_position)
	var target_card_level = game_manager.get_card_level(target_card_collection_index)
	
	if target_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, target_card_level):
		print("HarmonyAbility: Executing ON_CAPTURE abilities for harmony-captured card: ", target_card.card_name)
		
		var capture_context = {
			"capturing_card": attacking_card,
			"capturing_position": attacker_position,
			"captured_card": target_card,
			"captured_position": target_position,
			"game_manager": game_manager,
			"direction": target_data.direction,
			"card_level": target_card_level
		}
		
		target_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, target_card_level)

func can_execute(context: Dictionary) -> bool:
	return true
