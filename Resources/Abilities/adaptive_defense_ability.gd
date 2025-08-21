# res://Resources/Abilities/adaptive_defense_ability.gd
class_name AdaptiveDefenseAbility
extends CardAbility

func _init():
	ability_name = "Adaptive Defense"
	description = "This card's stats are doubled when it's the opponent's turn"
	trigger_condition = TriggerType.PASSIVE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var action = context.get("passive_action", "")
	var defending_card = context.get("boosting_card")
	var defending_position = context.get("boosting_position", -1)
	var game_manager = context.get("game_manager")
	
	print("AdaptiveDefenseAbility: Action = ", action, " for card at position ", defending_position)
	
	if not defending_card or defending_position == -1 or not game_manager:
		print("AdaptiveDefenseAbility: Missing required context data")
		return false
	
	match action:
		"apply":
			return apply_adaptive_defense(defending_position, defending_card, game_manager)
		"remove":
			return remove_adaptive_defense(defending_position, defending_card, game_manager)
		_:
			print("AdaptiveDefenseAbility: Unknown action: ", action)
			return false

func apply_adaptive_defense(position: int, card: CardResource, game_manager) -> bool:
	print("Adaptive Defense activated for ", card.card_name, " at position ", position)
	
	# Check if already active to prevent multiple applications
	if card.has_meta("adaptive_defense_active") and card.get_meta("adaptive_defense_active"):
		print("Adaptive Defense already active - skipping")
		return false
	
	# Store original values if not already stored
	if not card.has_meta("adaptive_defense_original_values"):
		card.set_meta("adaptive_defense_original_values", card.values.duplicate())
		print("Stored original values: ", card.get_meta("adaptive_defense_original_values"))
	
	# Double all stats from original values
	var original_values = card.get_meta("adaptive_defense_original_values")
	for direction in range(4):
		card.values[direction] = original_values[direction] * 2
	
	# Mark as active
	card.set_meta("adaptive_defense_active", true)
	
	print("Stats doubled to: ", card.values)
	
	# Update visual display
	game_manager.update_card_display(position, card)
	
	# Start passive pulse effect to show the ability is active
	var card_display = game_manager.get_card_display_at_position(position)
	if card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.start_passive_pulse(card_display)
	
	return true

func remove_adaptive_defense(position: int, card: CardResource, game_manager) -> bool:
	print("Adaptive Defense deactivated for ", card.card_name, " at position ", position)
	
	# Check if actually active
	if not (card.has_meta("adaptive_defense_active") and card.get_meta("adaptive_defense_active")):
		print("Adaptive Defense not active - skipping removal")
		return false
	
	# Restore original values if they were stored
	if card.has_meta("adaptive_defense_original_values"):
		var original_values = card.get_meta("adaptive_defense_original_values")
		card.values = original_values.duplicate()
		print("Stats restored to original: ", card.values)
	else:
		# Fallback: halve current values
		for direction in range(4):
			card.values[direction] = max(1, card.values[direction] / 2)
		print("Stats halved (fallback): ", card.values)
	
	# Mark as inactive
	card.set_meta("adaptive_defense_active", false)
	
	# Update visual display
	game_manager.update_card_display(position, card)
	
	# Stop passive pulse effect
	var card_display = game_manager.get_card_display_at_position(position)
	if card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.stop_passive_pulse(card_display)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
