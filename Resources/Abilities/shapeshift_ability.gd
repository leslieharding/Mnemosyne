# res://Resources/Abilities/shapeshift_ability.gd
class_name ShapeshiftAbility
extends CardAbility

func _init():
	ability_name = "Shapeshift"
	description = "After one turn transforms if not captured"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var shapeshift_card = context.get("boosting_card")
	var shapeshift_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("ShapeshiftAbility: Action = ", action, " for card at position ", shapeshift_position)
	
	if not shapeshift_card or shapeshift_position == -1 or not game_manager:
		print("ShapeshiftAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_shapeshift_tracking(shapeshift_position, shapeshift_card, game_manager)
		"remove":
			return remove_shapeshift_tracking(shapeshift_position, shapeshift_card, game_manager)
		"turn_start":
			return check_and_trigger_transform(shapeshift_position, shapeshift_card, game_manager)
		_:
			print("ShapeshiftAbility: Unknown action: ", action)
			return false

func apply_shapeshift_tracking(position: int, card: CardResource, game_manager) -> bool:
	print("Shapeshift tracking started for ", card.card_name, " at position ", position)
	
	# Only set placement owner if it doesn't exist (first time placing)
	if not card.has_meta("shapeshift_placement_owner"):
		var placement_owner = game_manager.get_owner_at_position(position)
		card.set_meta("shapeshift_placement_owner", placement_owner)
		print("Shapeshift: INITIAL placement by ", "Player" if placement_owner == 1 else "Opponent")
	else:
		print("Shapeshift: Preserving existing placement_owner = ", card.get_meta("shapeshift_placement_owner"))
	
	# Only set transformed flag if it doesn't exist
	if not card.has_meta("shapeshift_transformed"):
		card.set_meta("shapeshift_transformed", false)
	
	# Only initialize counter if it doesn't exist (preserve during refresh)
	if not card.has_meta("shapeshift_turns_survived"):
		card.set_meta("shapeshift_turns_survived", 0)
		print("Shapeshift: Initial turns_survived = 0")
	else:
		print("Shapeshift: Preserving existing turns_survived = ", card.get_meta("shapeshift_turns_survived"))
	
	# Store original stats if not already stored
	if not card.has_meta("shapeshift_original_stats"):
		card.set_meta("shapeshift_original_stats", card.values.duplicate())
	
	return true

func remove_shapeshift_tracking(position: int, card: CardResource, game_manager) -> bool:
	print("Shapeshift tracking removed for ", card.card_name, " at position ", position)
	
	# Don't clean up metadata during refresh - let it persist
	print("Shapeshift: Metadata preserved for potential re-application")
	
	return true

func check_and_trigger_transform(position: int, card: CardResource, game_manager) -> bool:
	"""Check if shapeshift should trigger transformation"""
	
	print("=== SHAPESHIFT CHECK START ===")
	print("Card: ", card.card_name, " at position ", position)
	
	# Get stored metadata
	if not card.has_meta("shapeshift_placement_owner"):
		print("ShapeshiftAbility: Missing placement metadata - ability may not be applied")
		return false
	
	# Check if already transformed
	if card.has_meta("shapeshift_transformed") and card.get_meta("shapeshift_transformed"):
		print("ShapeshiftAbility: Already transformed")
		return false
	
	var placement_owner = card.get_meta("shapeshift_placement_owner")
	var current_owner = game_manager.get_owner_at_position(position)
	
	print("Placement owner: ", placement_owner, " | Current owner: ", current_owner)
	
	# Check if ownership has changed (card was captured)
	if current_owner != placement_owner:
		print("ShapeshiftAbility: Card was captured - no transformation")
		return false
	
	# Check whose turn it is
	var is_player_turn = game_manager.turn_manager.is_player_turn()
	var player_owner = game_manager.Owner.PLAYER
	
	print("Is player turn: ", is_player_turn, " | Player owner value: ", player_owner)
	
	# Only process on the OWNER'S turn
	var is_owner_turn = (placement_owner == player_owner and is_player_turn) or (placement_owner != player_owner and not is_player_turn)
	
	print("Is owner's turn: ", is_owner_turn)
	
	if is_owner_turn:
		# Get current turn count
		var turns_survived = card.get_meta("shapeshift_turns_survived")
		print("ShapeshiftAbility: Owner's turn - turns_survived: ", turns_survived)
		
		# Increment the counter FIRST
		card.set_meta("shapeshift_turns_survived", turns_survived + 1)
		print("ShapeshiftAbility: Counter incremented to: ", turns_survived + 1)
		
		# Check if enough turns have passed
		# After increment, if counter >= 1, transform (means this is the 2nd owner turn, survived 1 cycle)
		if turns_survived + 1 >= 1:
			print("ShapeshiftAbility: *** TRIGGERING TRANSFORMATION ***")
			return trigger_transformation(position, card, game_manager)
		else:
			print("ShapeshiftAbility: Not ready yet, need counter >= 1")
	else:
		print("ShapeshiftAbility: Not owner's turn, skipping")
	
	print("=== SHAPESHIFT CHECK END ===")
	return false

func trigger_transformation(position: int, card: CardResource, game_manager) -> bool:
	"""Execute the transformation - change stats"""
	
	print("ShapeshiftAbility: Starting transformation for ", card.card_name)
	
	# Store original stats if not already stored
	if not card.has_meta("shapeshift_original_stats"):
		card.set_meta("shapeshift_original_stats", card.values.duplicate())
	
	var original_stats = card.get_meta("shapeshift_original_stats")
	print("ShapeshiftAbility: Original stats: ", original_stats)
	
	# Transform stats - for now, we'll double all stats as the transformation
	# You can customize this transformation logic as needed
	for i in range(card.values.size()):
		card.values[i] = original_stats[i] * 2
	
	print("ShapeshiftAbility: Transformed stats: ", card.values)
	
	# Mark as transformed
	card.set_meta("shapeshift_transformed", true)
	
	# Update visual display
	var slot = game_manager.grid_slots[position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = card
			child.update_display()
			print("ShapeshiftAbility: Updated CardDisplay visual for transformed card")
			break
	
	# Show notification
	if game_manager.notification_manager:
		game_manager.notification_manager.show_notification("🦎 " + card.card_name + " has shapeshifted!")
	
	print(ability_name, " activated! ", card.card_name, " has transformed!")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
