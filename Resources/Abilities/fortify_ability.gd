# res://Resources/Abilities/fortify_ability.gd
class_name FortifyAbility
extends CardAbility

func _init():
	ability_name = "Fortify"
	description = "When this card is in a corner slot it has +2 stats."
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var fortifying_card = context.get("boosting_card")
	var fortifying_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("FortifyAbility: Action = ", action, " for card at position ", fortifying_position)
	
	if not fortifying_card or fortifying_position == -1 or not game_manager:
		print("FortifyAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_fortify(fortifying_position, fortifying_card, game_manager)
		"remove":
			return remove_fortify(fortifying_position, fortifying_card, game_manager)
		_:
			print("FortifyAbility: Unknown action: ", action)
			return false

func apply_fortify(position: int, card: CardResource, game_manager) -> bool:
	# Check if this position is a corner slot (0, 2, 6, 8 in 3x3 grid)
	if not is_corner_position(position):
		print("Fortify not applied - position ", position, " is not a corner slot")
		return false
	
	print("Fortify activated for ", card.card_name, " at corner position ", position)
	
	# Check if already active to prevent multiple applications
	if card.has_meta("fortify_active") and card.get_meta("fortify_active"):
		print("Fortify already active - skipping")
		return false
	
	# Store original values if not already stored
	if not card.has_meta("fortify_original_values"):
		card.set_meta("fortify_original_values", card.values.duplicate())
		print("Stored original values: ", card.get_meta("fortify_original_values"))
	
	# Add +2 to all stats from original values
	var original_values = card.get_meta("fortify_original_values")
	for direction in range(4):
		card.values[direction] = original_values[direction] + 2
	
	# Mark as active
	card.set_meta("fortify_active", true)
	
	print("Stats fortified to: ", card.values, " (added +2 to all directions)")
	
	# Update visual display
	game_manager.update_card_display(position, card)
	
	return true

func remove_fortify(position: int, card: CardResource, game_manager) -> bool:
	print("Removing fortify from ", card.card_name, " at position ", position)
	
	# Check if fortify was active
	if not card.has_meta("fortify_active") or not card.get_meta("fortify_active"):
		print("Fortify was not active - nothing to remove")
		return false
	
	# Restore original values
	if card.has_meta("fortify_original_values"):
		var original_values = card.get_meta("fortify_original_values")
		for direction in range(4):
			card.values[direction] = original_values[direction]
		print("Stats restored to original: ", card.values)
	else:
		print("Warning: No original values stored for fortify removal")
	
	# Mark as inactive
	card.set_meta("fortify_active", false)
	
	# Update visual display
	game_manager.update_card_display(position, card)
	
	return true

func is_corner_position(position: int) -> bool:
	# In a 3x3 grid, corner positions are: 0, 2, 6, 8
	# Top-left: 0, Top-right: 2, Bottom-left: 6, Bottom-right: 8
	return position in [0, 2, 6, 8]

func can_execute(context: Dictionary) -> bool:
	return true
