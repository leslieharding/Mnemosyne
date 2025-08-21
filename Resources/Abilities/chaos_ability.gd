# res://Resources/Abilities/chaos_ability.gd
class_name ChaosAbility
extends CardAbility

func _init():
	ability_name = "Chaos"
	description = "On play, this card's stats are randomized (1-10 for each direction)"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("ChaosAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("ChaosAbility: Missing required context data")
		return false
	
	# Store original values for logging
	var original_values = placed_card.values.duplicate()
	
	# Randomize each direction independently (1-10)
	placed_card.values[0] = randi_range(1, 10)  # North
	placed_card.values[1] = randi_range(1, 10)  # East
	placed_card.values[2] = randi_range(1, 10)  # South
	placed_card.values[3] = randi_range(1, 10)  # West
	
	print("ChaosAbility activated! ", placed_card.card_name, " stats randomized!")
	print("Original stats: ", original_values)
	print("New stats: ", placed_card.values)
	
	# Update the visual display to show the new stats
	if game_manager.has_method("update_card_display"):
		game_manager.update_card_display(grid_position, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
