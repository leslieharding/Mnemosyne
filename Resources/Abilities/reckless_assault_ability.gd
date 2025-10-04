# res://Resources/Abilities/reckless_assault_ability.gd
class_name RecklessAssaultAbility
extends CardAbility

func _init():
	ability_name = "Reckless Assault"
	description = "After combat this card's stats are reduced to 1"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("RecklessAssaultAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("RecklessAssaultAbility: Missing required context data")
		return false
	
	# Check if already reduced to prevent multiple applications
	if placed_card.has_meta("reckless_assault_applied") and placed_card.get_meta("reckless_assault_applied"):
		print("RecklessAssaultAbility: Already applied - skipping")
		return false
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Wait for combat to complete before reducing stats
	# This allows the card to use its full power during initial combat
	await game_manager.get_tree().process_frame
	
	# Verify the card still exists at this position after combat
	var current_card = game_manager.get_card_at_position(grid_position)
	if not current_card or current_card != placed_card:
		print("RecklessAssaultAbility: Card no longer at position ", grid_position, " - checking all positions")
		# Card might have moved or been captured - find it
		grid_position = find_card_position(placed_card, game_manager)
		if grid_position == -1:
			print("RecklessAssaultAbility: Card not found on board - likely destroyed")
			return false
	
	# Reduce all stats to 1
	placed_card.values[0] = 1  # North
	placed_card.values[1] = 1  # East
	placed_card.values[2] = 1  # South
	placed_card.values[3] = 1  # West
	
	# Mark as applied so it doesn't trigger again
	placed_card.set_meta("reckless_assault_applied", true)
	
	print("RecklessAssaultAbility activated! ", placed_card.card_name, " exhausted after combat!")
	print("Original stats: ", original_values)
	print("New stats: ", placed_card.values)
	
	# Update the visual display to show the new stats
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card
			child.update_display()
			print("RecklessAssaultAbility: Updated CardDisplay visual for exhausted card")
			break
	
	return true

func find_card_position(card: CardResource, game_manager) -> int:
	"""Find the current position of a card on the board"""
	for i in range(game_manager.grid_card_data.size()):
		if game_manager.grid_card_data[i] == card:
			return i
	return -1

func can_execute(context: Dictionary) -> bool:
	return true
