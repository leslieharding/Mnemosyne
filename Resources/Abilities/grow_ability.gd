# res://Resources/Abilities/grow_ability.gd
class_name GrowAbility
extends CardAbility

func _init():
	ability_name = "Grow"
	description = "On play, this card gains +1 to all stats for the entire run"
	trigger_condition = TriggerType.ON_PLAY

# Static helper function to get level-scaled growth amount
static func get_growth_for_level(card_level: int) -> int:
	# Every 2 levels: 1 + floor((level - 1) / 2)
	# Levels 1-2: +1, Levels 3-4: +2, Levels 5-6: +3, etc.
	return 1 + int(floor(float(card_level - 1) / 2.0))

# Static helper function to get dynamic description based on level
static func get_description_for_level(card_level: int) -> String:
	var growth_amount = get_growth_for_level(card_level)
	return "On play, this card gains +" + str(growth_amount) + " to all stats for the entire run"

# Static helper function to get base stat scaling for cards with Grow ability
# This gives permanent stat increases based on card level (separate from run growth)
static func get_stat_bonus_for_level(card_level: int) -> int:
	# Every 2 levels, same as growth scaling
	# Levels 1-2: +0, Levels 3-4: +1, Levels 5-6: +2, etc.
	return int(floor(float(card_level - 1) / 3.0))

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	var card_level = context.get("card_level", 1)
	
	print("GrowAbility: Starting execution for card at position ", grid_position, " (Level ", card_level, ")")
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("GrowAbility: Missing required context data")
		return false
	
	# Calculate level-scaled growth amount
	var growth_amount = get_growth_for_level(card_level)
	
	# Check for Seasons power and modify growth accordingly
	if game_manager.has_method("is_seasons_power_active") and game_manager.is_seasons_power_active():
		var current_season = game_manager.get_current_season()
		match current_season:
			game_manager.Season.SUMMER:
				growth_amount *= 2
				print("GrowAbility: Summer season - doubling growth to +", growth_amount)
			game_manager.Season.WINTER:
				growth_amount = -growth_amount
				print("GrowAbility: Winter season - reversing growth to ", growth_amount)
	
	var card_collection_index = game_manager.get_card_collection_index(grid_position)
	if card_collection_index == -1:
		print("GrowAbility: Could not find collection index for card at position ", grid_position)
		return false
	
	var growth_tracker = game_manager.get_node_or_null("/root/RunStatGrowthTrackerAutoload")
	if not growth_tracker:
		print("GrowAbility: RunStatGrowthTrackerAutoload not found!")
		return false
	
	growth_tracker.add_stat_growth(card_collection_index, growth_amount)
	
	# Apply the growth immediately to the card that was just played, clamping to minimum of 0
	placed_card.values[0] = max(0, placed_card.values[0] + growth_amount)  # North
	placed_card.values[1] = max(0, placed_card.values[1] + growth_amount)  # East
	placed_card.values[2] = max(0, placed_card.values[2] + growth_amount)  # South
	placed_card.values[3] = max(0, placed_card.values[3] + growth_amount)  # West
	
	if growth_amount > 0:
		print("GrowAbility activated! ", placed_card.card_name, " grew +", growth_amount, " to all stats!")
	else:
		print("GrowAbility activated! ", placed_card.card_name, " withered by ", abs(growth_amount), " to all stats!")
	print("New stats: ", placed_card.values)
	
	# Update the visual display
	var slot = game_manager.grid_slots[grid_position]
	for child in slot.get_children():
		if child is CardDisplay:
			child.card_data = placed_card
			child.update_display()
			print("GrowAbility: Updated CardDisplay visual for grown card")
			break
	
	return true

func can_execute(context: Dictionary) -> bool:
	return true
