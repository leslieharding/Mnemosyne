# res://Resources/Abilities/pursuit_ability.gd
class_name PursuitAbility
extends CardAbility

func _init():
	ability_name = "Pursuit"
	description = "If this card can capture, it attacks cards played in the same row/column and moves adjacent to them."
	trigger_condition = TriggerType.PASSIVE  # We'll use PASSIVE since we need custom triggering

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Check if this is a passive ability setup call (when card is first placed)
	var passive_action = context.get("passive_action", "")
	if passive_action == "apply" or passive_action == "remove":
		# This is just passive ability management - Pursuit doesn't need to do anything here
		print("PursuitAbility: Passive ability setup - no action needed")
		return true
	
	var pursuit_card = context.get("pursuit_card")
	var pursuit_position = context.get("pursuit_position", -1)
	var target_card = context.get("target_card")
	var target_position = context.get("target_position", -1)
	var game_manager = context.get("game_manager")
	var move_to_position = context.get("move_to_position", -1)
	var direction = context.get("direction", -1)
	
	print("PursuitAbility: Starting execution")
	print("  Pursuit card: ", pursuit_card.card_name if pursuit_card else "none", " at position ", pursuit_position)
	print("  Target card: ", target_card.card_name if target_card else "none", " at position ", target_position)
	print("  Move to position: ", move_to_position)
	print("  Attack direction: ", direction)
	
	if not pursuit_card or pursuit_position == -1 or not target_card or target_position == -1 or not game_manager or move_to_position == -1 or direction == -1:
		print("PursuitAbility: Missing required context data")
		return false
	
	# Step 1: Move the pursuit card to the new position
	if not move_pursuit_card(pursuit_position, move_to_position, pursuit_card, game_manager):
		print("PursuitAbility: Failed to move pursuit card")
		return false
	
	print("PursuitAbility: Successfully moved ", pursuit_card.card_name, " from position ", pursuit_position, " to position ", move_to_position)
	
	# Step 2: Attempt normal combat from the new position
	var combat_result = attempt_pursuit_combat(move_to_position, target_position, direction, pursuit_card, target_card, game_manager)
	
	if combat_result:
		print("PursuitAbility: Successfully captured target!")
	else:
		print("PursuitAbility: Combat failed or target defended successfully")
	
	return true

func move_pursuit_card(from_position: int, to_position: int, card: CardResource, game_manager) -> bool:
	"""Move a card from one position to another, updating all data structures"""
	
	print("Moving card from position ", from_position, " to position ", to_position)
	
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

func attempt_pursuit_combat(attacker_position: int, defender_position: int, direction: int, attacker_card: CardResource, defender_card: CardResource, game_manager) -> bool:
	"""Attempt combat between pursuit card and target, following normal combat rules"""
	
	print("Attempting pursuit combat: position ", attacker_position, " attacking position ", defender_position, " in direction ", direction)
	
	var attacker_value = attacker_card.values[direction]
	var defender_direction = get_opposite_direction(direction)
	var defender_value = defender_card.values[defender_direction]
	
	print("Combat values: Attacker (", get_direction_name(direction), ") = ", attacker_value, " vs Defender (", get_direction_name(defender_direction), ") = ", defender_value)
	
	# Check if attacker wins
	if attacker_value > defender_value:
		print("Pursuit combat successful! Capturing target.")
		
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
		
		# Award experience if player's pursuit card captured
		if attacker_owner == 1:  # 1 = PLAYER in the Owner enum
			var attacker_collection_index = game_manager.get_card_collection_index(attacker_position)
			if attacker_collection_index != -1:
				var exp_tracker = game_manager.get_node_or_null("/root/RunExperienceTrackerAutoload")
				if exp_tracker:
					exp_tracker.add_capture_exp(attacker_collection_index, 10)
					print("Pursuit capture awarded 10 exp to card at collection index ", attacker_collection_index)
		
		# Update board visuals
		game_manager.update_board_visuals()
		game_manager.update_game_status()
		
		return true
	else:
		print("Pursuit combat failed - defender wins or ties")
		
		# Check for defensive abilities on the defending card
		var defender_collection_index = game_manager.get_card_collection_index(defender_position)
		var defender_card_level = 1  # Default level
		if defender_collection_index != -1:
			defender_card_level = game_manager.get_card_level(defender_collection_index)
		
		if defender_card.has_ability_type(CardAbility.TriggerType.ON_DEFEND, defender_card_level):
			print("Executing ON_DEFEND abilities for defending card: ", defender_card.card_name)
			
			var defend_context = {
				"defending_card": defender_card,
				"defending_position": defender_position,
				"attacking_card": attacker_card,
				"attacking_position": attacker_position,
				"game_manager": game_manager,
				"direction": get_direction_name(direction),
				"card_level": defender_card_level
			}
			
			defender_card.execute_abilities(CardAbility.TriggerType.ON_DEFEND, defend_context, defender_card_level)
		
		return false

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
