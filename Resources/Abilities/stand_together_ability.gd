# res://Resources/Abilities/stand_together_ability.gd
class_name StandTogetherAbility
extends CardAbility

func _init():
	ability_name = "Stand Together"
	description = "On play this card gains +1 stats for each friendly card in the same row or column."
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("StandTogetherAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("StandTogetherAbility: Missing required context data")
		return false
	
	# Get the owner of this card
	var card_owner = game_manager.get_owner_at_position(grid_position)
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Count friendly cards in same row and column
	var friendly_count = count_friendly_cards_in_row_and_column(grid_position, card_owner, game_manager)
	
	print("StandTogetherAbility: Found ", friendly_count, " friendly cards in same row/column")
	
	# Apply the stat boost (+1 per friendly card to each direction)
	if friendly_count > 0:
		placed_card.values[0] += friendly_count  # North
		placed_card.values[1] += friendly_count  # East
		placed_card.values[2] += friendly_count  # South
		placed_card.values[3] += friendly_count  # West
		
		print(ability_name, " activated! ", placed_card.card_name, " gained +", friendly_count, " to all stats!")
		print("Stats boosted from ", original_values, " to ", placed_card.values)
		
		# FIXED: Update the visual display to show the new stats
		var slot = game_manager.grid_slots[grid_position]
		for child in slot.get_children():
			if child is CardDisplay:
				child.card_data = placed_card  # Update the card data reference
				child.update_display()         # Refresh the visual display
				print("StandTogetherAbility: Updated CardDisplay visual for boosted card")
				break
		
		return true
	else:
		print("StandTogetherAbility: No friendly cards in same row/column - no boost applied")
		return false

func count_friendly_cards_in_row_and_column(grid_position: int, card_owner, game_manager) -> int:
	var grid_size = game_manager.grid_size  # Should be 3 for 3x3 grid
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	var friendly_count = 0
	
	print("StandTogetherAbility: Checking row ", grid_y, " and column ", grid_x, " for friendly cards")
	
	# Check same row (exclude self)
	for x in range(grid_size):
		if x == grid_x:  # Skip self
			continue
		var check_position = grid_y * grid_size + x
		if game_manager.grid_occupied[check_position]:
			var check_owner = game_manager.get_owner_at_position(check_position)
			if check_owner == card_owner:
				var friendly_card = game_manager.get_card_at_position(check_position)
				print("  Found friendly card in same row: ", friendly_card.card_name, " at position ", check_position)
				friendly_count += 1
	
	# Check same column (exclude self)
	for y in range(grid_size):
		if y == grid_y:  # Skip self
			continue
		var check_position = y * grid_size + grid_x
		if game_manager.grid_occupied[check_position]:
			var check_owner = game_manager.get_owner_at_position(check_position)
			if check_owner == card_owner:
				var friendly_card = game_manager.get_card_at_position(check_position)
				print("  Found friendly card in same column: ", friendly_card.card_name, " at position ", check_position)
				friendly_count += 1
	
	return friendly_count

func can_execute(context: Dictionary) -> bool:
	return true
