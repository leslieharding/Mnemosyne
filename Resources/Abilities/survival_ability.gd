# res://Resources/Abilities/survival_ability.gd
class_name SurvivalAbility
extends CardAbility

func _init():
	ability_name = "Survival"
	description = "This card prevents the first time it would be captured, but reduces its stats to 1 to do so"
	trigger_condition = TriggerType.ON_DEFEND

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Check if survival has already been used
	var defending_card = context.get("defending_card")
	if defending_card and defending_card.has_meta("survival_used") and defending_card.get_meta("survival_used"):
		print("SurvivalAbility: Already used - cannot activate again")
		return false
	
	# Get context information
	var defending_position = context.get("defending_position", -1)
	var attacking_card = context.get("attacking_card")
	var game_manager = context.get("game_manager")
	
	print("SurvivalAbility: Starting execution for ", defending_card.card_name if defending_card else "unknown card", " at position ", defending_position)
	
	# Safety checks
	if not defending_card or defending_position == -1 or not game_manager:
		print("SurvivalAbility: Missing required context data")
		return false
	
	# Mark survival as used
	defending_card.set_meta("survival_used", true)
	
	# Set flag in game manager to prevent capture for this specific position
	game_manager.set_meta("cheat_death_prevented_" + str(defending_position), true)
	
	# Store original values for logging
	var original_values = defending_card.values.duplicate()
	
	# Reduce all stats to 1
	defending_card.values[0] = 1  # North
	defending_card.values[1] = 1  # East
	defending_card.values[2] = 1  # South
	defending_card.values[3] = 1  # West
	
	print(ability_name, " activated! ", defending_card.card_name, " survived capture but stats reduced from ", original_values, " to ", defending_card.values)
	
	# Update the visual display to show the new stats
	var slot = game_manager.grid_slots[defending_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = defending_card  # Update the card data reference
			child.update_display()             # Refresh the visual display
			print("SurvivalAbility: Updated CardDisplay visual for survival card")
			break
	
	return true

func can_execute(context: Dictionary) -> bool:
	var defending_card = context.get("defending_card")
	if not defending_card:
		return false
	
	# Can only execute if survival hasn't been used yet
	return not (defending_card.has_meta("survival_used") and defending_card.get_meta("survival_used"))
