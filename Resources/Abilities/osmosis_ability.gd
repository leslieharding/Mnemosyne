# res://Resources/Abilities/osmosis_ability.gd
class_name OsmosisAbility
extends CardAbility

func _init():
	ability_name = "Osmosis"
	description = "Gain the stats of any cards you capture"
	trigger_condition = TriggerType.ON_PLAY

func execute(context: Dictionary) -> bool:
	if not can_execute(context):
		return false
	
	# Get the card that was just placed
	var placed_card = context.get("placed_card")
	var grid_position = context.get("grid_position", -1)
	var game_manager = context.get("game_manager")
	
	print("OsmosisAbility: Starting execution for card at position ", grid_position)
	
	if not placed_card or grid_position == -1 or not game_manager:
		print("OsmosisAbility: Missing required context data")
		return false
	
	var osmosis_owner = game_manager.get_owner_at_position(grid_position)
	
	# Store the original stats before any combat
	var original_stats = placed_card.values.duplicate()
	
	# Perform normal combat to see what gets captured
	var combat_captures = perform_osmosis_combat(placed_card, grid_position, osmosis_owner, game_manager)
	
	if combat_captures.is_empty():
		print("OsmosisAbility: No captures made - ability has no effect")
		return false
	
	print("OsmosisAbility: ", combat_captures.size(), " cards captured through standard combat")
	
	# Track total stats gained per direction
	var stats_gained = [0, 0, 0, 0]
	
	# Absorb stats from each captured card
	for capture_data in combat_captures:
		var captured_position = capture_data.position
		var captured_card = capture_data.card
		
		print("OsmosisAbility: Absorbing stats from ", captured_card.card_name, " at position ", captured_position)
		print("  Captured card stats: ", captured_card.values)
		
		# Add captured card's stats directionally (North to North, East to East, etc.)
		for i in range(4):
			stats_gained[i] += captured_card.values[i]
	
	# Apply gained stats to osmosis card
	var total_stats_gained = stats_gained[0] + stats_gained[1] + stats_gained[2] + stats_gained[3]
	if total_stats_gained > 0:
		print("OsmosisAbility: Adding absorbed stats to osmosis card")
		print("Stats before absorption: ", original_stats)
		print("Stats to gain per direction: ", stats_gained)
		
		# Add the absorbed stats to original stats (not current stats that may have changed during combat)
		for i in range(placed_card.values.size()):
			placed_card.values[i] = original_stats[i] + stats_gained[i]
		
		print("Stats after absorption: ", placed_card.values)
		
		# Update the visual display for the osmosis card
		var osmosis_slot = game_manager.grid_slots[grid_position]
		for child in osmosis_slot.get_children():
			if child is CardDisplay:
				child.card_data = placed_card  # Update the card data reference
				child.update_display()  # Refresh the visual display
				print("OsmosisAbility: Updated CardDisplay visual for osmosis card at position ", grid_position)
				break
		
		print(ability_name, " activated! ", placed_card.card_name, " absorbed ", total_stats_gained, " total stats from ", combat_captures.size(), " captured cards!")
		return true
	
	return false

func perform_osmosis_combat(osmosis_card: CardResource, osmosis_position: int, osmosis_owner, game_manager) -> Array:
	"""Perform combat and return array of captured card data"""
	var captures = []
	
	# Check all four adjacent positions
	var directions = [
		{"index": 0, "name": "North", "attack_index": 0, "defense_index": 2},
		{"index": 1, "name": "East", "attack_index": 1, "defense_index": 3},
		{"index": 2, "name": "South", "attack_index": 2, "defense_index": 0},
		{"index": 3, "name": "West", "attack_index": 3, "defense_index": 1}
	]
	
	for direction in directions:
		var adj_index = game_manager.get_adjacent_position(osmosis_position, direction.index)
		
		if adj_index == -1:
			continue
		
		if not game_manager.grid_occupied[adj_index]:
			continue
		
		var adjacent_owner = game_manager.grid_ownership[adj_index]
		
		# Only attack enemies
		if adjacent_owner == osmosis_owner or adjacent_owner == game_manager.Owner.NONE:
			continue
		
		var adjacent_card = game_manager.get_card_at_position(adj_index)
		
		if not adjacent_card:
			continue
		
		var attack_value = osmosis_card.values[direction.attack_index]
		var defense_value = adjacent_card.values[direction.defense_index]
		
		print("OsmosisAbility: Combat ", direction.name, " - ", osmosis_card.card_name, " (", attack_value, ") vs ", adjacent_card.card_name, " (", defense_value, ")")
		
		# Check if osmosis attack wins
		if attack_value > defense_value:
			print("OsmosisAbility: Capture successful - capturing ", adjacent_card.card_name)
			
			# Store the captured card data BEFORE changing ownership
			captures.append({
				"position": adj_index,
				"card": adjacent_card
			})
			
			# Capture the enemy card
			game_manager.set_card_ownership(adj_index, osmosis_owner)
			
			# Execute ON_CAPTURE abilities on the captured card
			execute_capture_abilities(adjacent_card, adj_index, osmosis_card, osmosis_position, game_manager)
	
	return captures

func execute_capture_abilities(captured_card: CardResource, captured_position: int, capturing_card: CardResource, capturing_position: int, game_manager):
	"""Execute ON_CAPTURE abilities for captured cards"""
	var card_collection_index = game_manager.get_card_collection_index(captured_position)
	var card_level = game_manager.get_card_level(card_collection_index)
	
	if captured_card.has_ability_type(CardAbility.TriggerType.ON_CAPTURE, card_level):
		print("OsmosisAbility: Executing ON_CAPTURE abilities for captured card: ", captured_card.card_name)
		
		var capture_context = {
			"capturing_card": capturing_card,
			"capturing_position": capturing_position,
			"captured_card": captured_card,
			"captured_position": captured_position,
			"game_manager": game_manager,
			"direction": "osmosis",
			"card_level": card_level
		}
		
		captured_card.execute_abilities(CardAbility.TriggerType.ON_CAPTURE, capture_context, card_level)

func can_execute(context: Dictionary) -> bool:
	return true
