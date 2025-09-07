# res://Resources/Abilities/charge_ability.gd
class_name ChargeAbility
extends CardAbility

func _init():
	ability_name = "Charge"
	description = "If there is a distant unblocked enemy in your row or column at the start of your turn, charge at and capture them"
	trigger_condition = TriggerType.PASSIVE  # We'll use PASSIVE since we need custom triggering

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Check if this is a passive ability setup call (when card is first placed)
	var passive_action = context.get("passive_action", "")
	if passive_action == "apply":
		# Only mark as "just placed" if this is a fresh placement, not a reactivation after movement
		var charge_card = context.get("boosting_card")
		var game_manager = context.get("game_manager")
		if charge_card and game_manager:
			# Check if this card already has placement metadata - if so, preserve it
			if not charge_card.has_meta("charge_placed_turn"):
				# This is a fresh placement - mark it as unable to charge this turn
				charge_card.set_meta("charge_placed_turn", game_manager.get_current_turn_number())
				print("ChargeAbility: Card freshly placed on turn ", game_manager.get_current_turn_number(), " - charging disabled for this turn")
			else:
				# This card already has placement metadata - keep the original placement turn
				var original_placement_turn = charge_card.get_meta("charge_placed_turn")
				print("ChargeAbility: Card already has placement metadata from turn ", original_placement_turn, " - preserving original placement turn")
		return true
	elif passive_action == "remove":
		# Only clean up metadata if this is a real removal (capture/destruction), not a refresh
		var charge_card = context.get("boosting_card")
		if charge_card:
			# Check if this is a refresh (re-applying abilities) vs real removal
			# During refresh, we want to keep the placement turn metadata
			var is_refresh = context.get("is_refresh", false)
			if not is_refresh:
				charge_card.remove_meta("charge_placed_turn")
				print("ChargeAbility: Charge metadata cleaned up (real removal)")
			else:
				print("ChargeAbility: Refresh detected - keeping charge placement metadata")
		return true
	
	var charge_card = context.get("charge_card")
	var charge_position = context.get("charge_position", -1)
	var target_card = context.get("target_card")
	var target_position = context.get("target_position", -1)
	var game_manager = context.get("game_manager")
	var move_to_position = context.get("move_to_position", -1)
	var direction = context.get("direction", -1)
	
	print("ChargeAbility: Starting execution")
	print("  Charge card: ", charge_card.card_name if charge_card else "none", " at position ", charge_position)
	print("  Target card: ", target_card.card_name if target_card else "none", " at position ", target_position)
	print("  Move to position: ", move_to_position)
	print("  Attack direction: ", direction)
	
	if not charge_card or charge_position == -1 or not target_card or target_position == -1 or not game_manager or move_to_position == -1 or direction == -1:
		print("ChargeAbility: Missing required context data")
		return false
	
	# Step 1: Move the charge card to the new position
	if not move_charge_card(charge_position, move_to_position, charge_card, game_manager):
		print("ChargeAbility: Failed to move charge card")
		return false
	
	print("ChargeAbility: Successfully moved ", charge_card.card_name, " from position ", charge_position, " to position ", move_to_position)
	
	# Step 2: Automatically capture the target (charge always wins)
	var capture_result = execute_charge_capture(move_to_position, target_position, direction, charge_card, target_card, game_manager)
	
	if capture_result:
		print("ChargeAbility: Successfully captured target!")
	else:
		print("ChargeAbility: Capture failed")
	
	return true

func move_charge_card(from_position: int, to_position: int, card: CardResource, game_manager) -> bool:
	"""Move a card from one position to another, updating all data structures"""
	
	print("Moving charge card from position ", from_position, " to position ", to_position)
	
	# Validate positions
	if from_position < 0 or from_position >= 9 or to_position < 0 or to_position >= 9:
		print("Invalid positions for move: from ", from_position, " to ", to_position)
		return false
	
	# Ensure source position has the card and target position is empty
	if not game_manager.grid_occupied[from_position]:
		print("Source position ", from_position, " is not occupied")
		return false
	
	if game_manager.grid_occupied[to_position]:
		print("Target position ", to_position, " is already occupied")
		return false
	
	# Get the visual card display before we move data structures
	var card_display = game_manager.get_card_display_at_position(from_position)
	if not card_display:
		print("No card display found at source position ", from_position)
		return false
	
	# Store the card owner
	var card_owner = game_manager.grid_ownership[from_position]
	
	# Get collection index if it exists
	var collection_index = -1
	if from_position in game_manager.grid_to_collection_index:
		collection_index = game_manager.grid_to_collection_index[from_position]
	
	# Update data structures
	# Clear source position
	game_manager.grid_occupied[from_position] = false
	game_manager.grid_ownership[from_position] = 0  # 0 = NEUTRAL in the Owner enum
	game_manager.grid_card_data[from_position] = null
	
	# Set target position
	game_manager.grid_occupied[to_position] = true
	game_manager.grid_ownership[to_position] = card_owner
	game_manager.grid_card_data[to_position] = card
	
	# Update collection index mapping if it exists
	if collection_index != -1:
		game_manager.grid_to_collection_index.erase(from_position)
		game_manager.grid_to_collection_index[to_position] = collection_index
	
	# Move the visual display
	var source_slot = game_manager.grid_slots[from_position]
	var target_slot = game_manager.grid_slots[to_position]
	
	# Remove card display from source slot
	source_slot.remove_child(card_display)
	
	# Add card display to target slot
	target_slot.add_child(card_display)
	
	# Apply correct styling to target slot
	if card_owner == 1:  # 1 = PLAYER in the Owner enum
		target_slot.add_theme_stylebox_override("panel", game_manager.player_card_style)
	else:
		target_slot.add_theme_stylebox_override("panel", game_manager.opponent_card_style)
	
	# Clear styling from source slot (reset to default)
	source_slot.remove_theme_stylebox_override("panel")
	
	print("Successfully moved card data structures and visual display")
	return true

func execute_charge_capture(attacker_position: int, defender_position: int, direction: int, attacker_card: CardResource, defender_card: CardResource, game_manager) -> bool:
	"""Execute charge capture - always successful regardless of stats"""
	
	print("Executing charge capture: position ", attacker_position, " charging position ", defender_position, " in direction ", direction)
	
	var attacker_value = attacker_card.values[direction]
	var defender_direction = get_opposite_direction(direction)
	var defender_value = defender_card.values[defender_direction]
	
	print("Combat values (informational): Attacker (", get_direction_name(direction), ") = ", attacker_value, " vs Defender (", get_direction_name(defender_direction), ") = ", defender_value)
	print("Charge always captures regardless of stats!")
	
	# Change ownership of the target card
	var attacker_owner = game_manager.get_owner_at_position(attacker_position)
	game_manager.set_card_ownership(defender_position, attacker_owner)
	
	# Execute ON_CAPTURE abilities on the captured card if it has any
	var defender_collection_index = game_manager.get_card_collection_index(defender_position)
	var defender_card_level = 1  # Default level, could be improved
	if defender_collection_index != -1:
		defender_card_level = game_manager.get_card_level(defender_collection_index)
	
	if defender_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, defender_card_level):
		print("Executing ON_CAPTURE abilities for captured card: ", defender_card.card_name)
		
		var capture_context = {
			"capturing_card": attacker_card,
			"capturing_position": attacker_position,
			"captured_card": defender_card,
			"captured_position": defender_position,
			"game_manager": game_manager,
			"direction": get_direction_name(direction),
			"card_level": defender_card_level
		}
		
		defender_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, defender_card_level)
	
	# Award experience if player's charge card captured
	if attacker_owner == 1:  # 1 = PLAYER in the Owner enum
		var attacker_collection_index = game_manager.get_card_collection_index(attacker_position)
		if attacker_collection_index != -1:
			var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
			if exp_tracker:
				exp_tracker.add_capture_exp(attacker_collection_index, 10)
				print("Charge capture awarded 10 exp to card at collection index ", attacker_collection_index)
	
	# Update board visuals
	game_manager.update_board_visuals()
	game_manager.update_game_status()
	
	return true

func get_opposite_direction(direction: int) -> int:
	"""Get the opposite direction for combat calculations"""
	match direction:
		0: return 2  # North -> South
		1: return 3  # East -> West
		2: return 0  # South -> North
		3: return 1  # West -> East
		_: return 0

func get_direction_name(direction: int) -> String:
	"""Get direction name for debugging"""
	match direction:
		0: return "North"
		1: return "East" 
		2: return "South"
		3: return "West"
		_: return "Unknown"

func can_execute(context: Dictionary) -> bool:
	return true
