# res://Resources/Abilities/grow_ability.gd
class_name GrowAbility
extends CardAbility

func _init():
	ability_name = "Grow"
	description = "On play, this card gains +1 to all stats for the entire run"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("GrowAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("GrowAbility: Missing required context data")
		return false
	
	# Get the card's collection index from the game manager
	var card_collection_index = game_manager.get_card_collection_index(grid_position)
	if card_collection_index == -1:
		print("GrowAbility: Could not find collection index for card at position ", grid_position)
		return false
	
	# Get the run stat growth tracker through the game manager
	var growth_tracker = game_manager.get_node_or_null("/root/RunStatGrowthTrackerAutoload")
	if not growth_tracker:
		print("GrowAbility: RunStatGrowthTrackerAutoload not found!")
		return false
	
	# Apply +1 growth to this card
	growth_tracker.add_stat_growth(card_collection_index, 1)
	
	# Apply the growth immediately to the card that was just played
	# This ensures the current combat uses the new grown stats
	placed_card.values[0] += 1  # North
	placed_card.values[1] += 1  # East
	placed_card.values[2] += 1  # South
	placed_card.values[3] += 1  # West
	
	print("GrowAbility activated! ", placed_card.card_name, " grew +1 to all stats!")
	print("New stats: ", placed_card.values)
	
	# Update the visual display to show the new stats
	if game_manager.has_method("update_card_display"):
		game_manager.update_card_display(grid_position, placed_card)
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
