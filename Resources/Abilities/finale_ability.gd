# res://Resources/Abilities/finale_ability.gd
class_name FinaleAbility
extends CardAbility

func _init():
	ability_name = "Finale"
	description = "If this card is played in the last available slot its stats are doubled"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("FinaleAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("FinaleAbility: Missing required context data")
		return false
	
	# Count how many empty slots remain AFTER this card was placed
	var empty_slots_remaining = 0
	for i in range(game_manager.grid_occupied.size()):
		if not game_manager.grid_occupied[i]:
			empty_slots_remaining += 1
	
	print("FinaleAbility: Empty slots remaining after placement: ", empty_slots_remaining)
	
	# Check if this was played in the last available slot (only 1 empty slot remains)
	if empty_slots_remaining != 1:
		print("FinaleAbility: Not played in last available slot (", empty_slots_remaining, " slots remain), no bonus applied")
		return false
	
	print("FinaleAbility: Card played in the LAST AVAILABLE SLOT - doubling all stats!")
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Double all directional stats (multiply by 2)
	placed_card.values[0] *= 2  # North
	placed_card.values[1] *= 2  # East
	placed_card.values[2] *= 2  # South
	placed_card.values[3] *= 2  # West
	
	print("FinaleAbility: Stats doubled from ", original_values, " to ", placed_card.values)
	print(ability_name, " activated! ", placed_card.card_name, " stats doubled for being played in the last available slot!")
	
	# Update the visual display to show the new stats
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card  # Update the card data reference
			child.update_display()         # Refresh the visual display
			print("FinaleAbility: Updated CardDisplay visual for doubled card")
			break
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
