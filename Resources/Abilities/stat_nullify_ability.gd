# res://Resources/Abilities/stat_nullify_ability.gd
class_name StatNullifyAbility
extends CardAbility

func _init():
	ability_name = "Stat Nullify"
	description = "When this card is captured, its stats are reduced to 1,1,1,1 making it easier to recapture"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just captured (this card)
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var capturing_card = context.get("capturing_card")
	var game_manager = context.get("game_manager")
	
	print("StatNullifyAbility: Starting execution for captured card at position ", captured_position)
	
	# Safety checks
	if not captured_card:
		print("StatNullifyAbility: No captured card provided")
		return false
	
	if captured_position == -1:
		print("StatNullifyAbility: Invalid captured position")
		return false
	
	if not game_manager:
		print("StatNullifyAbility: No game manager provided")
		return false
	
	# Check if stats are already at minimum (1,1,1,1) - no need to nullify
	var already_nullified = true
	for value in captured_card.values:
		if value > 1:
			already_nullified = false
			break
	
	if already_nullified:
		print("StatNullifyAbility: Card stats are already at minimum (1,1,1,1), no nullification needed")
		return false  # Return false to indicate no effect occurred
	
	# Store original values for logging
	var original_values = captured_card.values.duplicate()
	
	# Set all stats to 1,1,1,1
	captured_card.values[0] = 1  # North
	captured_card.values[1] = 1  # East
	captured_card.values[2] = 1  # South
	captured_card.values[3] = 1  # West
	
	print(ability_name, " activated! ", captured_card.card_name, " was captured and nullified its own stats!")
	print("Stats changed from ", original_values, " to ", captured_card.values)
	
	# Update the visual display
	if game_manager.has_method("update_card_display"):
		game_manager.update_card_display(captured_position, captured_card)
	
	# VISUAL EFFECT: Show stat nullify arrow (only when stats actually changed)
	var card_display = game_manager.get_card_display_at_position(captured_position)
	if card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.show_stat_nullify_arrow(card_display)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
