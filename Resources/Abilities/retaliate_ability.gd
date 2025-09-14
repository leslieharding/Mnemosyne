# res://Resources/Abilities/retaliate_ability.gd
class_name RetaliateAbility
extends CardAbility

func _init():
	ability_name = "Retaliate"
	description = "When this card is captured, it weakens the attacking card's stats to 1,1,1,1"
	trigger_condition = TriggerType.ON_CAPTURE

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just captured (this retaliate card)
	var captured_card = context.get("captured_card")
	var captured_position = context.get("captured_position", -1)
	var capturing_card = context.get("capturing_card")
	var capturing_position = context.get("capturing_position", -1)
	var game_manager = context.get("game_manager")
	
	print("RetaliateAbility: Starting execution for captured card at position ", captured_position)
	
	# Safety checks
	if not captured_card:
		print("RetaliateAbility: No captured card provided")
		return false
	
	if captured_position == -1:
		print("RetaliateAbility: Invalid captured position")
		return false
	
	if not capturing_card:
		print("RetaliateAbility: No capturing card provided")
		return false
	
	if capturing_position == -1:
		print("RetaliateAbility: Invalid capturing position")
		return false
	
	if not game_manager:
		print("RetaliateAbility: No game manager provided")
		return false
	
	# Check if the attacking card already has 1,1,1,1 stats - no need to retaliate
	var already_weakened = true
	for value in capturing_card.values:
		if value > 1:
			already_weakened = false
			break
	
	if already_weakened:
		print("RetaliateAbility: Attacking card stats are already at minimum (1,1,1,1), no retaliation needed")
		return false  # Return false to indicate no effect occurred
	
	# Store original values for logging
	var original_values = capturing_card.values.duplicate()
	
	# Weaken all attacking card stats to 1,1,1,1
	capturing_card.values[0] = 1  # North
	capturing_card.values[1] = 1  # East
	capturing_card.values[2] = 1  # South
	capturing_card.values[3] = 1  # West
	
	print(ability_name, " activated! ", captured_card.card_name, " was captured but retaliated against ", capturing_card.card_name, "!")
	print("Attacking card stats weakened from ", original_values, " to ", capturing_card.values)
	
	# VISUAL EFFECT: Show stat nullify arrow on the attacking card (reusing existing effect)
	var attacking_card_display = game_manager.get_card_display_at_position(capturing_position)
	if attacking_card_display and game_manager.visual_effects_manager:
		game_manager.visual_effects_manager.show_stat_nullify_arrow(attacking_card_display)
	
	# Update the visual display AFTER the arrow effect to ensure it sticks
	game_manager.call_deferred("update_board_visuals")
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
