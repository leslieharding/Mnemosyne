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
		print("Original stats: ", original_values)
		print("New stats: ", placed_card.values)
		
		# Update the visual display to show the new stats
		if game_manager.has_method("update_card_display"):
			game_manager.update_card_display(grid_position, placed_card)
		
		return true
	else:
		print(ability_name, " had no effect - no friendly cards found in same row/column")
		return false

func count_friendly_cards_in_row_and_column(grid_position: int, card_owner, game_manager) -> int:
	var grid_size = game_manager.grid_size
	var grid_x = grid_position % grid_size
	var grid_y = grid_position / grid_size
	var friendly_count = 0
	
	print("StandTogetherAbility: Checking row/column for position ", grid_position, " (", grid_x, ",", grid_y, ")")
	
	# Check all positions in the same row
	for x in range(grid_size):
		if x != grid_x:  # Don't count the card itself
			var check_position = grid_y * grid_size + x
			if is_friendly_card_at_position(check_position, card_owner, game_manager):
				friendly_count += 1
				print("  Found friendly card in same row at position ", check_position)
	
	# Check all positions in the same column
	for y in range(grid_size):
		if y != grid_y:  # Don't count the card itself
			var check_position = y * grid_size + grid_x
			if is_friendly_card_at_position(check_position, card_owner, game_manager):
				friendly_count += 1
				print("  Found friendly card in same column at position ", check_position)
	
	return friendly_count

func is_friendly_card_at_position(position: int, card_owner, game_manager) -> bool:
	# Check if position is occupied
	if not game_manager.grid_occupied[position]:
		return false
	
	# Check if the card at this position has the same owner
	var position_owner = game_manager.get_owner_at_position(position)
	return position_owner == card_owner

func can_execute(context: Dictionary) -> bool:
	return true
