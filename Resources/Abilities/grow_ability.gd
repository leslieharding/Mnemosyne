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
	
	# Check for Seasons power and modify growth accordingly
	var growth_amount = 1  # Default growth
	if game_manager.has_method("is_seasons_power_active") and game_manager.is_seasons_power_active():
		var current_season = game_manager.get_current_season()
		match current_season:
			game_manager.Season.SUMMER:
				growth_amount = 2  # Double growth in Summer
				print("GrowAbility: Summer season - doubling growth to +2")
			game_manager.Season.WINTER:
				growth_amount = -1  # Reverse growth in Winter
				print("GrowAbility: Winter season - reversing growth to -1")
	
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
	
	# Apply the growth to this card (can be positive or negative based on season)
	growth_tracker.add_stat_growth(card_collection_index, growth_amount)
	
	# Apply the growth immediately to the card that was just played
	# This ensures the current combat uses the new grown stats
	placed_card.values[0] += growth_amount  # North
	placed_card.values[1] += growth_amount  # East
	placed_card.values[2] += growth_amount  # South
	placed_card.values[3] += growth_amount  # West
	
	if growth_amount > 0:
		print("GrowAbility activated! ", placed_card.card_name, " grew +", growth_amount, " to all stats!")
	else:
		print("GrowAbility activated! ", placed_card.card_name, " withered by ", abs(growth_amount), " to all stats!")
	print("New stats: ", placed_card.values)
	
	# FIXED: Update the visual display to show the new stats
	# Find the CardDisplay in the grid slot and update it directly
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card  # Update the card data reference
			child.update_display()         # Refresh the visual display
			print("GrowAbility: Updated CardDisplay visual for grown card")
			break
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
